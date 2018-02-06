#!/bin/bash

aws_access_key=$1
aws_secret_key=$2
sn=$3
ver=$4
model=$5
cpu=$6
disk=$7
net=$8
sysup=$9
netup=${10}
beup=${11}
kinesisUrl=${12}

read -r -d '' jsonBody << EOM
{
	"Data" : {
		"sn" : "${sn}",
		"ts" : "`date +%s`",
		"ver" : "${ver}",
		"model" : "${model}",
		"cpu" : "${cpu}",
		"disk" : "${disk}",
		"net" : "${net}",
		"sysup" : "${sysup}",
		"netup" : "${netup}",
		"beup" : "${beup}"
	},
	"PartitionKey" : "${sn}"
}
EOM

./apiGwSigv4.sh "${aws_access_key}" "${aws_secret_key}" "PUT" "${jsonBody}" "${kinesisUrl}/s-cam-tel/record"
exit $?
