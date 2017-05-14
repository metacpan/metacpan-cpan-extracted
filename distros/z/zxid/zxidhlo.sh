#!/bin/sh
# zxidhlo.sh -  Hello World CGI shell script for SAML 2 SP
# Copyright (c) 2007 Symlabs (symlabs@symlabs.com), All Rights Reserved.
# Author: Sampo Kellomaki (sampo@iki.fi)
# This is confidential unpublished proprietary source code of the author.
# NO WARRANTY, not even implied warranties. Contains trade secrets.
# Distribution prohibited unless authorized in writing.
# Licensed under Apache License 2.0, see file COPYING.
# $Id: zxidhlo.sh,v 1.6 2009-08-30 15:09:26 sampo Exp $
#
# 16.1.2007, created --Sampo
#
# See also: http://hoohoo.ncsa.uiuc.edu/cgi/interface.html (CGI specification)
#           README-zxid, section 10 "zxid_simple() API"
#
# N.B. This shell script needs to find zxidsimple(1) program, which see, in its path.

CONF="PATH=/var/zxid/&URL=https://sp1.zxidsp.org:8443/zxidhlo.sh"
./zxidsimple -o /tmp/zxidhlo.sh.$$ $CONF 4095 || exit;
#echo "exit=$?" >>/tmp/hlo.err

# First we split the result of the backtick into a list on (literal)
# newline. Then we process the list with for loop and look with case
# for the interesting attributes and capture them into local variables.
IFS="
"
res=`cat /tmp/zxidhlo.sh.$$`
#echo "=====RES($res)" >>/tmp/hlo.err
case "$res" in
dn*)
  for x in $res; do
    case "$x" in
    sesid:*)  SID=${x##*sesid: } ;;
    idpnid:*) NID=${x##*idpnid: } ;;
    cn:*)     CN=${x##*cn: } ;;
    esac
  done
  ;;
*) echo "ERROR($res)" >>/tmp/hlo.err; exit ;;
esac

cat << EOF
Content-Type: text/html

<title>ZXID HELLO SP Mgmt</title>
<h1>ZXID HELLO SP Management (user $CN logged in, session active)</h1>
<form method=post action="zxidhlo.sh?o=P">
<input type=hidden name=s value="$SID">
<input type=submit name=gl value=" Local Logout ">
<input type=submit name=gr value=" Single Logout (Redir) ">
<input type=submit name=gs value=" Single Logout (SOAP) ">
<input type=submit name=gt value=" Defederate (Redir) ">
<input type=submit name=gu value=" Defederate (SOAP) ">

sid($SID) nid($NID) <a href="zxid?s=$SID">Reload</a>

</form><hr>
<a href="http://zxid.org/">zxid.org</a>
EOF

# EOF  --  zxidhlo.sh
