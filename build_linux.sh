#!/bin/bash

set -e

echo building...

GOOS=linux GOARCH=amd64 go build -o s3uploader_linux main.go

echo uploading...

AWS_PROFILE=scicomp aws s3 cp --acl public-read s3uploader_linux s3://fredhutch-aws-batch-tools/linux-build-of-s3uploader/s3uploader
