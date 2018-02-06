#!/bin/bash

############################################################################################################
# Functions
############################################################################################################
function sha256Hash() {
    printf "$1" | openssl dgst -sha256 -binary -hex | sed 's/^.* //'
}

to_hex() {
    printf "$1" | od -A n -t x1 | tr -d [:space:]
}

function hmac_sha256() {
    printf "$2" | \
        openssl dgst -binary -hex -sha256 -mac HMAC -macopt hexkey:"$1" | \
        sed 's/^.* //'
}

############################################################################################################
# Variables
############################################################################################################
aws_access_key=$1
aws_secret_key=$2
http_request_method=$3
body=$4
api_url=$5

echo "-${body}-"

############################################################################################################
# Make sign and headers
############################################################################################################
timestamp=${timestamp-$(date -u +"%Y%m%dT%H%M%SZ")}
today=${today-$(date -u +"%Y%m%d")}

api_host=$(printf ${api_url} | awk -F/ '{print $3}')
api_uri=$(printf ${api_url} | grep / | cut -d/ -f4-)

aws_region=$(cut -d'.' -f3 <<<"${api_host}")
aws_service=$(cut -d'.' -f2 <<<"${api_host}")

algorithm="AWS4-HMAC-SHA256"
credential_scope="${today}/${aws_region}/${aws_service}/aws4_request"

signed_headers="content-type;host;x-amz-date"
header_content_type="content-type:application/json"
header_host="host:${api_host}"
header_x_amz_date="x-amz-date:${timestamp}"

# canonical_request
canonical_uri="/${api_uri}"
canonical_query=""
canonical_headers="${header_content_type}\n${header_host}\n${header_x_amz_date}"
request_payload=$(sha256Hash "${body}")
canonical_request="${http_request_method}\n${canonical_uri}\n${canonical_query}\n${canonical_headers}\n\n${signed_headers}\n${request_payload}"
hashed_canonical_request="$(sha256Hash ${canonical_request})"

# string_to_sign
string_to_sign="${algorithm}\n${timestamp}\n${credential_scope}\n${hashed_canonical_request}"

# signature
secret=$(to_hex "AWS4${aws_secret_key}")
k_date=$(hmac_sha256 "${secret}" "${today}")
k_region=$(hmac_sha256 "${k_date}" "${aws_region}")
k_service=$(hmac_sha256 "${k_region}" "${aws_service}")
k_signing=$(hmac_sha256 "${k_service}" "aws4_request")
signature=$(hmac_sha256 "${k_signing}" "${string_to_sign}" | sed 's/^.* //')

# authorization_header
credentialHeader="Credential=${aws_access_key}/${credential_scope}"
signedHeader="SignedHeaders=${signed_headers}"
signatureHeader="Signature=${signature}"
authorization_header="Authorization: ${algorithm} ${credentialHeader}, ${signedHeader}, ${signatureHeader}"

############################################################################################################
# Call the api
############################################################################################################
curl -vvv -si -H "${header_content_type}" -H "${authorization_header}" -H "${header_x_amz_date}" -X ${http_request_method} -d "${body}" "${api_url}"
exit $?