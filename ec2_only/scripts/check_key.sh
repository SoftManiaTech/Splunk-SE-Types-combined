#!/bin/bash

KEY_NAME=$1
AWS_REGION=$2

# Check if key exists
if aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$AWS_REGION" > /dev/null 2>&1; then
    echo "{\"exists\":\"true\"}"
else
    echo "{\"exists\":\"false\"}"
fi
