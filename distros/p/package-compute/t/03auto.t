=head1 PURPOSE

Check the C<< -filename >> import option works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More;
use File::Basename qw(dirname);
use strict;
use warnings;

use lib dirname($0);

use_ok('My::Package');

no warnings 'once';
is($My::Package::Foo, 'Done.', "Can read variable");
is($My::Package::Funky::Monkey, 'Done.', "Can read variable");

done_testing();
