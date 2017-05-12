=head1 PURPOSE

This is a slightly modified version of Dave Rolsky's C<< t/context.t >>
from L<Exception::Class>.

It should demonstrate a fair degree of compatibility between
L<Throwable::Factory> and L<Exception::Class>.

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

use Throwable::Factory (
    'Foo',
    'Bar' => { isa => 'Foo' },
);

#Bar->NoContextInfo(1);

{
    eval { Foo->throw( message => 'foo' ) };

    my $e = $@;

    ok( defined( $e->stack_trace ), 'has trace detail' );
}

#{
#    eval { Bar->throw( error => 'foo' ) };
#
#    my $e = $@;
#
#    ok( !defined( $e->trace ), 'has no trace detail' );
#}

done_testing();
