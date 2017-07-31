use strict;
use warnings;
use 5.12.0;

use REST::Client;
use JSON;

use vars qw($VERSION);
$VERSION = '1.001';

=head1 NAME

WebService::IFConfig::Client - Client for Martin Polden's https://ifconfig.co

=head1 SYNOPSIS 

    use strict;
    use warnings;
    use 5.12.0;

    use feature qw/say/;
    use WebService::IFConfig::Client;
    my $ifconfig = WebService::IFConfig::Client->new();

    say $ifconfig->get_city;
    say $ifconfig->get_country;
    say $ifconfig->get_hostname;
    say $ifconfig->get_ip;
    say $ifconfig->get_ip_decimal;

    # Time passes ...
    
    # Request again
    $ifconfig->request;

Calling C<new()> with no arguments, defaults to requesting immediately from https://ifconfig.co.

To defer requesting, the data you can pass the argument C<'run' =E<gt> 0>.

To use a different server, pass C<'server' =E<gt> $my_server>.

=cut

package WebService::IFConfig::Client;
use Moose;
use experimental qw/switch/;

=head1 METHODS

=head2 WebService::IFConfig::Client->new( 'run' =E<gt> $boolean , 'server' =E<gt> $my_server );

Constructor to create an new client. Default values are

  Argument  Default                     Meaning
  --------  -------                     -------
  run       1                           1 means run immediately.
                                        0 means do not run until a request is made.
  server    https://ifconfig.co/json    IPD Server, but you can run your own and provide it here.

=cut

# Whether to run immediately at construction. Default true.
has 'run' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
    reader  => '_run_at_construction'
);

=head2 get_server

Get the URL this client is configured to talk to

=cut

=head2 set_server

Set the URL this client is configured to talk to

=cut

has 'server' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://ifconfig.co/json',
    reader  => 'get_server',
    writer  => 'set_server'
);

has '_json' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
    reader  => '_get_json',
    writer  => '_set_json'
);

=head2 get_raw_status

Get the HTTP Response Code of the latest request. Returns 0 if no request has been made.

=cut

has '_raw_status' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
    reader  => 'get_raw_status',
    writer  => '_set_raw_status'
);

sub BUILD {
    my $self = shift;

    $self->request if $self->_run_at_construction;
}

=head2 get_status

Returns 1 if the HTTP Response Code of the latest request was 200, or 0 if not.
Returns undef if no request has been made.

=cut

sub get_status {
    my $self = shift;
    my $answer;

    given ( $self->get_raw_status ) {
        $answer = undef when 0;
        $answer = 1 when 200;
        default { $answer = 0 }
    }

    return $answer;
}

=head2 request

Makes a(nother) request from the server.

=cut

sub request {
    my $self   = shift;
    my $client = REST::Client->new();
    my $json   = JSON->new();

    # Reset
    $self->_set_json({});

    $client->GET( $self->get_server );

    $self->_set_raw_status( $client->responseCode() );
    $self->get_status()
        and $self->_set_json( $json->decode( $client->responseContent() ) );
}

sub _request_if_not_ok {
    my $self = shift;
    $self->get_status() or $self->request();
}

sub _elements {
    my ( $self, $element ) = @_;
    $self->_request_if_not_ok();
    return $self->_get_json->{$element};
}

=head2 get_city

Get the City name. Forces a request if no valid data.

=cut

sub get_city       { return $_[0]->_elements('city'); }

=head2 get_country

Get the Country name. Forces a request if no valid data.

=cut

sub get_country    { return $_[0]->_elements('country'); }

=head2 get_hostname

Get the Hostname. Forces a request if no valid data.

=cut

sub get_hostname   { return $_[0]->_elements('hostname'); }

=head2 get_ip

Get the IP address. Forces a request if no valid data.

=cut

sub get_ip         { return $_[0]->_elements('ip'); }

=head2 get_ip_decimal

Get a decimal representation of the IP. Forces a request if no valid data.

=cut

sub get_ip_decimal { return $_[0]->_elements('ip_decimal'); }

=head1 AUTHOR

Nic Doye E<lt>nic@worldofnic.orgE<gt>

=head1 BUGS

None. None whatsoever. (This is a lie).

=head1 LICENSE

   Copyright 2017 Nicolas Doye

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

=cut

1;
