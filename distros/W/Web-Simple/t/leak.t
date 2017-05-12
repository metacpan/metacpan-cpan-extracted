use strictures;
use Test::More 0.88;

plan skip_all => 'No Devel::Cycle' unless eval { require Devel::Cycle; 1 };

use Web::Simple;

my $counter;
my $on_cycle = sub { Devel::Cycle::_do_report( ++$counter, shift ) };
{
    local *STDOUT = *STDERR;
    Devel::Cycle::find_cycle( main->new->to_psgi_app, $on_cycle );
}
ok !$counter, "no leak in to_psgi_app";

done_testing;
