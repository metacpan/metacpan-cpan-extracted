#!/usr/bin/perl
# Copyright (c) 2006-2007 Symlabs (symlabs@symlabs.com), All Rights Reserved.
# Author: Sampo Kellomaki (sampo@iki.fi)
# This is confidential unpublished proprietary source code of the author.
# NO WARRANTY, not even implied warranties. Contains trade secrets.
# Distribution prohibited unless authorized in writing.
# Licensed under Apache License 2.0, see file COPYING.
# $Id: zxid.pl,v 1.10 2009-08-30 15:09:26 sampo Exp $
# 31.8.2006, created --Sampo

use Net::SAML;
use Data::Dumper;

$| = 1;

open STDERR, ">>tmp/zxid.stderr";   # Helps CGI debugging where web server eats the stderr

$cf = Net::SAML::new_conf("/var/zxid/");
$url = "https://sp1.zxidsp.org:8443/zxid.pl";
$cdc_url = "https://sp1.zxidcommon.org:8443/zxid.pl"; # NET::SAML::CDC_URL
Net::SAML::url_set($cf, $url);
Net::SAML::set_opt($cf, 1 ,1);  # Turn on libzxid level debugging
$cgi = Net::SAML::new_cgi($cf, $ENV{'QUERY_STRING'});
$op = Net::SAML::zxid_cgi::swig_op_get($cgi);
warn "op($op)";
if ($op eq 'P') {
    $qs = <STDIN>;
    warn "post input($qs)";
    Net::SAML::parse_cgi($cgi, $qs);
    $op = Net::SAML::zxid_cgi::swig_op_get($cgi);
}
$op ||= 'M';

$sid = Net::SAML::zxid_cgi::swig_sid_get($cgi)
    and $ses = Net::SAML::fetch_ses($cf, $sid)
    and mgmt_screen($cf, $cgi, $ses, $op)
    and exit;
$ses = Net::SAML::fetch_ses($cf, "");  # Just allocate an empty one

warn "Not logged in case op($op) ses($ses)";

### Not logged in case

if ($op eq 'M') {       # Invoke LECP or redirect to CDC reader.
    exit if Net::SAML::lecp_check($cf, $cgi);
    print "Location: $cdc_url?o=C\r\n\r\n";
    exit;
} elsif ($op eq 'C') {  # CDC Read: Common Domain Cookie Reader
    &Net::SAML::cdc_read($cf, $cgi);
    exit;
} elsif ($op eq 'E') {  # Return from CDC read, or start here to by-pass CDC read.
    #exit if Net::SAML::lecp_check($cf, $cgi);
    exit if Net::SAML::cdc_check($cf, $cgi);
} elsif ($op eq 'L') {
    warn "Start login";
    $url = Net::SAML::start_sso_url($cf, $cgi);
    if ($url) {
	warn "Start SSO redirect($url)";
	print "Location: $url\r\n\r\n";
	exit;
    }
    warn "Login trouble ($url)";
} elsif ($op eq 'A') {
    $ret = Net::SAML::sp_deref_art($cf, $cgi, $ses);
    warn "deref art ret($ret)";
    exit if $ret == 2;
    if ($ret == 3) {
	exit if mgmt_screen($cf, $cgi, $ses, $op);
    }
} elsif ($op eq 'P') {
    $ret = Net::SAML::sp_dispatch($cf, $cgi, $ses, Net::SAML::zxid_cgi::swig_saml_resp_get($cgi));
    warn "saml_resp ret($ret)";
    exit if $ret == 2;
    if ($ret == 3) {
	exit if mgmt_screen($cf, $cgi, $ses, $op);
    }
} elsif ($op eq 'Q') {
    $ret = Net::SAML::sp_dispatch($cf, $cgi, $ses, Net::SAML::zxid_cgi::swig_saml_req_get($cgi));
    exit if $ret == 2;
    if ($ret == 3) {
	exit if mgmt_screen($cf, $cgi, $ses, $op);
    }
} elsif ($op eq 'B') {
    $md = Net::SAML::sp_meta($cf, $cgi);
    printf "CONTENT-LENGTH: %d\r\nCONTENT-TYPE: text/xml\r\n\r\n%s", length $md, $md;
    exit;
} elsif ($op eq 'K') {
    warn "Redirect back from SLO";
} else {
    warn "Unknown op($op)";
}

print <<HTML;
CONTENT-TYPE: text/html

<title>ZXID SP PERL SSO</title>
<link rel="shortcut icon" href="/favicon.ico" type="image/x-icon" />
<body bgcolor="#330033" text="#ffaaff" link="#ffddff" vlink="#aa44aa" alink="#ffffff"><font face=sans><h1>ZXID SP Perl Federated SSO (user NOT logged in, no session.)</h1><pre>
</pre><form method=post action="zxid.pl?o=P">

<h3>Login Using New IdP</h3>

<i>A new IdP is one whose metadata we do not have yet. We need to know
the Entity ID in order to fetch the metadata using the well known
location method. You will need to ask the adminstrator of the IdP to
tell you what the EntityID is.</i>

<p>IdP EntityID URL <input name=e size=100>
<input type=submit name=l1 value=" Login (SAML20:Artifact) ">
<input type=submit name=l2 value=" Login (SAML20:POST) ">

HTML
    ;

$idp = Net::SAML::load_cot_cache($cf);
if ($idp) {
    print "<h3>Login Using Known IdP</h3>\n";
    while ($idp) {
	$eid = Net::SAML::zxid_entity::swig_eid_get($idp);
	$eid_len = Net::SAML::zxid_entity::swig_eid_len_get($idp);
	$eid = substr($eid, 0, $eid_len);
	warn "eid_len($eid_len) eid($eid)";
	print <<HTML;
<input type=submit name="l1$eid" value=" Login to $eid (SAML20:Artifact) ">
<input type=submit name="l2$eid" value=" Login to $eid (SAML20:POST) ">
HTML
;
	$idp = Net::SAML::zxid_entity::swig_n_get($idp);
    }
}

$version_str = Net::SAML::version_str();

print <<HTML;
<h3>CoT configuration parameters your IdP may need to know</h3>

Entity ID of this SP: <a href="$url?o=B">$url?o=B</a> (Click on the link to fetch SP metadata.)

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

</form><hr><a href="http://zxid.org/">zxid.org</a>, $version_str
HTML
    ;

### Logged in case

sub mgmt_screen {
    my ($cf, $cgi, $ses, $op) = @_;
    warn "mgmt op($op)";
    if ($op eq 'l') {
	Net::SAML::del_ses($cf, $ses);
	$msg = "Local logout Ok. Session terminated.";
	return 0;  # Simply abandon local session. Falls thru to login screen.
    } elsif ($op eq 'r') {
	Net::SAML::sp_slo_redir($cf, $cgi, $ses);
	Net::SAML::del_ses($cf, $ses);
	return 1;  # Redirect already happened. Do not show login screen.
    } elsif ($op eq 's') {
	Net::SAML::sp_slo_soap($cf, $cgi, $ses);
	Net::SAML::del_ses($cf, $ses);
	$msg = "SP Initiated logout (SOAP). Session terminated.";
	return 0;  # Falls thru to login screen.
    } elsif ($op eq 't') {
	Net::SAML::sp_nireg_redir($cf, $cgi, $ses, '');
	return 1;  # Redirect already happened. Do not show login screen.
    } elsif ($op eq 'u') {
	Net::SAML::sp_nireg_soap($cf, $cgi, $ses, '');
	$msg = "SP Initiated defederation (SOAP).";
    } elsif ($op eq 'P') {
	$ret = Net::SAML::sp_dispatch($cf, $cgi, $ses, Net::SAML::zxid_cgi::swig_saml_resp_get($cgi));
	return 0 if $ret == 1;
	return 1 if $ret == 2;
    } elsif ($op eq 'Q') {
	$ret = Net::SAML::sp_dispatch($cf, $cgi, $ses, Net::SAML::zxid_cgi::swig_saml_req_get($cgi));
	return 0 if $ret == 1;
	return 1 if $ret == 2;
    }

    $sid = Net::SAML::zxid_ses::swig_sid_get($ses);
    $nid = Net::SAML::zxid_ses::swig_nid_get($ses);

    # In gimp flatten the image and Save Copy as pnm
    # giftopnm favicon.gif | ppmtowinicon >favicon.ico
    #printf("COOKIE: foo\r\n");
    print <<HTML;
CONTENT-TYPE: text/html

<title>ZXID SP Mgmt</title>
<link rel="shortcut icon" href="/favicon.ico" type="image/x-icon" />
<body bgcolor="#330033" text="#ffaaff" link="#ffddff" vlink="#aa44aa" alink="#ffffff"><font face=sans>

<h1>ZXID SP Perl Management (user logged in, session active)</h1><pre>
</pre><form method=post action="zxid.pl?o=P">
<input type=hidden name=s value="$sid">
<input type=submit name=gl value=" Local Logout ">
<input type=submit name=gr value=" Single Logout (Redir) ">
<input type=submit name=gs value=" Single Logout (SOAP) ">
<input type=submit name=gt value=" Defederate (Redir) ">
<input type=submit name=gu value=" Defederate (SOAP) ">

<h3>Technical options (typically hidden fields on production site)</h3>
  
sid($sid) nid($nid) <a href="zxid.pl?s=$sid">Reload</a>

</form><hr>
<a href="http://zxid.org/">zxid.org</a>
HTML
;
  return 1;
}

__EOF__
