#!/bin/zsh

if prove -I lib t &> /tmp/www-mobile-carrier-jp-smoke-log ; then
    # succeeded. nop.
else
    cat /tmp/www-mobile-carrier-jp-smoke-log
fi
