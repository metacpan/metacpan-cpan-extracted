# BEGIN { $Pegex::Parser::Debug = 1 }
# use Test::Differences; *is = \&eq_or_diff;
use Test::More;
use strict;

BEGIN {
    if (not eval "require YAML::XS") {
        plan skip_all => "requires YAML::XS";
    }
    plan tests => 1;
}

use TestML;
use TestML::Compiler::Pegex;
use TestML::Compiler::Lite;
use YAML::XS;

my $testml = '
# A comment
%TestML 0.1.0

Plan = 2;
Title = "O HAI TEST";

*input.uppercase == *output;

=== Test mixed case string
--- input: I Like Pie
--- output: I LIKE PIE

=== Test lower case string
--- input: i love lucy
--- output: I LOVE LUCY
';

my $func = TestML::Compiler::Pegex->new->compile($testml);
my $func_lite = TestML::Compiler::Lite->new->compile($testml);

is Dump($func_lite), Dump($func),
    'Lite compile matches normal compile';
