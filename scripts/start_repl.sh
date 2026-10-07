#!/bin/bash


# Change directory to the script location
cd "$(dirname "${BASH_SOURCE[0]}" )"
cd .. # Move to package root


# Open an interactive julia session
julia -i --project=. -e 'using Revise; using ReplTree; include("./scripts/repl_start.jl")'
