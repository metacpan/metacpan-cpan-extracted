package WG::API;

use 5.014;
use Moo;
use WG::API::Error;
use LWP;
use JSON;
use Data::Dumper;

=encoding utf8

=head1 NAME

WG::API - Module for work with Wargaming.net Public API

=head1 VERSION

Version v0.8.1

=cut

our $VERSION = 'v0.8.1';

=head1 SYNOPSIS

Wargaming.net Public API is a set of API methods that provide access to Wargaming.net content, including in-game and game-related content, as well as player statistics.

This module provide access to WG Public API

    use WG::API::NET;

    my $wg = WG::API::NET->new( application_id => 'demo' );
    ...
    my $player = $wg->account_info( account_id => '1' );

=head1 ATTRIBUTES

=over 1

=item I<application_id*>

Rerquired application id: http://ru.wargaming.net/developers/documentation/guide/getting-started/

=back

=cut 

has application_id => (
    is  => 'ro',
    require => 1,
);

=over 1

=item I<ua>

User agent, default - LWP::UserAgent.

=back

=cut 

has ua => ( 
    is  => 'ro',
    default => sub{ LWP::UserAgent->new() },
);

=over 1

=item I<language>

Localization language. Default - 'ru', Valid values:

=over 4

=item "en" — English

=item "ru" — Русский (by default)

=item "pl" — Polski

=item "de" — Deutsch

=item "fr" — Français

=item "es" — Español

=item "zh-cn" — 简体中文

=item "tr" — Türkçe

=item "cs" — Čeština

=item "th" — ไทย

=item "vi" — Tiếng Việt

=item "ko" — 한국어

=back

=back

=cut 

has language => (
    is  => 'ro',
    default => sub{ 'ru' },
);

=over 1

=item I<api_uri>

URL for which a request is sent.

=back

=cut 

has api_uri => (
    is  => 'ro',
    default => sub{ 'api.worldoftanks.ru/wgn' },
);

=over 1 

=item I<status>

Request status - 'ok', 'error' or undef, if request not finished.

=back 

=cut

has status => (
    is  => 'rw',
);

=over 1

=item I<response>

Response from WG API

=back

=cut

has response => (
    is  => 'rw',
);

=over 1

=item I<meta>

Meta from response

=back

=cut

has meta => (
    is  => 'rw',
);

=over 1

=item I<error>

Once an error occurred, the following values are returned:

=over 4

=item code

=item message

=item field

=item value

=back

=back

=cut

has error => (
    is  => 'rw',
);

sub _request {
    my ( $self, $method, $uri, $params, $required_params, %passed_params ) = @_;

    $self->status( undef );

    unless ( $self->_validate_params( $required_params, %passed_params ) ) {    #check required params
            $self->status( 'error' );
            $self->error( WG::API::Error->new(
                code    => '997',
                message => 'missing a required field',
                field   => 'xxx',
                value   => 'xxx',
                raw     => 'xxx',
            ) );
    }

    unless ( $method =~ /^(?:get|post)$/ ) {
            $self->status( 'error' );
            $self->error( WG::API::Error->new(
                code    => '996',
                message => 'unknow method',
                field   => 'xxx',
                value   => 'xxx',
                raw     => 'xxx',
            ) );
    }

    $method = "_".$method;                                                              # add prefix for private methods

    $self->$method( $uri, $params, %passed_params );

    return 1;
}

sub _validate_params {
    my ( $self, $required_params, %passed_params ) = @_;

    return undef if $required_params && ! keys %passed_params;                               #without params when they are needed

    for ( @$required_params ) {
        return undef unless defined $passed_params{ $_ };
    }

    return 'passed';
}

sub _get {
    my ( $self, $uri, $params, %passed_params ) = @_;

    my $url = sprintf 'https://%s/%s/?application_id=%s',
            $passed_params{ 'api_uri' } ? $passed_params{ 'api_uri' } : $self->api_uri,
            $uri ? $uri : '',
            $self->application_id,
    ;
    for ( @$params ) {
        $url .= sprintf "&%s=%s", $_, $passed_params{ $_ } if defined $passed_params{ $_ }; 
    }

    my $response = $self->ua->get( $url ); 
    $self->_parse( $response->is_success ? decode_json $response->decoded_content : undef );
    return;
}

sub _post {
    my ( $self, $uri, $params, %passed_params ) = @_;

    my $url = sprintf 'https://%s/%s/', 
        $passed_params{ 'api_uri' } ? $passed_params{ 'api_uri' } : $self->api_uri,
        $uri ? $uri : '';

    #remove unused fields
    if ( $params && %passed_params ) {
        my %params;
        @params{ keys %passed_params } = ();
        delete @params{ @$params };
        delete $passed_params{ $_ } for keys %params;
    }

    $passed_params{ 'application_id' } = $self->application_id;

    my $response = $self->{ 'ua' }->post( $url, %passed_params ); 
    $self->_parse( $response->is_success ? decode_json $response->decoded_content : undef );
    return;
}

sub _parse {
    my ( $self, $response ) = @_;

    if ( ! $response ) { 
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
    } elsif ( ! $response->{ 'status' } ) {
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

    $self->status( delete $response->{ 'status' } );

    if ( $self->status eq 'error' ) {
        $self->error( WG::API::Error->new( $response->{ 'error' } ) );
    } else {
        $self->error( undef );
        $self->meta( $response->{ 'meta' } );
        $self->response( $response->{ 'data' } );
    }

    return;
}

=head1 BUGS

Please report any bugs or feature requests to C<cynovg at cpan.org>, or through the web interface at L<https://github.com/cynovg/WG-API/issues>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WG::API

You can also look for information at:

=over 4

=item * RT: GitHub's request tracker (report bugs here)

L<https://github.com/cynovg/WG-API/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WG-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WG-API>

=item * Search CPAN

L<http://search.cpan.org/dist/WG-API/>

=back


=head1 ACKNOWLEDGEMENTS

...

=head1 SEE ALSO

WG API Reference L<http://ru.wargaming.net/developers/>

=head1 AUTHOR

cynovg , C<< <cynovg at cpan.org> >>

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

1; # End of WG::API
