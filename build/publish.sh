#!/bin/bash

set -e

export AWS_PROFILE=sdlc

aws s3 sync ./ s3://stokedconsulting.com-sdlc-artifacts/sdlc/ --delete
