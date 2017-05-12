=pod

=encoding utf-8

=head1 PURPOSE

Test that Types::Interface works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::TypeTiny;

use lib qw( t/lib lib );

use Local::DirectImpl;
use Local::IndirectImpl;
use Local::Liar;
use Local::NonImpl;
use Local::PublicImpl;

BEGIN {
	if ($] < 5.010000) {
		require UNIVERSAL::DOES;
	}
};

use Types::Interface -types;

my $class    = ClassDoesInterface['Local::Role'];
my $class_p  = ClassDoesInterface['Local::Role', private => 0];
my $object   = ObjectDoesInterface['Local::Role'];
my $object_p = ObjectDoesInterface['Local::Role', private => 0];

should_pass('Local::DirectImpl', $class);
should_pass('Local::IndirectImpl', $class);
should_pass('Local::Liar', $class);
should_fail('Local::NonImpl', $class);
should_fail('Local::PublicImpl', $class);
should_fail('Local::DirectImpl'->new, $class);
should_fail('Local::IndirectImpl'->new, $class);
should_fail('Local::Liar'->new, $class);
should_fail('Local::NonImpl'->new, $class);
should_fail('Local::PublicImpl'->new, $class);

should_pass('Local::DirectImpl', $class_p);
should_pass('Local::IndirectImpl', $class_p);
should_pass('Local::Liar', $class_p);
should_fail('Local::NonImpl', $class_p);
should_pass('Local::PublicImpl', $class_p);
should_fail('Local::DirectImpl'->new, $class_p);
should_fail('Local::IndirectImpl'->new, $class_p);
should_fail('Local::Liar'->new, $class_p);
should_fail('Local::NonImpl'->new, $class_p);
should_fail('Local::PublicImpl'->new, $class_p);

should_fail('Local::DirectImpl', $object);
should_fail('Local::IndirectImpl', $object);
should_fail('Local::Liar', $object);
should_fail('Local::NonImpl', $object);
should_fail('Local::PublicImpl', $object);
should_pass('Local::DirectImpl'->new, $object);
should_pass('Local::IndirectImpl'->new, $object);
should_pass('Local::Liar'->new, $object);
should_fail('Local::NonImpl'->new, $object);
should_fail('Local::PublicImpl'->new, $object);

should_fail('Local::DirectImpl', $object_p);
should_fail('Local::IndirectImpl', $object_p);
should_fail('Local::Liar', $object_p);
should_fail('Local::NonImpl', $object_p);
should_fail('Local::PublicImpl', $object_p);
should_pass('Local::DirectImpl'->new, $object_p);
should_pass('Local::IndirectImpl'->new, $object_p);
should_pass('Local::Liar'->new, $object_p);
should_fail('Local::NonImpl'->new, $object_p);
should_pass('Local::PublicImpl'->new, $object_p);

done_testing;
