# Grok 3 Web API Wrapper

This is a Go-based tool designed to interact with the Grok 3 Web API, offering an OpenAI-compatible API endpoint for chat completions. It enables users to send messages to the Grok 3 Web API and receive responses in a format consistent with OpenAI's chat completion API.

This project includes Docker support for easy setup and deployment.

## Features

- **OpenAI-Compatible Endpoint**: Supports `/v1/chat/completions` and `/v1/models` endpoints.
- **Streaming Support**: Enables real-time streaming of responses.
- **Model Selection**: Choose between standard (`grok-3`) and reasoning (`grok-3-reasoning`) models.
- **Cookie Management**: Manages multiple cookies for load balancing or rotation.
- **Proxy Support**: Compatible with HTTP and SOCKS5 proxies for network requests.
- **Configurable Options**: Includes flags/options for retaining chat conversations, filtering thinking content, enabling web search, and more.
- **Dockerized**: Easy setup and deployment using Docker and Docker Compose.

## Prerequisites

Before you use this tool, ensure you have the following:

- **Grok Cookie**: Obtain your account's cookie from [grok.com](https://grok.com) using your browser's developer tools (look for the `cookie` header in requests to `grok.com` or individual cookie values like `aaa=bbb; ccc=ddd`).
- **API Authentication Token**: Prepare a secret token to secure the OpenAI-compatible API endpoints you will expose. This is a token *you* define for clients connecting to *this wrapper*, not a token from xAI.
- **Go Environment (Optional)**: A working Go installation (version specified in `go.mod`) is needed if you plan to build from source instead of using Docker.
- **Docker & Docker Compose**: Required for the recommended deployment method. Install from [Docker's official website](https://www.docker.com/get-started).
- **Git**: Required to clone the repository.

## Running with Docker (Recommended Method)

Using Docker Compose is the recommended way to run this application locally or on a server.

1.  **Clone the Repository**:
    ```bash
    git clone [https://github.com/juju-w/grok3_api_docker.git](https://github.com/juju-w/grok3_api_docker.git) # Replace with the actual URL
    cd grok3_api_docker
    ```

2.  **Create Configuration File**:
    Copy the example environment file if provided:
    ```bash
    # cp .env.example .env # Uncomment if you provide a .env.example file
    ```
    Or create a new `.env` file in the project root directory with the following content:

    ```env
    # .env file - Configure your Grok 3 Wrapper - DO NOT COMMIT TO GIT

    # --- Required ---
    # Define a secret token that clients will use to authenticate with this wrapper API
    GROK3_AUTH_TOKEN=YOUR_SECRET_WRAPPER_TOKEN_HERE

    # Your Grok Cookie(s) obtained from grok.com
    # Can be a single string or a JSON array string like '["cookie1", "cookie2"]'
    GROK3_COOKIE='YOUR_GROK_COOKIE_STRING_OR_JSON_HERE'

    # --- Optional Overrides ---
    # Port mapping: HOST_PORT is the port accessible on your machine, CONTAINER_PORT is internal to Docker (usually keep 8180)
    HOST_PORT=8180
    CONTAINER_PORT=8180

    # Uncomment and set path inside container if using a cookie file via volume mount (requires docker-compose.yml modification)
    # COOKIE_FILE_PATH=/app/cookies.txt

    # Other optional flags (uncomment to override defaults set in Go code or docker-compose command)
    # TEXT_BEFORE_PROMPT="Custom text before prompt"
    # TEXT_AFTER_PROMPT="Custom text after prompt"
    # KEEP_CHAT=true
    # IGNORE_THINKING=true
    # CHARS_LIMIT=60000
    # HTTP_PROXY=socks5://user:password@your_proxy_host:1080
    ```
    **Important**: Fill in `GROK3_AUTH_TOKEN` with a strong secret token you create and `GROK3_COOKIE` with your actual Grok cookie(s). Add this `.env` file to your `.gitignore` to prevent committing secrets.

3.  **Build and Run**:
    ```bash
    docker-compose up -d --build
    ```
    * `up`: Creates and starts the container.
    * `-d`: Runs in detached mode (background).
    * `--build`: Builds the Docker image from the Dockerfile before starting (required first time or after code/Dockerfile changes).

4.  **Access the API**:
    The OpenAI-compatible API endpoints will be available at `http://localhost:${HOST_PORT}/v1` (default: `http://localhost:8180/v1`). Use the `GROK3_AUTH_TOKEN` you defined in the `.env` file as the Bearer token for authorization.

5.  **Stopping**:
    ```bash
    docker-compose down
    ```

## Building and Running from Source (Alternative Method)

If you prefer not to use Docker, you can build and run the application directly from the source code.

1.  **Clone the Repository**:
    ```bash
    git clone [https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME.git](https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME.git) # Replace with the actual URL
    cd YOUR_REPO_NAME
    ```

2.  **Build the Binary**:
    Ensure you have a compatible Go environment installed.
    ```bash
    go build -o grok3-adapter main.go
    ```
    This creates an executable file named `grok3-adapter` (or `grok3-adapter.exe` on Windows).

3.  **Run the Application**:
    You need to provide the required authentication token and cookie via command-line flags or environment variables.
    ```bash
    ./grok3-adapter -token YOUR_SECRET_WRAPPER_TOKEN_HERE -cookie 'YOUR_GROK_COOKIE_STRING' [other flags...]
    ```
    Or using environment variables:
    ```bash
    export GROK3_AUTH_TOKEN="YOUR_SECRET_WRAPPER_TOKEN_HERE"
    export GROK3_COOKIE='YOUR_GROK_COOKIE_STRING'
    ./grok3-adapter [other flags...]
    ```
    Refer to the "Configuration Details" section below for all available flags.

4.  **Access the API**:
    The API will be available at `http://localhost:8180/v1` (or the port specified with the `-port` flag).

## Configuration Details

Configuration can be provided via command-line flags, environment variables, or overridden per-request in the API call body.

### Priority

1.  **Command-line flags** passed directly to the Go binary have the highest priority.
2.  **Environment Variables**: `GROK3_AUTH_TOKEN` and `GROK3_COOKIE` are directly read by the Go application as alternatives to flags.
3.  **Request Body (Completions)**: Specific parameters like `model`, `stream`, `grokCookies`, `keepChat` etc., can be overridden per-request in the JSON body sent to the `/v1/chat/completions` endpoint.

### Configuration Options Reference

(Referencing the Go application's flags)

* `-token` / `GROK3_AUTH_TOKEN` (Env Var): API authentication token for clients connecting to this wrapper (**required**).
* `-cookie` / `GROK3_COOKIE` (Env Var): Grok cookie(s). Accepts a single string or a JSON array string.
* `-cookieFile`: Path to a text file containing Grok cookies line by line.
* `-textBeforePrompt`: Text prepended to the prompt sent to Grok.
* `-textAfterPrompt`: Text appended to the prompt sent to Grok.
* `-keepChat`: Boolean flag. Retains chat conversations if set.
* `-ignoreThinking`: Boolean flag. Excludes thinking tokens.
* `-charsLimit`: Character limit before uploading message as file (default: 50,000).
* `-httpProxy`: HTTP or SOCKS5 proxy URL (e.g., `http://127.0.0.1:1080`, `socks5://user:pass@host:port`).
* `-port`: Server port *inside the container* (default: 8180).
* `-help`: Prints the help message detailing all flags and defaults.

*(Note: When running with Docker Compose, flags like `-port`, `-keepChat`, etc., are typically set via the `command:` section in `docker-compose.yml`, which sources values from the `.env` file.)*

### Request Body Options (for `/v1/chat/completions`)

These JSON fields override other configurations for a specific request:

```json
{
  "messages": [ { "role": "user", "content": "Hello!" } ],
  "model": "grok-3", // "grok-3" or "grok-3-reasoning"
  "stream": false, // true or false
  "grokCookies": "override_cookie_string", // Optional: Override cookies for this request
  "cookieIndex": 2, // Optional: Select a specific cookie from the list (1-based index)
  "enableSearch": 1, // Optional: 1 to enable web search
  "uploadMessage": 0, // Optional: 1 forces upload as file, 0 uses charsLimit logic
  "textBeforePrompt": "Override system prompt", // Optional
  "textAfterPrompt": "Override suffix", // Optional
  "keepChat": 0, // Optional: 1 forces keep, 0 forces temporary
  "ignoreThinking": 0 // Optional: 1 forces ignore, 0 forces include
}
```

## Warnings

This tool offers an unofficial OpenAI-compatible API of Grok 3, so your account may be **banned** by xAI if using this tool.

Please do not abuse or use this tool for commercial purposes. Use it at your own risk.

## Special Thanks

- [orzogc/grok3_api](https://github.com/orzogc/grok3_api)
- [mem0ai/grok3-api: Unofficial Grok 3 API](https://github.com/mem0ai/grok3-api)
- [RoCry/grok3-api-cf: Grok 3 via API with Cloudflare for free](https://github.com/RoCry/grok3-api-cf/tree/master)
- Most code was written by Grok 3, thanks to Grok 3.
- Most Dockerized code was written by Gemini-2.5-pro-exp-0325, thanks google.

## License

This project is licensed under the `AGPL-3.0` License.
