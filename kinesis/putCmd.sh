#!/bin/bash

aws_access_key=$1
aws_secret_key=$2
sn=$3
ver=$4
model=$5
cmd=$6
arg=$7
kinesisUrl=$8

read -r -d '' jsonBody << EOM
{
	"Data" : {
		"sn" : "${sn}",
		"ts" : "`date +%s`",
		"ver" : "${ver}",
		"model" : "${model}",
		"cmd" : "${cmd}",
		"arg" : ${arg}
	},
	"PartitionKey" : "${sn}"
}
EOM

./apiGwSigv4.sh "${aws_access_key}" "${aws_secret_key}" "PUT" "${jsonBody}" "${kinesisUrl}/s-cam-cmd/record"
exit $?
