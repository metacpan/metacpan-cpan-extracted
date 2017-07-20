package WebService::CastleIO;

use 5.10.0;
use strict;
use warnings;
use feature 'switch';
use feature 'say';

use JSON;
use REST::Client;
use MIME::Base64;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;


=head1 NAME

WebService::CastleIO - Castle.io API client


=head1 VERSION

Version 1.03

=cut


our $VERSION = '1.03';



has api_secret => (
  is        => 'rw',
  isa       => 'Str'
);

has api_url => (
  is        => 'ro',
  isa       => 'Str',
  default   => 'https://api.castle.io/v1'
);

has format => (
  is        => 'ro',
  isa       => 'Str',
  default   => 'json'
);

has cookie_id => (
  is        => 'rw',
  isa       => 'Str'
);

has ip_address => (
  is        => 'rw',
  isa       => 'Str'
);

has headers => (
  is        => 'rw',
  isa       => 'Str',
);

has source => (
  is        => 'rw',
  isa       => 'Str'
);

has debug => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0
);



=head1 SYNOPSIS

Castle detects and mitigates account takeover in web and mobile apps. This is a third party API client built for the Castle.io API.


=head1 CONFIGURATION
 
    use WebService::CastleIO;
 
    my $castle = WebService::CastleIO->new(
        api_secret => 'sRq3Zmzpxwu6eDXiYCFB3xyfi4ZnVjnn',
        cookie_id  => 'abcd',
        ip_address => '24.61.128.172',
        headers    => JSON->new->allow_nonref->utf8->encode({'User-Agent' => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:54.0) Gecko/20100101 Firefox/54.0'}),
        source     => 'backend',
        debug      => 1
     );


=head1 SUBROUTINES/METHODS


=head2 track

Track lets you record security-related actions your users perform. Events are processed 
asynchronously to return as quickly as possible.

    my $event_result = $castle->track(
        data => {user_id => 'dummy', name => '$login.succeeded', properties => {threat => 'Large', whatever => 'made up'}}
    );

=cut

sub track {
  my ($self, %params) = validated_hash(
    \@_,
    data    => {isa => 'Maybe[HashRef]'},
  );

  say '[track] Create new event' if $self->debug;

  $self->_call(endpoint => 'track', args => \%params, method => 'POST');
}



=head2 authenticate

Authenticate is processed synchronous and returns returns an action of the types approve, challenge or deny.

    my $auth_result = $castle->authenticate(
        data => {user_id => 'dummywriter', name => '$login.succeeded'},
    );


=cut

sub authenticate {
  my ($self, %params) = validated_hash(
    \@_,
    data => {isa => 'Maybe[HashRef]'},
  );

  say '[authenticate] Authenticate user' if $self->debug;

  $self->_call(endpoint => 'authenticate', args => \%params, method => 'POST');
}




=head2 identify

User updates are processed asynchronously to return as quickly as possible.

    my $identify_result = $castle->identify(
        data => {user_id => 'dummywriter', traits => {'foo' => 'bar'}},
    );

=cut

sub identify {
  my ($self, %params) = validated_hash(
    \@_,
    data => {isa => 'Maybe[HashRef]'},
  );

  say '[identify] Identify user' if $self->debug;

  $self->_call(endpoint => 'identify', args => \%params, method => 'POST');
}



=head2 review

Reviews lets you fetch the context for a user to review anomalous account activity.

    my $reviews_result = $castle->review(review_id => 12356789);

=cut

sub review {
  my ($self, %params) = validated_hash(
    \@_,
    review_id => {isa => 'Int'}
  );

  say '[review] Review user activity' if $self->debug;

  $self->_call(endpoint => "reviews/$params{review_id}", args => \%params, method => 'GET');
}



=head2 _call

Private method that makes call to API web service.

=cut

sub _call {
  my ($self, %params) = validated_hash(
    \@_,
    endpoint => {isa => 'Str'},
    args     => {isa => 'Maybe[HashRef]'},
    method   => {isa => enum([qw(POST GET)])}
  );

  my $headers = {
      'X-Castle-Ip'                => $self->ip_address,
      'X-Castle-Source'            => $self->source,
      'X-Castle-Cookie-Id'         => $self->cookie_id,
      'X-Castle-Headers'           => $self->headers,
      'X-Castle-Client-User-Agent' => $self->_client_user_agent,
      'Content-Type'               => 'application/json',
      'User-Agent'                 => 'Castle API Client ' . $VERSION
  };

  my $url = $self->api_url . '/' . $params{endpoint} . '.' . $self->format;

  my $client = REST::Client->new();
  $client->addHeader("Authorization", "Basic " . encode_base64(':' . $self->api_secret, ''));

  for ($params{method}) {
    when ('GET')  {
      say "[_call]: Making call GET $url" if $self->debug;
      my $url_args  = defined $params{args}{data} ? '?' . join('&', map {"$_=$params{args}{data}{$_}"} keys %{$params{args}{data}}) : '';
      $url .= $url_args;
      $client->GET($url);
    }
    when ('POST') {
      my $json_args = JSON->new->allow_nonref->utf8->encode($params{args}{data});
      say "[_call]: Making call POST $url" if $self->debug;
      $client->POST($url, $json_args, $headers)
    }
  }

  $client->responseCode();
}



=head2 _client_user_agent

Private method to return user agent.

=cut

sub _client_user_agent {
    JSON->new->allow_nonref->utf8->encode({
      bindings_version => $VERSION,
      lang             => 'perl',
      publisher        => 'castle',
      uname            => `uname -a`
    });
}


  
=head2 _json_to_object

Private method that converts JSON result to object

=cut
  
sub _json_to_object {
  my $self = shift;
  my $json = shift;
  JSON->new->allow_nonref->utf8->decode($json);
} 





=head1 AUTHOR

Dino Simone, C<< <dino at simone.is> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-castleio at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-CastleIO>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::CastleIO


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-CastleIO>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-CastleIO>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-CastleIO>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-CastleIO/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Dino Simone - dinosimone.com

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=cut

1; # End of WebService::CastleIO
