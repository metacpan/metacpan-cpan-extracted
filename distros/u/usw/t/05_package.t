use Test::More 0.98 tests => 4;
use Encode qw(is_utf8 encode_utf8 decode_utf8);
use version;

my @qr = (
    qr/^Global symbol "\$inner" requires explicit package name/,
    qr/^(?:Variable "\$inner" is not imported|Argument "2:" isn't numeric in addition \(\+\))/,
);
local $SIG{__WARN__} = sub {
    return if $_[0] =~ $qr[0];
    $_[0] =~ /^Variable/
        ? like $_[0], $qr[1], 'warnings pragma DOES work now'
        : die $_[0];
};

subtest 'Before package' => \&::test4off;

SKIP: {
    skip "elder Perl version", 1 if version->parse($]) lt '5.014.000';
    eval <<'EOL' or fail("fail to evaluate");
package Inner {    # syntax error in 5.12.5 or elder
    ::subtest 'Inner package' => \&::inner;
}
EOL
}

package Outer;
use Test::More 0.98;
use Encode qw(is_utf8 encode_utf8 decode_utf8);
use usw;    # turn it on

subtest 'Inner package' => \&::inner;
subtest 'After package' => \&::test4off;

done_testing;

sub ::inner {
    plan tests => 4;

    my $outer = eval q( $inner = 'strings'; );    # with no `my`
    like $@, $qr[0], "Successfully detected a declaration missing `my`";

    eval { my $a = "2:" + 3; } or pass("Successfully die");    # isn't numeric

    my $plain   = '宣言あり';
    my $encoded = encode_utf8($plain);
    is is_utf8($plain), 1, "$encoded is DECODED automatically";
}

sub ::test4off {
    plan tests => 3;
    no strict;    # Of course it defaults no, but declare it explicitly
    no warnings;
    no utf8;

    eval q( $inner = 'strings'; );    # missing to declare with `my`
    is $@, '', "Successfully ignored a declaration without `my`";

    local $SIG{__WARN__} = sub {
        like $_[0], qr/^\QArgument "2:" isn't numeric in addition (+)/,
            , 'warnings pragma DOES work now';
    };

    eval { my $a = "2:" + 3; };       # isn't numeric

    is $@, '', 'warnings pragma does NOT work yet';

    my $plain = '宣言なし';
    is is_utf8($plain), '', "$plain is NOT decoded yet";
}
