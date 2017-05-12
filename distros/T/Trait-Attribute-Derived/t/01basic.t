=head1 PURPOSE

Check basic usage of the module.

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

my $bob = Person->new(full_name => 'Robert Redford');
is($bob->first_name, 'Robert');
is($bob->initial, 'R');
is($bob->last_name, 'Redford');
done_testing;

