#!/bin/bash
# Scan oktaverify QR code and obtain totp secret.
# The secret can be used in any tool implementing rfc4226 algorithm to generate OTPs
# (oathtool, Google Authenticator, etc.)
# Required tools: zbarimg, curl, grep, sed
set -eu
#set -x

# $1 = url
# $2 = parameter to parse
parse_parameter()
{
    echo "$1" | grep -oP '(?<=(\?|&)'$2'=)[^&]+'
}

#
# $1 = qr-code image file
# Main

# scan oktaverify qr-code
URL=$(zbarimg $1)
DOMAIN=$(parse_parameter "$URL" s)
DOMAIN=$(echo $DOMAIN | sed 's|^https\?://||')
# keys is a valid json snippet without the embracing curly braces
keys=$(curl -s -f --retry 5 https://$DOMAIN/oauth2/v1/keys | sed -e 's/^{//' -e 's/}$//'
t=$(parse_parameter "$URL" t)
f=$(parse_parameter "$URL" f)
curl --request POST \
  --url https://$DOMAIN/idp/authenticators \
  --header 'Accept: application/json; charset=UTF-8' \
  --header 'Accept-Encoding: gzip, deflate' \
  --header "Authorization: OTDT $t" \
  --header 'Content-Type: application/json; charset=UTF-8' \
  --header 'User-Agent: D7C27D5527.com.okta.android.auth/6.9.1 DeviceSDK/0.19.0 Android/7.1.1 unknown/Google' \
  --data '{
	"authenticatorId": "'"$f"'",
	"device": {
		"clientInstanceBundleId": "com.okta.android.auth",
		"clientInstanceDeviceSdkVersion": "DeviceSDK 0.19.0",
		"clientInstanceVersion": "6.9.1",
		"clientInstanceKey": {
			"okta:isFipsCompliant": false,
			"okta:kpr": "SOFTWARE",
            '"$keys"'
		},
		"deviceAttestation": {},
		"displayName": "Android",
		"fullDiskEncryption": true,
		"isHardwareProtectionEnabled": true,
		"manufacturer": "unknown",
		"model": "Google",
		"osVersion": "30",
		"platform": "ANDROID",
		"rootPrivileges": false,
		"screenLock": true,
		"secureHardwarePresent": true
	},
	"key": "okta_verify",
	"methods": [
		{
			"isFipsCompliant": false,
			"supportUserVerification": false,
			"type": "totp"
		}
	]
}'

