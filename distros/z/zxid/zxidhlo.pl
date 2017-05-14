#!/usr/bin/perl
# Copyright (c) 2007-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
# Author: Sampo Kellomaki (sampo@iki.fi)
# This is confidential unpublished proprietary source code of the author.
# NO WARRANTY, not even implied warranties. Contains trade secrets.
# Distribution prohibited unless authorized in writing.
# Licensed under Apache License 2.0, see file COPYING.
# $Id: zxidhlo.pl,v 1.7 2009-11-14 22:44:43 sampo Exp $
# 16.1.2007, created --Sampo
# 14.11.2009, Added zxid_az() example --Sampo

use Net::SAML;
use Data::Dumper;

$| = 1;
undef $/;

open STDERR, ">>tmp/zxid.stderr";   # Helps CGI debugging where web server eats the stderr

#$url = "https://sp1.zxidsp.org:8443/zxidhlo.pl";  # Edit to match your situation
$url = "http://sp.tas3.pt:8082/zxidhlo.pl";  # Edit to match your situation
$conf = "PATH=/var/zxid/&URL=$url";
$cf = Net::SAML::new_conf_to_cf($conf);
#warn "cf($cf):".Dumper($cf);
$qs = $ENV{'QUERY_STRING'};
$qs = <STDIN> if $qs =~ /o=P/;
$res = Net::SAML::simple_cf($cf, -1, $qs, undef, 0x1828);
$op = substr($res, 0, 1);
if ($op eq 'L' || $op eq 'C') { warn "res($res) len=".length($res); print $res; exit; } # LOCATION (Redir) or CONTENT
if ($op eq 'n') { exit; } # already handled
if ($op eq 'e') { my_render_login_screen(); exit; }
if ($op ne 'd') { die "Unknown Net::SAML::simple() res($res)"; }

# *** add code to parse the LDIF in $res into a hash of attributes

($sid) = $res =~ /^sesid: (.*)$/m;

if (Net::SAML::az_cf($cf, "Action=Show", $sid)) {
    $az = "Permit.\n";
} else {
    $az = "<b>Deny.</b> Normally page would not be shown, but we show session attributes for debugging purposes.\n";
}

print <<HTML
CONTENT-TYPE: text/html

<title>ZXID perl HLO SP Mgmt</title>
<link rel="shortcut icon" href="/favicon.ico" type="image/x-icon" />
<body bgcolor="#330033" text="#ffaaff" link="#ffddff" vlink="#aa44aa" alink="#ffffff"><font face=sans>
$az
<h1>ZXID SP Perl HLO Management (user logged in, session active)</h1>
sesid: $sid
HTML
    ;
print Net::SAML::fed_mgmt_cf($cf, undef, -1, $sid, 0x1900);
exit;

###
### Render the login screen
###

sub my_render_login_screen {
    print <<HTML;
CONTENT-TYPE: text/html

<title>ZXID SP PERL HLO SSO</title>
<link rel="shortcut icon" href="/favicon.ico" type="image/x-icon" />
<body bgcolor="#330033" text="#ffaaff" link="#ffddff" vlink="#aa44aa" alink="#ffffff"><font
face=sans><h1>ZXID SP Perl HLO Federated SSO (user NOT logged in, no session.)</h1>
<form method=get action="zxidhlo.pl">

<h3>Login Using New IdP</h3>

<i>A new IdP is one whose metadata we do not have yet. We need to know
the Entity ID in order to fetch the metadata using the well known
location method. You will need to ask the adminstrator of the IdP to
tell you what the EntityID is.</i>

<p>IdP URL <input name=e size=60>
<input type=submit name=l1 value=" Login (A2) ">
<input type=submit name=l2 value=" Login (P2) ">
HTML
;
    print Net::SAML::idp_list_cf($cf, undef, 0x1c00);   # Get the IdP selection form
    print <<HTML;
<h3>CoT configuration parameters your IdP may need to know</h3>

Entity ID of this SP: <a href="$url?o=B">$url?o=B</a> (Click on the link to fetch SP metadata.)

<h3>Technical options</h3>
<input type=checkbox name=fc value=1 checked> Create federation,
   NID Format: <select name=fn>
                 <option value=prstnt>Persistent
                 <option value=trnsnt>Transient
                 <option value="">(none)
               </select><br>

<input type=hidden name=fq value="">
<input type=hidden name=fy value="">
<input type=hidden name=fa value="">
<input type=hidden name=fm value="">
<input type=hidden name=fp value=0>
<input type=hidden name=ff value=0>

</form><hr><a href="http://zxid.org/">zxid.org</a>
HTML
    ;
}

__END__
