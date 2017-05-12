use strict;
use warnings;

use Test::More;
use Unicorn::Manager::CLI::Proc;

my $u_p_table = Unicorn::Manager::CLI::Proc::Table->new;

isa_ok $u_p_table, 'Unicorn::Manager::CLI::Proc::Table';

done_testing;
