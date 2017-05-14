<?
# zxid/zxidwspdemo.php  -  Hello World Id-WSF WSP using zxid PHP extension
#
# Copyright (c) 2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
# Copyright (c) 2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
# Author: Sampo Kellomaki (sampo@iki.fi)
# This is confidential unpublished proprietary source code of the author.
# NO WARRANTY, not even implied warranties. Contains trade secrets.
# Distribution prohibited unless authorized in writing.
# Licensed under Apache License 2.0, see file COPYING.
# $Id$
# 27.11.2009, Created, --Sampo
#
# QUERY_STRING=o=B REQUEST_METHOD=GET php ./zxidwspdemo.php
# Discovery registration: ./zxcot -e http://sp.tas3.pt:8082/zxidwspdemo.php 'TAS3 WSP PHP Demo' http://sp.tas3.pt:8082/zxidwspdemo.php?o=B urn:x-foobar | ./zxcot -d -b /var/zxid/idpdimd

dl("php_zxid.so");  # These three lines can go to initialization: they only need to run once
# CONFIG: You must have created /var/zxid directory hierarchy. See `make dir'
# CONFIG: You must edit the URL to match your domain name and port
#$conf = "URL=https://sp1.zxidsp.org:5443/zxidwspdemo.php&PATH=/var/zxid/";
$conf = "PATH=/var/zxid/&URL=http://sp.tas3.pt:8082/zxidwspdemo.php";
$cf = zxid_new_conf_to_cf($conf);
zxid_set_opt_cstr($cf, 2, "\tzxphp");
?>
<?
zxid_set_opt_cstr($cf, 3, "wsp: ");
$fullURL = "http://" + $_SERVER['HTTP_HOST'] + $_SERVER['SCRIPT_NAME'];
#zxid_url_set($cf, $fullURL);  # Virtual host support
error_log("fullURL($fullURL)");

# For every page that is accessed. Debug: QUERY_STRING=o=E REQUEST_METHOD=GET ./zxidhlo.php
#print_r(phpinfo());
#print_r($_SERVER);
$qs = $_SERVER['REQUEST_METHOD'] == 'GET'
      ? $_SERVER['QUERY_STRING']
      : file_get_contents('php://input');
error_log("zxidphp: qs($qs)");

if ($qs == "o=B") {   # As a pure WSP, we only support metadata request. No SSO here.
    $res = zxid_simple_cf($cf, -1, $qs, null, 0x1814);
    error_log("zxidphp: res($res) conf($conf)");
    switch (substr($res, 0, 1)) {
    case 'L': header($res); zxid_set_opt_cstr($cf, 4, "wsp: "); exit;  # Redirect (Location header)
    case '<': header('Content-type: text/xml'); echo $res; zxid_set_opt_cstr($cf, 4, "wsp: "); exit;  # Metadata or SOAP
    default:  zxid_set_opt_cstr($cf, 4, "wsp: "); die("Unhandled zxid_simple() res($res)");
    }
}

error_log("zxidphp: processing SOAP request ");

$ses = zxid_fetch_ses($cf, $attr['sesid']);

$nid = zxid_wsp_validate($cf, $ses, null, $qs);

error_log("working for nid($nid)");

if (zxid_az_cf_ses($cf, "Action=Call", $ses)) {
    echo zxid_wsp_decorate($cf, $ses, null,
			   "<barfoo>" +
			   "<lu:Status code=\"OK\" comment=\"Permit\"></lu:Status>" +
			   "<data>nid="+nid+"</data>" +
			   "</barfoo>");
} else {
    echo zxid_wsp_decorate($cf, $ses, null,
			   "<barfoo>" +
			   "<lu:Status code=\"Fail\" comment=\"Deny\"></lu:Status>" +
			   "<data>Deny: nid="+nid+"</data>" +
			   "</barfoo>");
}

zxid_set_opt_cstr($cf, 4, "wsp: ");

?>
