#!/bin/sh

## Testing aware output
echo "TEST: params=$*"
echo "TEST: executed=false"

## execute the command
if [ "$1" != "" ]; then
    echo "TEST: executed=true"
    $*
fi

## Testing aware output
echo "TEST: output=$?"
