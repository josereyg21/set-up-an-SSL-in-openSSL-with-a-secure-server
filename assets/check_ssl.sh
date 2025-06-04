#!/bin/bash

# Output file
REPORT="report.json"
report=()

# Helper function to add key-value pairs to the report
add_report() {
    key="$1"
    value="$2"
    report+=("\"$key\": \"$value\"")
}

# 1. Check if Apache is running
if systemctl is-active --quiet apache2 || systemctl is-active --quiet httpd; then
    add_report "Apache Service" "✅ Apache is running."
else
    add_report "Apache Service" "❌ Apache is NOT running. Please start it with: sudo systemctl start apache2"
fi

# 2. Check if the SSL module is enabled (supporting apache2ctl and apachectl)
if command -v apache2ctl &> /dev/null; then
    MODULES=$(apache2ctl -M 2>/dev/null)
elif command -v apachectl &> /dev/null; then
    MODULES=$(apachectl -M 2>/dev/null)
else
    MODULES=""
fi

if echo "$MODULES" | grep -q ssl_module; then
    add_report "SSL Module" "✅ The SSL module is enabled."
else
    add_report "SSL Module" "❌ The SSL module is NOT enabled. Please enable it with: sudo a2enmod ssl && sudo systemctl restart apache2"
fi

# 3. Search for certificate and key files in active virtual hosts
CRT_PATH=""
KEY_PATH=""

for conf in /etc/apache2/sites-enabled/*.conf /etc/httpd/conf.d/*.conf; do
    [[ -f "$conf" ]] || continue
    crt=$(grep -i "SSLCertificateFile" "$conf" | awk '{print $2}')
    key=$(grep -i "SSLCertificateKeyFile" "$conf" | awk '{print $2}')
    
    if [[ -f "$crt" && -f "$key" ]]; then
        CRT_PATH="$crt"
        KEY_PATH="$key"
        break
    fi
done

if [[ -n "$CRT_PATH" ]]; then
    add_report "Certificate File" "✅ Found certificate at $CRT_PATH"
else
    add_report "Certificate File" "❌ No certificate file found. Please check your Apache SSL configuration."
fi

if [[ -n "$KEY_PATH" ]]; then
    add_report "Key File" "✅ Found private key at $KEY_PATH"
else
    add_report "Key File" "❌ No private key file found. Please check your Apache SSL configuration."
fi

# 4. Validate the certificate using OpenSSL
if [[ -n "$CRT_PATH" && -f "$CRT_PATH" ]]; then
    CN=$(openssl x509 -in "$CRT_PATH" -noout -subject | sed -n 's/.*CN *= *//p')
    EXPIRE_DATE=$(openssl x509 -in "$CRT_PATH" -noout -enddate | cut -d= -f2)
    EXPIRE_SECONDS=$(date --date="$EXPIRE_DATE" +%s)
    NOW_SECONDS=$(date +%s)
    DAYS_LEFT=$(( (EXPIRE_SECONDS - NOW_SECONDS) / 86400 ))

    if [[ $DAYS_LEFT -gt 0 ]]; then
        add_report "Certificate Validity" "✅ Valid certificate. Common Name (CN): $CN"
        add_report "Days Until Expiry" "✅ The certificate will expire in $DAYS_LEFT days."
    else
        add_report "Certificate Validity" "❌ The certificate has expired. Please generate a new one."
    fi
else
    add_report "Certificate Validity" "❌ Cannot verify the certificate. File not found or invalid format."
fi

# 5. Generate JSON report
echo -e "{\n$(IFS=,; echo "  ${report[*]}")\n}" > "$REPORT"
echo "✅ Validation complete. Check the file: $REPORT"
