=pod

=encoding utf-8

=head1 PURPOSE

Test that match::simple works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

use match::simple;

diag(sprintf('implementation: %s', match::simple::IMPLEMENTATION));

my $obj = do {
	package Local::SomeClass;
	use overload q[""] => sub { q(XXX) }, fallback => 1;
	bless [];
};

sub does_match {
	my ($a, $b, $name) = @_;
	my ($as, $bs) = map do {
		no if ($] >= 5.010001), 'overloading';
		ref($_) ? qq[$_] : defined($_) ? qq["$_"] : q[undef];
	}, @_;
	$name ||= "$as matches $bs";
	ok(
		$a |M| $b,
		$name,
	);
}

sub doesnt_match {
	my ($a, $b, $name) = @_;
	my ($as, $bs) = map do {
		no if ($] >= 5.010001), 'overloading';
		ref($_) ? qq[$_] : defined($_) ? qq["$_"] : q[undef];
	}, @_;
	$name ||= "$as NOT matches $bs";
	ok(
		!($a |M| $b),
		$name,
	);
}

# If the right hand side is "undef", then there is only a match if
# the left hand side is also "undef".
does_match(undef, undef);
doesnt_match($_, undef)
	for 0, 1, q(), q(XXX), [], {}, sub {}, $obj;

# If the right hand side is a non-reference, then the match is a
# simple string match.
does_match(q(xxx), q(xxx));
doesnt_match($_, q(xxx))
	for 0, 1, q(), q(XXX), [], {}, sub {}, $obj;

# If the right hand side is a reference to a regexp, then the left
# hand is evaluated.
does_match(q(xxx), qr(xxx), 'q(xxx) |M| qr(xxx)');
does_match(q(wwwxxxyyyzzz), qr(xxx), 'q(wwwxxxyyyzzz) |M| qr(xxx)');
doesnt_match($_, qr(xxx))
	for 0, 1, q(), q(XXX), [], {}, sub {}, $obj;
doesnt_match(qr(xxx), q(xxx));

# If the right hand side is a code reference, then it is called in a
# boolean context with the left hand side being passed as an
# argument.
does_match(1, sub {$_});
doesnt_match(0, sub {$_});
does_match(1, sub {$_[0]});
doesnt_match(0, sub {$_[0]});
does_match(1, sub {1});
does_match(0, sub {1});

# If the right hand side is an object which provides a "MATCH"
# method, then it this is called as a method, with the left hand side
# being passed as an argument.
my $obj2 = do {
	package Local::SomeOtherClass;
	sub MATCH { $_[1] }
	bless [];
};
does_match(1, $obj2);
doesnt_match(0, $obj2);

# If the right hand side is an object which overloads "~~", then a
# true smart match is performed.
if ($] >= 5.010001 and $] < 5.020000)
{
	my $obj3 = eval q{
		no warnings;
		package Local::YetAnotherClass;
		use overload q[~~] => sub { $_[1] };
		bless [];
	};
	does_match(1, $obj3);
	doesnt_match(0, $obj3);
}

# If the right hand side is an arrayref, then the operator recurses
# into the array, with the match succeeding if the left hand side
# matches any array element.
does_match(q(x), [qw(x y z)], 'q(x) |M| [qw(x y z)]');

# If any other value appears on the right hand side, the operator
# will croak.
ok(
	exception { "Foo" |M| { foo => 1 } },
	q(Matching against a regexp throws an exception.),
);
ok(
	exception { "Foo" |M| \*STDOUT },
	q(Matching against a filehandle throws an exception.),
);

done_testing;

