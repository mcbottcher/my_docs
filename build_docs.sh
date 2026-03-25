#!/bin/bash

set -e

NO_BROWSER=false
if [[ "$1" == "--no-browser" ]]; then
    NO_BROWSER=true
fi

if ! poetry env info --path &>/dev/null; then
    poetry install
fi

poetry run make -C docs html

if [[ "$NO_BROWSER" == false ]]; then
    firefox docs/build/html/index.html
fi
