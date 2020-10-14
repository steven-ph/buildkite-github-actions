#!/bin/bash

set -eou pipefail

CURRENT_DIR=$(pwd)
ROOT_DIR="$( dirname "${BASH_SOURCE[0]}" )"/..

BUCKET_NAME="buildkite-secrets-someorgslug"
KEY="id_rsa_buildkite"

echo "creating bucket $BUCKET_NAME.."
aws s3 mb s3://$BUCKET_NAME

ssh-keygen -t rsa -b 4096 -f $KEY -N ''

aws s3 cp --acl private --sse aws:kms $KEY "s3://$BUCKET_NAME/private_ssh_key"
aws s3 cp --acl private --sse aws:kms $KEY.pub "s3://$BUCKET_NAME/public_key.pub"

pbcopy < id_rsa_buildkite.pub
echo "public key contents copied in clipboard."

rm -f $KEY

cd $CURRENT_DIR
