#!/bin/bash

set -e

SLACK_WEBHOOK_URL=${1}
EMAIL=${2}

if [ -z "$SLACK_WEBHOOK_URL" ]; then
  echo "❌ Slack webhook URL required"
  echo "Usage: $0 <slack_webhook_url> [email]"
  exit 1
fi

echo "🚨 Setting up alerting..."

# Update AlertManager configuration with Slack webhook
sed -i "s/YOUR_SLACK_WEBHOOK_URL/$SLACK_WEBHOOK_URL/g" monitoring/alertmanager/alertmanager.yml

if [ ! -z "$EMAIL" ]; then
  # Add email alerting
  cat >> monitoring/alertmanager/alertmanager.yml << EOF

- name: 'email-alerts'
  email_configs:
  - to: '$EMAIL'
    subject: 'FinTech Platform Alert'
    body: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
EOF
fi

echo "✅ Alerting configured"
echo "💡 Test alerts with: curl -X POST http://localhost:9093/api/v1/alerts" 