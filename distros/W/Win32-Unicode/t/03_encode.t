use strict;
use Test::More;

use Win32::Unicode::Util;
use utf8;
use Encode qw/encode/;

my $utf8_str  = 'あかさたなｶｷｸｹｺ';
my $utf16_str = encode 'utf16-le', $utf8_str;

is utf8_to_utf16($utf8_str), $utf16_str;
is utf16_to_utf8($utf16_str), $utf8_str;
ok not utf8_to_utf16;
ok not utf16_to_utf8;

done_testing;
