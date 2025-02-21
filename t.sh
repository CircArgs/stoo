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
            margin: 0;
            display: flex;
            height: 100vh;
            overflow: hidden;
        }
        .sidebar {
            width: 250px;
            background: #007bff;
            color: white;
            display: flex;
            flex-direction: column;
            padding: 20px;
            box-shadow: 2px 0px 5px rgba(0, 0, 0, 0.2);
        }
        .sidebar h2 {
            margin-top: 0;
            font-size: 20px;
        }
        .tab-button {
            background: none;
            border: none;
            color: white;
            padding: 12px;
            text-align: left;
            width: 100%;
            cursor: pointer;
            font-size: 16px;
            transition: background 0.3s;
        }
        .tab-button:hover, .tab-button.active {
            background: rgba(255, 255, 255, 0.2);
        }
        .status {
            font-size: 14px;
            margin-left: 10px;
        }
        .status.up { color: lightgreen; }
        .status.down { color: red; }
        .main-content {
            flex: 1;
            display: flex;
            flex-direction: column;
            height: 100vh;
        }
        .header {
            background: #f4f4f4;
            padding: 10px;
            text-align: center;
            font-size: 20px;
            font-weight: bold;
        }
        .iframe-container {
            flex: 1;
            overflow: hidden;
        }
        iframe {
            width: 100%;
            height: 100%;
            border: none;
        }
        .info-box {
            padding: 10px;
            font-size: 14px;
            text-align: center;
            background: #f4f4f4;
        }
        .info-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }
        .info-table th, .info-table td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        .info-table th {
            background: #007bff;
            color: white;
        }
    </style>
</head>
<body>

    <div class="sidebar">
        <h2>Workflow Dev Env</h2>
        <button class="tab-button" onclick="loadTab('https://example.com', this)">Example 
            <span id="status-example" class="status">Checking...</span>
        </button>
        <button class="tab-button" onclick="loadTab('https://google.com', this)">Google 
            <span id="status-google" class="status">Checking...</span>
        </button>

        <div class="info-box">
            <p>Uptime: <span id="uptime">Calculating...</span></p>
            <table class="info-table">
                <tr>
                    <th>Client Version</th>
                    <td>$CLIENT_VERSION</td>
                </tr>
                <tr>
                    <th>Workflow Chart Version</th>
                    <td>$WORKFLOW_CHART_VERSION</td>
                </tr>
            </table>
        </div>
    </div>

    <div class="main-content">
        <div class="header">Select an option from the sidebar</div>
        <div class="iframe-container">
            <iframe id="content-frame" src=""></iframe>
        </div>
    </div>

    <script>
        function loadTab(url, button) {
            document.getElementById("content-frame").src = url;
            document.querySelectorAll(".tab-button").forEach(btn => btn.classList.remove("active"));
            button.classList.add("active");
        }

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
