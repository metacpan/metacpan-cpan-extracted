
# `make test'. After `make install' it should work as `perl Thread-Workers.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use threads;
use Test::Simple tests =>16;

use lib '/home/kal/code/Thread-Workers/lib';

use Thread::Workers;

sub boss_cb { sleep 1; 1 };
sub worker_cb { 1 };
sub boss_log_cb { 1 };
sub drain_cb { 1 };

my $pool = Thread::Workers->new(threadinterval=>1, bossinterval=>5);
ok (defined $pool);
ok ($pool->isa('Thread::Workers'));
ok ($pool->set_boss_fetch_cb(\&boss_cb));
ok ($pool->set_worker_work_cb(\&worker_cb));
ok ($pool->set_drain_cb(\&drain_cb));
ok ($pool->start_boss());
ok ($pool->start_workers());
ok ($pool->add_worker());
ok ($pool->pause_workers());
ok ($pool->wake_workers());
ok ($pool->pause_boss());
sleep(1);
ok ($pool->start_boss());
ok ($pool->kill_boss());
ok ($pool->kill_workers());
ok ($pool->dump_queue());
ok ($pool->destroy());
sleep(2);

#########################

