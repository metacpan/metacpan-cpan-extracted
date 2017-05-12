use strict;
use warnings;

use Test::More;

use fork::hook;

my $a = bless {}, 'TEST';

my $parent_pid = $$;

unless(fork){
	Test::More::done_testing(4);
}

package TEST;
use Test::More;

sub AFTER_FORK {
	isnt($parent_pid, $$, 'AFTER_FORK called in child process');
	is($_[0], undef,'AFTER_FORK, first element is undefined ref');
}

sub AFTER_FORK_OBJ {
	my $self = $_[0];
	isnt($parent_pid, $$, 'AFTER_FORK_OBJ called in child process');
	is(ref $self, 'TEST','AFTER_FORK_OBJ, first element is blessed ref');
}



#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

