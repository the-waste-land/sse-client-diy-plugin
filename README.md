# SSE Client Plugin

This plugin provides a tool to make SSE (Server-Sent Events) requests and stream the output.

## Tools

### SSE Client

Makes an HTTP request to an SSE endpoint and streams the `data` field of the received events.

#### Parameters

- **URL**: The URL to make the request to.
- **Method**: HTTP method (GET or POST). Default is GET.
- **Headers**: JSON string of headers to include in the request.
- **Body**: JSON string of the body to include in the request (for POST).

#### Output

Streams the content of the `data` field from the SSE events.
