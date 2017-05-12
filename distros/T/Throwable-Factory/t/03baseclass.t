=head1 PURPOSE

Test that Throwable::Factory::Base can be used.

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
use Throwable::Factory;

try {
	Throwable::Factory::Base->throw('Test');
}
catch {
	my $e = shift;
	BAIL_OUT("not a blessed exception: $e") unless blessed $e;
	
	isa_ok $e, Throwable::Factory::Base;
	is_deeply([$e->FIELDS], ['message']);
	is($e->description, 'Generic exception');
};

done_testing;
