package WWW::Gitea::Role::HTTP;

# ABSTRACT: HTTP + token/basic auth role for the Gitea REST API

use Moo::Role;
use Carp qw(croak);
use JSON::MaybeXS qw(decode_json encode_json);
use HTTP::Request;
use LWP::UserAgent;
use MIME::Base64 qw(encode_base64);
use URI;
use Log::Any qw($log);


requires 'api_url';
requires 'token';
requires 'username';
requires 'password';

has ua => (
    is      => 'lazy',
    builder => sub {
        LWP::UserAgent->new(
            agent   => 'WWW-Gitea/' . ($WWW::Gitea::VERSION // 'dev'),
            timeout => 30,
        );
    },
);


sub _apply_auth {
    my ($self, $req) = @_;
    if (defined $self->token && length $self->token) {
        $req->header(Authorization => 'token ' . $self->token);
    }
    elsif (defined $self->username && defined $self->password) {
        $req->header(Authorization => 'Basic '
            . encode_base64($self->username . ':' . $self->password, ''));
    }
    return;
}

sub request {
    my ($self, $method, $path, %args) = @_;

    my $uri = URI->new($self->api_url . $path);
    $uri->query_form($args{query}) if $args{query};

    my $req = HTTP::Request->new($method => $uri);
    $self->_apply_auth($req);
    $req->header(Accept => 'application/json');
    for my $k (keys %{ $args{headers} || {} }) {
        $req->header($k => $args{headers}{$k});
    }

    if (defined $args{body}) {
        my $ct = $args{content_type} || 'application/json';
        $req->header('Content-Type' => $ct);
        $req->content(ref $args{body} ? encode_json($args{body}) : $args{body});
    }

    $log->debugf('Gitea %s %s', $method, $uri);
    my $res = $self->ua->request($req);

    my $body = $res->decoded_content;
    my $data;
    if (defined $body && length $body && $body =~ /\A\s*[\{\[]/) {
        $data = decode_json($body);
    }

    unless ($res->is_success) {
        my $msg = ref $data eq 'HASH'
            ? ($data->{message} || $data->{error} || $res->status_line)
            : $res->status_line;
        $log->errorf('Gitea API error: %s', $msg);
        croak "Gitea API error ($method $path): $msg";
    }

    # 204 No Content (deletes etc.) — no body to decode
    return defined $data ? $data : 1;
}


sub request_status {
    my ($self, $method, $path, %args) = @_;
    my $uri = URI->new($self->api_url . $path);
    $uri->query_form($args{query}) if $args{query};
    my $req = HTTP::Request->new($method => $uri);
    $self->_apply_auth($req);
    $req->header(Accept => 'application/json');
    $log->debugf('Gitea %s %s (status only)', $method, $uri);
    return $self->ua->request($req)->code;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Gitea::Role::HTTP - HTTP + token/basic auth role for the Gitea REST API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    package WWW::Gitea;
    use Moo;

    has api_url  => ( is => 'lazy' );
    has token    => ( is => 'ro' );
    has username => ( is => 'ro' );
    has password => ( is => 'ro' );

    with 'WWW::Gitea::Role::HTTP';

    # Now: $self->request(POST => '/repos/getty/foo/issues', body => \%payload);

=head1 DESCRIPTION

HTTP transport role consumed by L<WWW::Gitea>. Builds and executes JSON
requests against a Gitea instance's C<api/v1> endpoint and applies
authentication: a personal access token (C<Authorization: token ...>) when a
L</token> is set, otherwise HTTP Basic with L</username> + L</password>.

The role requires its consumer to provide C<api_url>, C<token>, C<username>
and C<password> (the latter three may be C<undef> for anonymous access to
public endpoints).

=head2 ua

The L<LWP::UserAgent> instance used for all HTTP traffic.

=head2 request

    my $data = $self->request('POST', '/repos/getty/foo/issues', body => \%payload);

Low-level request method used by the API controllers. Accepts C<body>,
C<query>, C<headers> and C<content_type> named arguments. Returns the decoded
JSON response (or C<1> for an empty C<2xx> such as C<204 No Content>); croaks
with the Gitea error message on a non-2xx response.

=head2 request_status

    my $code = $self->request_status('GET', '/repos/getty/foo/pulls/1/merge');

Sends a request and returns only the numeric HTTP status code, B<without>
croaking on a non-2xx response. Used for status-only endpoints such as the
pull-request "is merged" check (C<204> merged, C<404> not merged).

=head1 SEE ALSO

=over 4

=item * L<WWW::Gitea>

=item * L<WWW::Gitea::Role::OpenAPI>

=item * L<https://docs.gitea.com/development/api-usage>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://codeberg.org/getty/p5-www-gitea/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
