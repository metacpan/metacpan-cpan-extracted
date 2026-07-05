# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

# Regression test: a malformed FINAL octet must be kept, not silently dropped.
#
# On the Shift_JIS family the second octet of a double-octet code spans the
# whole 0x00-0xFF range, so a lead byte that ends a string with no octet after
# it cannot complete a two-octet sequence. mb must NOT delete such a stray
# octet and must NOT fold it into the preceding character: the strict codepoint
# walk treats it as its own one-octet unit, so mb::chop returns exactly that
# octet and leaves everything before it byte-for-byte intact. This is the
# long-standing Sjis/Esjis behaviour ("not ignored and not deleted
# automatically ... Esjis::chop subroutine returns this octet").
#
# mb is loaded with require (no source filter), so this runs on every perl from
# 5.005_03 up. Only US-ASCII source and \x escapes are used so the file stays
# US-ASCII at the byte level.

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
require mb;
use vars qw(@test);

@test = (
# --- sjis: malformed final octet is RETURNED by chop, prefix left intact ---
    sub { mb::set_script_encoding('sjis');
          my $s = "\x82\xA0\x82"; my $r = mb::chop($s);
          ($r eq "\x82") && ($s eq "\x82\xA0") },           # the core assertion
    sub { mb::set_script_encoding('sjis');
          my $s = "\x82\xA0\x82"; mb::chop($s);
          $s eq "\x82\xA0" },                               # full char untouched
    sub { mb::set_script_encoding('sjis');
          my $s = "\x82\xA0\x82"; my $r = mb::chop($s);
          $r eq "\x82" },                                   # stray octet, not "\x82\xA0"
# --- a stray lead byte that is the WHOLE string ---
    sub { mb::set_script_encoding('sjis');
          my $s = "\x82"; my $r = mb::chop($s);
          ($r eq "\x82") && ($s eq '') },
# --- a well-formed full DBCS char chops cleanly ---
    sub { mb::set_script_encoding('sjis');
          my $s = "\x82\xA0"; my $r = mb::chop($s);
          ($r eq "\x82\xA0") && ($s eq '') },
# --- a single-octet half-width kana (0xA0-0xDF) is one unit, not a trail ---
    sub { mb::set_script_encoding('sjis');
          my $s = "\x82\xA0\xB1"; my $r = mb::chop($s);
          ($r eq "\xB1") && ($s eq "\x82\xA0") },
# --- the strict walk counts the stray octet as its own unit (length 2) ---
    sub { mb::set_script_encoding('sjis');
          mb::length("\x82\xA0\x82") == 2 },
# --- under sjis the dangling lead is tolerated (valid), string unmodified ---
    sub { mb::set_script_encoding('sjis');
          my $s = "\x82\xA0\x82"; my $v = mb::valid($s);
          ($v == 1) && ($s eq "\x82\xA0\x82") },
# --- contrast: under utf8 a dangling lead byte is reported invalid ---
    sub { mb::set_script_encoding('utf8');
          mb::valid("\xE3\x81\x82\xE3") == 0 },
    sub { mb::set_script_encoding('utf8');
          mb::valid("\xE3\x81\x82")     == 1 },
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
