#!/usr/bin/env perl

use v5.14;
use warnings;

use Test::Load::Helper;

use Test::YAFT::Act;

sub build_context {
	Test::YAFT::Act::->new (@_)->context;
}

assume q (act without dependencies)
	=> got    { build_context (q (act)) }
	=> expect =>
		+ expect_listmethods (arguments    => [ ])
		+ expect_listmethods (unresolved   => [ ])
	;

assume q (act with resolved dependencies)
	=> arrange { foo => q (foo-1) }
	=> arrange { bar => q (bar-2) }
	=> got     { build_context (q (act), qw (foo bar)) }
	=> expect  =>
		+ expect_listmethods (arguments    => [q (foo-1), q (bar-2)])
		+ expect_listmethods (unresolved   => [ ])
	;

assume q (act with unresolved dependencies)
	=> arrange { foo => q (foo-1) }
	=> got     { build_context (q (act), qw (foo bar)) }
	=> expect  =>
		+ expect_listmethods (arguments    => [q (foo-1), undef])
		+ expect_listmethods (unresolved   => [q (bar)])
	;

not 1 and
assume q (act with default values)
	=> arrange { foo => q (foo-1) }
	=> got     { build_context (q (act), foo => { default => 1 }, bar => { default => 2 }) }
	=> expect  =>
		+ expect_listmethods (arguments    => [q (foo-1), 2])
		+ expect_listmethods (unresolved   => [ ])
	;

assume q (act with pseudo-named arguments)
	=> arrange { foo => q (foo-1) }
	=> arrange { bar => q (bar-2) }
	=> got     { +{ build_context (q (act), {}, qw (foo bar))->arguments } }
	=> expect  => {
		foo => q (foo-1),
		bar => q (bar-2),
	};

had_no_warnings;
done_testing;
