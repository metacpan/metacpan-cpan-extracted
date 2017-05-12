package Weewar;
use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use XML::LibXML;

use Weewar::User;
use Weewar::Game;
use Weewar::HQ;

our $VERSION = '0.01';

use Readonly;
Readonly my $server => $ENV{WEEWAR_SERVER} || 'weewar.com';
Readonly my $base   => $ENV{WEEWAR_BASE} || 'api1';

=head1 NAME

Weewar - get data from the weewar.com XML API

=head1 SYNOPSIS

   use Weewar;

   # get all users
   my @users = Weewar->all_users;     # all active players on weewar

   # get a single user
   my $me = Weewar->user('jrockway'); # one user only (as a Weewar::User)
   my $me = Weewar::User->new({ name => 'jrockway }); # lazy-loaded

   # get a game
   my $game = Weewar->game('27056');  # get game (as a Weewar::Game)
   my $game = Weewar::Game->new({ id => '27056' });
   
   # access headquarters
   my $hq = Weewar->hq('jrockway' => $jrockways_api_key);
   my $hq = Weewar::HQ->new({ user => 'jrockway',
                              key  => $jrockways_api_key,
                            });

=head1 DESCRIPTION

This module lets you interact with the
(L<Weewar|http://weewar.com/?referrer=jrockway>) API.  See
L<Weewar::User>, L<Weewar::Game>, and L<Weewar::HQ> for details about
what data you can get from the API.

=head1 METHODS

Right now, everything is a class method since the weewar API is public
for everything except the HQ (and no state needs to be kept between
requests).  If this changes, then this API will change a bit.

=cut

{ package Weewar::UA;
  use base 'LWP::UserAgent';
  sub new {
      my ($class, $args) = @_;
      $args ||= {};
      bless $args => $class;
  }
  sub get_basic_credentials {
      my $self = shift;
      return unless $self->{username};
      return (map {$self->{$_}} qw/username password/);
  }
}

# separate method so that WeewarTest can override the HTTP part
sub _get {
    my ($class, $path, $args) = @_;
    
    my $ua = Weewar::UA->new($args);
    my $res = $ua->get("http://$server/$base/$path");
    
    croak 'request error: '. $res->status_line if !$res->is_success;
    return $res->decoded_content;
}

sub _request {
    my ($class, $path, $args) = @_;
    my $content = $class->_get($path, $args);
    my $parser = XML::LibXML->new;
    return $parser->parse_string($content);
}

=head2 all_users

Return a list of all active Weewar users as L<Weewar::User> objects.
The objects are loaded lazily, so this method only causes one request
to be sent to the server.  When you start accessing the returned
children, they will be populated on-demand from the server.

An exception will be thrown if something goes wrong.

=cut

sub all_users {
    my $class = shift;
    my $doc = $class->_request('users/all');
    my @raw_users = $doc->getElementsByTagName('user');
    
    my @users;
    foreach my $user (@raw_users){
        my $def;
        $def->{$_} = $user->getAttributeNode($_)->value for qw/name id rating/;
        $def->{points} = $def->{rating}; # API uses 2 names for the same thing
        push @users, Weewar::User->new($def);
    }
    return @users;
}

=head2 user($username)

Returns a C<Weewar::User> object representing C<$username>.  If there is
no user by that name, and exception is thrown.

=cut

sub user {
    my $class     = shift;
    my $username  = shift;
    my $user = Weewar::User->new({ name => $username });
    $user->draws; # force the object to be populated
    return $user;
}

=head2 game($id)

Returns a C<Weewar::Game> object representing the game with id C<$id>.  If 
there is no game with that id, an exception is thrown.

=cut

sub game {
    my $class   = shift;
    my $gameid  = shift;
    my $game    = Weewar::Game->new({ id => $gameid });
    $game->name; # force the object to be populated
    return $game;   
}

=head2 hq($username => $apikey)

Returns a C<Weewar::HQ> object representing C<$username>'s
"headquarters".  If there is an error getting the data (bad API key,
etc.), an exception is thrown.

=cut

sub hq {
    my $class = shift;
    my ($user, $key) = @_;
    my $hq = Weewar::HQ->new({ key => $key, user => $user });
    return $hq;
}

=head1 ENVIRONMENT

You can use different weewar servers by changing these environment
variables.  I doubt there are other weewar servers that speak this
API, though.

=over 4

=item WEEWAR_SERVER

The hostname of the Weewar server, defaulting to C<weewar.com>

=item WEEWAR_BASE

The base URL of the API, defaulting to C<api1>.

=back

=head1 BUGS

If the Weewar API changes, this module will need an update.  Let me
know if something is broken so I can fix it.

The combination of Weewar's odd XML, C<XML::LibXML>, and the fact that
I had very little sleep before writing this makes for some very ugly
code.  Feel free to clean it up and send me a patch.

Bugs should be reported through RT, but you can email me directly too.

=head1 AUTHOR

Jonathan Rockway C<< <jrockway@cpan.org> >>

=head1 COPYRIGHT

This module is copyright (c) 2007 Jonathan Rockway.

You can distribute, modify, and use this module under the same terms
as Perl itself.

=cut

1;
