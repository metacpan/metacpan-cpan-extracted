#!/usr/bin/perl -w
# $Id: 04pragma.t,v 1.2 1999/12/17 22:18:02 aqua Exp $

BEGIN {
    $| = 1; print "1..7\n";
}
END {print "not ok 1\n" unless $loaded;}
use Text::BasicTemplate;
$loaded = 1;
print "ok 1\n";

use strict;

my $bt = new Text::BasicTemplate;
$bt or print "not ";
print "ok 2\n";

my %ov = (
	  me => 'something',
);


my $ss;
my $tf = "/tmp/maketest-04pragma-$$-it.tmpl";
open(TT,">$tf") || do {
    print "not ok 3\n";
    exit(1);
};
print TT "included %me%";
close TT;
print "ok 3\n";

print "not "
  unless $bt->parse($tf,\%ov) eq 'included something';
print "ok 4\n";

$ss = "I have %&bt_include(file,$tf)%";
print "not " unless $bt->parse(\$ss,\%ov) eq 'I have included something';
print "ok 5\n";

$bt->{pragma_enable}->{bt_include} = 0;
$bt->purge_cache;
print "not " unless $bt->parse(\$ss,\%ov) eq 'I have '.$bt->{disabled_pragma_identifier};
print "ok 6\n";

if (-x '/bin/echo') {
    $ss = "exec is %&bt_exec(cmd,/bin/echo working,noparse)%";
} elsif (-x '/usr/bin/echo') {
    $ss = "exec is %&bt_exec(cmd,/usr/bin/echo working,noparse)%";
} else {
    $ss = "exec is %&bt_exec(cmd,$^X -e 'print \"working\"',noparse)%";
}
$bt->{pragma_enable}->{bt_exec} = 1;
print "not " unless $bt->parse(\$ss,\%ov) =~ /^exec is working/;
print "ok 7\n";


unlink($tf);
