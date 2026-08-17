#!/usr/bin/env perl

use v5.14;
use warnings;

use Test::Load::Helper;

assume_test_yaft_exports act
	=> by_default => 1
	=> on_demand  => 1
	=> by_tag     => [qw [all default utils helpers]]
	;

subtest q (act {} block can specify implicit got value builder) => sub {
	my $iterator = [ 42 ];

	act { push @$iterator, $iterator->[-1] + 1; $iterator->[-1] };

	assume q (assumption doesn't execute act {} block when got is specified)
		=> got    => $iterator
		=> expect => [ 42 ]
		;

	assume q (act {} block is used to build got value)
		=> expect => 43
		;

	assume q (act {} has side effects)
		=> got    => $iterator
		=> expect => [ 42, 43 ]
		;
};

subtest q (act {} block is used as default builder of tested value) => sub {
	act { [ @_ ] } qw [foo bar];

	arrange { foo => q (foo-1) };
	arrange { bar => q (bar-1) };

	assume q (act {} is used when got is not provided)
		=> expect => [ q (foo-1), q (bar-1) ]
		;

	assume q (act {} uses arranged properties from execution context)
		=> with_foo => q (another-foo)
		=> expect   => [ q (another-foo), q (bar-1) ]
		;

	subtest q (arranged values can be overridden in sub-context) => sub {
		arrange { foo => q (subtest-foo) };
		arrange { bar => q (subtest-bar) };

		assume q (sub-context uses parent's act {} when not redefined)
			=> expect => [ q (subtest-foo), q (subtest-bar) ]
			;
	};
};

subtest q (act {} is called for each test) => sub {
	my $cache = [ ];

	act { push @$cache, @_; $cache->[-1]; } q (increment);

	arrange { increment => 42 };

	assume q (act {} is not executed when got is provided)
		=> got    => $cache
		=> expect => [ ]
		;

	assume q (act {} uses property arranged in current context)
		=> expect => 42
		;

	assume q (act {} uses property provided to assumption)
		=> with_increment => 99
		=> expect         => 99
		;

	assume q (act {} should have been called twice)
		=> got    => $cache
		=> expect => [ 42, 99 ]
		;
};

subtest q (act {} with unresolved dependencies) => sub {
	act { [ @_ ] } qw [foo2 bar2 aaa2];

	arrange { foo2 => q (foo-2) };

	it q (should throw exception when there are missing dependencies)
		=> throws => q (Act dependencies not fulfilled: aaa2, bar2)
		;
};

subtest q (act {} throwing exception) => sub {
	act { die q (Exception foo) };

	it q (should catch exception thrown by act {} block)
		=> throws => expect_re (qr (^Exception foo at))
		;
};

subtest q (act {} is not called when got is provided) => sub {
	act { die q (foo) };

	it q (should not execute act {} when got is provided)
		=> got    { 1 }
		=> expect => 1
		;
};

frame {
	act { 1 }
		q (host),
		q (path),
		;

	arrange { host => q (example.com) };

	assume q (throws an exception when dependencies are not resolved)
		=> throws => q (Act dependencies not fulfilled: path)
		;
};

subtest q (only single `act {}` per context) => sub {
	# following tests cannot standard Test::YAFT style because every
	# assumption creates its own subcontext, there `do block`

	assume q (`act {}` can be defined in current context)
		=> got    => do { eval { act { q (parent-context-act) } }; $@ }
		=> expect => expect_false
		;

	assume q (`act {}` is installed)
		=> expect => q (parent-context-act)
		;

	assume q (`act {}` in current context cannot be redefined)
		=> got    => do { eval { act { } }; $@ }
		=> expect => expect_re (qr (Act already known in current context))
		;

	assume q (`act {}` is still available)
		=> expect => q (parent-context-act)
		;

	subtest q (in subcontext one can define new act) => sub {
		assume q (`act {}` can be defined in current context)
			=> got    => do { eval { act { q (subcontext-act) } }; $@ }
			=> expect => expect_false
			;

		assume q (`act {}` is installed)
			=> expect => q (subcontext-act)
		;
	};

	subtest q (in subcontext one can use act from parent context) => sub {
		assume q (`act {}` is inherited)
			=> expect => q (parent-context-act)
			;
	};
};

had_no_warnings;
done_testing;
