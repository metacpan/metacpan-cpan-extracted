package WWW::OpenBao;
# ABSTRACT: HTTP client for OpenBao / HashiCorp Vault API
our $VERSION = '0.003';
use Moo;
use HTTP::Tiny;
use JSON::MaybeXS;
use Carp qw(croak);
use namespace::clean;

has endpoint       => (is => 'ro', required => 1);
has token          => (is => 'rw', default => sub { '' });
has kv_mount       => (is => 'ro', default => sub { 'secret' });
has k8s_auth_mount => (is => 'ro', default => sub { 'kubernetes' });
has _http          => (is => 'lazy');

sub _build__http { HTTP::Tiny->new(timeout => 10) }

# KV v2 paths
sub _kv_path          { my ($self, $p) = @_; "v1/" . $self->kv_mount . "/data/$p" }
sub _kv_metadata_path { my ($self, $p) = @_; "v1/" . $self->kv_mount . "/metadata/$p" }
sub _kv_delete_path   { my ($self, $p) = @_; "v1/" . $self->kv_mount . "/delete/$p" }
sub _kv_undelete_path { my ($self, $p) = @_; "v1/" . $self->kv_mount . "/undelete/$p" }
sub _kv_destroy_path  { my ($self, $p) = @_; "v1/" . $self->kv_mount . "/destroy/$p" }

# Core HTTP
sub _request {
  my ($self, $method, $path, $body) = @_;
  my $url = $self->endpoint . '/' . $path;
  my %opts = (headers => {
    'X-Vault-Token' => $self->token,
  });
  if ($body) {
    $opts{content} = encode_json($body);
    $opts{headers}{'Content-Type'} = 'application/json';
  }
  my $resp = $self->_http->request($method, $url, \%opts);
  return undef if $resp->{status} == 404;
  croak "OpenBao $method $path: $resp->{status} $resp->{content}"
    unless $resp->{success};
  return $resp->{content} ? decode_json($resp->{content}) : {};
}

# KV v2: GET data/<path>, latest version by default; version => $n reads an
# older version via ?version=N. defined (not truthy) so an explicit
# version => 0 is honoured as a real argument, not dropped as "none".
sub _kv_read {
  my ($self, $path, %args) = @_;
  my $kv_path = $self->_kv_path($path);
  $kv_path .= '?version=' . $args{version} if defined $args{version};
  return $self->_request('GET', $kv_path);
}

# KV v2: read secret data (data.data)
sub read_secret {
  my ($self, $path, %args) = @_;
  my $resp = $self->_kv_read($path, %args);
  return undef unless $resp;
  return $resp->{data}{data};
}

# KV v2: read the metadata (version / created_time / destroyed / ...) that
# rides along the same data/ read. Separate entry point on purpose so
# read_secret keeps returning the bare data.data hashref consumers depend on.
sub read_secret_metadata {
  my ($self, $path, %args) = @_;
  my $resp = $self->_kv_read($path, %args);
  return undef unless $resp;
  return $resp->{data}{metadata};
}

# KV v2: write secret data
sub write_secret {
  my ($self, $path, $data) = @_;
  return $self->_request('POST', $self->_kv_path($path), { data => $data });
}

# KV v2: delete secret (all versions + metadata) — ladder level 3, irreversible
sub delete_secret {
  my ($self, $path) = @_;
  return $self->_request('DELETE', $self->_kv_metadata_path($path));
}

# KV v2 delete ladder level 1 (reversible soft delete). Without versions,
# soft-deletes the latest version via DELETE data/; with a version list,
# soft-deletes exactly those versions via POST delete/. Reverse with
# undelete_secret.
sub soft_delete_secret {
  my ($self, $path, @versions) = @_;
  return $self->_request('POST', $self->_kv_delete_path($path), { versions => \@versions })
    if @versions;
  return $self->_request('DELETE', $self->_kv_path($path));
}

# KV v2: restore soft-deleted versions (reverses soft_delete_secret)
sub undelete_secret {
  my ($self, $path, @versions) = @_;
  croak "undelete_secret requires at least one version" unless @versions;
  return $self->_request('POST', $self->_kv_undelete_path($path), { versions => \@versions });
}

# KV v2 delete ladder level 2 (irreversible): permanently destroy named
# versions via PUT destroy/. The version bytes are gone; key and metadata stay.
sub destroy_secret {
  my ($self, $path, @versions) = @_;
  croak "destroy_secret requires at least one version" unless @versions;
  return $self->_request('PUT', $self->_kv_destroy_path($path), { versions => \@versions });
}

# KV v2: list secrets at path
sub list_secrets {
  my ($self, $path) = @_;
  my $resp = $self->_request('LIST', $self->_kv_metadata_path($path));
  return [] unless $resp;
  return $resp->{data}{keys} // [];
}

# KV v2: check if secret exists without fetching data. Only a 404 (absent
# path) is a soft "no"; a 403 (policy forbids a path that may well exist) and
# any other non-2xx propagate via _request's croak, so callers can tell
# "not allowed to see" apart from "not there".
sub secret_exists {
  my ($self, $path) = @_;
  return defined $self->_request('GET', $self->_kv_metadata_path($path));
}

# Auth: Kubernetes ServiceAccount login
sub login_k8s {
  my ($self, %args) = @_;
  my $role = $args{role} // croak "login_k8s requires 'role'";
  my $jwt  = $args{jwt}  // _read_sa_token();
  my $resp = $self->_request('POST', 'v1/auth/' . $self->k8s_auth_mount . '/login', {
    role => $role, jwt => $jwt,
  });
  $self->token($resp->{auth}{client_token});
  return $resp->{auth};
}

sub _read_sa_token {
  my $path = '/var/run/secrets/kubernetes.io/serviceaccount/token';
  open my $fh, '<', $path or croak "Cannot read SA token: $!";
  local $/;
  return <$fh>;
}

# Sys: health check. standbyok/perfstandbyok/sealedcode/uninitcode flatten the
# operational states that otherwise answer with a non-2xx status (standby 429,
# performance standby, sealed 503, uninitialised 501) to a 200, so _request
# decodes the body instead of croaking — the caller reads the state out of the
# returned hashref (initialized, sealed, standby, ...). The eval still maps a
# genuinely unreachable server (network error, or non-2xx despite the codes)
# to undef, so "no answer at all" stays distinct from any reported state.
sub health {
  my ($self) = @_;
  return eval {
    $self->_request('GET',
      'v1/sys/health?standbyok=true&perfstandbyok=true&sealedcode=200&uninitcode=200')
  };
}

# Sys: initialize vault (first time)
sub init {
  my ($self, %args) = @_;
  my $shares    = $args{secret_shares}    // 1;
  my $threshold = $args{secret_threshold} // 1;
  return $self->_request('POST', 'v1/sys/init', {
    secret_shares => $shares, secret_threshold => $threshold,
  });
}

# Sys: unseal
sub unseal {
  my ($self, $key) = @_;
  return $self->_request('POST', 'v1/sys/unseal', { key => $key });
}

# Sys: enable secrets engine
sub enable_engine {
  my ($self, $path, $type) = @_;
  return $self->_request('POST', "v1/sys/mounts/$path", { type => $type });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::OpenBao - HTTP client for OpenBao / HashiCorp Vault API

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use WWW::OpenBao;

  my $bao = WWW::OpenBao->new(
    endpoint => $ENV{OPENBAO_ADDR}  // 'http://127.0.0.1:8200',
    token    => $ENV{OPENBAO_TOKEN} // '',
    kv_mount => 'secret',
  );

  $bao->write_secret('app/db', { user => 'app', pass => 'hunter2' });
  my $creds = $bao->read_secret('app/db');
  my $meta  = $bao->read_secret_metadata('app/db');  # version, created_time, ...
  my $keys  = $bao->list_secrets('app/');
  $bao->delete_secret('app/db');

  $bao->login_k8s( role => 'my-app' );  # sets $bao->token

=head1 DESCRIPTION

L<WWW::OpenBao> is a minimal HTTP client for L<OpenBao|https://openbao.org/>
and HashiCorp Vault. It covers the day-to-day surface used by application
code: KV v2 secret read/write/list/delete, Kubernetes ServiceAccount login,
and a handful of C<sys/*> bootstrap helpers (C<health>, C<init>, C<unseal>,
C<enable_engine>).

It is intentionally small — no caching, no lease renewal, no policy
management. If you need those, reach for a heavier client; if you just want
to talk to Vault/OpenBao from Perl, this is enough.

Every request goes through one shared seam, and its error contract applies to
every method: a non-2xx response C<croak>s with the status and response body,
except C<404>, which is never a C<croak>. A C<404> comes back as a soft miss:

=over 4

=item * L</read_secret> and L</read_secret_metadata> return C<undef>. KV v2
answers C<404> both for an absent path and for a soft-deleted version, so
C<undef> means "no readable value", not "never existed".

=item * L</list_secrets> returns an empty arrayref.

=item * L</secret_exists> returns false. Only a C<404> does that; a C<403>
(permission denied) croaks like any other non-2xx.

=item * L</write_secret>, L</delete_secret>, L</soft_delete_secret>,
L</undelete_secret>, L</destroy_secret>, L</init>, L</unseal> and
L</enable_engine> return C<undef>.

=item * L</login_k8s> does not croak either: it returns an empty hashref and
leaves L</token> undefined, since no C<client_token> came back.

=back

L</health> is the one method that never croaks: it returns C<undef> whenever
the server gives no usable answer, see there.

=head2 endpoint

Required. Base URL of the Vault/OpenBao server, e.g.
C<http://127.0.0.1:8200>. No trailing slash.

=head2 token

Vault token used for the C<X-Vault-Token> header. Writable — L</login_k8s>
overwrites it on success.

=head2 kv_mount

Mount path of the KV v2 engine. Defaults to C<secret>.

=head2 k8s_auth_mount

Mount path of the Kubernetes auth method. Defaults to C<kubernetes>, the
OpenBao/Vault default. Set it when the method is mounted elsewhere — e.g.
C<k8s_auth_mount =E<gt> 'kubernetes-prod'> makes L</login_k8s> post to
C<v1/auth/kubernetes-prod/login>.

=head2 read_secret($path, version => $n)

Returns the C<data.data> hashref for a KV v2 secret, or C<undef> if the path
does not exist. By default it reads the latest version; pass
C<version =E<gt> $n> to read a specific earlier version instead, which appends
C<?version=N> to the C<GET .../data/...> request. C<undef> (a soft-deleted or
absent version both answer C<404>) still means "no readable value".

=head2 read_secret_metadata($path, version => $n)

Returns the C<data.metadata> hashref that KV v2 returns alongside the value on
the same C<GET .../data/...> read — the C<version> number, C<created_time>,
C<destroyed> flag and C<custom_metadata> — or C<undef> on a C<404>. Like
L</read_secret> it reads the latest version by default and takes an optional
C<version =E<gt> $n> to read a specific version's metadata via C<?version=N>.

This is a separate entry point on purpose: L</read_secret> keeps returning the
bare C<data.data> hashref, so callers that only want the values are
unaffected. Note it reads the C<data/> endpoint (the metadata that
accompanies a value read), not the C<metadata/> version-history endpoint.

=head2 write_secret($path, \%data)

Writes (creates a new version of) a KV v2 secret. Returns the decoded
response.

=head2 delete_secret($path)

B<Delete ladder level 3 — irreversible, destroys everything.> Removes the key
together with all of its versions and history via
C<DELETE /E<lt>mountE<gt>/metadata/...>. This is the most destructive of the KV
v2 delete operations and there is no undo: despite the plain name it is I<not>
the soft delete a caller might expect. For the reversible level-1 soft delete
of the latest (or of named) versions use L</soft_delete_secret>, reversed by
L</undelete_secret>; to permanently destroy specific versions while keeping the
key and its metadata use L</destroy_secret> (level 2).

=head2 soft_delete_secret($path, @versions)

B<Delete ladder level 1 — reversible.> Soft-deletes KV v2 versions: they then
read back as C<404>, but the data is retained and can be restored with
L</undelete_secret>. Called with no C<@versions> it soft-deletes the latest
version via C<DELETE /E<lt>mountE<gt>/data/...>; called with one or more version
numbers it soft-deletes exactly those via C<POST /E<lt>mountE<gt>/delete/...>.

=head2 undelete_secret($path, @versions)

Restores versions previously soft-deleted by L</soft_delete_secret>, via
C<POST /E<lt>mountE<gt>/undelete/...>. At least one version number is required
(it C<croak>s otherwise). This reverses a level-1 soft delete only — it cannot
bring back versions removed by L</destroy_secret> or L</delete_secret>.

=head2 destroy_secret($path, @versions)

B<Delete ladder level 2 — irreversible.> Permanently destroys the named
versions via C<PUT /E<lt>mountE<gt>/destroy/...>: their contents are gone for
good and cannot be undeleted. The key itself and its metadata survive, so this
is narrower than L</delete_secret> (level 3) but just as final for the versions
it names. At least one version number is required (it C<croak>s otherwise).

=head2 list_secrets($path)

Returns an arrayref of keys at the given KV v2 metadata path. Empty arrayref
if the path is missing.

=head2 secret_exists($path)

True if the given path exists, false if it answers C<404>. Does not fetch the
secret data. A C<403> (permission denied) or any other non-2xx C<croak>s, so a
path the token may not see is not reported as absent.

=head2 login_k8s(role => $role, jwt => $jwt)

Performs a Kubernetes ServiceAccount login. Posts to
C<v1/auth/E<lt>k8s_auth_mountE<gt>/login>, i.e. C<v1/auth/kubernetes/login> by
default; see L</k8s_auth_mount> to reach a method mounted elsewhere. C<role>
is required. C<jwt> defaults to the in-pod ServiceAccount token at
C</var/run/secrets/kubernetes.io/serviceaccount/token>. On success the
returned C<client_token> is stored in L</token> and the full C<auth> hashref
is returned.

=head2 health

Returns the decoded C</v1/sys/health> response as a hashref for B<every>
reachable server, whatever its seal, standby or init state. The request is made
with C<standbyok=true&perfstandbyok=true&sealedcode=200&uninitcode=200>, so
OpenBao/Vault answers C<200> — and therefore a body — for the states that
otherwise carry their answer only in a non-2xx status code: standby (C<429>),
performance standby, sealed (C<503>) and uninitialised (C<501>). Read the state
out of the returned fields — C<initialized>, C<sealed>, C<standby>,
C<performance_standby>, C<version> and the rest of the health payload.

Because of this, a sealed, uninitialised or standby server yields an
inspectable hashref rather than C<undef>. C<undef> means only that the server
gave no usable answer — a network-level failure, a C<404>, or another non-2xx
status returned in spite of the flattening parameters. C<health> never
C<croak>s.

=head2 init(secret_shares => $n, secret_threshold => $n)

Initialises an uninitialised server. Both arguments default to C<1>. Use
this for dev/test only.

=head2 unseal($key)

Submits a single unseal key share.

=head2 enable_engine($path, $type)

Mounts a secrets engine at C<$path> with the given C<$type> (e.g.
C<kv-v2>).

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-openbao/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
