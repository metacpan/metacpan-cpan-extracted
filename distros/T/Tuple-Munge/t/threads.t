use warnings;
use strict;

BEGIN {
	eval { require threads; };
	if($@ =~ /\AThis Perl not built to support threads/) {
		require Test::More;
		Test::More::plan(skip_all => "non-threading perl build");
	}
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "threads unavailable");
	}
	eval { require Thread::Semaphore; };
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "Thread::Semaphore unavailable");
	}
	eval { require threads::shared; };
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "threads::shared unavailable");
	}
}

use threads;

use Test::More tests => 6;
use Thread::Semaphore ();
use threads::shared;

alarm 10;   # failure mode may involve an infinite loop

my(@exit_sems, @threads);

sub test_in_thread($) {
	my($test_code) = @_;
	my $done_sem = Thread::Semaphore->new(0);
	my $exit_sem = Thread::Semaphore->new(0);
	push @exit_sems, $exit_sem;
	my $ok :shared;
	push @threads, threads->create(sub {
		$ok = !!$test_code->();
		$done_sem->up;
		$exit_sem->down;
	});
	$done_sem->down;
	ok $ok;
}

sub basic_test {
	our @values = ();
	eval q{
		use Tuple::Munge qw(variable_tuple tuple_slot);
		my $t = variable_tuple(\3, \%::s0);
		push @values, ref(\$t), ref($t);
		push @values, (tuple_slot($t, 1) == \%::s0 ? 1 : 0);
	} or die $@;
	return join(",", @values) eq "REF,OBJECT,1";
}

test_in_thread(\&basic_test) foreach 0..1;
ok basic_test();
test_in_thread(\&basic_test);

our $tt0;
eval q{
	use Tuple::Munge qw(variable_tuple);
	$tt0 = variable_tuple(\3, \@::s0);
} or die $@;
test_in_thread(sub {
	our @values = ();
	eval q{
		use Tuple::Munge qw(tuple_slot);
		push @values, ref(\$tt0), ref($tt0);
		push @values, ${tuple_slot($tt0, 0)};
		push @values, (tuple_slot($tt0, 1) == \@::s0 ? 1 : 0);
	} or die $@;
	return join(",", @values) eq "REF,OBJECT,3,1";
});

$_->up foreach @exit_sems;
$_->join foreach @threads;
ok 1;

1;
