#!/bin/bash

# Create a temporary file
TMP_FILE=$(mktemp)
TMP_HTML="${TMP_FILE}.html"
mv "$TMP_FILE" "$TMP_HTML"

# Define the UTC start time (modify as needed)
START_TIME="2025-02-19T12:00:00Z"

# Define fake versions (replace with actual logic if needed)
CLIENT_VERSION="1.2.3"
WORKFLOW_CHART_VERSION="4.5.6"

# Write HTML content with JavaScript
cat > "$TMP_HTML" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Workflow Development Environment</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f4f4;
            text-align: center;
            margin: 0;
            padding: 20px;
        }
        .container {
            background: white;
            max-width: 700px;
            margin: 20px auto;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0px 4px 6px rgba(0, 0, 0, 0.1);
        }
        h1 {
            color: #333;
            font-size: 24px;
        }
        .button-container {
            margin: 20px 0;
        }
        .link-button {
            display: flex;
            justify-content: space-between;
            align-items: center;
            background-color: #007bff;
            color: white;
            text-decoration: none;
            padding: 10px 15px;
            margin: 10px auto;
            border-radius: 5px;
            width: 80%;
            max-width: 300px;
            font-size: 16px;
            font-weight: bold;
            transition: background 0.3s;
        }
        .link-button:hover {
            background-color: #0056b3;
        }
        .status {
            font-size: 14px;
            margin-left: 10px;
        }
        .status.up { color: green; }
        .status.down { color: red; }
        .info {
            font-size: 14px;
            color: #666;
            margin-top: 20px;
        }
        .uptime {
            font-weight: bold;
            color: #333;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 10px;
            text-align: left;
        }
        th {
            background-color: #007bff;
            color: white;
        }
        td {
            background-color: #f9f9f9;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Workflow Development Environment</h1>
        
        <div class="button-container">
            <a href="https://example.com" target="_blank" class="link-button">
                Example
                <span id="status-example" class="status">Checking...</span>
            </a>
            <a href="https://google.com" target="_blank" class="link-button">
                Google
                <span id="status-google" class="status">Checking...</span>
            </a>
        </div>

        <div class="info">
            <p>This page provides quick access to important resources in your workflow development environment.</p>
            <p>Click on the buttons above to open the respective tools.</p>
        </div>

        <div class="info">
            <p>Environment has been up for: <span id="uptime" class="uptime">Calculating...</span></p>
        </div>

        <table>
            <tr>
                <th>Parameter</th>
                <th>Value</th>
            </tr>
            <tr>
                <td>Client Version</td>
                <td>$CLIENT_VERSION</td>
            </tr>
            <tr>
                <td>Workflow Chart Version</td>
                <td>$WORKFLOW_CHART_VERSION</td>
            </tr>
        </table>
    </div>

    <script>
        // List of sites to check
        const sites = [
            { url: "https://example.com", id: "status-example" },
            { url: "https://google.com", id: "status-google" }
        ];

        // Function to check if a site is reachable
        function checkStatus(url, elementId) {
            fetch(url, { mode: 'no-cors' }) // no-cors to avoid blocking issues
                .then(() => {
                    document.getElementById(elementId).textContent = "✅ Up";
                    document.getElementById(elementId).classList.add("up");
                })
                .catch(() => {
                    document.getElementById(elementId).textContent = "❌ Down";
                    document.getElementById(elementId).classList.add("down");
                });
        }

        // Run status checks
        sites.forEach(site => checkStatus(site.url, site.id));

        // Uptime Counter
        const startTime = new Date("$START_TIME");
        
        function updateUptime() {
            const now = new Date();
            const diff = now - startTime;
            
            // Convert difference into readable format
            const seconds = Math.floor(diff / 1000) % 60;
            const minutes = Math.floor(diff / (1000 * 60)) % 60;
            const hours = Math.floor(diff / (1000 * 60 * 60)) % 24;
            const days = Math.floor(diff / (1000 * 60 * 60 * 24));

            document.getElementById("uptime").textContent = 
                \`\${days}d \${hours}h \${minutes}m \${seconds}s\`;
        }

        // Update uptime every second
        setInterval(updateUptime, 1000);
        updateUptime(); // Initial call
    </script>
</body>
</html>
EOF

# Open the temporary HTML file in the default browser
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    xdg-open "$TMP_HTML"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    open "$TMP_HTML"
else
    echo "Unsupported OS"
fi
