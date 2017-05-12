package WWW::Plurk;

use warnings;
use strict;

use Carp;
use DateTime::Format::Mail;
use HTML::Tiny;
use HTTP::Cookies;
use JSON;
use Data::Dumper;
use LWP::UserAgent;
use Time::Piece;
use WWW::Plurk::Friend;
use WWW::Plurk::Message;

=head1 NAME

WWW::Plurk - Unoffical plurk.com API

=head1 VERSION

This document describes WWW::Plurk version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use WWW::Plurk;
    my $plurk = WWW::Plurk->new;
    $plurk->login( 'username', 'password' );
    my $msg = $plurk->add_plurk( content => 'Hello, World' );

=head1 DESCRIPTION

This is an unofficial API for plurk.com. It uses the same interfaces
that plurk itself uses internally which are not published and not
necessarily stable. When Plurk publish a stable API this module will be
updated to take advantage of it. In the mean time use with caution.

Ryan Lim did the heavy lifting of reverse engineering the API. His PHP
implementation can be found at L<http://code.google.com/p/rlplurkapi/>.

If you'd like to lend a hand supporting the bits of Plurk that this API
doesn't yet reach please feel free to send me a patch. The Plurk API
Wiki at L<http://plurkwiki.badchemicals.net/> is a good source of
information.

=cut

# Default API URIs

use constant MAX_MESSAGE_LENGTH => 140;

my $BASE_DEFAULT = 'http://www.plurk.com';

my %PATH_DEFAULT = (
    accept_friend     => '/Notifications/allow',
    add_plurk         => '/TimeLine/addPlurk',
    add_response      => '/Responses/add',
    deny_friend       => '/Notifications/deny',
    get_completion    => '/Users/getCompletion',
    get_friends       => '/Users/getFriends',
    get_plurks        => '/TimeLine/getPlurks',
    get_responses     => '/Responses/get2',
    get_unread_plurks => '/TimeLine/getUnreadPlurks',
    home              => undef,
    login             => '/Users/login?redirect_page=main',
    notifications     => '/Notifications',
);

BEGIN {
    my @ATTR = qw(
      _base_uri
      info
      state
      trace
    );

    my @INFO = qw(
      display_name
      full_name
      gender
      has_profile_image
      id
      is_channel
      karma
      location
      nick_name
      page_title
      relationship
      star_reward
      uid
    );

    for my $attr ( @ATTR ) {
        no strict 'refs';
        *{$attr} = sub {
            my $self = shift;
            return $self->{$attr} unless @_;
            return $self->{$attr} = shift;
        };
    }

    for my $info ( @INFO ) {
        no strict 'refs';
        *{$info} = sub {
            my $self = shift;
            # Info attributes only available when logged in
            $self->_logged_in;
            return $self->info->{$info};
        };
    }
}

=head1 INTERFACE 

All methods throw errors in the event of any kind of failure. There's no
need to check return values but you might want to wrap calls in an
C<eval> block.

=head2 C<< new >>

Create a new C<< WWW::Plurk >>. Optionally accepts two arguments
(username, password). If they are supplied it will attempt to login to
Plurk. If no arguments are supplied C<login> must be called before
attempting to access the service.

    # Create and login
    my $plurk = WWW::Plurk->new( 'user', 'pass' );
    
    # Create then login afterwards
    my $plurk = WWW::Plurk->new;
    $plurk->login( 'user', 'pass' );

=cut

sub new {
    my $class = shift;
    my $self  = bless {
        _base_uri => $BASE_DEFAULT,
        path      => {%PATH_DEFAULT},
        state     => 'init',
        trace     => $ENV{PLURK_TRACE} ? 1 : 0,
    }, $class;

    if ( @_ ) {
        croak "Need two arguments (user, pass) if any are supplied"
          unless @_ == 2;
        $self->login( @_ );
    }

    return $self;
}

sub _make_ua {
    my $self = shift;
    my $ua   = LWP::UserAgent->new;
    $ua->agent( join ' ', __PACKAGE__, $VERSION );
    $ua->cookie_jar( HTTP::Cookies->new );
    return $ua;
}

sub _ua {
    my $self = shift;
    return $self->{_ua} ||= $self->_make_ua;
}

sub _trace {
    my ( $self, @msgs ) = @_;
    if ( $self->trace ) {
        print STDERR "$_\n" for @msgs;
    }
}

sub _raw_post {
    my ( $self, $uri, $params ) = @_;
    $self->_trace(
        POST => $uri,
        Data::Dumper->Dump( [$params], [qw($params)] )
    );
    my $resp = $self->_ua->post( $uri, $params );
    $self->_trace( $resp->status_line );
    return $resp;
}

sub _raw_get {
    my ( $self, $uri ) = @_;
    $self->_trace( GET => $uri );
    my $resp = $self->_ua->get( $uri );
    $self->_trace( $resp->status_line );
    return $resp;
}

sub _cookies { shift->_ua->cookie_jar }

sub _post {
    my ( $self, $service, $params ) = @_;
    my $resp
      = $self->_raw_post( $self->_uri_for( $service ), $params || {} );
    croak $resp->status_line
      unless $resp->is_success
          or $resp->is_redirect;
    return $resp;
}

sub _json_post {
    my $self = shift;
    return $self->_decode_json( $self->_post( @_ )->content );
}

sub _get {
    my ( $self, $service, $params ) = @_;
    my $resp
      = $self->_raw_get( $self->_uri_for( $service, $params || {} ) );
    croak $resp->status_line
      unless $resp->is_success
          or $resp->is_redirect;
    return $resp;
}

sub _json_get {
    my $self = shift;
    return $self->_decode_json( $self->_get( @_ )->content );
}

=head2 C<< login >>

Attempt to login to a Plurk account. The two mandatory arguments are the
username and password for the account to be accessed.

    my $plurk = WWW::Plurk->new;
    $plurk->login( 'user', 'pass' );

=cut

sub login {
    my ( $self, $name, $pass ) = @_;

    my $resp = $self->_post(
        login => {
            nick_name => $name,
            password  => $pass,
        }
    );

    my $ok = 0;
    $self->_cookies->scan( sub { $ok++ if $_[1] eq 'plurkcookie' } );
    croak "Login for $name failed, no cookie returned"
      unless $ok;

    $self->_path_for( home => $resp->header( 'Location' )
          || "/user/$name" );

    $self->_parse_user_home;
    $self->state( 'login' );
}

sub _parse_time {
    my ( $self, $time ) = @_;
    return DateTime::Format::Mail->parse_datetime( $time )->epoch;
}

# This is a bit of a bodge. Plurk doesn't return pure JSON; instead it
# returns JavaScript that's nearly JSON apart from the fact that
# timestamps are specified as 'new Date("...")'. So we need to hoist
# those out of the text and replace them with the corresponding epoch
# timestamp.
#
# Theoretically we could just do a search and replace. Because the Date
# constructor contains a quoted string there's no danger of false
# positives when someone happens to post a message that contains
# matching text - because in that case the nested quotes would be
# backslashed and the regex wouldn't match.
#
# Of course that didn't occur to me until /after/ I'd written the code
# to pull all the string literals out of the text before replacing the
# Date constructors...
#
# I'll leave that code in place because it's useful to have lying around
# in case some future version of this routine has to handle embedded JS
# that could collide with the contents of string literals.

sub _decode_json {
    my ( $self, $json ) = @_;

    my %strings    = ();
    my $next_token = 1;

    my $tok = sub {
        my $str = shift;
        my $key = sprintf '#%d#', $next_token++;
        $strings{$key} = $str;
        return qq{"$key"};
    };

    # Stash string literals to avoid false positives
    $json =~ s{ " ( (?: \\. | [^\\"]+ )* ) " }{ $tok->( $1 ) }xeg;

    # Plurk actually returns JS rather than JSON.
    $json =~ s{ new \s+ Date \s* \( \s* " (\#\d+\#) " \s* \) }
        { $self->_parse_time( $strings{$1} ) }xeg;

    # Replace string literals
    $json =~ s{ " (\#\d+\#) " }{ qq{"$strings{$1}"} }xeg;

    # Now we have JSON
    return decode_json $json;
}

sub _parse_user_home {
    my $self = shift;
    my $resp = $self->_get( 'home' );
    if ( $resp->content =~ /^\s*var\s+GLOBAL\s*=\s*(.+)$/m ) {
        my $global = $self->_decode_json( $1 );
        $self->info(
            $global->{session_user}
              or croak "No session_user data found"
        );
    }
    else {
        croak "Can't find GLOBAL data on user page";
    }
}

=head2 C<< is_logged_in >>

Returns a true value if we're currently logged in.

    if ( $plurk->is_logged_in ) {
        $plurk->add_plurk( content => 'w00t!' );
    }

=cut

sub is_logged_in { shift->state eq 'login' }

sub _logged_in {
    my $self = shift;
    croak "Please login first"
      unless $self->is_logged_in;
}

=head2 C<< friends_for >>

Return a user's friends.

    my @friends = $plurk->friends_for( $uid );

Pass the user id as either

=over

=item * an integer

    my @friends = $plurk->friends_for( 12345 );

=item * an object that has a method called C<uid>

    # $some_user isa WWW::Plurk::Friend
    my @friends = $plurk->friends_for( $some_user );

=back

Returns a list of L<WWW::Plurk::Friend> objects.

=cut

sub friends_for {
    my $self = shift;
    my $for = $self->_uid_cast( shift || $self );
    $self->_logged_in;
    my $friends
      = $self->_json_get( get_completion => { user_id => $for } );
    return map { WWW::Plurk::Friend->new( $self, $_, $friends->{$_} ) }
      keys %$friends;
}

=head2 C<< friends >>

Return the current user's friends. This

    my @friends = $plurk->friends;

is equivalent to

    my @friends = $plurk->friends_for( $self->uid );

=cut

sub friends {
    my $self = shift;
    return $self->friends_for( $self );
}

=head2 C<< add_plurk >>

Post a new plurk.

    $plurk->add_plurk(
        content => 'Hello, World'
    );

Arguments are supplied as a number of key, value pairs. The following
arguments are recognised:

=over

=item * content - the message content

=item * qualifier - the qualifier string ('is', 'says' etc)

=item * lang - the (human) language for this Plurk

=item * no_comments - true to disallow comments

=item * limited_to - limit visibility

=back

The only mandatory argument is C<content> which should be a string of
140 characters or fewer.

C<qualifier> is first word of the message - which has special
significance that you will understand if you have looked at the Plurk
web interface. The following qualifiers are supported:

  asks feels gives has hates is likes loves 
  says shares thinks wants was will wishes

If omitted C<qualifier> defaults to ':' which signifies that you are
posting a free-form message with no qualifier.

C<lang> is the human language for this Plurk. It defaults to 'en'.
Apologies to those posting in languages other than English.

C<no_comments> should be true to lock the Plurk preventing comments from
being made.

C<limited_to> is an array of user ids (or objects with a method called
C<uid>). If present the Plurk will only be visible to those users. To
limit visibility of a Plurk to friends use:

    my $msg = $plurk->add_plurk(
        content => 'Hi chums',
        limited_to => [ $plurk->friends ]
    );

Returns a L<WWW::Plurk::Message> representing the new Plurk.

=cut

sub _is_user {
    my ( $self, $obj ) = @_;
    return UNIVERSAL::can( $obj, 'can' ) && $obj->can( 'uid' );
}

sub _uid_cast {
    my ( $self, $obj ) = @_;
    return $self->_is_user( $obj ) ? $obj->uid : $obj;
}

sub _msg_common {
    my ( $self, $cb, @args ) = @_;

    croak "Needs a number of key => value pairs"
      if @args & 1;
    my %args = @args;

    my $content = delete $args{content} || croak "Must have content";
    my $lang    = delete $args{lang}    || 'en';
    my $qualifier = delete $args{qualifier} || ':';

    my @extras = $cb->( \%args );

    if ( my @unknown = sort keys %args ) {
        croak "Unknown parameter(s): ", join ',', @unknown;
    }

    if ( length $content > MAX_MESSAGE_LENGTH ) {
        croak 'Plurks are limited to '
          . MAX_MESSAGE_LENGTH
          . ' characters';
    }

    return ( $content, $lang, $qualifier, @extras );
}

sub add_plurk {
    my ( $self, @args ) = @_;

    my ( $content, $lang, $qualifier, $no_comments, @limit )
      = $self->_msg_common(
        sub {
            my $args        = shift;
            my $no_comments = delete $args->{no_comments};
            my @limit       = @{ delete $args->{limit} || [] };
            return ( $no_comments, @limit );
        },
        @args
      );

    my $reply = $self->_json_post(
        add_plurk => {
            posted      => localtime()->datetime,
            qualifier   => $qualifier,
            content     => $content,
            lang        => $lang,
            uid         => $self->uid,
            no_comments => ( $no_comments ? 1 : 0 ),
            @limit
            ? ( limited_to => '['
                  . join( ',', map { $self->_uid_cast( $_ ) } @limit )
                  . ']' )
            : (),
        }
    );

    if ( my $error = $reply->{error} ) {
        croak "Error posting: $error";
    }

    return WWW::Plurk::Message->new( $self, $reply->{plurk} );
}

=head2 C<< plurks >>

Get a list of recent Plurks for the logged in user. Returns an array of
L<WWW::Plurk::Message> objects.

    my @plurks = $plurk->plurks;

Any arguments must be passed as key => value pairs. The following
optional arguments are recognised:

=over

=item * uid - the user whose messages we want

=item * date_from - the start date for retrieved messages

=item * date_offset - er, not sure what this does :)

=back

As you may infer from the explanation of C<date_offset>, I'm not
entirely sure how this interface works. I cargo-culted the options from
the PHP version. If anyone can explain C<date_offset> please let me know
and I'll update the documentation.

=cut

sub plurks {
    my ( $self, @args ) = @_;
    croak "Needs a number of key => value pairs"
      if @args & 1;
    my %args = @args;

    my $uid = $self->_uid_cast( delete $args{uid} || $self );

    my $date_from   = delete $args{date_from};
    my $date_offset = delete $args{date_offset};

    if ( my @extra = sort keys %args ) {
        croak "Unknown parameter(s): ", join ',', @extra;
    }

    my $reply = $self->_json_post(
        get_plurks => {
            user_id => $uid,
            defined $date_from
            ? ( from_date => gmtime( $date_from )->datetime )
            : (),
            defined $date_offset
            ? ( offset => gmtime( $date_offset )->datetime )
            : (),
        }
    );

    return
      map { WWW::Plurk::Message->new( $self, $_ ) } @{ $reply || [] };
}

=head2 C<< unread_plurks >>

Return a list of unread Plurks for the current user.

=cut

sub unread_plurks {
    my $self = shift;
    my $reply = $self->_json_post( get_unread_plurks => {} );
    return
      map { WWW::Plurk::Message->new( $self, $_ ) } @{ $reply || [] };
}

# Plurk returns an empty array rather than an empty hash if there
# are no elements. D'you think it's written in PHP? :)
#
# (That's not a dig at PHP, but since arrays and hashes are the same
# thing in PHP I assume the JSON encoder can't tell what an empty
# hash/array is)

sub _want_hash {
    my ( $self, $hash, @keys ) = @_;
    # Replace empty arrays with empty hashes at the top level of a hash.
    for my $key ( @keys ) {
        $hash->{$key} = {}
          if !exists $hash->{$key}
              || ( 'ARRAY' eq ref $hash->{$key}
                  && @{ $hash->{$key} } == 0 );
    }
}

=head2 C<< responses_for >>

Get the responses for a Plurk. Returns a list of
L<WWW::Plurk::Message> objects. Accepts a single argument which is the
numeric ID of the Plurk whose responses we want.

    my @responses = $plurk->responses_for( $msg->plurk_id );

=cut

sub responses_for {
    my ( $self, $plurk_id ) = @_;

    my $reply
      = $self->_json_post( get_responses => { plurk_id => $plurk_id } );

    $self->_want_hash( $reply, 'friends' );

    my %friends = map {
        $_ =>
          WWW::Plurk::Friend->new( $self, $_, $reply->{friends}{$_} )
    } keys %{ $reply->{friends} };

    return map {
        WWW::Plurk::Message->new( $self, $_, $friends{ $_->{user_id} } )
    } @{ $reply->{responses} || [] };
}

=head2 C<< respond_to_plurk >>

Post a response to an existing Plurk. The first argument must be the ID
of the Plurk to respond to. Additional arguments are supplied as a
number of key => value pairs. The following arguments are recognised:

=over

=item * content - the message content

=item * qualifier - the qualifier string ('is', 'says' etc)

=item * lang - the (human) language for this Plurk

=back

See C<add_plurk> for details of how these arguments are interpreted.

    my $responce = $plurk->respond_to_plurk(
        $plurk_id,
        content => 'Nice!'
    );

Returns an L<WWW::Plurk::Message> representing the newly posted
response.

=cut

sub respond_to_plurk {
    my ( $self, $plurk_id, @args ) = @_;

    my ( $content, $lang, $qualifier )
      = $self->_msg_common( sub { () }, @args );

    my $reply = $self->_json_post(
        add_response => {
            posted    => localtime()->datetime,
            qualifier => $qualifier,
            content   => $content,
            lang      => $lang,
            p_uid     => $self->uid,
            plurk_id  => $plurk_id,
            uid       => $self->uid,
        }
    );

    if ( my $error = $reply->{error} ) {
        croak "Error posting: $error";
    }

    return WWW::Plurk::Message->new( $self, $reply->{object} );
}

sub _path_for {
    my ( $self, $service ) = ( shift, shift );
    croak "Unknown service $service"
      unless exists $PATH_DEFAULT{$service};
    return $self->{path}{$service} unless @_;
    return $self->{path}{$service} = shift;
}

sub _uri_for {
    my ( $self, $service ) = ( shift, shift );
    my $uri = $self->_base_uri . $self->_path_for( $service );
    return $uri unless @_;
    my $params = shift;
    return join '?', $uri, HTML::Tiny->new->query_encode( $params );
}

=head2 Accessors

The following accessors are available:

=over

=item * C<< info >> - the user info hash

=item * C<< state >> - the state of this object (init or login)

=item * C<< trace >> - set true to enable HTTP query tracing

=item * C<< display_name >> - the user's display name

=item * C<< full_name >> - the user's full name

=item * C<< gender >> - the user's gender

=item * C<< has_profile_image >> - has a profile image?

=item * C<< id >> - appears to be a synonym for uid

=item * C<< is_channel >> - unknown; anyone know?

=item * C<< karma >> - user's karma score

=item * C<< location >> - user's location

=item * C<< nick_name >> - user's nick name

=item * C<< page_title >> - unknown; anyone know?

=item * C<< relationship >> - married, single, etc

=item * C<< star_reward >> - ???

=item * C<< uid >> - the user's ID

=back

=cut

1;
__END__

=head1 CONFIGURATION AND ENVIRONMENT
  
WWW::Plurk requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-www-plurk@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy.armstrong@messagesystems.com> >>

L<< http://www.plurk.com/user/AndyArmstrong >>

=head1 LICENCE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

Copyright (c) 2008, Message Systems, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or
without modification, are permitted provided that the following
conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in
      the documentation and/or other materials provided with the
      distribution.
    * Neither the name Message Systems, Inc. nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
