=head1 PURPOSE

This is a slightly modified version of Dave Rolsky's C<< t/ecb-standalone.t >>
from L<Exception::Class>.

It should demonstrate a fair degree of compatibility between
L<Throwable::Factory::Struct> and L<Exception::Class::Base>.

=head1 AUTHOR

Dave Rolsky E<lt>autarch@urth.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Dave Rolsky.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut

use strict;
use warnings;

use Test::More;

{

    package MyE;

    use strict;
    use warnings;

    use Throwable::Factory ();
    use base Throwable::Factory::Base;
}

eval { MyE->throw() };
isa_ok( $@, 'MyE', 'can throw MyE without importing Throwable::Factory' );

#my $caught = MyE->caught();
#is( $@, q{}, 'no exception calling MyE->caught()' );
#ok( $caught, 'caught MyE exception' );

done_testing();
