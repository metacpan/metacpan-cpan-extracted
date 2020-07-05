package cPanel::APIClient::Pending;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

cPanel::APIClient::Pending

=head1 DESCRIPTION

This class encapsulates a pending API request.

=cut

#----------------------------------------------------------------------

use Call::Context ();

#----------------------------------------------------------------------

# Left undocumented since instantiation is internal-only.
sub new {
    my ( $class, $promise, @details ) = @_;

    return bless [ $promise, @details ], $class;
}

# This also is not (yet?) meant for public consumption.
sub get_details {
    Call::Context::must_be_list();

    return @{ $_[0] }[ 1 .. $#{ $_[0] } ];
}

=head1 METHODS

This class is not documented for public instantiation.
Functionality that pertains to callers’ interest is documented below:

=head2 $promise = I<OBJ>->promise()

Returns a promise object (whose specific class is determined by the
chosen transport mechanism) that will resolve or reject according to
whether the API request succeeds or fails.

=cut

sub promise {
    return $_[0][0];
}

=head1 LICENSE

Copyright 2020 cPanel, L. L. C. All rights reserved. L<http://cpanel.net>

This is free software; you can redistribute it and/or modify it under the
same terms as Perl itself. See L<perlartistic>.

=cut

1;
