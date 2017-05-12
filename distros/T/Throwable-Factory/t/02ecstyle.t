=head1 PURPOSE

Exception::Class-like hashref factory.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Try::Tiny;
use Scalar::Util 'blessed';
use Throwable::Factory
	Except1 => [qw< $foo $bar >],
	Except2 => {
		isa         => 'Except1',
		fields      => [ 'baz' ],
		description => 'Extended version of Except1',
	},
	Except3 => {
		isa         => 'Except2',
		fields      => 'bam',
		description => 'Extended version of Except2',
	},
;

# Throws for unsupported Exception::Class-style options.
try {
	Throwable::Factory->import(Except3 => { huh => 123 });
}
catch {
	like $_[0], qr{^Exception::Class-style huh option not supported};
};

is_deeply(
	[ Except2->FIELDS ],
	[ qw< message foo bar baz > ]
);

try {
	Except2->throw('Test');
}
catch {
	my $e = shift;
	BAIL_OUT("not a blessed exception: $e") unless blessed $e;

	isa_ok $e, Except2;
	isa_ok $e, Except1;
	is($e->error, 'Test');
	is($e->description, 'Extended version of Except1');
};

try {
	Except3->throw('Test 3');
}
catch {
	my $e = shift;
	BAIL_OUT("not a blessed exception: $e") unless blessed $e;

	is($e->error, 'Test 3');
	is_deeply([$e->FIELDS], [qw/ message foo bar baz bam /]);
};

done_testing;
