# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

# Runtime test for mb::valid() (path-3 entry point).
#
# mb::valid is the explicit, opt-in well-formedness check. It uses the STRICT
# unit ($over_ascii or a US-ASCII byte), NOT the lenient $x, so any stray octet
# makes the whole string fail and the predicate returns 0. The string is never
# modified. mb is loaded with require (no source filter, so this runs on every
# perl from 5.005_03 up) and the script encoding is set explicitly.

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
require mb;
mb::set_script_encoding('utf8');
use vars qw(@test);

@test = (
# well-formed input is valid
    sub { mb::valid('')                                  == 1 },
    sub { mb::valid('ABC')                               == 1 },
    sub { mb::valid('あいうえお')                        == 1 },
    sub { mb::valid('あいうえお漢字ABC')                 == 1 },
    sub { mb::valid("\xC2\xA0")                          == 1 }, # 2-byte (NBSP as U+00A0)
    sub { mb::valid("\xE3\x81\x82")                      == 1 }, # 3-byte
    sub { mb::valid("\xF0\x9F\x98\x80")                  == 1 }, # 4-byte (emoji)
    sub { mb::valid("A\xE3\x81\x82Z")                    == 1 }, # mixed ASCII + multibyte
# malformed octets are invalid (no UTF-8 flag, but explicit check rejects)
    sub { mb::valid("\x85")                              == 0 }, # lone continuation byte
    sub { mb::valid("\xA0")                              == 0 }, # lone continuation byte
    sub { mb::valid("A\x85B")                            == 0 }, # stray byte in the middle
    sub { mb::valid("\xE3\x81")                          == 0 }, # truncated 3-byte sequence
    sub { mb::valid("\xE3\x81\x82\x85")                  == 0 }, # valid char then stray byte
    sub { mb::valid("\xC0\x80")                          == 0 }, # overlong encoding of NUL
    sub { mb::valid("\xFF")                              == 0 }, # never a valid lead byte
# default to $_
    sub { local $_='漢字';     mb::valid()              == 1 },
    sub { local $_="\x85";     mb::valid()              == 0 },
# the string is never modified by mb::valid
    sub { my $s="A\x85B"; mb::valid($s); $s eq "A\x85B" },
# valid agrees with the strict codepoint walk used throughout mb: well-formed
# input has a definite codepoint length and passes, while a stray octet halts
# the strict walk early (so $x-based length stops short) and fails validation.
    sub { (mb::length('あいう') == 3)  and (mb::valid('あいう') == 1) },
    sub { (mb::length("A\x85B") == 1)  and (mb::valid("A\x85B") == 0) },
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
