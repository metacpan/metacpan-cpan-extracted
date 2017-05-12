#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 19;
use Test::MockObject;
use Test::Exception;

use POE;

# TODO
# stringification

my $m; BEGIN { use_ok($m = "Verby::Step::Closure", "step") };


POE::Session->create(
	inline_states => {
		_start => sub {
			my $t = Test::MockObject->new;

			isa_ok((my $s = step $t, sub { }, sub { }), $m);

			$t->set_false("verify");
			ok(!$s->is_satisfied, "step not satisfied");
			$t->called_ok("verify");

			$t->clear;

			$t->set_true("verify");
			ok($s->is_satisfied, "step satisfied");

			$t->clear;

			$t->mock("do");
			$s->do;
			$t->called_ok("do");
		},
	},
);

$poe_kernel->run;

{
	dies_ok {
		step "BlahBlah::Action::Class::That::Does'nt::Exist";
	} "action class with require error is fatal";
}

{
	my $t = Test::MockObject->new;
	$t->set_true("do");

	my ($before, $after) = ( 0, 0 );
	my $s = step $t, sub { $before++ }, sub { $after++ };

	is( $before, 0, "before hook" );
	is( $after,  0, "after hook" );

	POE::Session->create(
		inline_states => {
			_start => sub {
				is( $before, 0, "before hook" );
				$s->do();
				is( $before, 1, "before hook" );
				is( $after,  0, "after hook" );
			},
			_stop  => sub {
				is( $before, 1, "before hook" );
				is( $after,  0, "after hook" );
				$_->() for @{ $_[HEAP]{post_hooks} };
				is( $after,  1, "after hook" );
			},
		},
		heap => { post_hooks => [] },
	);

	$poe_kernel->run;
}

{
	# autoplural accessors and stuff
	my $t = Test::MockObject->new;
	my $s1 = step $t;
	my $s2 = step $t;
	my $s3 = step $t;

	is_deeply([ $s1->depends ], [ ], "no deps yet");
	$s1->add_deps($s2);
	is_deeply([ $s1->depends ], [ $s2 ], "dep appended");
	$s1->add_deps($s3);
	is_deeply([ $s1->depends ], [ $s2, $s3 ], "dep appended");
	$s1->depends([ $s2 ]);
	is_deeply([ $s1->depends ], [ $s2 ], "dep replaced");
}
