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
# Dash idea: show four field of icons
# 1. Who (humans) have accessed, tried to access, could access
# 2. What systems have accessed, tried to access, could access
# 3. Why the access (which business processes),
#    which biz processes tried to access, which bp could access
# 4. What data have been accessed, tried to access, could be accessed
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
Web GUI CGI for exploring ZXID logs and audit trail
Usage: http://localhost:8081/zxidexplo.pl?QUERY_STRING
       ./zxidexplo.pl -a QUERY_STRING
         -a Ascii mode
USAGE
    ;

die $USAGE if $ARGV[0] =~ /^-[Hh?]/;
$ascii = shift if $ARGV[0] eq '-a';
syswrite STDOUT, "Content-Type: text/html\r\n\r\n" if !$ascii;

$ENV{QUERY_STRING} ||= shift;
$cgi = cgidec($ENV{QUERY_STRING});
$cmd = $$cgi{'c'};
$dir = $$cgi{'d'} || '/var/zxid/';
$eid = $$cgi{'e'};
$nid = $$cgi{'n'};
$sid = $$cgi{'s'};

sub cgidec {
    my ($d) = @_;
    my %qs;
    for $nv (split '&', $d) {
	($n, $v) = split '=', $nv, 2;
	$qs{$n} = $v;
    }
    return \%qs;
}

sub uridec {
    my ($val) = @_;
    $val =~ s/\+/ /g;
    $val =~ s/%([0-9a-f]{2})/chr(hex($1))/gsex;  # URI decode
    return $val;
}

sub urienc {
    my ($val) = @_;
    $val =~ s/([^A-Za-z0-9.,_-])/sprintf("%%%02x",ord($1))/gsex; # URI enc
    return $val;
}

sub read_log {
    open LOG, "./zxlogview ${dir}pem/logsign-nopw-cert.pem ${dir}pem/logenc-nopw-cert.pem <${dir}log/act|"
	or die "Cannot open log decoding pipe: $!";
    $/ = "\n";
    while ($line = <LOG>) {
	# ----+ 104 PP - 20100217-151751.352 19700101-000000.501 -:- - - - -      zxcall N W GOTMD http://idp.tas3.eu/zxididp?o=B -
	($pre, $len, $se, $sig, $ourts, $srcts, $ipport, $ent, $mid, $a7nid, $nid, $mm, $vvv, $res, $op, $para, @rest) = split /\s+/, $line;

	syswrite STDOUT, "$ourts $op\n";
    }
    close LOG;
}

sub show_log {
    print "<title>ZXID SP Log Explorer Log listing</title><link type=\"text/css\" rel=stylesheet href=\"dash.css\">\n<pre>\n";
    read_log();
    syswrite STDOUT, "</pre>";
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
    syswrite STDOUT, $templ;
    exit;
}

show_templ("dash-main.html", $cgi);

__END__
