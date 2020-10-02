use Test::More 0.98 tests => 5;
use Encode qw(is_utf8 encode_utf8 decode_utf8);
use lib 'lib';

no utf8;    # Of course it defaults no, but declare it explicitly

my $plain = '宣言なし';
is is_utf8($plain), '', "$plain is NOT decoded yet";

my $decoded = decode_utf8($plain);
is is_utf8($decoded), 1, encode_utf8 "$decoded is DECODED manually";

my $encoded = encode_utf8($decoded);
is is_utf8($encoded), '', "$encoded is now encoded to utf8 again";

use usw;    # turn it on

$plain   = '宣言あり';
$encoded = encode_utf8($plain);
is is_utf8($plain), 1, "$encoded is DECODED automatically";

#is is_utf8($plain), 1, "$plain is DECODED automatically"; # does not work well

no utf8;    # turn it off again

$plain = '再び宣言なし';
is is_utf8($plain), '', "$plain is NOT decoded again";

done_testing;
