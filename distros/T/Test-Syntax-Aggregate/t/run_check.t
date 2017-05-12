use Test::More;
use Test::Syntax::Aggregate;

plan skip_all => "developer only test" unless $ENV{RUN_DEVEL_TESTS};
plan tests => 1;

check_scripts_syntax( scripts => [ qw(t/scripts/a.pl t/scripts/b.pl t/scripts/c.pl t/scripts/d.pl) ] );
