#!/usr/bin/env python3
"""
Test script for SSE Client Tool
"""
import json
import sys
from pathlib import Path

import httpx


def test_sse_stream_direct():
    """Test SSE stream directly without Tool class"""
    # Parameters matching the curl command
    url = "https://rag-fat.gz.cvte.cn/qs/deepagent/ask/stream"
    method = "POST"
    headers = {
        "Content-Type": "application/json"
    }
    body = {
        "question": "CX2715灯板的驱动芯片/芯片型号是什么？",
        "thread_id": "test-001"
    }
    
    print("=" * 80)
    print("Testing SSE Stream (Direct)")
    print("=" * 80)
    print(f"URL: {url}")
    print(f"Method: {method}")
    print(f"Headers: {headers}")
    print(f"Body: {body}")
    print("=" * 80)
    print("\nStreaming response:\n")
    
    try:
        has_data = False
        buffer = ""
        done = False
        message_count = 0
        total_chars = 0
        
        def process_sse_line(line: str):
            """Process a single SSE line"""
            # Skip comment lines
            if line.startswith(":"):
                return None, False
            
            # Process data lines
            if line.startswith("data: "):
                data = line[6:]
                if data.strip() == "[DONE]":
                    return None, True
                if data:
                    return data, False
                else:
                    # Empty data: line represents a newline
                    return "\n", False
            elif line == "data:":
                # data: without space also represents a newline
                return "\n", False
            elif line and not line.startswith("data:"):
                # Non-standard format, treat as data
                return line, False
            
            return None, False
        
        with httpx.stream(method, url, headers=headers, json=body, timeout=None) as response:
            response.raise_for_status()
            
            # Process SSE stream using raw bytes to preserve newlines
            for chunk in response.iter_bytes():
                if not chunk or done:
                    continue
                
                buffer += chunk.decode('utf-8', errors='replace')
                
                # Process complete lines from buffer
                while '\n' in buffer:
                    line, buffer = buffer.split('\n', 1)
                    
                    # Empty line marks end of SSE event
                    if not line.strip():
                        continue
                    
                    content, is_done = process_sse_line(line)
                    if is_done:
                        done = True
                        buffer = ""
                        break
                    if content is not None:
                        has_data = True
                        message_count += 1
                        print(content, end='', flush=True)
                        total_chars += len(content)
            
            # Process any remaining data in buffer
            if buffer.strip() and not done:
                content, is_done = process_sse_line(buffer)
                if not is_done and content is not None:
                    has_data = True
                    message_count += 1
                    print(content, end='', flush=True)
                    total_chars += len(content)
        
        print("\n\n" + "=" * 80)
        print(f"Total messages received: {message_count}")
        print(f"Total characters received: {total_chars}")
        if not has_data:
            print("WARNING: No data received from SSE stream")
        print("=" * 80)
        
    except KeyboardInterrupt:
        print("\n\nTest interrupted by user")
        sys.exit(0)
    except Exception as e:
        print(f"\n\nError occurred: {str(e)}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    test_sse_stream_direct()

