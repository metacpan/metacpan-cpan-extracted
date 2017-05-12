package WebService::Lucene::Client;

use strict;
use warnings;

use base qw( XML::Atom::Client );

use WebService::Lucene::Exception;

=head1 NAME

WebService::Lucene::Client - XML::Atom::Client subclass

=head1 DESCRIPTION

This is a simple L<XML::Atom::Client> subclass with some extra logic
to throw exceptions on failure.

=head1 METHODS

=head2 make_request( @options )

overloaded method to throw a L<WebService::Lucene::Exception> on failure.

=cut

sub make_request {
    my ( $self, @rest ) = @_;
    my $response = $self->SUPER::make_request( @rest );

    if ( !$response->is_success ) {
        WebService::Lucene::Exception->throw( $response );
    }

    return $response;
}

=head1 AUTHORS

=over 4

=item * Brian Cassidy E<lt>brian.cassidy@nald.caE<gt>

=item * Adam Paynter E<lt>adam.paynter@nald.caE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2009 National Adult Literacy Database

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
