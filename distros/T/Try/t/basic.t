#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Try;

sub _eval {
	local $@;
	local $Test::Builder::Level = $Test::Builder::Level + 2;
	return ( scalar(eval { $_[0]->(); 1 }), $@ );
}


sub lives_ok (&$) {
	my ( $code, $desc ) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;

	my ( $ok, $error ) = _eval($code);

	ok($ok, $desc );

	diag "error: $@" unless $ok;
}

sub throws_ok (&$$) {
	my ( $code, $regex, $desc ) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;

	my ( $ok, $error ) = _eval($code);

	if ( $ok ) {
		fail($desc);
	} else {
		like($error || '', $regex, $desc );
	}
}


my $prev;

lives_ok {
	try {
		die "foo";
	}
        pass("syntax ok");
} "basic try";

throws_ok {
	try {
		die "foo";
	} catch { die $_ }
        pass("syntax ok");
} qr/foo/, "rethrow";

lives_ok {
	try {
		die "foo";
	} catch {
		my $err = shift;

		try {
			like $err, qr/foo/;
		} catch {
			fail("shouldn't happen");
		}

		pass "got here";
	}
        pass("syntax ok");
} "try in try catch block";

throws_ok {
	try {
		die "foo";
	} catch {
		my $err = shift;

		try { } catch { }
                pass("syntax ok");

		die "rethrowing $err";
	}
        pass("syntax ok");
} qr/rethrowing foo/, "rethrow with try in catch block";


sub Evil::DESTROY {
	eval { "oh noes" };
}

sub Evil::new { bless { }, $_[0] }

{
	local $@ = "magic";
	local $_ = "other magic";

	try {
		my $object = Evil->new;
		die "foo";
	} catch {
		pass("catch invoked");
		like($_, qr/foo/);
	}
        pass("syntax ok");

	is( $@, "magic", '$@ untouched' );
	is( $_, "other magic", '$_ untouched' );
}

{
	my ( $caught, $prev );

	{
		local $@;

		eval { die "bar\n" };

		is( $@, "bar\n", 'previous value of $@' );

		try {
			die {
				prev => $@,
			}
		} catch {
			$caught = $_;
			$prev = $@;
		}
                pass("syntax ok");
	}

	is_deeply( $caught, { prev => "bar\n" }, 'previous value of $@ available for capture' );
	is( $prev, "bar\n", 'previous value of $@ also available in catch block' );
}

done_testing;
