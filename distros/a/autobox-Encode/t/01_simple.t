use strict;
use warnings;
use autobox::Encode;
use Encode ();
use Test::More tests => 8;

ok Encode::is_utf8('あいうえお'->decode('utf-8'));
is 'あいうえお'->decode('utf-8'), "\x{3042}\x{3044}\x{3046}\x{3048}\x{304a}";
is uc(unpack "H*", 'あいうえお'->decode('utf-8')->encode('euc-jp')), "A4A2A4A4A4A6A4A8A4AA";
is 'あいうえお'->decode('utf-8')->encode('ascii', Encode::FB_PERLQQ), '\x{3042}\x{3044}\x{3046}\x{3048}\x{304a}';
ok 'あいうえお'->decode('utf-8')->is_utf8;
ok not 'あいうえお'->is_utf8;

my $x = 'あいうえお';
is uc(unpack "H*", $x->from_to('utf-8' => 'euc-jp')), "A4A2A4A4A4A6A4A8A4AA";

is "\x{1234}"->charname, "ETHIOPIC SYLLABLE SEE";
