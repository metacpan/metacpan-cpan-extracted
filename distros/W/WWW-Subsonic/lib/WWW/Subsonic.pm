package WWW::Subsonic;
# ABSTRACT: Interface with the Subsonic API


use strict;
use warnings;

use Digest::MD5 qw(md5_hex);
use HTML::Entities qw(decode_entities);
use JSON::MaybeXS;
use Mojo::UserAgent;
use Moo;
use Types::Standard qw(Enum InstanceOf Int Str);
use URI;
use URI::QueryParam;

# Clean Up the Namespace
use namespace::autoclean;

our $VERSION = '0.003'; # VERSION


has 'protocol' => (
    is      => 'ro',
    isa     => Enum[qw(http https)],
    default => sub { 'https' },
);


has 'server' => (
    is      => 'ro',
    isa     => Str,
    default => sub { 'localhost' },
);


has 'port' => (
    is      => 'ro',
    isa     => Int,
    default => sub { 'localhost' },
);


has 'username' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);


has 'password' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);


has 'salt' => (
    is       => 'ro',
    isa      => Str,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_salt',
);
sub _build_salt {
    my @chars = ( 'a'..'z', 0..9, 'A'..'Z' );
    my $salt = '';
    $salt .= $chars[int(rand(@chars))] for 1..12;
    return $salt;
}


has 'token' => (
    is       => 'ro',
    isa      => Str,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_token',
);
sub _build_token {
    my ($self) = @_;
    return md5_hex( $self->password . $self->salt );
}


has 'ua' => (
    is       => 'ro',
    isa      => InstanceOf['Mojo::UserAgent'],
    default  => sub { Mojo::UserAgent->new() },
);


has 'api_version' => (
    is       => 'ro',
    isa      => Str,
    default  => sub { '1.15.0' },
);


has 'client_id' => (
    is       => 'ro',
    isa      => Str,
    default  => sub { 'perl(WWW::Subsonic)' },
);


sub api_request {
    my ($self,$path,$params) = @_;

    my $uri = URI->new( sprintf "%s://%s:%d/rest/%s",
        $self->protocol,
        $self->server,
        $self->port,
        $path
    );
    my %q = (
        u => $self->username,
        s => $self->salt,
        t => $self->token,
        v => $self->api_version,
        c => $self->client_id,
        f => 'json',
        defined $params ? %{ $params } : (),
    );
    foreach my $k ( keys %q ) {
        $uri->query_param( $k => $q{$k} );
    }

    my $as_url = $uri->as_string;
    my $result = $self->ua->get( $as_url )->result;
    my $data;
    if( $result->is_success ) {
        my $body = $result->body;
        if( $result->headers->content_type =~ m{application/json} ) {
            eval {
                my $d = decode_json($body);
                $data = $d->{'subsonic-response'};
                1;
            } or do {
                my $err = $@;
                warn sprintf "Failed JSON Decode from: %s",
                    $as_url, $err, $result->message;
            };
        }
        else {
            # Don't try to decode, just pass back our response
            $data = $body;
        }
    }
    else {
        warn sprintf "Failed request: %s\n\n%s\n",
            $as_url,
            $result->message,
            $result->body,
        ;
    }
    return $data;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Subsonic - Interface with the Subsonic API

=head1 VERSION

version 0.003

=head1 SYNOPSIS

This module provides a very simple interface to using the Subsonic API.

    use Path::Tiny;
    use WWW::Subsonic;

    my $subsonic = WWW::Subsonic->new(
        username => 'user1',
        password => 'Assw0rd1P',
    );

    my $pinged = $subsonic->api_request('ping.view');

    my $starred = $subsonic->api_request('getStarred2');

    foreach my $song (@{ $starred->{song} }) {
        my $dst = path($song->{path});
        $dst->parent->mkpath;
        $dst->spew_raw( $subsonic->api_request(download => { id => $song->{id} }) );
    }

=head1 ATTRIBUTES

=head2 B<protocol>

Subsonic protocol, https (the default) or http.

=head2 B<server>

Subsonic server name, defaults to localhost

=head2 B<port>

Subsonic server port, default 4000

=head2 B<username>

Subsonic username, B<required>.

=head2 B<password>

Subsonic user's password, B<required>.  This is never sent over the wire,
instead it's hashed using a salt for the server to verify.

=head2 B<salt>

Salt for interacting with the server, regenerated each object instantiation.
Will be randomly generated.

=head2 B<token>

Generated from the B<salt> and B<password>.

=head2 B<ua>

UserAgent object used to interface with the Subsonic server.  Needs
to be an instance of Mojo::UserAgent.

=head2 B<api_version>

The Subsonic API verion to target, currently defaults to the latest, Subsonic
6.1, API version 1.15.0.

=head2 B<client_id>

The identifier to use for interfacing with the server, defaults to
perl(WWW::Subsonic).

=head1 METHODS

=head2 B<api_request>

Builds an API request using the parameters.

=over 2

=item 1. API Method

This is the name of of the method to call, ie, C<getStarred>, C<download>, etc.

=item 2. Hash Reference of Arguments

Most API calls take one or more named arguments.  Specify those named arguments
in this hash reference and they will be encoded properly and joined with the
other parameters to form the request.

=back

This method provides the following arguments to all API calls so you don't have
to: B<u> - username, B<s> - salt, B<t> - token, B<v> - API version, B<c> -
client identified, B<f> - format (json).

=head1 SEE ALSO

L<Subsonic API Docs|http://www.subsonic.org/pages/api.jsp>

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=head1 CONTRIBUTORS

=for stopwords Brad Lhotsky Mohammad S Anwar

=over 4

=item *

Brad Lhotsky <brad.lhotsky@gmail.com>

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/WWW-Subsonic>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=WWW-Subsonic>

=back

=head2 Source Code

This module's source code is available by visiting:
L<https://github.com/reyjrar/WWW-Subsonic>

=cut
