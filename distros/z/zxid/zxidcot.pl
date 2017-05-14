#!/usr/bin/perl
# Copyright (c) 2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
# This is confidential unpublished proprietary source code of the author.
# NO WARRANTY, not even implied warranties. Contains trade secrets.
# Distribution prohibited unless authorized in writing.
# Licensed under Apache License 2.0, see file COPYING.
# $Id$
#
# 17.2.2010, created --Sampo
#
# Web GUI CGI for exploring ZXID logs and audit trail
#
# CGI / QUERY_STRING variables
#   c  $cmd    Command
#   d  $dir    Path to ZXID config directory, e.g: /var/zxid/ or /var/zxid/idp
#   e  $eid    Filter logs by Entity ID
#   n  $nid    Filter logs by Name ID
#   s  $sid    Filter logs by session ID

$usage = <<USAGE;
Web GUI for attribute selection and privacy preferences
Usage: http://localhost:8081/zxidatsel.pl?QUERY_STRING
       ./zxidcot.pl -a QUERY_STRING
         -a Ascii mode
USAGE
    ;
die $USAGE if $ARGV[0] =~ /^-[Hh?]/;
$ascii = shift if $ARGV[0] eq '-a';

$path = '/var/zxid/idp';

$bot = <<HTML;
<div class=zxbot>
<a class=zx href="http://zxid.org/">ZXID.org</a>
| <a class=zx href="http://www.tas3.eu/">TAS3.eu</a>
-- <a class=zx href="/index-idp.html">Top</a>
| <a class=zx href="?op=md">Register Metadata</a>
| <a class=zx href="?op=viewcot">View Metadata</a>
| <a class=zx href="?op=direg">Register Web Service</a>
| <a class=zx href="?op=viewreg">View Discovery</a>
</div>
HTML
    ;

use Data::Dumper;

close STDERR;
open STDERR, ">>/var/tmp/zxid.stderr" or die "Cant open error log: $!";
select STDERR; $|=1; select STDOUT;

$ENV{QUERY_STRING} ||= shift;
cgidec($ENV{QUERY_STRING});

if ($ENV{CONTENT_LENGTH}) {
    sysread STDIN, $data, $ENV{CONTENT_LENGTH};
    #warn "GOT($data) $ENV{CONTENT_LENGTH}";
    cgidec($data);
}
warn "$$: cgi: " . Dumper(\%cgi);

sub uridec {
    my ($val) = @_;
    $val =~ s/\+/ /g;
    $val =~ s/%([0-9a-f]{2})/chr(hex($1))/gsexi;  # URI decode
    return $val;
}

sub urienc {
    my ($val) = @_;
    $val =~ s/([^A-Za-z0-9.,_-])/sprintf("%%%02x",ord($1))/gsex; # URI enc
    return $val;
}

sub cgidec {
    my ($d) = @_;
    for $nv (split '&', $d) {
	($n, $v) = split '=', $nv, 2;
	$cgi{$n} = uridec($v);
    }
}

sub readall {
    my ($f) = @_;
    my ($pkg, $srcfile, $line) = caller;
    undef $/;         # Read all in, without breaking on lines
    open F, "<$f" or die "$srcfile:$line: Cant read($f): $!";
    binmode F;
    my $x = <F>;
    close F;
    return $x;
}

sub show_templ {
    my ($templ, $hr) = @_;
    $templ = readall($templ);
    $templ =~ s/!!(\w+)/$$hr{$1}/gs;
    my $len = length $templ;
    syswrite STDOUT, "Content-Type: text/html\r\nContent-Length: $len\r\n\r\n$templ";
    exit;
}

sub redirect {
    my ($url) = @_;
    syswrite STDOUT, "Location: $url\r\n\r\n";
    exit;
}

### Metadata

if ($cgi{'op'} eq 'md') {
    syswrite STDOUT, "Content-Type: text/html\r\n\r\n".<<HTML;
<title>ZXID IdP CoT Mgr: MD Reg</title>
<link type="text/css" rel=stylesheet href="an.css">
<h1 class=zxtop>ZXID IdP Circle of Trust Manager</h1>

<h3>Service Provider Metadata Registration</h3>

<form method=post xaction="zxidcot.pl">
Paste metadata here:<br>
<textarea name=mdxml cols=80 rows=10>
</textarea><br>
<input type=submit name="okmd" value="Submit Metadata">
</form>
$bot
HTML
    ;
    exit;
}

if ($cgi{'okmd'}) {
    (undef, $eid) = $cgi{'mdxml'} =~ /entityID=([\"\']?)([^\"\' >]+)$1/;
    open COT, "|./zxcot -a ${path}cot/" or die "Cant write pipe zxcot -a ${path}cot/: $! $?";
    print COT $cgi{'mdxml'};
    close COT;
    open COT, "./zxcot -p '$eid'|" or die "Cant read pipe zxcot -p $eid: $! $?";
    $cgi{'sha1name'} = <COT>;
    close COT;
    chomp $cgi{'sha1name'};
    $cgi{'msg'} = "<span class=zxmsg>Metadata for $eid added.</span>";
    $cgi{'op'}  = 'viewcot';  # Fall thru to viewcot
}

if ($cgi{'op'} eq 'viewcot') {
    open COT, "./zxcot ${path}cot/|" or die "Cant read pipe zxcot ${path}cot/: $! $?";
    while ($line = <COT>) {
	($mdpath, $eid, $desc) = split /\s+/, $line, 3;
	($sha1name) = $mdpath =~ /\/([A-Za-z0-9_-]+)$/;
	$ts = gmtime((stat($mdpath))[9]);
	if ($sha1name eq $cgi{'sha1name'}) {
	    push @splist, "<tr><td><a href=\"$eid\">$eid</a></td><td><b><a href=\"?op=view1md&sha1name=$sha1name\">$sha1name</a></b></td><td>$ts</td><td>$desc</td></tr>\n";
	} else {
	    push @splist, "<tr><td><a href=\"$eid\">$eid</a></td><td><a href=\"?op=view1md&sha1name=$sha1name\">$sha1name</a></td><td>$ts</td><td>$desc</td></tr>\n";
	}
    }
    close COT;
    $splist = join '', sort @splist;
    syswrite STDOUT, "Content-Type: text/html\r\n\r\n".<<HTML;
<title>ZXID IdP CoT Mgr: SP List</title>
<link type="text/css" rel=stylesheet href="an.css">
<h1 class=zxtop>ZXID IdP Circle of Trust Manager</h1>
$cgi{'msg'}
<h3>Service Provider Metadata Listing</h3>
<i>This listing reflects the Service Providers known to us, i.e. in our Circle of Trust.</i>

<table>
<tr><th>EntityID</th><th>Metadata (sha1name)</th><th>Last updated</th><th>Description</th></tr>
$splist
</table>

$bot
HTML
    ;
    exit;
}

if ($cgi{'op'} eq 'view1md') {   # View one metadata
    $fn = $cgi{'sha1name'};
    die "Malicious sha1name($fn)" unless $fn =~ /^[A-Za-z0-9_-]+$/;
    $md = readall("${path}cot/$fn");
    syswrite STDOUT, "Content-Type: text/xml\r\n\r\n".$md;
    exit;
}

### Discovery Registration

if ($cgi{'op'} eq 'direg') {
    syswrite STDOUT, "Content-Type: text/html\r\n\r\n".<<HTML;
<title>ZXID IdP CoT Mgr: DI Reg</title>
<link type="text/css" rel=stylesheet href="an.css">
<h1 class=zxtop>ZXID IdP Circle of Trust Manager</h1>

<h3>Web Service Discovery Registration</h3>

<form method=post xaction="zxidcot.pl">

<table>
<tr><th>Endpoint URL</th><td><input name=endpoint size=60></td></tr>
<tr><th>Abstract</th><td><input name=abstract size=60></td></tr>
<tr><th>Entity ID</th><td><input name=eid size=60></td></tr>
<tr><th>Service Type (URN)</th><td><input name=svctype size=60></td></tr>
</table>
<p><input type=submit name="okdireg" value="Submit Discovery Registration">
</form>
$bot
HTML
    ;
    exit;
}

if ($cgi{'okdireg'}) {
    warn "./zxcot -e '$cgi{'endpoint'}' '$cgi{'abstract'}' '$cgi{'eid'}' '$cgi{'svctype'}' | ./zxcot -b ${path}dimd/";
    system "./zxcot -e '$cgi{'endpoint'}' '$cgi{'abstract'}' '$cgi{'eid'}' '$cgi{'svctype'}' | ./zxcot -b ${path}dimd/";
    $cgi{'msg'} = "<span class=zxmsg>Registration for $cgi{'eid'} added.</span>";
    $cgi{'op'} = 'viewreg';  # Fall through to viewreg
}

if ($cgi{'op'} eq 'viewreg') {
    #open COT, "./zxcot ${path}dimd/|" or die "Cant read pipe zxcot ${path}dimd/: $! $?";
    opendir DIMD, "${path}dimd/" or die "Cant read dir ${path}dimd/ $!";
    while ($fn = readdir DIMD) {
	next if $fn =~ /^\./;
	$data = readall("${path}dimd/$fn");
	(undef, undef, $svctype) = $data =~ /<((\w+:)?ServiceType)[^>]*>([^<]*)<\/\1>/;
	(undef, undef, $eid)  = $data =~ /<((\w+:)?ProviderID)[^>]*>([^<]*)<\/\1>/;
	(undef, undef, $desc) = $data =~ /<((\w+:)?Abstract)[^>]*>([^<]*)<\/\1>/;
	(undef, undef, $url)  = $data =~ /<((\w+:)?Address)[^>]*>([^<]*)<\/\1>/;
	#$dbg .= "\n===== $fn =====\n" . $data . "\n---- svctype($svctype) eid($eid) desc($desc) url($url)";
	push @{$by_type{$svctype}}, $fn;
	$ts = gmtime((stat("${path}dimd/$fn"))[9]);
	$line{$fn} = "<tr><td>EntityID:<br>Endpoint:<br>File:</td><td><a href=\"$eid\">$eid</a><br><a href=\"$url\">$url</a><br><a href=\"?op=view1reg&sha1name=$fn\">$fn</a></td><td>$ts</td><td>$desc</td></tr>\n";	
    }
    close COT;

    for $svctype (sort keys %by_type) {
	$reglist .= "<tr><th colspan=4>$svctype</th></tr>\n"
	    . join('', sort map($line{$_}, @{$by_type{$svctype}}));
    }
    
    syswrite STDOUT, "Content-Type: text/html\r\n\r\n".<<HTML;
<title>ZXID IdP CoT Mgr: SP List</title>
<link type="text/css" rel=stylesheet href="an.css">
<h1 class=zxtop>ZXID IdP Circle of Trust Manager</h1>
$cgi{'msg'}
<h3>Web Service Discovery Registration Listing</h3>
<i>This listing reflects the web services known to us, i.e. the ones that are discoverable.</i>

<table>
<tr><th colspan=2>Service Type / EntityID / Endpoint URL / sha1name</th><th>Last updated</th><th>Description</th></tr>
$reglist
</table>
$bot
HTML
    ;
#<textarea cols=100 rows=40>$dbg</textarea>
    exit;
}

if ($cgi{'op'} eq 'view1reg') {   # View one metadata
    $fn = $cgi{'sha1name'};
    die "Malicious sha1name($fn)" if $fn =~ /\.\./;
    $reg = readall("${path}dimd/$fn");
    syswrite STDOUT, "Content-Type: text/xml\r\n\r\n".$reg;
    exit;
}

warn "Unsupported op($cgi{'op'})";
redirect('/?err=unsupported-op');

__END__
