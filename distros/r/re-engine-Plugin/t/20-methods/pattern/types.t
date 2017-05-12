use strict;
use Test::More tests => 7;
use re::engine::Plugin (
    exec => sub {
        my ($re, $str) = @_;
        my $pattern = $re->pattern;

        isa_ok($pattern, $str);
    },
);

my $sv;
"SCALAR" =~ \$sv;
"REF"    =~ \\$sv;
"ARRAY"  =~ [];
"HASH"   =~ {};
"GLOB"   =~ \*STDIN;
"CODE"   =~ sub {};
"main"   =~ bless {} => "main";
