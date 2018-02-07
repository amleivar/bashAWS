#!/bin/bash

############################################################################################################
# Functions
############################################################################################################
hex256() {
  printf "$1" | od -A n -t x1 | sed ':a;N;$!ba;s/[\n ]//g'
}

sha256Hash() {
  output=$(printf "$1" | sha256sum)
  echo "${output%% *}"
}

sha256HashFile() {
  output=$(sha256sum $1)
  echo "${output%% *}"
}

hmac_sha256() {
  printf "$2" | openssl dgst -binary -hex -sha256 -mac HMAC -macopt hexkey:$1 \
              | sed 's/^.* //'
}

sign() {
  kSigning=$(hmac_sha256 $(hmac_sha256 $(hmac_sha256 \
                 $(hmac_sha256 $(hex256 "AWS4$1") $2) $3) $4) "aws4_request")
  hmac_sha256 "${kSigning}" "$5"
}

convS3RegionToEndpoint() {
  case "$1" in
    us-east-1) echo "s3.amazonaws.com"
      ;;
    *) echo s3-${1}.amazonaws.com
      ;;
    esac
}

############################################################################################################
# Variables
############################################################################################################
awsAccess=$1
awsSecret=$2
awsRegion=$3
fileLocal=$4
resourcePath="/${5}"
httpMethod='PUT'

############################################################################################################
# Make sign and headers
############################################################################################################
timestamp=$(date -u "+%Y-%m-%d %H:%M:%S")
isoTimestamp=$(date -ud "${timestamp}" "+%Y%m%dT%H%M%SZ")
dateScope=$(date -ud "${timestamp}" "+%Y%m%d")
host=$(convS3RegionToEndpoint "${awsRegion}")

# Generate payload hash
payloadHash=$(sha256HashFile $fileLocal)

cmd=("curl")
headers=
headerList=

cmd+=("--verbose")
cmd+=("-T" "${fileLocal}")
cmd+=("-X" "${httpMethod}")

cmd+=("-H" "Host: ${host}")
headers+="host:${host}"
headerList+="host"

cmd+=("-H" "x-amz-content-sha256: ${payloadHash}")
headers+="\nx-amz-content-sha256:${payloadHash}"
headerList+=";x-amz-content-sha256"

cmd+=("-H" "x-amz-date: ${isoTimestamp}")
headers+="\nx-amz-date:${isoTimestamp}"
headerList+=";x-amz-date"

cmd+=("-H" "x-amz-meta-timestamp: 333666")
headers+="\nx-amz-meta-timestamp:333666"
headerList+=";x-amz-meta-timestamp"

# Generate canonical request
canonicalRequest="${httpMethod}
${resourcePath}

${headers}

${headerList}
${payloadHash}"

# Generated request hash
hashedRequest=$(sha256Hash "${canonicalRequest}")

# Generate signing data
stringToSign="AWS4-HMAC-SHA256
${isoTimestamp}
${dateScope}/${awsRegion}/s3/aws4_request
${hashedRequest}"

# Sign data
signature=$(sign "${awsSecret}" "${dateScope}" "${awsRegion}" "s3" "${stringToSign}")

authorizationHeader="AWS4-HMAC-SHA256 Credential=${awsAccess}/${dateScope}/${awsRegion}/s3/aws4_request, SignedHeaders=${headerList}, Signature=${signature}"
cmd+=("-H" "Authorization: ${authorizationHeader}")

cmd+=("https://${host}${resourcePath}")

############################################################################################################
# Call
############################################################################################################
"${cmd[@]}"
exit $?