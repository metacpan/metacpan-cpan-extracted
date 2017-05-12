package WWW::PGXN;

use 5.010;
use strict;
use WWW::PGXN::Distribution;
use WWW::PGXN::Extension;
use WWW::PGXN::User;
use WWW::PGXN::Tag;
use WWW::PGXN::Mirror;
use HTTP::Tiny;
use URI::Template;
use JSON ();
use Carp;

our $VERSION = v0.12.4;

sub new {
    my($class, %params) = @_;
    my $self = bless {} => $class;
    for my $key (qw(url proxy)) {
        $self->$key($params{$key}) if exists $params{$key}
    }
    return $self;
}

sub get_distribution {
    my ($self, $dist, $version) = @_;
    my $data = $self->_fetch_json(
        (defined $version ? 'meta' : 'dist'),
        { dist => lc $dist, version => lc($version || '') }
    ) or return;
    WWW::PGXN::Distribution->new($self, $data);
}

sub get_extension {
    my ($self, $ext) = @_;
    my $data = $self->_fetch_json(extension => { extension => lc $ext })
        or return;
    WWW::PGXN::Extension->new($self, $data);
}

sub get_user {
    my ($self, $user) = @_;
    my $data = $self->_fetch_json(user => { user => lc $user }) or return;
    WWW::PGXN::User->new($data);
}

sub get_tag {
    my ($self, $tag) = @_;
    my $data = $self->_fetch_json(tag => { tag => lc $tag }) or return;
    WWW::PGXN::Tag->new($data);
}

sub get_stats {
    my ($self, $name) = @_;
    my $data = $self->_fetch_json(stats => { stats => lc $name }) or return;
}

sub get_userlist {
    my ($self, $letter) = @_;
    return undef unless $self->_uri_templates->{userlist};
    return $self->_fetch_json(userlist => { letter => lc $letter }) || [];
}

my %valid_in = ( map { $_ => undef } qw(docs dists extensions users tags));

sub search {
    my ($self, %params) = @_;
    my $url = $self->url;
    my $in  = delete $params{in}
        or croak 'Missing required "in" parameter to search()';

    croak qq{Invalid "in" parameter to search(); Must be one of:\n}
        . join("\n", map { "* $_" } sort keys %valid_in)
        unless exists $valid_in{$in};

    if ($url->scheme eq 'file') {
        # Fetch it via PGXN::API::Searcher.
        my $searcher = $self->{_searcher} ||= PGXN::API::Searcher->new(
            File::Spec->catdir($url->path_segments)
        );
        return $searcher->search(in => $in, %params);
    }

    my $qurl = $self->_url_for(search => { in => $in });
    $qurl->query_form({
        map { substr($_, 0, 1) => $params{$_} } keys %params
    });
    my $res = $self->_fetch($qurl) or return;
    return JSON->new->utf8->decode($res->{content});
}

sub mirrors {
    my $self = shift;
    return @{ $self->{mirrors} ||= do {
        my $mirrors = $self->_fetch_json('mirrors');
        [ map { WWW::PGXN::Mirror->new($_) } @{ $mirrors } ];
    } };
}

sub spec {
    my ($self, $format) = @_;
    $format ||= 'txt';
    my $res = $self->_fetch(
        $self->_url_for('spec' => { format => $format })
    ) or return;
    utf8::decode $res->{content};
    return $res->{content};
}

sub url {
    my $self = shift;
    return $self->{url} unless @_;
    (my $url = shift) =~ s{/+$}{}g;
    $self->{url} = URI->new($url);
    require PGXN::API::Searcher if $self->{url}->scheme eq 'file';
    delete $self->{_req};
    delete $self->{_searcher};
    $self->{url};
}

sub proxy {
    my $self = shift;
    return $self->{proxy} unless @_;
    $self->{proxy} = shift;
}

BEGIN {
    for my $thing (qw(meta download source)) {
        no strict 'refs';
        *{"$thing\_url_for"} = sub {
            $_[0]->_url_for( $thing => { dist => lc $_[1], version => lc $_[2] });
        };
        *{"$thing\_path_for"} = sub {
            $_[0]->_path_for( $thing => { dist => lc $_[1], version => lc $_[2] });
        };
    }

    for my $thing (qw(tag extension user)) {
        no strict 'refs';
        *{"$thing\_url_for"} = sub {
            $_[0]->_url_for( $thing => { $thing => lc $_[1] });
        };
        *{"$thing\_path_for"} = sub {
            $_[0]->_path_for( $thing => { $thing => lc $_[1] });
        };
    }
}

sub html_doc_path_for {
    my ($self, $dist, $version, $path) = @_;
    $self->_path_for(htmldoc => {
        dist    => lc $dist,
        version => lc $version,
        docpath => $path,
    });
}

sub html_doc_url_for {
    my $self = shift;
    return URI->new($self->url . $self->html_doc_path_for(@_));
}

sub _uri_templates {
    my $self = shift;
    return $self->{uri_templates} ||= { do {
        my $req = $self->_request;
        my $url = URI->new($self->url . '/index.json');
        my $res = $req->get($url);
        croak "Request for $url failed: $res->{status}: $res->{reason}\n"
            unless $res->{success};
        my $tmpl = JSON->new->utf8->decode($res->{content});
        map { $_ => URI::Template->new($tmpl->{$_}) } keys %{ $tmpl };
    }};
}

sub _path_for {
    my ($self, $name, $vars) = @_;
    my $tmpl = $self->_uri_templates->{$name}
        or croak qq{No URI template named "$name"};
    return $tmpl->process($vars);
}

sub _url_for {
    my $self = shift;
    return URI->new($self->url . $self->_path_for(@_));
}

sub _request {
    my $self = shift;
    $self->{_req} ||= $self->url =~ m{^file:} ? WWW::PGXN::FileReq->new : HTTP::Tiny->new(
        agent => __PACKAGE__ . '/' . __PACKAGE__->VERSION,
        proxy => $self->proxy,
    );
}

sub _fetch {
    my ($self, $url) = @_;
    my $res = $self->_request->get($url);
    return $res if $res->{success};
    return if $res->{status} == 404;
    croak "Request for $url failed: $res->{status}: $res->{reason}\n";
}

sub _fetch_json {
    my $self = shift;
    my $res = $self->_fetch($self->_url_for(@_)) or return;
    return JSON->new->utf8->decode($res->{content});
}

sub _download_to {
    my ($self, $file) = (shift, shift);
    my $url = $self->_url_for(download => @_);
    my $res = $self->_fetch($url);
    if (-e $file) {
        if (-d $file) {
            my @seg = $url->path_segments;
            $file = File::Spec->catfile($file, $seg[-1]);
        } else {
            croak "$file already exists";
        }
    }

    open my $fh, '>:raw', $file or die "Cannot open $file: $!\n";
    print $fh $res->{content};
    close $fh or die "Cannot close $file: $!\n";
    return $file;
}

package
WWW::PGXN::FileReq;

use strict;
use URI::file ();
use File::Spec ();
use URI::Escape ();

sub new {
    bless {} => shift;
}

sub get {
    my $self = shift;
    my $file = File::Spec->catfile(shift->path_segments);

    return {
        success => 0,
        status  => 404,
        reason  => 'not found',
        headers => {},
    } unless -e $file;

    open my $fh, '<:raw', $file or return {
        success => 0,
        status  => 500,
        reason  => $!,
        headers => {},
    };

    local $/;
    return {
        success => 1,
        status  => 200,
        reason  => 'OK',
        content => <$fh> || undef,
        headers => {},
    };
}

1;
__END__

=head1 Name

WWW::PGXN - Interface to PGXN mirrors and the PGXN API

=head1 Synopsis

  my $pgxn = WWW::PGXN->new( url => 'http://api.pgxn.org/' );
  my $dist = $pgxn->get_distribution('pgTAP');
  $dist->download_to('.');

=head1 Description

This module provide a simple Perl interface over the the L<PGXN
API|http://github.com/pgxn/pgxn-api/wiki>. It also works with any PGXN mirror
server. It provides an interface for finding distributions, extensions, users,
and tags, as well as for accessing documentation, lists of users, and the
full-text search interface. WWW::PGXN is designed to make it dead simple for
applications such as web apps and command-line clients to get the data they
need from a PGXN mirror with a minimum of hassle, including via the file
system, if there is a local mirror.

L<PGXN|http://pgxn.org> is a L<CPAN|http://cpan.org>-inspired network for
distributing extensions for the L<PostgreSQL RDBMS|http://www.postgresql.org>.
All of the infrastructure tools, however, have been designed to be used to
create networks for distributing any kind of release distributions and for
providing a lightweight static file JSON REST API. As such, WWW::PGXN should
work with any mirror that gets its data from a
L<PGXN::Manager|http://github.com/theory/pgxn-manager>-managed master server,
and with any L<PGXN::API>-powered server.

=head1 Interface

=head2 Constructor

=head3 C<new>

  my $pgxn = WWW::PGXN->new(url => 'http://api.pgxn.org/');

Construct a new WWW::PGXN object. The only required attribute is C<url>. The
supported parameters are:

=over

=item C<url>

The base URL for the API server or mirror the client should fetch from.
Required.

=item C<proxy>

URL of a proxy server to use. Ignored if C<url> is a C<file:> URL.

=back

=head2 Instance Accessors

=head3 C<url>

  my $url = $pgxn->url;
  $pgxn->url($url);

Get or set the URL for the PGXN mirror or API server. May be a C<file:> URL,
in which case the API will be accessed purely via the file system. Otherwise
it uses L<HTTP::Tiny> to access the API.

=head3 C<proxy>

  my $proxy = $pgxn->proxy;
  $pgxn->proxy($proxy);

Get or set the URL for a proxy server to use. Ignored if C<url> is a C<file:>
URL.

=head2 Instance Methods

=head3 C<get_distribution>

  my $dist = $pgxn->get_distribution($dist_name, $version);

Finds the data for a distribution. Returns a L<WWW::PGXN::Distribution>
object. The first argument, the name of the distribution, is required. The
second argument, the version, is optional. If not present, the current stable
release will be retrieved.

If the distribution cannot be found, C<undef> will be returned. For any other
errors, an exception will be thrown.

=head3 C<get_extension>

  my $extension = $pgxn->get_extension($extension_name);

Finds the data for the named extension. Returns a L<WWW::PGXN::Extension>
object. If the extension cannot be found, C<undef> will be returned. For any
other errors, an exception will be thrown.

=head3 C<get_user>

  my $user = $pgxn->get_user($user_name);

Finds the data for the named user. Returns a L<WWW::PGXN::User> object. If the
user cannot be found, C<undef> will be returned. For any other errors, an
exception will be thrown.

=head3 C<get_tag>

  my $tag = $pgxn->get_tag($tag_name);

Finds the data for the named tag. Returns a L<WWW::PGXN::Tag> object. If the
tag cannot be found, C<undef> will be returned. For any other errors, an
exception will be thrown.

=head3 C<get_stats>

  my $stats = $pgxn->get_stats($stats_name);

Returns the contents of a stats file. The current stats names are:

=over

=item * C<summary>

=item * C<dist>

=item * C<extension>

=item * C<user>

=item * C<tag>

=back

=head3 C<get_userlist>

  my $userlist = $pgxn->get_userlist('t');

Returns a the contents of a user list, which contains data on all users whose
nickname starts with the specified lowercase ASCII letter. If called against a
mirror, this method always returns C<undef>. When called against an API, it
will always return an array of users. If there is no user list file for the
specified letter, the array will be empty. Otherwise, it will contain a list
of hash references with two keys:

=over

=item * C<user>

The user's nickname.

=item * C<name>

The user's full name.

=back

=head3 C<mirrors>

  my @mirrors = $pgxn->mirrors;

Returns a list of L<WWW::PGXN::Mirror> objects representing all of the mirrors
in the network to which the PGXN API or mirror server belongs.

=head3 C<spec>

  my $spec = $pgxn->spec;
  my $html = $pgxn->spec('html');

Returns the contents of the PGXN Meta Spec document. By default, this is a
text document. But you can get an HTML version by passing C<HTML> as the
argument. Pass C<txt> to be specific about wanting the text document.

=head3 C<search>

  my $results = $pgxn->search( query => 'tap' );
  $results    = $pgxn->search( query => 'wicked', index => 'dists' );

Sends a search query to the API server (not supported for mirrors). For an API
server accessed via a C<file:> URL, L<PGXN::API::Searcher> is required and
used to fetch the results directly. Otherwise, an HTTP request is sent to the
server as usual.

The supported parameters are:

=over

=item query

The search query. See L<Lucy::Search::QueryParser> for the supported syntax of
the query. Required.

=item index

The name of the search index to query. The default is "docs". The possible
values are:

=over

=item docs

=item dists

=item extensions

=item users

=item tags

=back

=item offset

How many hits to skip before showing results. Defaults to 0.

=item limit

Maximum number of hits to return. Defaults to 50 and may not be greater than
1024.

=back

Currently the return value is a hash composed directly from the JSON returned
by the search request. See L<PGXN::API::Searcher> for details on its
structure.

=head3 C<meta_url_for>

  my $meta_url = $pgxn->meta_url_for($dist_name, $dist_version);

Returns the URL for a distribution meta file. This is the file fetched by
C<get_distribution()>.

=head3 C<download_url_for>

  my $download_url = $pgxn->download_url_for($dist_name, $dist_version);

Returns the download URL for a distribution and version. This is the zipped
archive file containing the distribution itself.

=head3 C<source_url_for>

  my $source_url = $pgxn->source_url_for($dist_name, $dist_version);

Returns the URL for a distribution source file. This URL is available only
from an API server, not a mirror.

=head3 C<html_doc_url_for>

  my $doc_url = $pgxn->html_doc_url_for($dist_name, $dist_version, $doc_path);

Returns the URL for a distribution documentation file. This URL is available
only from an API server, not a mirror.

=head3 C<extension_url_for>

  my $extension_url = $pgxn->extension_url_for($extension_name);

Returns the URL for an extension metadata file. This is the file fetched by
C<get_extension()>.

=head3 C<user_url_for>

  my $user_url = $pgxn->user_url_for($nickname);

Returns the URL for an user metadata file. This is the file fetched by
C<get_user()>.

=head3 C<tag_url_for>

  my $tag_url = $pgxn->tag_url_for($tag_name);

Returns the URL for an tag metadata file. This is the file fetched by
C<get_tag()>.

=head3 C<meta_path_for>

  my $meta_path = $pgxn->meta_path_for($dist_name, $dist_version);

Returns the path for a distribution meta file.

=head3 C<download_path_for>

  my $download_path = $pgxn->download_path_for($dist_name, $dist_version);

Returns the download path for a distribution and version.

=head3 C<source_path_for>

  my $source_path = $pgxn->source_path_for($dist_name, $dist_version);

Returns the path for a distribution source file. This path is available only
from an API server, not a mirror.

=head3 C<html_doc_path_for>

  my $doc_path = $pgxn->html_doc_path_for($dist_name, $dist_version, $doc_path);

Returns the PATH for a distribution documentation file. This PATH is available
only from an API server, not a mirror.

=head3 C<extension_path_for>

  my $extension_path = $pgxn->extension_path_for($extension_name);

Returns the path for an extension metadata file.

=head3 C<user_path_for>

  my $user_path = $pgxn->user_path_for($nickname);

Returns the path for an user metadata file.

=head3 C<tag_path_for>

  my $tag_path = $pgxn->tag_path_for($tag_name);

Returns the path for an tag metadata file.

=head1 See Also

=over

=item * L<PGXN|http://pgxn.org/>

The PostgreSQL Extension Network, the reference implementation of the PGXN
infrastructure.

=item * L<PGXN::API>

Creates and serves a PGXN API implementation from a PGXN mirror.

=item * L<API Documentation|http://github.com/theory/pgxn-api>

Comprehensive documentation of the REST API provided by L<PGXN::API> and
consumed by WWW::PGXN.

=item * L<PGXN::Manager|http://github.com/theory/pgxn-manager>

Server for managing a master PGXN mirror and allowing users to upload
distributions to it.

=back

=head1 Support

This module is stored in an open L<GitHub
repository|http://github.com/theory/www-pgxn/>. Feel free to fork and
contribute!

Please file bug reports via L<GitHub
Issues|http://github.com/theory/www-pgxn/issues/> or by sending mail to
L<bug-WWW-PGXN@rt.cpan.org|mailto:bug-WWW-PGXN@rt.cpan.org>.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2011 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
