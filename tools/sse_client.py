import json
from collections.abc import Generator
from typing import Any

import httpx
from dify_plugin import Tool
from dify_plugin.entities.tool import ToolInvokeMessage

class SSEClientTool(Tool):
    def _process_sse_line(self, line: str) -> tuple[ToolInvokeMessage | None, bool]:
        """
        Process a single SSE line and return (message, is_done).
        Returns (message, False) if data should be yielded, (None, True) if [DONE], (None, False) otherwise.
        """
        # Skip comment lines (lines starting with :)
        if line.startswith(":"):
            return None, False
        
        # Process data lines
        if line.startswith("data: "):
            data = line[6:]
            if data.strip() == "[DONE]":
                return None, True
            if data:
                return self.create_text_message(data), False
            else:
                # Empty data: line represents a newline character in SSE protocol
                return self.create_text_message("\n"), False
        elif line == "data:":
            # data: without space also represents a newline
            return self.create_text_message("\n"), False
        elif line and not line.startswith("data:"):
            # Non-standard format, treat as data and yield immediately
            return self.create_text_message(line), False
        
        return None, False

    def _invoke(self, tool_parameters: dict[str, Any]) -> Generator[ToolInvokeMessage, None, None]:
        url = tool_parameters.get("url")
        method = tool_parameters.get("method", "GET")
        headers_str = tool_parameters.get("headers", "{}")
        body_str = tool_parameters.get("body", "{}")

        try:
            headers = json.loads(headers_str.strip()) if headers_str and headers_str.strip() else {}
        except json.JSONDecodeError:
            yield self.create_text_message("Error: Invalid JSON for headers")
            return

        try:
            body = json.loads(body_str.strip()) if body_str and body_str.strip() else {}
        except json.JSONDecodeError:
            yield self.create_text_message("Error: Invalid JSON for body")
            return

        try:
            with httpx.stream(method, url, headers=headers, json=body if method == "POST" else None, timeout=None) as response:
                response.raise_for_status()
                
                has_data = False
                buffer = ""
                done = False
                
                # Process SSE stream using raw bytes to preserve newlines
                for chunk in response.iter_bytes():
                    if not chunk or done:
                        continue
                    
                    buffer += chunk.decode('utf-8', errors='replace')
                    
                    # Process complete lines from buffer
                    while '\n' in buffer:
                        line, buffer = buffer.split('\n', 1)
                        
                        # Empty line marks end of SSE event in SSE protocol
                        if not line.strip():
                            continue
                        
                        message, is_done = self._process_sse_line(line)
                        if is_done:
                            done = True
                            buffer = ""
                            break
                        if message is not None:
                            has_data = True
                            yield message
                
                # Process any remaining data in buffer
                if buffer.strip() and not done:
                    message, is_done = self._process_sse_line(buffer)
                    if not is_done and message is not None:
                        has_data = True
                        yield message
                
                if not has_data:
                    yield self.create_text_message("No data received from SSE stream")
                    
        except httpx.RequestError as e:
            yield self.create_text_message(f"Error: Request failed - {str(e)}")
        except Exception as e:
            yield self.create_text_message(f"Error: {str(e)}")
