package WG::API::Base;

use Modern::Perl '2015';
use Moo::Role;

use WG::API::Error;
use HTTP::Tiny;
use JSON;
use Data::Dumper;
use Log::Any qw($log);
use URI;
use URI::QueryParam;

=encoding utf8

=head1 VERSION

Version v0.13

=cut

our $VERSION = 'v0.13';

=head1 SYNOPSIS

Base class for all instances

=cut

requires '_api_uri';

=head1 ATTRIBUTES

=over 1

=item I<application_id*>

Required application id: L<https://developers.wargaming.net/documentation/guide/getting-started/>

=cut

has application_id => (
    is      => 'ro',
    require => 1,
);

=item I<language>

=cut

has language => (
    is      => 'ro',
    default => sub {'ru'},
);

=item I<status>

Return request status

=cut

has status => ( is => 'rw', );

=item I<response>

Return response

=cut

has response => ( is => 'rw', );

=item I<meta_data>

Return meta data from response

=cut

has meta_data => ( is => 'rw', );

=item I<debug>

Get current debug mode

=back

=cut

has debug => (
    is      => 'rw',
    writer  => 'set_debug',
    default => '0',
);

=head1 METHODS

=over 1

=item B<ua>

Returns a user agent instance

=cut

#@returns HTTP::Tiny
has ua => (
    is      => 'ro',
    default => sub {
        require HTTP::Tiny;
        require IO::Socket::SSL;
        HTTP::Tiny->new;
    },
);

=item B<error>

Returns a WG::API::Error instance if defined;

=cut

#@returns WG::API::Error
has error => ( is => 'rw', );

=item B<set_debug>

Set debug mode

=over 1

=item B<log>

Logger

=back

=back

=cut

sub log {
    my ( $self, $event ) = @_;

    return unless $self->debug;

    $log->debug($event);
}

sub _request {
    my ( $self, $method, $uri, $params, $required_params, %passed_params ) = @_;

    $self->status(undef);

    unless ( $self->_validate_params( $required_params, %passed_params ) ) {    #check required params
        $self->status('error');
        $self->error(
            WG::API::Error->new(
                code    => '997',
                message => 'missing a required field',
                field   => 'xxx',
                value   => 'xxx',
                raw     => 'xxx',
            )
        );
        return;
    }

    $method = "_" . $method;    # add prefix for private methods

    $self->$method( $uri, $params, %passed_params );

    return $self->status eq 'ok' ? $self->response : undef;
}

sub _validate_params {
    my ( undef, $required_params, %passed_params ) = @_;

    $required_params //= [];
    return if @$required_params > keys %passed_params;

    for (@$required_params) {
        return unless defined $passed_params{$_};
    }

    return 'passed';
}

sub _get {
    my ( $self, $uri, $params, %passed_params ) = @_;

    #@type HTTP::Response
    my $response = $self->_raw_get( $self->_build_url($uri) . $self->_build_get_params( $params, %passed_params ) );

    return $self->_parse( $response->{'status'} eq '200' ? decode_json $response->{'content'} : undef );
}

sub _post {
    my ( $self, $uri, $params, %passed_params ) = @_;

    #@type HTTP::Response
    my $response = $self->_raw_post( $self->_build_url($uri), $self->_build_post_params( $params, %passed_params ) );

    return $self->_parse( $response->{'status'} eq '200' ? decode_json $response->{'content'} : undef );
}

sub _parse {
    my ( $self, $response ) = @_;

    if ( !$response ) {
        $response = {
            status => 'error',
            error  => {
                code    => '999',
                message => 'invalid api_uri',
                field   => 'xxx',
                value   => 'xxx',
                raw     => Dumper $response,
            },
        };
    }
    elsif ( !$response->{'status'} ) {
        $response = {
            status => 'error',
            error  => {
                code    => '998',
                message => 'unknown status',
                field   => 'xxx',
                value   => 'xxx',
                raw     => Dumper $response,
            },
        };
    }

    $self->status( delete $response->{'status'} );

    if ( $self->status eq 'error' ) {
        $self->error( WG::API::Error->new( $response->{'error'} ) );
    }
    else {
        $self->error(undef);
        $self->meta_data( $response->{'meta'} );
        $self->response( $response->{'data'} );
    }

    $self->log( $self->error );

    return;
}

#@returns URI;
sub _build_url {
    my ( $self, $uri ) = @_;

    my $url = URI->new( $self->_api_uri );
    $url->scheme("https");
    $url->path($uri);

    return $url->as_string;
}

sub _build_get_params {
    my ( $self, $params, %passed_params ) = @_;

    my $url = URI->new( "", "https" );
    $url->query_param( application_id => $self->application_id );
    foreach my $param (@$params) {
        $passed_params{$param} = $self->language if $param eq 'language' && !exists $passed_params{$param};
        $url->query_param( $param => $passed_params{$param} ) if defined $passed_params{$param};
    }

    return $url->as_string;
}

sub _build_post_params {
    my ( $self, $params, %passed_params ) = @_;

    my %params;
    @params{ keys %passed_params } = ();
    delete @params{@$params};
    delete $passed_params{$_} for keys %params;

    $passed_params{'application_id'} = $self->application_id;
    $passed_params{'language'} = $self->language unless exists $passed_params{'language'};

    return \%passed_params;
}

sub _raw_get {
    my ( $self, $url ) = @_;

    $self->log( sprintf "METHOD GET, URL: %s\n", $url );

    return $self->ua->get($url);
}

sub _raw_post {
    my ( $self, $url, $params ) = @_;

    $self->log( sprintf "METHOD POST, URL %s, %s\n", $url, Dumper $params );

    return $self->ua->post_form( $url, $params );
}

=head1 BUGS

Please report any bugs or feature requests to C<cynovg at cpan.org>, or through the web interface at L<https://gitlab.com/cynovg/WG-API/issues>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WG::API

You can also look for information at:

=over 4

=item * RT: Gitlab's request tracker (report bugs here)

L<https://gitlab.com/cynovg/WG-API/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WG-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WG-API>

=item * Search CPAN

L<https://metacpan.org/pod/WG::API>

=back


=head1 ACKNOWLEDGEMENTS

...

=head1 SEE ALSO

WG API Reference L<https://developers.wargaming.net/>

=head1 AUTHOR

Cyrill Novgorodcev , C<< <cynovg at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Cyrill Novgorodcev.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of WG::API::Base
