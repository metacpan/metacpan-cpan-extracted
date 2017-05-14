#!/apps/bin/php
<?
# zxid/zxidhlocgi.php  -  Hello World SAML SP role in PHP using zxid extension
#
# Copyright (c) 2007 Symlabs (symlabs@symlabs.com), All Rights Reserved.
# Author: Sampo Kellomaki (sampo@iki.fi)
# This is confidential unpublished proprietary source code of the author.
# NO WARRANTY, not even implied warranties. Contains trade secrets.
# Distribution prohibited unless authorized in writing.
# Licensed under Apache License 2.0, see file COPYING.
# $Id: zxidhlocgi.php,v 1.1 2007-08-11 12:34:13 sampo Exp $
# 16.1.2007, created --Sampo

dl("php_zxid.so");  # These three lines can go to initialization: they only need to run once
# CONFIG: You must have created /var/zxid directory hierarchy. See `make dir'
# CONFIG: You must edit the URL to match your domain name and port
$conf = "PATH=/var/zxid/&URL=https://sp1.zxidsp.org:8443/zxidhlocgi.php";
$cf = zxid_new_conf_to_cf($conf);
?>
<?
# For every page that is accessed. Debug: QUERY_STRING=o=E REQUEST_METHOD=GET ./zxidhlo.php
#print_r(phpinfo());
#print_r($_SERVER);
$qs = $_SERVER['REQUEST_METHOD'] == 'GET'
      ? $_SERVER['QUERY_STRING']
      : file_get_contents('php://input');
#error_log("zxidphp: qs($qs)");
$res = zxid_simple_cf($cf, -1, $qs, null, 0x0814);
#error_log("zxidphp: res($res) conf($conf)");

switch (substr($res, 0, 1)) {
case 'L': header($res); exit;  # Redirect (Location header)
case '<': header('Content-type: text/xml'); echo $res; exit;  # Metadata or SOAP
case 'n': exit;   # Already handled
case 'e':
?>
Content-type: text/html

<title>Please Login Using IdP</title>
<body bgcolor="#330033" text="#ffaaff" link="#ffddff"
 vlink="#aa44aa" alink="#ffffff"><font face=sans>
<h1>Please Login Using IdP</h1>
<?=zxid_idp_select_cf($cf, null, 0x0800)?>
<hr>zxidhlo.php, <a href="http://zxid.org/">zxid.org</a>
<?
exit;
case 'd': break;  # Logged in case -- continue after switch
default:  die("Unknown zxid_simple() res($res)");
}

# Parse the LDIF in $res into a hash of attributes $attr

foreach (split("\n", $res) as $line) {
    $a = split(": ", $line);
    $attr[$a[0]] = $a[1];
}
?>
Content-type: text/html

<title>Protected content, logged in</title>
<body bgcolor="#330033" text="#ffaaff" link="#ffddff"
 vlink="#aa44aa" alink="#ffffff"><font face=sans>
<h1>Protected content, logged in as <?=$attr['cn']?>, session(<?=$attr['sesid']?>)</h1>
<?=zxid_fed_mgmt_cf($cf, null, -1, $attr['sesid'], 0x0800)?>
<hr>zxidhlo.php, <a href="http://zxid.org/">zxid.org</a>
