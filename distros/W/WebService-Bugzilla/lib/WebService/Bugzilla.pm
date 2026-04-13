#!/usr/bin/false
# ABSTRACT: Perl API for Bugzilla REST API
# PODNAME: WebService::Bugzilla

package WebService::Bugzilla 0.001;
use v5.24;
use strictures 2;
use Moo;
use Carp qw( croak );
use URI::Escape qw( uri_escape_utf8 );
use namespace::clean;

with 'WebService::Client';

has '+base_url' => (is => 'ro', default   => sub { die 'base_url is required' });
has '+mode'     => (is => 'ro', default   => sub { 'v2' });
has api_key     => (is => 'ro', predicate => 1);
has allow_http  => (is => 'ro', default   => 0);

sub BUILD {
    my ($self) = @_;

    my $url = $self->base_url;
    $url =~ s{/+$}{};

    if ($url =~ m{^http://(?!localhost\b|127\.|::1\b|\[::1\])} && !$self->allow_http) {
        croak 'HTTPS required by default. '
            . 'Set allow_http => 1 to allow insecure HTTP.';
    }

    if ($url =~ m{^https?://[^/]+$}) {
        $self->{base_url} = "$url/bugzilla/rest/";
    }

    my $ua = $self->ua;
    if ($self->has_api_key) {
        $ua->default_header('X-BUGZILLA-API-KEY' => $self->api_key);
    }
    $ua->default_header(
        'User-Agent' => sprintf(
            'WebService::Bugzilla %s (perl %s; %s)',
            $WebService::Bugzilla::VERSION, $^V, $^O
        )
    );
    return;
}

# Unwrap WebService::Client::Response objects, throw Exception on non-2xx,
# and return undef for GET 404/410 (resource not found / gone).
around req => sub {
    my ($orig, $self, $req, %args) = @_;
    my $res = $self->$orig($req, %args);

    if (!$res->ok && $req->method eq 'GET' && $res->code =~ m/^(?:404|410)$/) {
        return;
    }

    if (!$res->ok) {
        require WebService::Bugzilla::Exception;
        my $data = eval { $res->data } // {};
        WebService::Bugzilla::Exception->throw(
            message     => ($data->{message} // $res->status_line),
            bz_code     => $data->{code},
            http_status => $res->code,
        );
    }

    # Handle empty-body responses before calling $res->data
    return unless $res->content;

    my $data = eval { $res->data };
    return $data if defined $data;
    return;
};

# URL-encode all query parameter values before they reach
# WebService::Client::get, which interpolates them raw into the URL.
# Without this, values containing spaces, '&', '=', etc. produce
# malformed query strings. See:
#   https://github.com/ironcamel/WebService-Client/issues/25
around get => sub {
    my ($orig, $self, $path, $params, @rest) = @_;
    if ($params && ref $params eq 'HASH') {
        my %encoded;
        for my $k (keys %{$params}) {
            my $v = $params->{$k};
            if (ref $v eq 'ARRAY') {
                $encoded{$k} = [ map { uri_escape_utf8($_) } @{$v} ];
            }
            else {
                $encoded{$k} = uri_escape_utf8($v);
            }
        }
        $params = \%encoded;
    }
    return $self->$orig($path, $params, @rest);
};

has 'attachment' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::Bugzilla::Attachment;
        return WebService::Bugzilla::Attachment->new(client => $self);
    },
);

has 'bug' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::Bugzilla::Bug;
        return WebService::Bugzilla::Bug->new(client => $self);
    },
);

has 'bug_user_last_visit' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::Bugzilla::BugUserLastVisit;
        return WebService::Bugzilla::BugUserLastVisit->new(client => $self);
    },
);

has 'classification' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::Bugzilla::Classification;
        return WebService::Bugzilla::Classification->new(client => $self);
    },
);

has 'comment' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::Bugzilla::Comment;
        return WebService::Bugzilla::Comment->new(client => $self);
    },
);

has 'component' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::Bugzilla::Component;
        return WebService::Bugzilla::Component->new(client => $self);
    },
);

has 'field' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::Bugzilla::Field;
        return WebService::Bugzilla::Field->new(client => $self);
    },
);

has 'flag_activity' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::Bugzilla::FlagActivity;
        return WebService::Bugzilla::FlagActivity->new(client => $self);
    },
);

has 'github' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::Bugzilla::GitHub;
        return WebService::Bugzilla::GitHub->new(client => $self);
    },
);

has 'group' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::Bugzilla::Group;
        return WebService::Bugzilla::Group->new(client => $self);
    },
);

has 'information' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::Bugzilla::Information;
        return WebService::Bugzilla::Information->new(client => $self);
    },
);

has 'product' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::Bugzilla::Product;
        return WebService::Bugzilla::Product->new(client => $self);
    },
);

has 'reminder' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::Bugzilla::Reminder;
        return WebService::Bugzilla::Reminder->new(client => $self);
    },
);

has 'user' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::Bugzilla::User;
        return WebService::Bugzilla::User->new(client => $self);
    },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bugzilla - Perl API for Bugzilla REST API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use WebService::Bugzilla;

    my $bz = WebService::Bugzilla->new(
        base_url => 'https://bugzilla.example.com',
        api_key  => 'your-api-key-here',
    );

    # Fetch a bug
    my $bug = $bz->bug->get(12345);
    say $bug->summary;

    # Search for bugs
    my $bugs = $bz->bug->search(product => 'MyProduct', status => 'NEW');

    # Create a comment
    $bz->comment->create(12345, comment => 'Fixed in latest build.');

    # Get the current user
    my $me = $bz->user->whoami();
    say $me->login_name;

=head1 DESCRIPTION

L<WebService::Bugzilla> is a L<Moo>-based client for the L<Bugzilla REST API|https://bmo.readthedocs.io/en/latest/api/core/v1/index.html>.
It consumes the L<WebService::Client> role and provides lazy accessors for
each Bugzilla API resource area.

HTTPS is required by default.  Set C<< allow_http => 1 >> to permit plain
HTTP connections (useful for local development against C<localhost>).

=head1 ALPHA STATUS

This release should be considered an alpha release. Please adjust your expectations accordingly.

Your feedback is very welcomed. Patches are even more welcome.

=head1 ATTRIBUTES

=over 4

=item C<base_url>

B<Required.>  Base URL of the Bugzilla instance
(e.g. C<https://bugzilla.example.com>).  A trailing C</bugzilla/rest/> path
is appended automatically when the URL contains no path component.

=item C<api_key>

Optional API key used for authentication.  When set it is sent as the
C<X-BUGZILLA-API-KEY> header on every request.

=item C<allow_http>

Boolean (default C<0>).  When false the constructor will C<croak> if
C<base_url> uses plain HTTP (except for loopback addresses).

=item C<mode>

API mode string passed to L<WebService::Client> (default C<v2>).

=item C<attachment>

Lazy accessor returning a L<WebService::Bugzilla::Attachment> instance.

=item C<bug>

Lazy accessor returning a L<WebService::Bugzilla::Bug> instance.

=item C<bug_user_last_visit>

Lazy accessor returning a L<WebService::Bugzilla::BugUserLastVisit> instance.

=item C<classification>

Lazy accessor returning a L<WebService::Bugzilla::Classification> instance.

=item C<comment>

Lazy accessor returning a L<WebService::Bugzilla::Comment> instance.

=item C<component>

Lazy accessor returning a L<WebService::Bugzilla::Component> instance.

=item C<field>

Lazy accessor returning a L<WebService::Bugzilla::Field> instance.

=item C<flag_activity>

Lazy accessor returning a L<WebService::Bugzilla::FlagActivity> instance.

=item C<github>

Lazy accessor returning a L<WebService::Bugzilla::GitHub> instance.

=item C<group>

Lazy accessor returning a L<WebService::Bugzilla::Group> instance.

=item C<information>

Lazy accessor returning a L<WebService::Bugzilla::Information> instance.

=item C<product>

Lazy accessor returning a L<WebService::Bugzilla::Product> instance.

=item C<reminder>

Lazy accessor returning a L<WebService::Bugzilla::Reminder> instance.

=item C<user>

Lazy accessor returning a L<WebService::Bugzilla::User> instance.

=back

=head1 METHODS

=head2 BUILD

L<Moo> lifecycle hook.  Validates C<base_url>, appends the REST base path
when needed, configures the user-agent with an API-key header (if provided),
and sets a descriptive C<User-Agent> string.

=head2 req

    my $data = $bz->req($http_request, %args);

C<around> modifier wrapping L<WebService::Client/req>.  Unwraps the
response object, returns C<undef> for GET 404/410 responses, and throws a
L<WebService::Bugzilla::Exception> on other non-2xx status codes.

=head2 get

    my $data = $bz->get($path, \%params);

C<around> modifier wrapping L<WebService::Client/get>.  URL-encodes all
query-parameter values before dispatch.

=head1 SEE ALSO

L<WebService::Client> - role consumed by this class

L<WebService::Bugzilla::Exception> - exception objects thrown on errors

L<https://bmo.readthedocs.io/en/latest/api/core/v1/index.html> - Bugzilla REST API documentation

=for Pod::Coverage has_api_key

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
