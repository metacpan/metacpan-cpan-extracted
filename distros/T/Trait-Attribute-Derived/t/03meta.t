=head1 PURPOSE

Test introspection via attribute meta objects.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

{
	package Person;
	use Moose;
	use Trait::Attribute::Derived Split => {
		source    => 'full_name',
		fields    => { segment => 'Num' },
		processor => sub { (split)[$_{segment}] },
	};
	has full_name  => (is => 'ro', isa => 'Str');
	has first_name => (traits => [Split], segment => +0);
	has initial    => (traits => [Split], segment => +0, postprocessor => sub { substr $_, 0, 1 });
	has last_name  => (traits => [Split], segment => -1);
}

my @A = qw/ first_name initial last_name /;
my %A = map { ;$_ => Person->meta->get_attribute($_) } @A;

ok(
	$A{$_}->derived_from,
	'full_name'
) for @A;

is(
	ref $A{$_}->derived_attribute_builder,
	'CODE'
) for @A;

is($A{first_name}->segment, 0);
is($A{initial}->segment, 0);
is($A{last_name}->segment, -1);

ok(not $A{first_name}->has_postprocessor);
ok($A{initial}->has_postprocessor);
ok(not $A{last_name}->has_postprocessor);

done_testing;

