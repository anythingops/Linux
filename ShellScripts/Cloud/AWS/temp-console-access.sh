#!/bin/bash

# Input parameters
ROLE_ARN=$1
SESSION_NAME=$2
DURATION_SECONDS=$3
AWS_PROFILE=$4

# Assume the role to get temporary credentials
ASSUME_ROLE_OUTPUT=$(aws sts assume-role \
    --role-arn "$ROLE_ARN" \
    --role-session-name "$SESSION_NAME" \
    --duration-seconds "$DURATION_SECONDS" \
    --profile "$AWS_PROFILE")

# Extract the temporary credentials from the assume role output
ACCESS_KEY=$(echo "$ASSUME_ROLE_OUTPUT" | jq -r '.Credentials.AccessKeyId')
SECRET_KEY=$(echo "$ASSUME_ROLE_OUTPUT" | jq -r '.Credentials.SecretAccessKey')
SESSION_TOKEN=$(echo "$ASSUME_ROLE_OUTPUT" | jq -r '.Credentials.SessionToken')

# Create the session JSON
SESSION_JSON=$(cat <<EOF
{
  "sessionId": "$ACCESS_KEY",
  "sessionKey": "$SECRET_KEY",
  "sessionToken": "$SESSION_TOKEN"
}
EOF
)

# Generate the signin token
SIGNIN_TOKEN=$(curl -s "https://signin.aws.amazon.com/federation?Action=getSigninToken&Session=$(echo -n "$SESSION_JSON" | jq -sRr @uri)" | jq -r .SigninToken)

# Construct the sign-in URL
SIGNIN_URL="https://signin.aws.amazon.com/federation?Action=login&Issuer=YourApp&Destination=https://console.aws.amazon.com/&SigninToken=$SIGNIN_TOKEN"

# Output the sign-in URL
echo "Sign-In URL: $SIGNIN_URL"
