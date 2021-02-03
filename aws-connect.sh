#!/bin/bash

set -e

# replace with your hostname
VPN_HOST="example.com"
# path to the patched openvpn
OVPN_BIN="openvpn"
# path to the configuration file
OVPN_CONF="vpn.conf"

wait_file() {
  local file="$1"; shift
  local wait_seconds="${1:-10}"; shift # 10 seconds as default timeout
  until test $((wait_seconds--)) -eq 0 -o -f "$file" ; do sleep 1; done
  ((++wait_seconds))
}

# create random hostname prefix for the vpn gw
RAND=$(openssl rand -hex 12)

# resolv manually hostname to IP, as we have to keep persistent ip address
SRV=$(dig a +short "${RAND}.${VPN_HOST}"|head -n1)

# cleanup
rm -f saml-response.txt

printf "%s\n%s\n" "N/A" "ACS::35001" > passwd.txt
echo "Getting SAML redirect URL from the AUTH_FAILED response (host: ${SRV})"
OVPN_OUT=$(openvpn --config $OVPN_CONF --auth-user-pass passwd.txt 2>&1 | grep AUTH_FAILED,CRV1) 

rm -f passwd.txt

echo "Opening browser and wait for the response file..."
URL=$(echo "$OVPN_OUT" | grep -Eo 'https://.+')
echo $URL
open "$URL"

wait_file "saml-response.txt" 30 || {
  echo "SAML Authentication time out"
  exit 1
}

# get SID from the reply
VPN_SID=$(echo "$OVPN_OUT" | awk -F : '{print $7}')
echo $OVPN_OUT
echo $VPN_SID
echo "Running OpenVPN with sudo. Enter password if requested"

# Finally OpenVPN with a SAML response we got
# Delete saml-response.txt after connect
SAML_RESPONSE=$(cat saml-response.txt)
printf "%s\n%s\n" "N/A" "CRV1:R:${VPN_SID}::${SAML_RESPONSE}" > passwd.txt 
$OVPN_BIN --config "${OVPN_CONF}" \
    --auth-nocache --inactive 3600 \
    --auth-user-pass passwd.txt