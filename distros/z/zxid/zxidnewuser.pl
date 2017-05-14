#!/usr/bin/perl
# Copyright (c) 2012-2014 Synergetics SA (sampo@synergetics.be), All Rights Reserved.
# Copyright (c) 2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
# This is confidential unpublished proprietary source code of the author.
# NO WARRANTY, not even implied warranties. Contains trade secrets.
# Distribution prohibited unless authorized in writing.
# Licensed under Apache License 2.0, see file COPYING.
# $Id$
#
# 8.3.2010, created --Sampo
# 5.2.2012, changed zxpasswd to use -n instead of -c --Sampo
# 9.2.2014, changed to use zxpasswd -new
#
# Web GUI for creating new user, possibly in middle of login sequence.
# The AuthnRequest is preserved through new user creation by passing ar.

$from = 'sampo-pwbot-noreply@zxid.org';
$admin_mail = 'sampo-pwadm@zxid.org';
$dir = '/var/zxid/idp';

$usage = <<USAGE;
Web GUI for creating new user, possibly in middle of login sequence.
Usage: http://localhost:8081/zxidnewuser.pl?QUERY_STRING
       ./zxidnewuser.pl -a QUERY_STRING
         -a Ascii mode
         -t Test mode
USAGE
    ;
die $usage if $ARGV[0] =~ /^-[Hh?]/;
if ($ARGV[0] eq '-t') {
    warn "Sending...";
    send_detail("Test $$");
    exit;
}

use Data::Dumper;
use MIME::Base64;

close STDERR;
open STDERR, ">>/var/tmp/zxid.stderr" or die "Cant open error log: $!";
select STDERR; $|=1; select STDOUT;

($sec,$min,$hour,$mday,$mon,$year) = gmtime(time);
$ts = sprintf "%04d%02d%02d-%02d%02d%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec;
#warn "$$: START env: " . Dumper(\%ENV);

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

sub send_mail {
    my ($to, $subj, $body) = @_;
    open S, "|/usr/sbin/sendmail -i -B 8BITMIME -t" or die "No sendmail in path: $! $?";
    $msg = <<MAIL;
From: $from
To: $to
Subject: $subj
MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-8859-1
Content-Transfer-Encoding: 8bit

$body
MAIL
;
    warn "msr($msg)";
    print S $msg;
    close S;
}

sub send_detail {
    my ($subj) = @_;
    send_mail($admin_mail, $subj, <<BODY);
uid: $cgi{'au'}
ip: $ENV{REMOTE_ADDR}
title: $cgi{'title'}
o: $cgi{'o'}
ou: $cgi{'ou'}
email: $cgi{'email'}
im: $cgi{'im'}
tel: $cgi{'tel'}
tag: $cgi{'tag'}

Comments or special requests:
$cgi{'comment'}
BODY
    ;
}

if (length $cgi{'continue'}) {
    if ($cgi{'zxidpurl'} && $cgi{'zxrfr'} && $cgi{'ar'}) {
       warn "Redirecting back to IdP";
       redirect("$cgi{'zxidpurl'}?o=$cgi{'zxrfr'}&ar=$cgi{'ar'}");
    } else {
       warn "Redirecting back to index page.";
       redirect("/");
    }
}

### MAIN

if (length $cgi{'ok'}) {
    if (length $cgi{'au'} < 3 || length $cgi{'au'} > 40) {
	$cgi{'ERR'} = "Username must be at least 3 characters long (and no longer than 40 chars).";
    } elsif ($cgi{'au'} !~ /^[A-Za-z0-9_-]+$/s) {
	$cgi{'ERR'} = "Username can only contain characters [A-Za-z0-9_-]";
    } elsif (length $cgi{'ap'} < 5 || length $cgi{'ap'} > 80) {
	$cgi{'ERR'} = "Password must be at least 5 characters long (and no longer than 80 chars).";
    } elsif (-e "${dir}uid/$cgi{'au'}") {
	$cgi{'ERR'} = "Username already taken.";
    } else {
	warn "Creating new user($cgi{'au'})";
	open P, "|./zxpasswd -new $cgi{'au'} ${dir}uid" or die "Cant open pipe to zxpasswd: $! $?";
	print P $cgi{'ap'};
	close P;
	warn "Populating user($cgi{'au'})";
	if (-e "${dir}uid/$cgi{'au'}") {
	    open LOG, ">${dir}uid/$cgi{'au'}/.log" or die "Cant open write .log: $!";
	    print LOG "$ts Created $cgi{'au'} ip=$ENV{REMOTE_ADDR}\n" or die "Cant write .log: $!";
	    close LOG or die "Cant close write .log: $!";

	    open IP, ">${dir}uid/$cgi{'au'}/.regip" or die "Cant open write .regip: $!";
	    print IP $ENV{REMOTE_ADDR} or die "Cant write .regip: $!";
	    close IP or die "Cant close write .regip: $!";

	    if ($cgi{'humanintervention'} > 0) {
		open HUMAN, ">${dir}uid/$cgi{'au'}/.human" or die "Cant open write .human: $!";
		print HUMAN $cgi{'humanintervention'} or die "Cant write .human: $!";
		close HUMAN or die "Cant close write .human: $!";
	    }
	    #mkdir "${dir}uid/$cgi{'au'}/.bs" or warn "Cant mkdir .bs: $!"; zxpasswd creates .bs
	    open AT, ">${dir}uid/$cgi{'au'}/.bs/.at" or die "Cant write .bs/.at: $!";
	    open OPTAT, ">${dir}uid/$cgi{'au'}/.bs/.optat" or die "Cant write .bs/.optat: $!";
	    
	    for $at (qw(cn title taxno o ou street citystc email im tel lang tag)) {
		$val = $cgi{$at};
		$val =~ s/[\r\n]//g;
		next if !length $val;
		if ($cgi{"${at}share"}) {
		    print AT "$at: $val\n";
		} else {
		    print OPTAT "$at: $val\n";
		}
	    }
	    
	    close AT;
	    close OPTAT;
	    
	    send_detail("New User $cgi{'au'}");

            if ($cgi{'zxidpurl'} && $cgi{'zxrfr'} && $cgi{'ar'}) {
		warn "Created user($cgi{'au'})";
		$cgi{MSG} = "Success! Created user $cgi{'au'}. Click Continue to get back to IdP login.";
		show_templ("newuser-status.html", \%cgi);
            } else {
		warn "Created user($cgi{'au'})";
		$cgi{MSG} = "Success! Created user $cgi{'au'}. Click Continue to get back to top.";
		show_templ("newuser-status.html", \%cgi);
            }
	} else {
	    $cgi{'ERR'} = "User creation failed. System error (${dir}uid/$cgi{'au'}).";
	}
    }
}

$cgi{'humaninterventionchecked'} = $cgi{'humanintervention'} eq '1' ? ' checked':'';
$cgi{'ip'} = $ENV{REMOTE_ADDR};
if (!length $cgi{'ap'}) {
    open R, "</dev/urandom" or die "Cant open read /dev/urandom: $!";
    sysread R, $pw, 9;
    close R;
    $cgi{'ap'} = encode_base64($pw,'');  # Just a suggestion
}
show_templ("newuser-main.html", \%cgi);

__END__
