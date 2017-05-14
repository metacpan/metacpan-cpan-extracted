#!/usr/bin/perl
# Copyright (c) 2010-2014 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
# This is confidential unpublished proprietary source code of the author.
# NO WARRANTY, not even implied warranties. Contains trade secrets.
# Distribution prohibited unless authorized in writing.
# Licensed under Apache License 2.0, see file COPYING.
# $Id$
#
# 13.3.2010, created --Sampo
# 14.2.2014, perfected local login with IdP --Sampo
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
       ./zxidatsel.pl -a QUERY_STRING
         -a Ascii mode
USAGE
    ;
die $usage if $ARGV[0] =~ /^-[Hh?]/;

$cpath = '/var/zxid/idp';

use Net::SAML;
use Data::Dumper;

close STDERR;
open STDERR, ">>/var/tmp/zxid.stderr" or die "Cant open error log: $!";
select STDERR; $|=1; select STDOUT;

#warn "$$: START env: " . Dumper(\%ENV);

$ENV{QUERY_STRING} ||= shift;
$qs = $ENV{QUERY_STRING};
cgidec($qs);

if ($ENV{CONTENT_LENGTH}) {
    sysread STDIN, $qs, $ENV{CONTENT_LENGTH};
    #warn "GOT($qs) $ENV{CONTENT_LENGTH}";
    cgidec($qs);
}

$confdata = readall("${cpath}zxid.conf",1);
($ses_cookie_name) = $confdata =~ /^SES_COOKIE_NAME=(.*)$/m;
$ses_cookie_name ||= 'ZXIDSES';
($ses_from_cookie) = $ENV{HTTP_COOKIE} =~ /$ses_cookie_name=([^; \t]+)/;

warn "$$ s-from-c($ses_from_cookie) cgi: " . Dumper(\%cgi);

### Due to circumstances, zxididp typically will not have set the cookie so we need to set it here

if (!$ses_from_cookie) {
    $ses_from_cookie = $cgi{'s'};
    $setcookie = "\r\nSet-Cookie: $ses_cookie_name=$ses_from_cookie";
}
if ($cgi{'s'}) {
    if ($cgi{'s'} ne $ses_from_cookie) {
	$cgi{'s'} = $ses_from_cookie;
	$setcookie = "\r\nSet-Cookie: $ses_cookie_name=$ses_from_cookie";
    }
} else {
    $cgi{'s'} = $ses_from_cookie;
    $setcookie = "\r\nSet-Cookie: $ses_cookie_name=$ses_from_cookie";
}

$sesdata = readall("${cpath}ses/$cgi{'s'}/.ses", 1);
$persona = readall("${cpath}ses/$cgi{'s'}/.persona", 1);
if (!length $sesdata) {
    $qs = $qs ? "$qs&" : "";
    $qs .= "o=F&redirafter=$ENV{SCRIPT_NAME}?s=X";
    warn "No session! Need to login($cgi{'s'}).  qs($qs)";
    $cf = Net::SAML::new_conf_to_cf("CPATH=$cpath");
    $res = Net::SAML::simple_cf($cf, -1, $qs, undef, 0x3fff); # 0x1829
    cgidec($res);
    warn "$$: SSO done($res): " . Dumper(\%cgi);
    # *** figure out the IdP session
    $sesdata = readall("${cpath}ses/XXX/.ses",1);
    $persona = readall("${cpath}ses/XXX/.persona",1);
}
(undef, undef, undef, undef, $uid) = split /\|/, $sesdata;
warn "uid($uid) sesdata($sesdata)";

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

sub cgidec {
    my ($d) = @_;
    for $nv (split '&', $d) {
	($n, $v) = split '=', $nv, 2;
	$cgi{$n} = uridec($v);
    }
}

# ./zxlogview /var/zxid/idppem/logsign-nopw-cert.pem /var/zxid/idppem/logenc-nopw-cert.pem </var/zxid/idpuid/Fool11/.log

sub read_user_log {
    my ($uid, $repeat, $nlog) = @_;
    open LOG, "tail -$nlog ${cpath}uid/$uid/.log | ./zxlogview ${cpath}pem/logsign-nopw-cert.pem ${cpath}pem/logenc-nopw-cert.pem|"
	or die "Cannot open log decoding pipe: $!";
    $/ = "\n";
    my ($what, $line, $x);
    my $accu = '';
    while ($line = <LOG>) {
	# 0     1   2  3 4                   5                   6   7 8 9 10     mm11   v r op
	# ----+ 104 PP - 20100217-151751.352 19700101-000000.501 -:- - - - -      zxcall N W GOTMD http://idp.tas3.eu/zxididp?o=B -
	my ($pre, $len, $se, $sig3, $ourts, $srcts5, $ipport6, $ent, $mid, $a7nid, $nid, $mm11, $vvv, $res, $op, $para, @rest) = split /\s+/, $line;
	#                                                                                           $para                        rest0       rest1
	# ----+ 124 PP - 20100314-172308.720 19700101-000000.501 -:- - - - -      zxidp N K INEWSES MSESey_n-6_oVkMlBR2dQCkgAlKs uid(Fool11) pw
	if ($op eq 'INEWSES') {
	    if ($rest[1] eq 'yk') {
		$what = "Authenticated using Yubikey. New session created.";
	    } elsif ($rest[1] eq 'pw') {
		$what = "Authenticated using password. New session created.";
	    } else {
		$what = "Other authn. New session created.";
	    }
	} elsif ($op eq 'DIA7N') {
	    $what = "Web Service Provider Bootstrap or Discovery.";
	} elsif ($op eq 'SSOA7N') {
	    $what = "Single Sign-On (SSO).";
	} else {
	    $what = "$op $para ".join(' ', @rest);
	}
	my %s = (when => $ourts, sp => $ent, id => $a7nid, what => $what);
	($x = $repeat) =~ s/!!(\w+)/$s{$1}/g;
	$accu .= $x;
    }
    close LOG;
    return $accu;
}

sub read_cot {
    my ($repeat, $selected_sp) = @_;
    open COT, "./zxcot ${cpath}cot|" or die "Cannot open zxcot pipe: $!";
    $/ = "\n";
    my ($line, $x);
    my $accu = '';
    while ($line = <COT>) {
	my ($file, $eid, $dpy_name) = split /\s+/, $line;
	my $selected = $eid eq $selected_sp ? 'selected' : '';
	my %s = (sp => $eid, spnice => $dpy_name, selectedsp => $selected);
	($x = $repeat) =~ s/!!(\w+)/$s{$1}/g;
	$accu .= $x;
    }
    close LOG;
    return $accu;
}

sub persona_menu {
    my ($repeat, $selected_persona, $ar_personae) = @_;
    my ($line, $x);
    my $accu = '';
    for $line (sort @{$ar_personae}) {
	my $selected = $line eq $selected_persona ? 'selected' : '';
	my %s = (pp => $line, selectedpp => $selected);
	($x = $repeat) =~ s/!!(\w+)/$s{$1}/g;
	$accu .= $x;
    }
    return $accu;
}

sub readall {
    my ($f, $nofatal) = @_;
    my ($pkg, $srcfile, $line) = caller;
    undef $/;         # Read all in, without breaking on lines
    open F, "<$f" or do { if ($nofatal) { warn "$srcfile:$line: Cant read($f): $!"; return undef; } else { die "$srcfile:$line: Cant read($f): $!"; } };
    binmode F;
    my $x = <F>;
    close F;
    return $x;
}

#######################################################################
### Typical idiom for loops (not supported directly by bangbang)
###    <!--REPEAT-->
###    <b>!!EDITION</b>: Pub date !!DATE
###    <!--END_REPEAT-->
###
### $t = filex::slurp('edition.ht');
### $t =~ s/<!--REPEAT-->(.*)<!--END_REPEAT-->/!!REPEAT/s;
### $repeat = $1;
### for $ed (1425, 1426) {
###	my %s = (EDITION => $ed, DATE => $shortdate{$ed});
###	($x = $repeat) =~ s/!!(\w+)/$s{$1}/g;
###	$accu .= $x;
### }
### $subst{REPEAT} = $accu;
###
### Typical idiom for ifs (supported directly by bangbang)
###    <!--IF(NEW)-->
###      <h3>Yes</h3>
###    <!--ELSE(NEW)-->
###      <h3>Else</h3>
###    <!--FI(NEW)-->
###
### bangbang(\$p, \%subst);   # modifies template $p in place
###
### The conditions can contain ! (not), && (and), and || (or) boolean
### operators. Parenthesis are not supported. No whitespace should be
### inserted between variables and operators.

sub eval_cond {
    my ($cond, $sr) = @_;
    my ($a,$op,$b);
  or_loop: for my $and_clause (split /\|\|/, $cond) {  # split by or
	for my $var (split /&&/, $and_clause) {
	    if (($a,$op,$b) = $var =~ /^(\w+)([<>=!]+)(\w+)$/) {
		$a = $$sr{$a} if $a !~ /^\d+$/;
		$b = $$sr{$b} if $b !~ /^\d+$/;
		next or_loop if $op eq '==' && $a ne $b;   # short circuit fail
		next or_loop if $op eq '!=' && $a eq $b;
		next or_loop if $op eq '<'  && $a >= $b;
		next or_loop if $op eq '>'  && $a <= $b;
		next or_loop if $op eq '<=' && $a >  $b;
		next or_loop if $op eq '>=' && $a <  $b;
	    } else {
		if (substr($var,0,1)eq'!') {
		    next or_loop if $$sr{substr($var,1)};  # short circuit fail
		} else {
		    next or_loop if !$$sr{$var};           # short circuit fail
		}
	    }
	}
	return 1;  # true: all ANDs were ok --> short circuit success
    }
    return ();  # false: all ORs failed
}

sub bangbang {
    my ($pr, $sr) = @_;

    ### Early substitutions
    my $n = 0;
    $n++ while $n<5 && $$pr =~ s/!%!(\w+)/$$sr{$1}/g;
    warn "$n levels of early substitution" if $n>=3;

    #warn "=======>$$pr<=======";
    1 while  # Process as many times as possible, handles nested ifs
    #do { warn "===>$$pr<===\n\n\n " if $x eq 'po_a' } while  # Debug
    #warn "==>$$sr{$3}:$1:$2:$3<==\n" while  # Debug
    #                     1-cond          2-then  3-else
	$$pr =~ s/<!--IF\(([\w!|&=<>]+)\)-->(.*?)
	          (?:<!--ELSE\(\1\)-->(.*?))?
		  <!--FI\(\1\)-->
	       / eval_cond($1,$sr) ? $2 : $3 /gsex;
    
    $n = 0;
    #do { $n++; warn "\n===>$$pr<===\n " if $x eq 'A105-pt'; } while $$pr =~ s/!!(\w+)/$$sr{$1}/g;
    $n++ while $n<20 && $$pr =~ s/!!(\w+)/$$sr{$1}/g;  # Do any remaining substitutions as many times it takes
    warn "$n levels of variable substitution" if $n>=10;
}

### $accu .= filex::bang($templ, 'err here', A=>"b", C=>"d");

sub show_templ {
    my ($templ, $hr) = @_;
    $templ = readall($templ);
    $templ =~ s/!!(\w+)/$$hr{$1}/gs;
    my $len = length $templ;
    syswrite STDOUT, "Content-Type: text/html\r\nContent-Length: $len$setcookie\r\n\r\n$templ";
    exit;
}

sub show_atsel {
    my ($uid, $hr) = @_;
    my $templ = readall("atsel-main.html");
    $templ =~ s/<!--REPEAT_LOG-->(.*)<!--END_REPEAT_LOG-->/!!REPEAT_LOG/s;
    my $repeat_log = $1;
    $templ =~ s/<!--REPEAT_SP-->(.*)<!--END_REPEAT_SP-->/!!REPEAT_SP/s;
    my $repeat_sp = $1;
    $templ =~ s/<!--REPEAT_PP-->(.*)<!--END_REPEAT_PP-->/!!REPEAT_PP/s;
    my $repeat_pp = $1;
    $templ =~ s/<!--REPEAT_ATTR-->(.*)<!--END_REPEAT_ATTR-->/!!REPEAT_ATTR/s;
    my $repeat_attr = $1;

    $$hr{NLOG} = 10;
    $$hr{REPEAT_LOG} = read_user_log($uid, $repeat_log, $$hr{NLOG});
    $$hr{REPEAT_SP}  = read_cot($repeat_sp, $selected_sp);
    $$hr{REPEAT_PP}  = read_cot($repeat_sp, $persona);
    
    # Scan all attributes according to algorithm

    
    
    bangbang(\$templ, $hr);
    my $len = length $templ;
    syswrite STDOUT, "Content-Type: text/html\r\nContent-Length: $len$setcookie\r\n\r\n$templ";
    exit;
}

show_atsel($uid, \%cgi);

__END__
