use Test::More;
use re::engine::Oniguruma;

my @t = (
    {
        in  => qr/aoeu/,
        out => '(?-xism:aoeu)',
    },
    {
        in  => qr/aoeu/m,
        out => '(?m-xis:aoeu)',
    },
    {
        in  => qr/aoeu/mx,
        out => '(?xm-is:aoeu)',
    },
    {
        in  => qr/aoeu/mxi,
        out => '(?xim-s:aoeu)',
    },
    {
        in  => qr/aoeu/mxis,
        out => '(?xism:aoeu)',
    },
);

plan tests => @t * 2;

for my $test (@t) {
    my $re = $test->{in};
    my $rep = $test->{out};
    isa_ok $re, 're::engine::Oniguruma';
    is "$re", $rep, $rep;
}
