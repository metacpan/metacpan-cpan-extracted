package Web::Session::Patroni;

use strict;
use Apache::Session::Lock::Null;
use Web::Session::PgJSON;
use Web::Session::Store::Patroni;
use Web::Session::Generate::SHA256;
use Web::Session::Serialize::JSON;

our @ISA     = qw(Web::Session::PgJSON);
our $VERSION = '1.0.0';

sub populate {
    my $self = shift;

    $self->{object_store} =
      new Web::Session::Store::Patroni $self;
    $self->{lock_manager} = new Apache::Session::Lock::Null $self;
    $self->{generate}     = \&Web::Session::Generate::SHA256::generate;
    $self->{validate}     = \&Web::Session::Generate::SHA256::validate;
    $self->{serialize}    = \&Web::Session::Serialize::JSON::serialize;
    $self->{unserialize}  = \&Web::Session::Serialize::JSON::unserialize;

    return $self;
}

# Sessions use Web::Session::Store::Patroni, which doesn't use the
# connection pool of Web::Session::Store::Postgres: class methods keep the
# handle of _classDbh() (DBI connect_cached())
sub _classPool { 0 }

1;
__END__

=head1 NAME

Web::Session::Patroni - PostgreSQL/Patroni cluster support
for L<Web::Session::PgJSON>

=head1 SYNOPSIS

Create table and indexes as for L<Web::Session::PgJSON> (see
its documentation for the recommended indexes and their exact expressions):

  CREATE UNLOGGED TABLE sessions (
      id varchar(64) not null primary key,
      a_session jsonb
  );

Use it with Perl:

  use Web::Session::Patroni;

  my $args = {
       DataSource => 'dbi:Pg:dbname=sessions',
       UserName   => $db_user,
       Password   => $db_pass,
       Commit     => 1,

       # List Patroni API endpoints (comma or space separated)
       # Put preferred (local) endpoints first
       PatroniUrl => 'http://1.2.3.4:8008/cluster, http://2.3.4.5:8008/cluster',

       # Optional parameters with defaults:
       # PatroniTimeout             => 3,   # API request timeout in seconds
       # PatroniCacheTTL            => 60,  # Leader cache TTL in seconds
       # PatroniCircuitBreakerDelay => 30,  # Delay before retrying failed API

       # Use a GIN index for searchOn(), see
       # Web::Session::PgJSON for its trade-offs:
       # GinIndex                   => 1,

       # SSL options (verification enabled by default):
       # PatroniVerifySSL           => 1,   # Verify SSL certificates (default: 1)
       # PatroniSSLCAFile           => '/path/to/ca.pem',  # Custom CA file
       # PatroniSSLCAPath           => '/path/to/certs/',  # Custom CA directory
  };

  # Use it like L<Web::Session::PgJSON>

=head1 DESCRIPTION

Web::Session provides some class methods to manipulate all
sessions and add the capability to index some fields to make research faster.

Web::Session::Patroni implements it for PostgreSQL databases
using "json" or "jsonb" type to be able to browse sessions and is able to dial
directly with Patroni API to find the master node of PostgreSQL cluster in
case of error.

searchLt() and searchGt() work as in L<Web::Session::PgJSON>.

=head2 Resilience features

=over 4

=item * B<Circuit breaker>: Avoids hammering the Patroni API when it's failing.
After a failure, the API won't be queried again for C<PatroniCircuitBreakerDelay>
seconds (default: 30).

=item * B<Leader caching>: The discovered leader is cached for
C<PatroniCacheTTL> seconds (default: 60). This cache is used as fallback when
the API is unavailable.

=item * B<Split-brain detection>: Refuses to use a cluster that reports
multiple leaders.

=item * B<Leader health check>: Verifies that the leader is in "running" state
before using it.

=item * B<Multi-source support>: Each DataSource maintains its own independent
cache, allowing multiple Patroni clusters to be used simultaneously.

=back

=head2 SSL/TLS Configuration

By default, SSL certificate verification is B<enabled> when connecting to
HTTPS Patroni endpoints. This protects against man-in-the-middle attacks.

Available SSL options:

=over 4

=item * C<PatroniVerifySSL> (default: 1)

Set to 0 to disable SSL certificate verification. B<Warning>: This makes
HTTPS connections vulnerable to MITM attacks. Only use in development or
when you have other network-level protections.

  PatroniVerifySSL => 0,  # INSECURE - disable SSL verification

=item * C<PatroniSSLCAFile>

Path to a custom CA certificate file (PEM format) for verifying the Patroni
API server certificate.

  PatroniSSLCAFile => '/etc/ssl/certs/patroni-ca.pem',

=item * C<PatroniSSLCAPath>

Path to a directory containing CA certificates for verification.

  PatroniSSLCAPath => '/etc/ssl/certs/',

=back

=head2 Unchanged sessions

As the other SQL backends, Patroni doesn't rewrite a session stored back
unchanged, see L<Web::Session/"UNCHANGED SESSIONS ARE NOT REWRITTEN">. But it
reads the session with C<SELECT ... FOR UPDATE>, as
L<Apache::Session::Store::Postgres> does: the row stays locked until the
transaction ends at untie, whether the save is skipped or not. Skipping it
saves the write, not the lock.

=head2 Connection pool

Database connections are kept open between sessions. By default, sessions
use the connection pool of L<Web::Session::PgJSON> (see "Connection pool
(KeepConnections)" there, with its C<MaxIdle>, C<IdleTimeout> and
C<MaxLifetime> options): each process keeps idle connections and lends each
one to a single tied session at a time.

As without the pool, each tie is one transaction: a session is read with
C<SELECT ... FOR UPDATE>, so its row stays locked until untie, where the
transaction is committed (C<Commit> is on by default) or rolled back. Two
processes that update the same session at the same time (two Lemonldap::NG
requests of the same user, for example) wait for each other instead of
overwriting each other's changes. A connection goes back to the pool only
once its transaction is ended; one whose transaction can't be ended is
closed.

The pool is keyed by the DSN of the primary node in use (the C<DataSource>
with the host and port of the leader found through the Patroni API) and the
user. So after a failover, a connection to the former primary is never lent
again: it could still answer C<ping()> (a demoted node) or hang until a TCP
timeout (an isolated node), and every write would fail. The failover is
detected as without the pool: a statement that fails closes its connection
(the pool never lends again a connection that met an error), the Patroni API
gives the new leader and the statement is retried on a connection to it. The
idle connections of the process to the former primary are then closed at
once, and those lent to other sessions at that moment are closed when they
are given back.

The pool is not used with C<Commit =E<gt> 0> (this backend commits when
C<Commit> isn't set), with C<KeepConnections =E<gt> 0>, with C<noreuse> or
with a C<Handle>: sessions then use the handle shared by the sessions of the
process (C<AutoCommit> off, a transaction committed at untie, see
L<Web::Session/"PERSISTENT DATABASE CONNECTIONS">), or with C<noreuse =E<gt> 1>
a connection opened and closed for each session.

Class methods don't use the pool, see L</Class methods>.

=head2 Class methods

Class methods (searchOn(), searchOnExpr(), searchLt(), searchGt(),
get_key_from_all_sessions(), deleteIfLowerThan()) don't query the Patroni
API and don't use the connection pool of L<Web::Session::PgJSON>: they
connect to the C<DataSource> found in their arguments, with the handle cached
by DBI C<connect_cached()>. A tied session replaces C<DataSource> in its
arguments by the DSN of the primary it found, so class methods called later
with the same arguments hash use this primary; called with the configured
arguments, they use the configured C<DataSource>. After a failover, they
reach the new primary only if C<DataSource> follows it (virtual IP, DNS name
or proxy such as HAProxy), or once a session tied with the same arguments
has found it.

=head1 SEE ALSO

L<http://lemonldap-ng.org>, L<Web::Session::PgJSON>

=head1 COPYRIGHT AND LICENSE

=encoding utf8

=over

=item 2009-2026 by Xavier Guimard

=item 2013-2025 by Clément Oudot

=item 2019-2025 by Maxime Besson

=item 2013-2025 by Worteks

=item 2023-2026 by Linagora

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
