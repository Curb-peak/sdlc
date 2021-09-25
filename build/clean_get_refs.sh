#!/bin/bash

set -e

git for-each-ref --format="%(refname)" | while read ref; do
    git show-ref --quiet --verify $ref 2>/dev/null || git update-ref -d $ref
done
