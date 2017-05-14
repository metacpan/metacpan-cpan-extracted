#!/bin/sh

#echo HERE >&2
echo Content-Type: text/plain
echo
echo ZXID.org environment dumper
echo '$Id: env.cgi,v 1.1 2008-09-24 22:50:25 sampo Exp $'
echo "sesid($SAML_sesid) idpnid($SAML_idpnid) authnctxlevel($SAML_authnctxlevel)"
echo
env|sort
exit
