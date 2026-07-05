# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

# mb::valid is the strict, opt-in check. What counts as well-formed differs by
# the current script encoding (utf8 / rfc2279 / wtf8). Each closure sets the
# encoding it needs, so the tests are order-independent. mb is loaded with
# require (no source filter), so this runs on every perl from 5.005_03 up.

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
require mb;
use vars qw(@test);

@test = (
# utf8 (RFC 3629): strict -- no surrogate, no overlong, not beyond U+10FFFF
    sub { mb::set_script_encoding('utf8');    mb::valid("\xED\xA0\x80")     == 0 }, # lone surrogate U+D800
    sub { mb::set_script_encoding('utf8');    mb::valid("\xE0\x80\x80")     == 0 }, # overlong 3-byte
    sub { mb::set_script_encoding('utf8');    mb::valid("\xF4\x90\x80\x80") == 0 }, # beyond U+10FFFF
    sub { mb::set_script_encoding('utf8');    mb::valid("\xE3\x81\x82")     == 1 }, # valid 3-byte
    sub { mb::set_script_encoding('utf8');    mb::valid("\xF0\x9F\x98\x80") == 1 }, # valid 4-byte (emoji)
# rfc2279 (RFC 2279): permissive -- accepts surrogate, overlong, and beyond
    sub { mb::set_script_encoding('rfc2279'); mb::valid("\xED\xA0\x80")     == 1 },
    sub { mb::set_script_encoding('rfc2279'); mb::valid("\xE0\x80\x80")     == 1 },
    sub { mb::set_script_encoding('rfc2279'); mb::valid("\xF4\x90\x80\x80") == 1 },
    sub { mb::set_script_encoding('rfc2279'); mb::valid("\xE3\x81\x82")     == 1 },
# wtf8 (WTF-8): like utf8 but also accepts a lone surrogate
    sub { mb::set_script_encoding('wtf8');    mb::valid("\xED\xA0\x80")     == 1 }, # surrogate accepted
    sub { mb::set_script_encoding('wtf8');    mb::valid("\xE0\x80\x80")     == 0 }, # overlong still rejected
    sub { mb::set_script_encoding('wtf8');    mb::valid("\xF4\x90\x80\x80") == 0 }, # beyond still rejected
    sub { mb::set_script_encoding('wtf8');    mb::valid("\xE3\x81\x82")     == 1 },
# the differences, stated as relations
    sub { mb::set_script_encoding('utf8');    my $u = mb::valid("\xED\xA0\x80");
          mb::set_script_encoding('wtf8');    my $w = mb::valid("\xED\xA0\x80");
          ($u == 0) and ($w == 1) },                       # surrogate: utf8 no, wtf8 yes
    sub { mb::set_script_encoding('utf8');    my $u = mb::valid("\xE0\x80\x80");
          mb::set_script_encoding('rfc2279'); my $r = mb::valid("\xE0\x80\x80");
          ($u == 0) and ($r == 1) },                       # overlong: utf8 no, rfc2279 yes
    sub { mb::set_script_encoding('wtf8');    my $w = mb::valid("\xF4\x90\x80\x80");
          mb::set_script_encoding('rfc2279'); my $r = mb::valid("\xF4\x90\x80\x80");
          ($w == 0) and ($r == 1) },                       # beyond: wtf8 no, rfc2279 yes
# get/set round trip, and restore the default
    sub { mb::set_script_encoding('wtf8');    mb::get_script_encoding() eq 'wtf8' },
    sub { mb::set_script_encoding('euctw');   mb::get_script_encoding() eq 'euctw' },
    sub { mb::set_script_encoding('hp15');    mb::get_script_encoding() eq 'hp15' },
    sub { mb::set_script_encoding('informixv6als'); mb::get_script_encoding() eq 'informixv6als' },
    sub { mb::set_script_encoding('utf8');    mb::get_script_encoding() eq 'utf8' },
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
