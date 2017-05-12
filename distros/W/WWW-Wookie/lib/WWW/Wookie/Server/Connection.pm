# -*- cperl; cperl-indent-level: 4 -*-
package WWW::Wookie::Server::Connection 0.102;
use strict;
use warnings;

use utf8;
use 5.020000;

use Moose qw/around has/;
use Moose::Util::TypeConstraints qw/as coerce from where subtype via/;
use URI;
use LWP::UserAgent;
use XML::Simple;
use namespace::autoclean '-except' => 'meta', '-also' => qr/^_/smx;

use overload '""' => 'as_string';

use Readonly;
## no critic qw(ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $EMPTY     => q{};
Readonly::Scalar my $MORE_ARGS => 3;
Readonly::Scalar my $ADVERTISE => q{advertise?all=true};
Readonly::Scalar my $TIMEOUT   => 15;
Readonly::Scalar my $AGENT     => q{WWW::Wookie/}
  . $WWW::Wookie::Server::Connection::VERSION;
Readonly::Scalar my $SERVER_CONNECTION =>
  q{Wookie Server Connection - URL: %sAPI Key: %sShared Data Key: %s};
## use critic

subtype 'Trailing' => as 'Str' => where { m{(^$|(/$))}gsmx };

coerce 'Trailing' => from 'Str' => via { s{([^/])$}{$1/}gsmx; $_ };

has '_url' => (
    'is'     => 'ro',
    'isa'    => 'Trailing',
    'coerce' => 1,
    'reader' => 'getURL',
);

has '_api_key' => (
    'is'      => 'ro',
    'isa'     => 'Str',
    'default' => q{TEST},
    'reader'  => 'getApiKey',
);

has '_shared_data_key' => (
    'is'      => 'ro',
    'isa'     => 'Str',
    'default' => q{mysharedkey},
    'reader'  => 'getSharedDataKey',
);

sub as_string {
    my $self = shift;
    return sprintf $SERVER_CONNECTION, $self->getURL, $self->getApiKey,
      $self->getSharedDataKey;
}

sub test {
    my $self = shift;
    my $url  = $self->getURL;
    if ( $url ne $EMPTY ) {
        my $ua = LWP::UserAgent->new(
            'timeout' => $TIMEOUT,
            'agent'   => $AGENT,
        );
        my $response = $ua->get( $url . $ADVERTISE );
        if ( $response->is_success ) {
            my $xml_obj =
              XML::Simple->new( 'ForceArray' => 1, 'KeyAttr' => 'id' )
              ->XMLin( $response->content );
            if ( exists $xml_obj->{'widget'} ) {
                return 1;
            }
        }
    }
    return 0;
}

around 'BUILDARGS' => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == $MORE_ARGS && !ref $_[0] ) {
        my ( $url, $api_key, $shareddata_key ) = @_;
        return $class->$orig(
            '_url'             => $url,
            '_api_key'         => $api_key,
            '_shared_data_key' => $shareddata_key,
        );
    }
    return $class->$orig(@_);
};

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=for stopwords Wookie API Readonly URI Ipenburg MERCHANTABILITY

=head1 NAME

WWW::Wookie::Server::Connection - A connection to a Wookie server

=head1 VERSION

This document describes WWW::Wookie::Server::Connection version 0.102

=head1 SYNOPSIS

    use WWW::Wookie::Server::Connection;
    $c = WWW::Wookie::Server::Connection->new($url, $api_key, $data_key);

=head1 DESCRIPTION

A connection to a Wookie server. This maintains the necessary data for
connecting to the server and provides utility methods for making common calls
via the Wookie REST API.

=head1 SUBROUTINES/METHODS

=head2 C<new>

Create a connection to a Wookie server at a given URL.

=over 4

=item 1. The URL of the Wookie server as string

=item 2. The API key for the server as string

=item 3. The shared data key for the server connection as string

=back

=head2 C<getURL>

Get the URL of the Wookie server. Returns the current Wookie connection's URL
as string.

=head2 C<setURL>

Set the URL of the Wookie server.

=head2 C<getApiKey>

Get the API key for this server. Returns the current Wookie connection's API
key as string. Throws a C<WookieConnectorException>.

=head2 C<setApiKey>

Set the API key for this server.

=head2 C<getSharedDataKey>

Get the shared data key for this server. Returns the current Wookie
connection's shared data key. Throws a C<WookieConnectorException>.

=head2 C<setSharedDataKey>

Set the shared data key for this server.

=head2 C<as_string>

Output connection information as string.

=head2 C<test>

Test the Wookie server connection.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over 4

=item * L<LWP::UserAgent|LWP::UserAgent>

=item * L<Moose|Moose>

=item * L<Moose::Util::TypeConstraints|Moose::Util::TypeConstraints>

=item * L<Readonly|Readonly>

=item * L<URI|URI>

=item * L<XML::Simple|XML::Simple>

=item * L<namespace::autoclean|namespace::autoclean>

=item * L<overload|overload>

=back

=head1 INCOMPATIBILITIES

=head1 DIAGNOSTICS

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests at L<RT for
rt.cpan.org|https://rt.cpan.org/Dist/Display.html?Queue=WWW-Wookie>.

=head1 AUTHOR

Roland van Ipenburg, E<lt>ipenburg@xs4all.nlE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 by Roland van Ipenburg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
