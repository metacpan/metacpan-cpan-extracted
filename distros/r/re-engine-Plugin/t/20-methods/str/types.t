use strict;
use Test::More tests => 7;
use re::engine::Plugin (
    exec => sub {
        my ($re, $str) = @_;

        isa_ok($str, $re->pattern);

        return 1;
    },
);

my $sv;
\$sv    =~ "SCALAR";
\\$sv   =~ "REF";
[]      =~ "ARRAY";
{}      =~ "HASH";
\*STDIN =~ "GLOB";
sub {}  =~ "CODE";
bless({} => "main") =~ "main"
