package WWW::OpenBao;
# ABSTRACT: HTTP client for OpenBao / HashiCorp Vault API
our $VERSION = '0.001';
use Moo;
use HTTP::Tiny;
use JSON::MaybeXS;
use Carp qw(croak);
use namespace::clean;

has endpoint  => (is => 'ro', required => 1);
has token     => (is => 'rw', default => sub { '' });
has kv_mount  => (is => 'ro', default => sub { 'secret' });
has _http     => (is => 'lazy');

sub _build__http { HTTP::Tiny->new(timeout => 10) }

# KV v2 paths
sub _kv_path          { my ($self, $p) = @_; "v1/" . $self->kv_mount . "/data/$p" }
sub _kv_metadata_path { my ($self, $p) = @_; "v1/" . $self->kv_mount . "/metadata/$p" }

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

# KV v2: read secret data
sub read_secret {
  my ($self, $path) = @_;
  my $resp = $self->_request('GET', $self->_kv_path($path));
  return undef unless $resp;
  return $resp->{data}{data};
}

# KV v2: write secret data
sub write_secret {
  my ($self, $path, $data) = @_;
  return $self->_request('POST', $self->_kv_path($path), { data => $data });
}

# KV v2: delete secret (all versions + metadata)
sub delete_secret {
  my ($self, $path) = @_;
  return $self->_request('DELETE', $self->_kv_metadata_path($path));
}

# KV v2: list secrets at path
sub list_secrets {
  my ($self, $path) = @_;
  my $resp = $self->_request('LIST', $self->_kv_metadata_path($path));
  return [] unless $resp;
  return $resp->{data}{keys} // [];
}

# KV v2: check if secret exists without fetching data
sub secret_exists {
  my ($self, $path) = @_;
  my $resp = eval { $self->_request('GET', $self->_kv_metadata_path($path)) };
  return defined $resp;
}

# Auth: Kubernetes ServiceAccount login
sub login_k8s {
  my ($self, %args) = @_;
  my $role = $args{role} // croak "login_k8s requires 'role'";
  my $jwt  = $args{jwt}  // _read_sa_token();
  my $resp = $self->_request('POST', 'v1/auth/kubernetes/login', {
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

# Sys: health check
sub health {
  my ($self) = @_;
  return eval { $self->_request('GET', 'v1/sys/health') };
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

version 0.001

=head1 SYNOPSIS

  use WWW::OpenBao;

  my $bao = WWW::OpenBao->new(
    endpoint => $ENV{OPENBAO_ADDR}  // 'http://127.0.0.1:8200',
    token    => $ENV{OPENBAO_TOKEN} // '',
    kv_mount => 'secret',
  );

  $bao->write_secret('app/db', { user => 'app', pass => 'hunter2' });
  my $creds = $bao->read_secret('app/db');
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

All methods C<croak> on non-2xx responses, with the single exception of
C<read_secret> which returns C<undef> on 404 so callers can treat "secret not
found" as a soft miss.

=head2 endpoint

Required. Base URL of the Vault/OpenBao server, e.g.
C<http://127.0.0.1:8200>. No trailing slash.

=head2 token

Vault token used for the C<X-Vault-Token> header. Writable — L</login_k8s>
overwrites it on success.

=head2 kv_mount

Mount path of the KV v2 engine. Defaults to C<secret>.

=head2 read_secret($path)

Returns the C<data.data> hashref for a KV v2 secret, or C<undef> if the path
does not exist.

=head2 write_secret($path, \%data)

Writes (creates a new version of) a KV v2 secret. Returns the decoded
response.

=head2 delete_secret($path)

Deletes the secret I<and> its metadata (all versions). This is the
destructive C<DELETE /metadata/...> form, not the soft-delete.

=head2 list_secrets($path)

Returns an arrayref of keys at the given KV v2 metadata path. Empty arrayref
if the path is missing.

=head2 secret_exists($path)

True if metadata exists for the given path, false otherwise. Does not fetch
the secret data.

=head2 login_k8s(role => $role, jwt => $jwt)

Performs a Kubernetes ServiceAccount login against
C<v1/auth/kubernetes/login>. C<role> is required. C<jwt> defaults to the
in-pod ServiceAccount token at
C</var/run/secrets/kubernetes.io/serviceaccount/token>. On success the
returned C<client_token> is stored in L</token> and the full C<auth> hashref
is returned.

=head2 health

Returns the parsed C</v1/sys/health> response, or C<undef> if the request
fails (sealed/uninitialised servers return non-2xx — that is fine here, the
caller usually just wants to know I<something> answered).

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

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
