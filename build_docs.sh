#!/bin/bash

set -e

if ! poetry env info --path &>/dev/null; then
    poetry install
fi

poetry run make -C docs html
firefox docs/build/html/index.html
