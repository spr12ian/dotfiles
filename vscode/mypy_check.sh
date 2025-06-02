#!/bin/bash
mypy "$@" || mypy --install-types --non-interactive
