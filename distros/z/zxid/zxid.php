<?
# zxid/zxid.php  -  Implement SAML SP role in PHP using zxid extension
#
# Copyright (c) 2006-2008 Symlabs (symlabs@symlabs.com), All Rights Reserved.
# Author: Sampo Kellomaki (sampo@iki.fi)
# This is confidential unpublished proprietary source code of the author.
# NO WARRANTY, not even implied warranties. Contains trade secrets.
# Distribution prohibited unless authorized in writing.
# Licensed under Apache License 2.0, see file COPYING.
# $Id: zxid.php,v 1.8 2008-05-26 15:28:44 sampo Exp $
# 31.8.2006, created --Sampo
# 15.9.2006, enhanced to actually support SSO --Sampo
# 5.3.2007, double checked and fixed to work against 0.16 --Sampo
# 25.5.2008, fixed to work against 0.27, fixed port number to 5443 --Sampo

dl("php_zxid.so");

$cf = zxid_new_conf("/var/zxid/");
$path = zxid_conf_path_get($cf);   # *** Weird: without "get" the cf->path is screwed?!?
#$path_len = zxid_conf_path_len_get($cf);
#error_log("path($path) len($len)", 0);

$url = "https://sp1.zxidsp.org:5443/zxid.php";
$cdc_url = "https://sp1.zxidcommon.org:5443/zxid.php";  # zxid_my_cdc_url()
zxid_url_set($cf, $url);
zxid_set_opt($cf, 1 ,1);  # Turn on libzxid level debugging
$cgi = zxid_new_cgi($cf, $_SERVER['QUERY_STRING']);
$op = zxid_cgi_op_get($cgi);
error_log("op($op)", 0);
if ($op == 'P') {
    $qs = file_get_contents('php://input');  # better than $HTTP_RAW_POST_DATA
    error_log("raw post($qs)", 0);
    zxid_parse_cgi($cgi, $qs);
    $op = zxid_cgi_op_get($cgi);
}
if (!$op) $op = 'M';

function mgmt_screen($cf, $cgi, $ses, $op)
{
    error_log("mgmt op($op)", 0);
    switch ($op) {
    case 'l':
	zxid_del_ses($cf, $ses);
        $msg = "Local logout Ok. Session terminated.";
	return 0;  # Simply abandon local session. Falls thru to login screen.
    case 'r':
	$loc = zxid_sp_slo_location($cf, $cgi, $ses);
	zxid_del_ses($cf, $ses);
        header($loc);
	return 1;  # Redirect already happened. Do not show login screen.
    case 's':
	zxid_sp_slo_soap($cf, $cgi, $ses);
	zxid_del_ses($cf, $ses);
	$msg = "SP Initiated logout (SOAP). Session terminated.";
	return 0;  # Falls thru to login screen.
    case 't':
	$loc = zxid_sp_nireg_location($cf, $cgi, $ses, 0);
        header($loc);
	return 1;  # Redirect already happened. Do not show login screen.
    case 'u':
	zxid_sp_nireg_soap($cf, $cgi, $ses, 0);
	$msg = "SP Initiated defederation (SOAP).";
        break;
    case 'P':
	$ret = zxid_sp_dispatch($cf, $cgi, $ses, zxid_cgi_saml_resp_get($cgi));
        switch ($ret) {
	case ZXID_OK:       return 0;
	case ZXID_REDIR_OK: return 1;
        }
        break;
    case 'Q':
	$ret = zxid_sp_dispatch($cf, $cgi, $ses, zxid_cgi_saml_req_get($cgi));
        switch ($ret) {
	case ZXID_OK:       return 0;
	case ZXID_REDIR_OK: return 1;
        }
        break;
    }

    $sid = zxid_ses_sid_get($ses);
    $nid = zxid_ses_nid_get($ses);
    
    # In gimp flatten the image and Save Copy as pnm
    # giftopnm favicon.gif | ppmtowinicon >favicon.ico
    #printf("COOKIE: foo\r\n");
?>
<title>ZXID SP Mgmt PHP</title>
<link rel="shortcut icon" href="/favicon.ico" type="image/x-icon" />
<body bgcolor="#330033" text="#ffaaff" link="#ffddff" vlink="#aa44aa" alink="#ffffff"><font face=sans>

<h1>ZXID SP Management PHP (user logged in, session active)</h1><pre>
</pre><form method=post action="zxid.php?o=P">
<input type=hidden name=s value="<?=$sid?>">
<input type=submit name=gl value=" Local Logout ">
<input type=submit name=gr value=" Single Logout (Redir) ">
<input type=submit name=gs value=" Single Logout (SOAP) ">
<input type=submit name=gt value=" Defederate (Redir) ">
<input type=submit name=gu value=" Defederate (SOAP) ">

<h3>Technical options (typically hidden fields on production site)</h3>
  
sid(<?=$sid?>) nid(<?=$nid?>) <a href="zxid.php?s=<?=$sid?>">Reload</a>

</form><hr>
<a href="http://zxid.org/">zxid.org</a>
<?
  return 1;
}

$sid = zxid_cgi_sid_get($cgi)
    and $ses = zxid_fetch_ses($cf, $sid)
    and mgmt_screen($cf, $cgi, $ses, $op)
    and exit;
$ses = zxid_fetch_ses($cf, "");  # Just allocate an empty one

error_log("Not logged-in case: op($op) ses($ses)", 0);

switch ($op) {
case 'M':       # Invoke LECP or redirect to CDC reader.
    #if (zxid_lecp_check($cf, $cgi)) exit;
    header("Location: $cdc_url?o=C");
    exit;
case 'C':  # CDC Read: Common Domain Cookie Reader
    zxid_cdc_read($cf, $cgi);
    exit;
case 'E':  # Return from CDC read, or start here to by-pass CDC read.
    #if (zxid_lecp_check($cf, $cgi)) exit;
    if (zxid_cdc_check($cf, $cgi)) exit;
    break;
case 'L':
    error_log("Start login", 0);
    $loc = zxid_start_sso_location($cf, $cgi);
    if ($loc) {
	error_log("login redir($loc)", 0);
	header($loc);
	exit;
    }
    error_log("Login trouble", 0);
    break;
case 'A':
    $ret = zxid_sp_deref_art($cf, $cgi, $ses);
    error_log("deref art ret($ret)", 0);
    if ($ret == ZXID_REDIR_OK) exit;
    if ($ret == ZXID_SSO_OK)
      if (mgmt_screen($cf, $cgi, $ses, $op))
        exit;
    break;
case 'P':
    $ret = zxid_sp_dispatch($cf, $cgi, $ses, zxid_cgi_saml_resp_get($cgi));
    error_log("saml_resp ret($ret)", 0);
    if ($ret == ZXID_REDIR_OK) exit;
    if ($ret == ZXID_SSO_OK)
      if (mgmt_screen($cf, $cgi, $ses, $op))
        exit;
    break;
case 'Q':
    $ret = zxid_sp_dispatch($cf, $cgi, $ses, zxid_cgi_saml_req_get($cgi));
    if ($ret == ZXID_REDIR_OK) exit;
    if ($ret == ZXID_SSO_OK)
      if (mgmt_screen($cf, $cgi, $ses, $op))
        exit;
    break;
case 'B':
    header("CONTENT-TYPE: text/xml");
    $md = zxid_sp_meta($cf, $cgi);
    echo $md;
    exit;
default:
    error_log("Unknown op($op)", 0);
}

?>
<title>ZXID SP SSO PHP</title>
<link rel="shortcut icon" href="/favicon.ico" type="image/x-icon" />
<body bgcolor="#330033" text="#ffaaff" link="#ffddff" vlink="#aa44aa" alink="#ffffff"><font face=sans><h1>ZXID SP Federated SSO PHP (user NOT logged in, no session.)</h1><pre>
</pre><form method=post action="zxid.php?o=P">

<h3>Login Using New IdP</h3>

<i>A new IdP is one whose metadata we do not have yet. We need to know
the Entity ID in order to fetch the metadata using the well known
location method. You will need to ask the adminstrator of the IdP to
tell you what the EntityID is.</i>

<p>IdP EntityID URL <input name=e size=60>
<input type=submit name=l1 value=" Login (SAML20:Artifact) ">
<input type=submit name=l2 value=" Login (SAML20:POST) ">
<?

$idp = zxid_load_cot_cache($cf);
if ($idp) {
    echo "<h3>Login Using Known IdP</h3>\n";
    while ($idp) {
	$eid = zxid_entity_eid_get($idp);
	$eid_len = zxid_entity_eid_len_get($idp);
	$eid = substr($eid, 0, $eid_len);
	error_log("eid_len($eid_len) eid($eid)", 0);
	echo <<< HTML
<input type=submit name="l1$eid" value=" Login to $eid (SAML20:Artifact) ">
<input type=submit name="l2$eid" value=" Login to $eid (SAML20:POST) ">
HTML;
	$idp = zxid_entity_n_get($idp);
    }
}

$version_str = zxid_version_str();

?>
<h3>CoT configuration parameters your IdP may need to know</h3>

Entity ID of this SP: <a href="<?=$url?>?o=B"><?=$url?>?o=B</a> (Click on the link to fetch SP metadata.)

<h3>Technical options (typically hidden fields on production site)</h3>

<input type=checkbox name=fc value=1 checked> Allow new federation to be created<br>
<input type=checkbox name=fp value=1> Do not allow IdP to interact (e.g. ask password) (IsPassive flag)<br>
<input type=checkbox name=ff value=1> IdP should reauthenticate user (ForceAuthn flag)<br>
NID Format: <select name=fn><option value=prstnt>Persistent<option value=trnsnt>Transient<option value="">(none)</select><br>
Affiliation: <select name=fq><option value="">(none)</select><br>

Consent: <select name=fy><option value="">(empty)
<option value="urn:liberty:consent:obtained">obtained
<option value="urn:liberty:consent:obtained:prior">obtained:prior
<option value="urn:liberty:consent:obtained:current:implicit">obtained:current:implicit
<option value="urn:liberty:consent:obtained:current:explicit">obtained:current:explicit
<option value="urn:liberty:consent:unavailable">unavailable
<option value="urn:liberty:consent:inapplicable">inapplicable
</select><br>
Authn Req Context: <select name=fa><option value="">(none)
<option value=pw>Password
<option value=pwp>Password with Protected Transport
<option value=clicert>TLS Client Certificate</select><br>
Matching Rule: <select name=fm><option value=exact>Exact
<option value=minimum>Min
<option value=maximum>Max
<option value=better>Better
<option value="">(none)</select><br>

</form><hr><a href="http://zxid.org/">zxid.org</a>, <?=$version_str?>
