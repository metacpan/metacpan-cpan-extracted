=head1 PURPOSE

Check that Web::ID compiles.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More;

#eval { require Moose; require MooseX::Types::Moose; 1 }
#	or plan skip_all => "need Moose";

plan tests => 1;
use_ok('Web::ID');

