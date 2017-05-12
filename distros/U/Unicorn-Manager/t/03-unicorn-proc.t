use strict;
use warnings;

use Test::More tests => 1;
use Unicorn::Manager::CLI::Proc;

my $uni_proc = Unicorn::Manager::CLI::Proc->new;

isa_ok $uni_proc, 'Unicorn::Manager::CLI::Proc';

