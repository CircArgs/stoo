#!/bin/bash

# Create a temporary file
TMP_FILE=$(mktemp)
TMP_HTML="${TMP_FILE}.html"
mv "$TMP_FILE" "$TMP_HTML"

# Define the UTC start time (modify as needed)
START_TIME="2025-02-19T12:00:00Z"
EXPIRATION_HOURS=36  # Environment expiration time in hours

# Define Links (Format: "Display Name|URL")
LINKS=(
    "Example|https://hugiugig.com"
    "Google|https://fghgfhgf.com"
    "GitHub|https://gitviuygiuygihub.com"
)

# Define Information (Format: "Parameter Name|Value")
INFO=(
    "Client Version|1.2.3"
    "Workflow Chart Version|4.5.6"
    "Server Status|Running"
    "Last Deployment|2025-02-19 14:00 UTC"
)

# Define Code Block Content
CODE_BLOCK="export ENV_VAR=production
./run-workflow.sh --start"

# Generate JavaScript arrays from Bash arrays
LINKS_JS="const links = ["
for link in "${LINKS[@]}"; do
    NAME="${link%%|*}"
    URL="${link##*|}"
    LINKS_JS+="{ name: \"$NAME\", url: \"$URL\" },"
done
LINKS_JS+="];"

INFO_JS="const infoData = ["
for info in "${INFO[@]}"; do
    KEY="${info%%|*}"
    VALUE="${info##*|}"
    INFO_JS+="{ key: \"$KEY\", value: \"$VALUE\" },"
done
INFO_JS+="];"

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
            max-width: 600px;
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
        .offline-warning {
            display: none;
            color: red;
            font-size: 16px;
            font-weight: bold;
            margin-top: 10px;
        }
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
        .code-block {
            background: #222;
            color: #fff;
            padding: 10px;
            border-radius: 5px;
            text-align: left;
            font-family: monospace;
            white-space: pre-wrap;
            position: relative;
        }
        .copy-button {
            background: #007bff;
            color: white;
            border: none;
            padding: 5px 10px;
            cursor: pointer;
            border-radius: 5px;
            position: absolute;
            top: 10px;
            right: 10px;
            font-size: 12px;
        }
        .copy-button:hover {
            background: #0056b3;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Workflow Development Environment</h1>
        
        <div class="button-container" id="links-container"></div>

        <p id="offline-warning" class="offline-warning">
            ⚠ No connections available. Please restart the client.
        </p>

        <div class="info">
            <p>Time Remaining: <span id="uptime" class="uptime">Calculating...</span></p>
            <table>
                <thead>
                    <tr><th>Parameter</th><th>Value</th></tr>
                </thead>
                <tbody id="info-table"></tbody>
            </table>
        </div>

        <h2>Run This Command:</h2>
        <div class="code-block">
            <button class="copy-button" onclick="copyCode()">Copy</button>
            <code id="command-code">$CODE_BLOCK</code>
        </div>
    </div>

    <script>
        ${LINKS_JS}
        ${INFO_JS}

        let activeLinks = 0;

        // Generate links dynamically
        const linksContainer = document.getElementById("links-container");
        links.forEach(link => {
            const button = document.createElement("a");
            button.className = "link-button";
            button.href = link.url;
            button.target = "_blank"; // Open in a new tab
            button.innerHTML = \`\${link.name} <span id="status-\${link.name}" class="status">Checking...</span>\`;
            linksContainer.appendChild(button);
        });

        // Generate info table dynamically
        const infoTable = document.getElementById("info-table");
        infoData.forEach(info => {
            const row = document.createElement("tr");
            row.innerHTML = \`<td>\${info.key}</td><td>\${info.value}</td>\`;
            infoTable.appendChild(row);
        });

        // Function to check if a site is reachable
        function checkStatus(url, elementId) {
            fetch(url, { mode: 'no-cors' })
                .then(() => {
                    document.getElementById(elementId).textContent = "✅ Up";
                    document.getElementById(elementId).classList.add("up");
                    activeLinks++;
                })
                .catch(() => {
                    document.getElementById(elementId).textContent = "❌ Down";
                    document.getElementById(elementId).classList.add("down");
                })
                .finally(() => {
                    setTimeout(() => {
                        if (activeLinks === 0) {
                            document.getElementById("offline-warning").style.display = "block";
                        }
                    }, 3000);
                });
        }

        // Run status checks
        links.forEach(link => checkStatus(link.url, \`status-\${link.name}\`));

        // Countdown Timer
        const expirationTime = new Date(new Date("$START_TIME").getTime() + ($EXPIRATION_HOURS * 60 * 60 * 1000));

        function updateCountdown() {
            const now = new Date();
            const diff = expirationTime - now;
            document.getElementById("uptime").textContent = diff > 0 ? 
                new Date(diff).toISOString().substr(11, 8) + " remaining" : 
                "⚠ Environment has expired!";
        }

        setInterval(updateCountdown, 1000);
        updateCountdown();

        function copyCode() {
            navigator.clipboard.writeText(document.getElementById("command-code").innerText);
            alert("Command copied to clipboard!");
        }
    </script>

</body>
</html>
EOF

# Open the HTML file
xdg-open "$TMP_HTML" 2>/dev/null || open "$TMP_HTML"
