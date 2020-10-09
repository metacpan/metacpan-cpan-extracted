use Test::More 0.98 tests => 6;
use Encode qw(is_utf8 encode_utf8 decode_utf8);

local $SIG{__WARN__} = sub {
    use usw;
    $_[0] =~ /(.+) line (\d+)\.$/;
    return pass("plain text $1 was warned") unless is_utf8($1);
    my $encoded = encode_utf8 $_[0];
    if ( $_[0] =~ qr/^宣言/ ) {
        fail "code is broken" if $_[0] =~ /^\x{5BA3}\x{8A00}\x{3042}\x{308A}$/;
        pass "it's an expected warning: $encoded";
    } else {
        fail "it's an unexpected warning: $encoded";
    }
};

no utf8;    # Of course it defaults no, but declare it explicitly
use strict;
use warnings;

my $plain = '宣言なし';
eval { warn $plain } and pass("$plain is a plain");

{
    use usw;    # turn it on
    use utf8;
    my $decoded = '宣言あり';
    eval { warn $decoded } and pass("pass to warn with decoded strings");
}

eval { warn $plain } and pass("$plain is a plain");

done_testing;
