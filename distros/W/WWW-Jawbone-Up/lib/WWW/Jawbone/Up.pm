package WWW::Jawbone::Up;

use 5.010;
use strict;
use warnings;

our $VERSION = '1.32.4';

=encoding utf-8

=head1 NAME

WWW::Jawbone::Up - Unofficial Jawbone UP API

=head1 SYNOPSIS

  use WWW::Jawbone::Up;

  my $up = WWW::Jawbone::Up->connect('alan@eatabrick.org', 's3kr3t');

  my $user = $up->user;
  my $score = $up->score;

  say $user->name . ' walked ' . $score->move->distance . 'km today';

  my $hours = int($score->sleep->asleep / 3600);
  my $minutes = int($score->sleep->asleep / 60); % 60;

  say $user->name . " slept for ${hours}h${minutes}m last night";

=head1 DESCRIPTION

WWW::Jawbone::Up is a perl binding to the unofficial Jawbone UP API.  After
authenticating you can find interesting bits of data.  The version number of
this library should reflect the associated version of the Jawbone API but I
have no way of knowing if they will be sane with their version numbers so we'll
see how that pans out.

=head1 METHODS

=cut

use Carp;
use DateTime;
use JSON 2.0;
use LWP::UserAgent;
use URI::Escape;

use WWW::Jawbone::Up::Feed;
use WWW::Jawbone::Up::Score;
use WWW::Jawbone::Up::Tick;
use WWW::Jawbone::Up::User;
use WWW::Jawbone::Up::Workout;

use constant URI_BASE => 'https://jawbone.com';
use constant URI_API  => URI_BASE . '/nudge/api/v.1.32';

sub _request {
  my ($self, $method, $uri, $data) = @_;

  $self->{ua} ||= LWP::UserAgent->new();

  my $request = HTTP::Request->new($method, $uri);
  $request->header('x-nudge-token', $self->{token}) if $self->{token};
  $request->content($data);

  my $response = $self->{ua}->request($request);

  croak $response->status_line if $response->is_error;

  return decode_json($response->decoded_content);
}

sub __encode {
  my ($hash) = @_;

  return join '&',
    map sprintf('%s=%s', uri_escape($_), uri_escape($hash->{$_})),
    keys %$hash;
}

sub _get {
  my ($self, $uri, $data) = @_;

  my $query_string = __encode($data);
  $uri .= ($uri =~ /\?/ ? '&' : '?') . $query_string;

  return $self->_request(GET => $uri);
}

sub _post {
  my ($self, $uri, $data) = @_;

  my $body = __encode($data);

  return $self->_request(POST => $uri, $body);
}

=head2 connect($email, $password)

Authenticates with the API.  Will return undef if there are any errors,
possibly also dying or warning about them.

=cut

sub connect {
  my ($class, $email, $password) = @_;

  my $self = bless {}, $class;

  my $json = $self->_post(
    URI_BASE . '/user/signin/login', {
      service => 'nudge',
      email   => $email,
      pwd     => $password,
    });

  if ($json->{error}) {
    carp $json->{error}{msg};
    return undef;
  }

  $self->{token} = $json->{token};

  return $self;
}

=head2 user()

Returns a L<WWW::Jawbone::Up::User> object representing the currently
authenticated user.

=cut

sub user {
  my ($self) = @_;

  unless ($self->{user}) {
    my $json = $self->_get(URI_API . '/users/@me');
    $self->{user} = WWW::Jawbone::Up::User->new($json->{data});
  }

  return $self->{user};
}

=head2 feed($date)

Returns an array of L<WWW::Jawbone::Up::Feed> objects for the given C<$date>.
If no date is given, the current date is used.

=cut

sub feed {
  my ($self, $date, $options) = @_;

  $options ||= {};
  $options->{date} = $date if defined $date;

  my $json = $self->_get(URI_API . '/users/@me/social', $options);

  return map WWW::Jawbone::Up::Feed->new($_), @{ $json->{data}{feed} };
}

=head2 score($date)

Returns a L<WWW::Jawbone::Up::Score> object for the given C<$date>.  If no date
is given, the current date is used.

=cut

sub score {
  my ($self, $date, $options) = @_;

  $options = {};
  $options->{date} = $date if defined $date;

  my $json = $self->_get(URI_API . '/users/@me/score', $options);

  return WWW::Jawbone::Up::Score->new($json->{data});
}

=head2 band($start, $end)

Returns an array of L<WWW::Jawbone::Up::Tick> objects for the given time range.
Both C<$start> and C<$end> should be epoch times (seconds since epoch).  If no
range is given, I think the current day is used, but I haven't really
researched that fact too much.

=cut

sub band {
  my ($self, $start, $end, $options) = @_;

  $options ||= {};
  $options->{start_time} = $start if defined $start;
  $options->{end_time}   = $end   if defined $end;

  my $json = $self->_get(URI_API . '/users/@me/band', $options);

  return map WWW::Jawbone::Up::Tick->new($_->{value}),
    @{ $json->{data}{ticks} };
}

=head2 workouts($date)

Returns an array of L<WWW::Jawbone::Up::Workout> objects for the give C<$date>.
If no $date is given, I think some number of recent workouts are given, but I
haven't really researched that fact too much.

=cut

sub workouts {
  my ($self, $date, $options) = @_;

  $options ||= {};
  $options->{date} = $date if defined $date;

  my $json = $self->_get(URI_API . '/users/@me/workouts', $options);

  return map WWW::Jawbone::Up::Workout->new($_), @{ $json->{data}{items} };
}

1;

=head1 TODO

The documentation for this distribution is utterly lacking.  I will fix that
sometime soon.

=head1 AUTHOR

Alan Berndt E<lt>alan@eatabrick.orgE<gt>

=head1 COPYRIGHT

Copyright 2013 Alan Berndt

=head1 LICENSE

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=head1 SEE ALSO

L<WWW::Jawbone::Up::Feed>
L<WWW::Jawbone::Up::Score>
L<WWW::Jawbone::Up::Tick>
L<WWW::Jawbone::Up::User>
L<WWW::Jawbone::Up::Workout>

=cut
