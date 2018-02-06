#!/bin/bash

aws_access_key=$1
aws_secret_key=$2
file=$3
bucket=$4
name=$5
resource="/${bucket}/${name}" 
acl="x-amz-acl:public-read" 
contentType="text/plain" 
dateValue=$(date +"%a, %d %b %Y %T %z")
stringToSign="PUT\n\n${contentType}\n${dateValue}\n${resource}" 
signature=$(echo -en "${stringToSign}" | openssl sha1 -hmac "${aws_secret_key}" -binary | base64)
curl -L -f -v -X PUT -T "${file}" \
    -H "Host: ${bucket}.s3.amazonaws.com" \
    -H "Date: ${dateValue}" \
    -H "Content-Type: ${contentType}" \
    -H "Authorization: AWS ${aws_access_key}:${signature}" \
    https://${bucket}.s3.amazonaws.com/${name}
