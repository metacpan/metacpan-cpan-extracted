use strict;
use warnings;
package TheGameCrafter::Client;
$TheGameCrafter::Client::VERSION = '0.0104';
BEGIN {
  $TheGameCrafter::Client::VERSION = '0.0103';
}

use LWP::UserAgent;
use HTTP::Request::Common;
use JSON;
use URI;
use Ouch;
use parent 'Exporter';

our @EXPORT = qw(tgc_get tgc_delete tgc_put tgc_post);

=head1 NAME

TheGameCrafter::Client - A simple client to TGC's web services.

=head1 VERSION

version 0.0103

=head1 SYNOPSIS

 use TheGameCrafter::Client;

 my $game = tgc_get('game/528F18A2-F2C4-11E1-991D-40A48889CD00');
 
 my $session = tgc_post('session', { username => 'me', password => '123qwe', api_key_id => 'abcdefghijklmnopqrztuz' });

 $game = tgc_put('game/528F18A2-F2C4-11E1-991D-40A48889CD00', { session_id => $session->{id}, name => 'Lacuna Expanse' });

 my $status = tgc_delete('game/528F18A2-F2C4-11E1-991D-40A48889CD00', { session_id => $session->{id} });

=head1 DESCRIPTION

A light-weight wrapper for The Game Crafter's (L<http://thegamecrafter.com>) RESTful API (L<https://www.thegamecrafter.com/developer/>). This wrapper basically hides the request cycle from you so that you can get down to the business of using the API. It doesn't attempt to manage the data structures or objects the web service interfaces with.

=head1 SUBROUTINES

The following subroutines are exported into your namespace wherever you C<use TheGameCrafter::Client>.

=head2 tgc_get(path, params)

Performs a C<GET> request, which is used for reading data from the service.

=over

=item path

The path to the REST interface you wish to call. You can abbreviate and leave off the C</api/> part if you wish.

=item params

A hash reference of parameters you wish to pass to the web service.

=back

=cut

sub tgc_get {
    my ($path, $params) = @_;
    my $uri = _create_uri($path);
    $uri->query_form($params);
    return _process_request( GET $uri->as_string );
}

=head2 tgc_delete(path, params)

Performs a C<DELETE> request, deleting data from the service.

=over

=item path

The path to the REST interface you wish to call. You can abbreviate and leave off the C</api/> part if you wish.

=item params

A hash reference of parameters you wish to pass to the web service.

=back

=cut

sub tgc_delete {
    my ($path, $params) = @_;
    my $uri = _create_uri($path);
    return _process_request( POST $uri->as_string, 'X-HTTP-Method' => 'DELETE', Content_Type => 'form-data', Content => $params );
}

=head2 tgc_put(path, params)

Performs a C<PUT> request, which is used for updating data in the service.

=over

=item path

The path to the REST interface you wish to call. You can abbreviate and leave off the C</api/> part if you wish.

=item params

A hash reference of parameters you wish to pass to the web service.

=back

=cut

sub tgc_put {
    my ($path, $params) = @_;
    my $uri = _create_uri($path);
    return _process_request( POST $uri->as_string, 'X-HTTP-Method' => 'PUT', Content_Type => 'form-data', Content => $params );
}

=head2 tgc_post(path, params)

Performs a C<POST> request, which is used for creating data in the service.

=over

=item path

The path to the REST interface you wish to call. You can abbreviate and leave off the C</api/> part if you wish.

=item params

A hash reference of parameters you wish to pass to the web service.

=back

=cut

sub tgc_post {
    my ($path, $params) = @_;
    my $uri = _create_uri($path);
    return _process_request( POST $uri->as_string, Content_Type => 'form-data', Content => $params );
}

sub _create_uri {
    my $path = shift;
    unless ($path =~ m/^\/api/) {
        $path = '/api/'.$path;
    }
    return URI->new('https://www.thegamecrafter.com'.$path);
}

sub _process_request {
    _process_response(LWP::UserAgent->new->request( @_ ));
}

sub _process_response {
    my $response = shift;
    my $result = eval { from_json($response->decoded_content) }; 
    if ($@) {
        ouch 500, 'Server returned unparsable content.', { error => $@, content => $response->decoded_content };
    }
    elsif ($response->is_success) {
        return $result->{result};
    }
    else {
        ouch $result->{error}{code}, $result->{error}{message}, $result->{error}{data};
    }
}

=head1 PREREQS

L<LWP::UserAgent>
L<Ouch>
L<HTTP::Request::Common>
L<JSON>
L<URI>

=head1 SUPPORT

=over

=item Repository

L<http://github.com/rizen/TheGameCrafter-Client>

=item Bug Reports

L<http://github.com/rizen/TheGameCrafter-Client/issues>

=back

=head1 AUTHOR

JT Smith <jt_at_plainblack_dot_com>

=head1 LEGAL

This module is Copyright 2012 Plain Black Corporation. It is distributed under the same terms as Perl itself. 

=cut

1;