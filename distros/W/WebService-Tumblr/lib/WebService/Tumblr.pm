package WebService::Tumblr;
BEGIN {
  $WebService::Tumblr::VERSION = '0.0010';
}
# ABSTRACT: A Perl interface to the Tumblr web API


use strict;
use warnings;

use Any::Moose;
use LWP::UserAgent;
use HTTP::Request::Common();
use URI::PathAbstract;
use JSON;
our $json = JSON->new->pretty;
sub json { $json }

use WebService::Tumblr::Dispatch;
use WebService::Tumblr::Result;

use constant TUMBLR_URL => 'http://www.tumblr.com';

sub empty ($) {
    return not defined $_[0] && length $_[0];
}

sub hash_refactor {
    my %arguments = @_;
    my ( $hash, $key0, $else, $delete, $exclusive, $exists ) = @arguments{qw/ hash key else delete exclusive exists /};

    # FIXME Return value of key0
    return unless defined $else;
    $else = [ $else ] unless ref $else eq 'ARRAY';

    my @found;
    for my $key ( $key0, @$else ) {
        if ( $exists ) {
            if ( $exists eq 'empty' )   { push @found, $key if ! empty $hash->{ $key } }
            else                        { push @found, $key if exists $hash->{ $key } }
        }
        else                            { push @found, $key if $hash->{ $key } }
    }

    return unless @found;

    my $has;
    if ( @found and $found[ 0 ] eq $key0 ) {
        $has = 1;
        shift @found;
    }

    my $value;
    if ( $exclusive ) {
        if ( $has && @found ) {
            die "Exclusivity violated: $key0 @found"; 
        }

        if ( @found > 1 ) {
            die "Exclusivity violated: @found"; 
        }
    }

    if ( $has ) {
        if ( $delete ) {
            delete $hash->{ $_ } for @found;
        }
        return $hash->{ $key0 };
    }
    else {
        my $value = $hash->{ $found[0] };
        if ( $delete ) {
            delete $hash->{ $_ } for @found;
        }
        return $hash->{ $key0 } = $value;
    }
}

sub _urlify ($) {
    my $given = shift;

    return if empty $given;

    if ( $given !~ m/\./ ) {
        $given = "$given.tumblr.com";
    }
    if ( $given !~ m/^[A-Za-z0-9]+:\/\// ) {
        $given = "http://$given";
    }

    return $given;
}

sub _url_from ($) {
    my $self = shift;
    my $given = shift;

    my ( $url, $blog ) = delete @$given{qw/ url blog /};

    return _urlify $url unless empty $url; 
    return _urlify $blog unless empty $blog; 
    return;
}

sub _extract ($@) {
    my $self = shift;
    my $given = shift;

    my %return;
    for ( @_ ) {
        $return{ $_ } = delete $given->{ $_ } if exists $given->{ $_ };
    }

    return \%return;
}

sub BUILD {
    my $self = shift;
    my $given = shift;

    die "*** Two or more of: name, blog, url" if 1 < grep { ! empty $given->{ $_ } } qw/ name blog url /;
    ! empty $given->{ $_ } and $self->url( $given->{ $_ } ) for qw/ name blog /;
}

has secure => qw/ is rw default 1 /;

has agent => qw/ is ro lazy_build 1 /;
sub _build_agent {
    my $agent = LWP::UserAgent->new;
    return $agent;
}

has [qw/ email password /] => qw/ is rw /;

has _name => qw/ is rw /;
has url => qw/ is rw /, trigger => sub {
    my ( $self, $value ) = @_;
    my $url = _urlify $value;
    if ( empty $url ) {
        $self->_name( undef );
        return undef;
    }
    my $uri = URI->new( $url );
    my $host = $uri->host;
    if ( $host =~ m/^([^\.]+)\.tumblr.com$/ )   { $self->_name( $1 ) }
    else                                        { $self->_name( $host ) }
    $self->{ url } = $url; # FIXME This is a hack, do this better
};

sub name {
    my $self = shift;
    return $self->_name unless @_;
    $self->url( @_ );
}

sub blog { return shift->name( @_ ) }

sub _url {
    my $self = shift;
    my $url = $self->url;
    die "*** Missing url" unless $self->url;
    return _urlify $url;
}

sub identity {
    my $self = shift;
    if ( @_ ) {
        my ( $email, $password ) = @_;
        $self->email( $email );
        $self->password( $password );
    }
    else {
        return ( $self->email, $self->password );
    }
}

sub new_dispatch {
    my $self = shift;
    return WebService::Tumblr::Dispatch->new( tumblr => $self, @_ );
}

sub dispatch {
    my $self = shift;
    my $arguments = shift;
    my %options = @_;

    my $base = TUMBLR_URL;
    $base = URI->new( $base );
    $base->scheme( 'https' ) if $self->secure;

    if ( $options{ url } ) {
        $base = $self->_url_from( $arguments );
        $base ||= $self->_url;
    }
    my $url = URI::PathAbstract->new( $base, path => $options{ path } );
    my $query = $self->_extract( $arguments, @{ $options{ passthrough } || [] } );
    my $dispatch = $self->new_dispatch( method => 'GET', url => $url, query => $query );
    $dispatch->authenticate if $options{ authenticate };

    return $dispatch;
}

sub write {
    my $self = shift;
    my %arguments = @_;

    my $dispatch = $self->dispatch( \%arguments,
        path => 'api/write',
        passthrough => [qw/
            email password type generator date private tags format group slug state send-to-twitter
            post-id
            title body 
            source data caption click-through-url
            quote source 
            name url description
            title conversation
            embed data title caption
            data externally-hosted-url caption
        /],
        authenticate => 1,
    );

    return $dispatch;
}

sub edit {
    my $self = shift;
    my %arguments = @_;

    die "*** Missing post-id" unless $arguments{ 'post-id' };

    return $self->write( @_ );
}

sub delete {
    my $self = shift;
    my %arguments = @_;

    my $dispatch = $self->dispatch( \%arguments,
        path => 'api/delete',
        passthrough => [qw/ email password post-id /],
        authenticate => 1,
    );

    return $dispatch;
}

sub reblog {
    my $self = shift;
    my %arguments = @_;

    my $dispatch = $self->dispatch( \%arguments,
        path => 'api/delete',
        passthrough => [qw/ email password post-id reblog-key comment as /],
        authenticate => 1,
    );

    return $dispatch;
}

sub pages {
    my $self = shift;
    my %arguments = @_;

    my $dispatch = $self->dispatch( \%arguments,
        url => 1,
        path => 'api/pages',
        passthrough => [qw/ email password /],
    );
    $dispatch->authenticate if $arguments{ all } || $dispatch->query->{ state };

    return $dispatch;
}

sub posts {
    my $self = shift;
    my %arguments = @_;

    my $dispatch = $self->dispatch( \%arguments,
        url => 1,
        path => 'api/read',
        passthrough => [qw/ email password start num type id filter tagged chrono search state /],
    );
    $dispatch->authenticate if $arguments{ all } || $dispatch->query->{ state };

    return $dispatch;
}

sub read {
    my $self = shift;

    return $self->posts( @_ );
}

sub dashboard {
    my $self = shift;
    my %arguments = @_;

    my $dispatch = $self->dispatch( \%arguments,
        path => 'api/dashboard',
        passthrough => [qw/ email password start num filter likes /],
        authenticate => 1,
    );

    return $dispatch;
}

sub likes {
    my $self = shift;
    my %arguments = @_;

    my $dispatch = $self->dispatch( \%arguments,
        path => 'api/dashboard',
        passthrough => [qw/ email password start num filter /],
        authenticate => 1,
    );

    return $dispatch;
}

sub like {
    my $self = shift;
    my %arguments = @_;

    my $dispatch = $self->dispatch( \%arguments,
        path => 'api/like',
        passthrough => [qw/ email password post-id reblog-key /],
        authenticate => 1,
    );

    return $dispatch;
}

sub authenticate {
    my $self = shift;
    my %arguments = @_;

    my $dispatch = $self->dispatch( \%arguments,
        path => 'api/authenticate',
        passthrough => [qw/ email password include-theme /],
        authenticate => 1,
    );

    return $dispatch;
}

1;

__END__
=pod

=head1 NAME

WebService::Tumblr - A Perl interface to the Tumblr web API

=head1 VERSION

version 0.0010

=head1 SYNOPSIS

    use WebService::Tumblr;

    # Interact with the Tumblr blog at http://example.tumblr.com
    my $tumblr = WebService::Tumblr->new(
        name => 'example', email => 'alice@example.com', password => 'hunter2'
    );

    # Make a post
    my $dispatch = $tumblr->write(
       type => 'regular',
       format => 'markdown',
       body => ...
       date => ...
       generator => ...
       state => ... # 'draft' or 'published'
    );
    if ( $dispatch->is_success ) {
        my $post_id = $dispatch->content; # Shortcut for $dispatch->response->decoded_content;
    }

    # Making a post, part II: Electric Boogaloo
    my $post_id = $tumblr->write( ... )->submit;

    # Editing a post (will die unless post-id is given)
    $tumblr->edit( 'post-id' => $post_id, ... )->submit;

=head1 DESCRIPTION

WebService::Tumblr is a L<LWP::UserAgent>-based interface for accessing the Tumblr API

=head1 USAGE

=head2 $tumblr = WebService::Tumblr->new( name => ..., email => ..., password => ... )

Returns a new Tumblr API agent configured for the Tumblr blog at C<(name).tumblr.com>

    name            The name (hostname) of the blog to interface with

    email           The e-mail & password of the account that owns the given blog
    password

=head2 $dispatch = $tumblr->write( ... )

    $post_id = $tumblr->write( ... )->content; # Will throw an exception if post fails (HTTP post is unsuccessful)

Create a new post or update an existing post (if given post-id)

    type                The post type, can be one of the following
                        * regular
                        * photo
                        * quote
                        * link
                        * conversation
                        * video
                        * audio

                        See below about the additional parameters associated with each type

    date (optional)     The post date, if different from now, in the blog's timezone
                        Most unambiguous formats are accepted, such as '2007-12-01 14:50:02'
                        Dates may not be in the future

    private (optional)  1 or 0 (Whether the post is private)
                        Private posts only appear in the dashboard or with authenticated links, and do not appear on the blog's main page

    tags (optional)     Comma-separated list of post tags
                        You may optionally enclose tags in double-quotes

    format (optional)   'html' or 'markdown'

    group (optional)    Post this to a secondary blog on your account, e.g. mygroup.tumblr.com (for public groups only)

    slug (optional)     A custom string to appear in the post's URL: myblog.tumblr.com/post/123456/this-string-right-here
                        URL-friendly formatting will be applied automatically
                        Maximum of 55 characters

    state (optional)    One of the following values:
                        * published (default)
                        * draft - Save in the drafts folder for later publishing
                        * submission - Add to the messages folder for consideration
                        * queue - Add to the queue for automatic publishing in a few minutes or hours
                          To publish at a specific time in the future instead, specify an additional publish-on parameter
                          with the date expression in the local time of the blog (e.g. publish-on=2010-01-01T13:34:00)
                          If the date format cannot be understood, a 401 error will be returned and the post will not be created

                        To change the state of an existing post, such as to switch from draft to published,
                        follow the editing process and pass the new value as the state parameter

                        Note: If a post has previously been saved as a draft, queue, or submission post,
                        it will be assigned a new post ID the first time it enters the published state.

Depending on the kind of post (type), additional parameters will be necessary:

    regular             Requires at least one:
                        * title
                        * body (HTML or Markdown, depending on 'format')

    photo               Requires either source or data, but not both. If both are specified, source is used.
                        * source - The URL of the photo to copy. This must be a web-accessible URL, not a local file or intranet location.
                        * data - An image file. See File uploads below.
                        * caption (optional, HTML allowed)
                        * click-through-url (optional)

    quote               *  quote
                        *  source (optional, HTML allowed)

    link                * name (optional)
                        * url
                        * description (optional, HTML allowed)

    conversation        * title (optional)
                        * conversation

    video               Requires either embed or data, but not both.
                        * embed - Either the complete HTML code to embed the video, or the URL of a YouTube video page.
                        * data - A video file for a Vimeo upload. See File uploads below.
                        * title (optional) - Only applies to Vimeo uploads.
                        * caption (optional, HTML allowed)

    audio               * data - An audio file. Must be MP3 or AIFF format. See File uploads below.
                        * externally-hosted-url (optional, replaces data) - Create a post that uses this
                        externally hosted audio-file URL instead of having Tumblr copy and host an uploaded file.
                        Must be MP3 format. No size or duration limits are imposed on externally hosted files.
                        * caption (optional, HTML allowed)

=head1 SEE ALSO

L<WWW::Tumblr>

=head1 AUTHOR

Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

