use Test::More 0.98 tests => 6;
use Encode qw(is_utf8 encode_utf8 decode_utf8);

no utf8;    # Of course it defaults no, but declare it explicitly
use strict;
use warnings;

my $keep = $SIG{__WARN__};
local $SIG{__WARN__} = sub { die &$keep };

my $plain = '宣言なし';
eval { warn $plain } or pass("$plain is a plain");
pass encode_utf8 $@ if $@;
{
    use usw;    # turn it on
    my $keep = $SIG{__WARN__};
    local $SIG{__WARN__} = sub { die &$keep };
    my $decoded = '宣言あり';
    eval { warn $decoded } or pass("pass to warn with decoded text");
    pass encode_utf8 $@ if $@;
}

eval { warn $plain } or pass("$plain is a plain");
pass encode_utf8 $@ if $@;

done_testing;
