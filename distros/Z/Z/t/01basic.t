=pod

=encoding utf-8

=head1 PURPOSE

Test that Z works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

use Z -compat;

my $app = app sub {
	class 'Thing';
};

my $thing = $app->new_thing;

ok is_Object $thing;

done_testing;

