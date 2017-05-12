package TiddlyWeb::Resting;

use strict;
use warnings;

use URI::Escape;
use LWP::UserAgent;
use HTTP::Request;
use Class::Field 'field';
use JSON::XS;

use Readonly;

our $VERSION = '0.1';

Readonly my $BASE_URI => '';
Readonly my %ROUTES   => (
    page           => $BASE_URI . '/:type/:ws/tiddlers/:pname',
    pages          => $BASE_URI . '/:type/:ws/tiddlers',
    revisions      => $BASE_URI . '/:type/:ws/pages/:pname/revisions',
    recipe         => $BASE_URI . '/recipes/:ws',
    recipes        => $BASE_URI . '/recipes',
    bag            => $BASE_URI . '/bags/:ws',
    bags           => $BASE_URI . '/bags',
    search         => $BASE_URI . '/search',
);

field 'workspace';
field 'username';
field 'password';
field 'user_cookie';
field 'server';
field 'verbose';
field 'accept';
field 'filter';
field 'count';
field 'order';
field 'query';
field 'etag_cache' => {};
field 'http_header_debug';
field 'response';
field 'json_verbose';
field 'cookie';
field 'agent_string';

sub new {
    my $invocant = shift;
    my $class    = ref($invocant) || $invocant;
    my $self     = {@_};
    #open($self->{log}, ">wiklog"); # handy with debugging
    return bless $self, $class;
}

sub get_page {
    my $self = shift;
    my $pname = shift;
    my $paccept;

    if (ref $pname){
	$paccept = $pname->{accept};
    }
    else {
	$paccept = $self->accept;
    }

    $pname = name_to_id($pname);
    my $accept = $paccept || 'text/plain';

    my $workspace = $self->workspace;
    my $uri = $self->_make_uri(
        'page',
        { pname => $pname, ws => $workspace }
    );
    $uri .= '?verbose=1' if $self->json_verbose;

    $accept = 'application/json' if $accept eq 'perl_hash';
    my ( $status, $content, $response ) = $self->_request(
        uri    => $uri,
        method => 'GET',
        accept => $accept,
    );

    if ( $status == 200 || $status == 404 ) {
        $self->{etag_cache}{$workspace}{$pname} = $response->header('etag');
        if (($self->accept || '') eq 'perl_hash') {
            if ($status == 200) {
                return decode_json($content);
            } else {
                # send an empty page
                return +{
                    text => 'Not found',
                    tags => [],
                    modifier => '',
                    modified => '',
                    bag => '',
                };
            }
        }
        return $content;
    }
    else {
        die "$status: $content\n";
    }
}

sub put_page {
    my $self         = shift;
    my $pname        = shift;
    my $page_content = shift;

    my $bag;
    my $type = 'text/plain';
    if ( ref $page_content ) {
        $type         = 'application/json';
        my $dict = {
            'text' => $page_content->{text},
            'tags' => $page_content->{tags},
            'fields' => $page_content->{fields},
        };
        $bag = $page_content->{bag};
        $page_content = encode_json($dict);
    }

    my $workspace = $self->workspace;
    my $uri;
    if ($bag) {
        $uri = $self->_make_uri(
            'page',
            { pname => $pname, ws => $bag, type => 'bags' }
        );
    } else {
        $uri = $self->_make_uri(
            'page',
            { pname => $pname, ws => $workspace }
        );
    }

    my %extra_opts;
    my $page_id = name_to_id($pname);
    if ($bag) {
        if (my $prev_etag = $self->{etag_cache}{"bag:$bag"}{$page_id}) {
            $extra_opts{if_match} = $prev_etag;
        }
    } elsif (my $prev_etag = $self->{etag_cache}{"recipe:$workspace"}{$page_id}) {
        $extra_opts{if_match} = $prev_etag;
    }

    my ( $status, $content ) = $self->_request(
        uri     => $uri,
        method  => 'PUT',
        type    => $type,
        content => $page_content,
        %extra_opts,
    );

    if ( $status == 204 || $status == 201 ) {
        return $content;
    }
    else {
        die "$status: $content\n";
    }
}

sub _name_to_id { name_to_id(@_) }
sub name_to_id { return shift; }

sub _make_uri {
    my $self         = shift;
    my $thing        = shift;
    my $replacements = shift;

    unless ($replacements->{type}) {
        $replacements->{type} = 'recipes';
    }

    my $uri = $ROUTES{$thing};

    # REVIEW: tried to do this in on /g go but had issues where
    # syntax errors were happening...
    foreach my $stub ( keys(%$replacements) ) {
        my $replacement
            = URI::Escape::uri_escape_utf8( $replacements->{$stub} );
        $uri =~ s{/:$stub\b}{/$replacement};
    }

    return $uri;
}

sub get_pages {
    my $self = shift;

    return $self->_get_things('pages');
}


sub get_revisions {
    my $self = shift;
    my $pname = shift;

    return $self->_get_things( 'revisions', pname => $pname );
}

sub get_search {
    my $self = shift;

    return $self->_get_things( 'search' );
}

sub _extend_uri {
    my $self = shift;
    my $uri = shift;
    my @extend;

    if ( $self->filter ) {
        push (@extend, "select=" . $self->filter);
    }
    if ( $self->query ) {
        push (@extend, "q=" . $self->query);
    }
    if ( $self->order ) {
        push (@extend, "sort=" . $self->order);
    }
    if ( $self->count ) {
        push (@extend, "limit=" . $self->count);
    }
    if (@extend) {
        $uri .= "?" . join(';', @extend);
    }
    return $uri;

}

sub _get_things {
    my $self         = shift;
    my $things       = shift;
    my %replacements = @_;
    my $accept = $self->accept || 'text/plain';

    my $uri = $self->_make_uri(
        $things,
        { ws => $self->workspace, %replacements }
    );
    $uri = $self->_extend_uri($uri);

    # Add query parameters from a
    if ( exists $replacements{_query} ) {
        my @params;
        for my $q ( keys %{ $replacements{_query} } ) {
            push @params, "$q=" . $replacements{_query}->{$q};
        }
        if (my $query = join( ';', @params )) {
            if ( $uri =~ /\?/ ) {
                $uri .= ";$query";
            }
            else {
                $uri .= "?$query";
            }
        }
    }

    $accept = 'application/json' if $accept eq 'perl_hash';
    my ( $status, $content ) = $self->_request(
        uri    => $uri,
        method => 'GET',
        accept => $accept,
    );

    if ( $status == 200 and wantarray ) {
        return ( grep defined, ( split "\n", $content ) );
    }
    elsif ( $status == 200 ) {
        return decode_json($content) 
            if (($self->accept || '') eq 'perl_hash');
        return $content;
    }
    elsif ( $status == 404 ) {
        return ();
    }
    elsif ( $status == 302 ) {
        return $self->response->header('Location');
    }
    else {
        die "$status: $content\n";
    }
}

sub get_workspace {
    my $self = shift;
    my $wksp = shift;

    my $prev_wksp = $self->workspace();
    $self->workspace($wksp) if $wksp;
    my $result = $self->_get_things('workspace');
    $self->workspace($prev_wksp) if $wksp;
    return $result;
}

sub get_workspaces {
    my $self = shift;

    return $self->_get_things('workspaces');
}

sub _request {
    my $self = shift;
    my %p    = @_;
    my $ua   = LWP::UserAgent->new(agent => $self->agent_string);
    my $server = $self->server;
    die "No server defined!\n" unless $server;
    $server =~ s/\/$//;
    my $uri  = "$server$p{uri}";
    warn "uri: $uri\n" if $self->verbose;

    my $request = HTTP::Request->new( $p{method}, $uri );
    if ( $self->user_cookie ) {
        $request->header( 'Cookie' => 'tiddlyweb_user=' . $self->user_cookie );
    } else {
        $request->authorization_basic( $self->username, $self->password );
    }
    $request->header( 'Accept'       => $p{accept} )   if $p{accept};
    $request->header( 'Content-Type' => $p{type} )     if $p{type};
    $request->header( 'If-Match'     => $p{if_match} ) if $p{if_match};
    if ($p{method} eq 'PUT') {
        my $content_len = 0;
        $content_len = do { use bytes; length $p{content} } if $p{content};
        $request->header( 'Content-Length' => $content_len );
    }

    if (my $cookie = $self->cookie) {
        $request->header('cookie' => $cookie);
    }
    $request->content( $p{content} ) if $p{content};
    $self->response( $ua->simple_request($request) );

    if ( $self->http_header_debug ) {
        use Data::Dumper;
        warn "Code: "
            . $self->response->code . "\n"
            . Dumper $self->response->headers;
    }

    # We should refactor to not return these response things
    return ( $self->response->code, $self->response->content,
        $self->response );
}

=head1 NAME

TiddlyWeb::Resting - module for accessing TiddlyWeb HTTP API

=head1 SYNOPSIS

  use TiddlyWeb::Resting;
  my $Rester = TiddlyWeb::Resting->new(
    username => $opts{username},
    password => $opts{password},
    server   => $opts{server},
  );
  $Rester->workspace('wikiname');
  $Rester->get_page('my_page');
}

=head1 DESCRIPTION

C<TiddlyWeb::Resting> is a module designed to allow remote access
to the TiddlyWeb API for use in Perl programs. It is a work in
progress, adapting C<Socialtext::Resting>. It maintains the
terms, from Socialtext, of workspace and page, which are translated
to recipe and tiddler.

=head1 METHODS

=head2 new

    my $Rester = TiddlyWeb::Resting->new(
        username => $opts{username},
        password => $opts{password},
        server   => $opts{server},
    );

    or

    my $Rester = TiddlyWeb::Resting->new(
        user_cookie => $opts{user_cookie},
        server      => $opts{server},
    );

Creates a TiddlyWeb::Resting object for the specified
server/user/password, or server/cookie combination.

=head2 accept

    $Rester->accept($mime_type);

Sets the HTTP Accept header to ask the server for a specific
representation in future requests.

Common representations:

=over 4

=item text/plain

=item text/html

=item application/json

=item text/x-tiddlywiki

=back

=head2 get_page

    $Rester->workspace('wikiname');
    $Rester->get_page('page_name');

Retrieves the content of the specified page.  Note that
the workspace method needs to be called first to specify
which workspace to operate on.

=head2 put_page

    $Rester->workspace('wikiname');
    $Rester->put_page('page_name',$content);

Save the content as a page in the wiki.  $content can either be a string,
which is treated as wikitext, or a hash with the following keys:

=over

=item text

A string which is the page's wiki content or a hash of content
plus other stuff.

=item tags

A list of tags.

=item fields

A hash of arbitrary key value pairs.

=back

=head2 get_pages

    $Rester->workspace('wikiname');
    $Rester->get_pages();

List all pages in the wiki.

=head2 get_revisions

    $Rester->get_revisions($page)

List all the revisions of a page.

=head2 get_workspace

    $Rester->get_workspace();

Return the metadata about a particular workspace.

=head2 get_workspaces

    $Rester->get_workspaces();

List all workspaces on the server

=head2 response

    my $resp = $Rester->response;

Return the HTTP::Response object from the last request.

=head1 AUTHORS / MAINTAINERS

Chris Dent C<< <cdent@peermore.com> >>

Based on work by:

Luke Closs C<< <luke.closs@socialtext.com> >>

Shawn Devlin C<< <shawn.devlin@socialtext.com> >>

Jeremy Stashewsky C<< <jeremy.stashewsky@socialtext.com> >>

=head2 CONTRIBUTORS

Chris Dent

Kirsten Jones

Michele Berg - get_revisions()

=cut

1;
