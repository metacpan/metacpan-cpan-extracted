package WWW::OpenSearch::Agent;

use strict;
use warnings;

use base qw( LWP::UserAgent );

use WWW::OpenSearch;
use WWW::OpenSearch::Response;

=head1 NAME

WWW::OpenSearch::Agent - An agent for doing OpenSearch requests

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head2 new( [%options] )

=head1 METHODS

=head2 request( $request | $url, \%params )

=head2 search( )

An alias for request()

=head1 AUTHOR

=over 4

=item * Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2013 by Tatsuhiko Miyagawa and Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

sub new {
    my ( $class, @rest ) = @_;
    return $class->SUPER::new(
        agent => join( '/', __PACKAGE__, $WWW::OpenSearch::VERSION ),
        @rest,
    );
}

*search = \&request;

sub request {
    my $self     = shift;
    my $request  = shift;
    my $response = $self->SUPER::request( $request, @_ );

    # allow regular HTTP::Requests to flow through
    return $response unless $request->isa( 'WWW::OpenSearch::Request' );
    return WWW::OpenSearch::Response->new( $response );
}

1;
