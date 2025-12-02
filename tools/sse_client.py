import json
from collections.abc import Generator
from typing import Any

import httpx
from dify_plugin import Tool
from dify_plugin.entities.tool import ToolInvokeMessage

class SSEClientTool(Tool):
    def _invoke(self, tool_parameters: dict[str, Any]) -> Generator[ToolInvokeMessage, None, None]:
        url = tool_parameters.get("url")
        method = tool_parameters.get("method", "GET")
        headers_str = tool_parameters.get("headers", "{}")
        body_str = tool_parameters.get("body", "{}")

        try:
            headers = json.loads(headers_str) if headers_str else {}
        except json.JSONDecodeError:
            yield self.create_text_message("Error: Invalid JSON for headers")
            return

        try:
            body = json.loads(body_str) if body_str else {}
        except json.JSONDecodeError:
            yield self.create_text_message("Error: Invalid JSON for body")
            return

        try:
            with httpx.stream(method, url, headers=headers, json=body if method == "POST" else None, timeout=None) as response:
                response.raise_for_status()
                for line in response.iter_lines():
                    if line.startswith("data: "):
                        data = line[6:]
                        if data == "[DONE]":
                            break
                        # Try to parse JSON and extract text if possible, otherwise yield raw data
                        # For generic usage, we yield the raw data string plus a newline to separate events if needed?
                        # Or just yield the data chunk.
                        # If the user wants to stream text, they usually expect the content directly.
                        # But if the SSE sends JSON objects, we might want to yield the whole JSON string.
                        yield self.create_text_message(data)
        except httpx.RequestError as e:
            yield self.create_text_message(f"Error: Request failed - {str(e)}")
        except Exception as e:
            yield self.create_text_message(f"Error: {str(e)}")
