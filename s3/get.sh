#!/bin/bash

aws_access_key=$1
aws_secret_key=$2
bucket=$3
file=$4
resource="/${bucket}/${file}" 
acl="x-amz-acl:public-read" 
contentType="text/plain" 
dateValue=$(date +"%a, %d %b %Y %T %z")
stringToSign="GET\n\n${contentType}\n${dateValue}\n${resource}" 
signature=$(echo -en "${stringToSign}" | openssl sha1 -hmac "${aws_secret_key}" -binary | base64)
curl -v -L -k -o "${file}" \
    -H "Host: ${bucket}.s3.amazonaws.com" \
    -H "Date: ${dateValue}" \
    -H "Content-Type: ${contentType}" \
    -H "Authorization: AWS ${aws_access_key}:${signature}" \
    https://${bucket}.s3.amazonaws.com/${file}
