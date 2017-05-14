#!/bin/sh

echo content-type: text/html
echo
echo '[ <a href="saml?gl=1&s='$SAML_sesid'">Local logout</a> '
echo '| <a href="saml?gr=1&s='$SAML_sesid'">Single logout</a>]'
echo '<pre>'
env | sort
ulimit -a
id
cat /proc/sys/kernel/core_pattern
echo '</pre>'
