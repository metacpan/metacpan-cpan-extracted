package Web::Session::Store::Patroni;

use strict;

use DBI;
use Apache::Session::Store::Postgres;
use Web::Session::Store::DBI;
use Web::Session::Store::Postgres;

our @ISA     = qw(Apache::Session::Store::Postgres);
our $VERSION = '1.0.0';

# Cache structure per DataSource:
# {
#   leader => { host => '...', port => '...', time => ... },
#   lastFailure => timestamp,
# }
our %patroniCache;

sub connection {
    my $self    = shift;
    my $session = shift;

    Web::Session::Store::DBI::_forgetInheritedHandle($self);
    return if ( defined $self->{dbh} );

    $self->{'table_name'} =
      $session->{args}->{TableName} || $Apache::Session::Store::DBI::TableName;

    if ( exists $session->{args}->{Handle} ) {
        $self->{dbh}    = $session->{args}->{Handle};
        $self->{commit} = $session->{args}->{Commit};
        return;
    }

    # Store original DataSource as cache key. Kept when _try() reconnects:
    # $session->{args}->{DataSource} then holds the DSN of the failed
    # primary, and the new leader must be cached under the original key, the
    # one that the next sessions read
    my $originalDataSource = $self->{_originalDataSource} //=
      $session->{args}->{DataSource};

    # Use cached leader if available and not expired
    my $cache    = $patroniCache{$originalDataSource}  || {};
    my $cacheTTL = $session->{args}->{PatroniCacheTTL} || 60;

    if (    $cache->{leader}
        and $cache->{leader}->{time}
        and ( time() - $cache->{leader}->{time} ) < $cacheTTL )
    {
        $session->{args}->{DataSource} =
          _buildDataSource( $originalDataSource, $cache->{leader} );
    }

    #the programmer has to tell us what commit policy to use
    my $commit = $session->{args}->{Commit} // 1;

    # Connection pool of the Postgres store (see Store/Postgres.pm), keyed by
    # the DSN of the primary in use
    return $self->_pooledPrimary( $session->{args}, $commit )
      if ( Web::Session::Store::Postgres::_poolApplies( $session->{args},
            $commit ) );

    # AutoCommit off, as Postgres: see "Why AutoCommit differs" in Store/DBI.pm
    my $reused;
    foreach ( 0 .. 1 ) {
        (
            $self->checkMaster( $session->{args} )
              or warn "Patroni check failed"
        ) if $self->{failure};
        eval {
            $reused = Web::Session::Store::DBI::_reusedHandle(
                $self, $session->{args},
                @{ $session->{args} }{qw(DataSource UserName Password)},
                { RaiseError => 1, AutoCommit => 0 }
            );
            $self->{dbh} = $reused || DBI->connect(
                $session->{args}->{DataSource},
                $session->{args}->{UserName},
                $session->{args}->{Password},
                { RaiseError => 1, AutoCommit => 0 }
            ) || die $DBI::errstr;
        };
        if ( $@ and !$_ ) {
            $self->{failure} = 1;
        }
        else {
            last;
        }
    }
    die $@ if $@;

    #If we open the connection, we close the connection
    $self->{disconnect} = $reused ? 0 : 1;

    $self->{commit} = $commit;
}

# connection() with the pool: a connection to the primary is borrowed from
# the pool of its DSN (the one in $args->{DataSource}, resolved from the
# leader cache or by checkMaster()), with the retry of connection().
#
# Keyed by the DSN of the primary, the pool never lends a connection to a
# former primary once the leader changed: such a connection may still answer
# ping() (a node demoted behind a proxy) or hang until a TCP timeout (an
# isolated node), and every write would fail. The failover is detected as
# without the pool: a statement that fails (a write on a demoted node, or a
# connection error) makes _try() give the connection back (flagged by
# HandleError, it is closed) and retry with a new primary found by
# checkMaster(). When the DSN changes, the idle connections to the former one
# are closed at once instead of waiting for IdleTimeout, and those lent at
# this time are closed when given back (see _dropIdle()).
#
# Pooled connections run with AutoCommit on, but this store keeps one
# transaction per tie, as without the pool: its materialize() is the one of
# Apache::Session::Store::Postgres (SELECT ... FOR UPDATE), and the row lock
# must last until untie so that two requests updating the same session wait
# for each other instead of overwriting each other's changes. The
# transaction starts here, before the first statement on the lent
# connection, and ends in DESTROY (see _endTransaction()).
sub _pooledPrimary {
    my ( $self, $args, $commit ) = @_;
    foreach ( 0 .. 1 ) {
        if ( $self->{failure} ) {
            my $failed = Web::Session::Store::Postgres::_poolKey(
                @{$args}{qw(DataSource UserName)} );
            $self->checkMaster($args) or warn "Patroni check failed";
            Web::Session::Store::Postgres::_dropIdle($failed)
              if ( $failed ne Web::Session::Store::Postgres::_poolKey(
                    @{$args}{qw(DataSource UserName)} ) );
        }
        eval {
            $self->Web::Session::Store::Postgres::_pooledConnection(
                @{$args}{qw(DataSource UserName Password)}, $args );
        };
        if ( $@ and !$_ ) {
            $self->{failure} = 1;
        }
        else {
            last;
        }
    }
    die $@ if $@;
    $self->{dbh}->begin_work;
    $self->{commit} = $commit;
}

# Ends the transaction of a tie on a pooled connection: committed if the
# store commits and no statement failed, rolled back otherwise. A connection
# whose transaction can't be ended is flagged, so that _giveBack() closes it:
# a connection never goes back to the pool inside a transaction
sub _endTransaction {
    my ($self) = @_;
    my $dbh = $self->{dbh} or return;

    # Lent when the process forked: the transaction is the parent's
    return if ( ( $dbh->{private_ws_pid} // 0 ) != $$ );
    local $@;

    # End of the program: the session is committed as without the pool, the
    # connection is not given back (see _giveBack())
    if ( ${^GLOBAL_PHASE} eq 'DESTRUCT' ) {
        eval {
            $dbh->commit
              if ( $self->{commit} and $dbh->{Active} and !$dbh->{AutoCommit} );
        };
        return;
    }
    return if ( $dbh->{AutoCommit} );
    my $ok = eval {
        ( $self->{commit} and !$dbh->{private_ws_error} )
          ? $dbh->commit
          : $dbh->rollback;
        1;
    };
    unless ( $ok and $dbh->{AutoCommit} ) {
        eval { $dbh->rollback } unless ( $dbh->{AutoCommit} );
        $dbh->{private_ws_error} = 1;
    }
}

# Apache::Session::Store::Postgres::DESTROY() commits: not in a child
# created by fork() on the parent's handle (see _forgetInheritedHandle() in
# Store/DBI.pm). A pooled connection ends its transaction and is given back
sub DESTROY {
    my $self = shift;
    return if ( Web::Session::Store::DBI::_forgetInheritedHandle($self) );
    if ( defined $self->{pool_key} ) {
        $self->_endTransaction;
        return $self->Web::Session::Store::Postgres::_giveBack;
    }
    $self->SUPER::DESTROY(@_);
}

sub _try {
    my $self = shift;
    my $sub  = shift;
    my $res;

    foreach ( 0 .. 1 ) {
        $res =
          eval { Apache::Session::Store::Postgres->can($sub)->( $self, @_ ) };
        if ( $@ and $@ !~ /Object does not exist/ and !$_ ) {
            $self->{failure} = 1;
            $self->DESTROY;
            delete $self->{"${sub}_sth"};
            delete $self->{dbh};
        }
        else {
            last;
        }
    }
    die $@ if $@;
    return $res;
}

sub insert {
    my $self = shift;
    return $self->_try( 'insert', @_ );
}

# update() and materialize() keep the serialized data that the database
# holds, and update() doesn't rewrite an unchanged session, as the stores
# inheriting from Web::Session::Store::DBI (see "Unchanged sessions are not
# rewritten" there)
sub update {
    my $self = shift;
    return if ( Web::Session::Store::DBI::_unchanged( $self, $_[0] ) );
    my $res = $self->_try( 'update', @_ );
    Web::Session::Store::DBI::_remember( $self, $_[0] );
    return $res;
}

sub materialize {
    my $self = shift;
    my $res  = $self->_try( 'materialize', @_ );
    Web::Session::Store::DBI::_remember( $self, $_[0] );
    return $res;
}

sub remove {
    my $self = shift;
    return $self->_try( 'remove', @_ );
}

sub checkMaster {
    my ( $self, $args ) = @_;
    delete $self->{failure};

    my $originalDataSource =
      $self->{_originalDataSource} || $args->{DataSource};
    my $cache = $patroniCache{$originalDataSource} ||= {};

    # Circuit breaker: avoid hammering Patroni API if it's failing
    my $circuitBreakerDelay = $args->{PatroniCircuitBreakerDelay} || 30;
    if ( $cache->{lastFailure}
        and ( time() - $cache->{lastFailure} ) < $circuitBreakerDelay )
    {
        # Circuit breaker active, try cached leader as fallback
        return $self->_useCachedLeader( $args, $originalDataSource,
            "Circuit breaker active" );
    }

    require JSON;
    require LWP::UserAgent;
    require IO::Socket::SSL;

    # SSL verification: secure by default, can be disabled with PatroniVerifySSL => 0
    my $verify_ssl = $args->{PatroniVerifySSL} // 1;
    my %ssl_opts;
    if ($verify_ssl) {
        %ssl_opts = (
            verify_hostname => 1,
            SSL_verify_mode => &IO::Socket::SSL::SSL_VERIFY_PEER,
            ( $args->{PatroniSSLCAFile} ? ( SSL_ca_file => $args->{PatroniSSLCAFile} ) : () ),
            ( $args->{PatroniSSLCAPath} ? ( SSL_ca_path => $args->{PatroniSSLCAPath} ) : () ),
        );
    }
    else {
        %ssl_opts = (
            verify_hostname => 0,
            SSL_verify_mode => &IO::Socket::SSL::SSL_VERIFY_NONE,
        );
    }

    my $ua = LWP::UserAgent->new(
        env_proxy => 1,
        ssl_opts  => \%ssl_opts,
        timeout   => $args->{PatroniTimeout} || 3,
    );
    my $res;

    foreach my $patroniUrl ( split /[,\s]\s*/,
        ( $args->{PatroniUrl} || $args->{patroniUrl} ) )
    {
        my $resp = $ua->get($patroniUrl);
        if ( $resp->is_success ) {
            my $c = eval { JSON::from_json( $resp->decoded_content ) };
            if ( $@ or !$c->{members} or ref( $c->{members} ) ne 'ARRAY' ) {
                print STDERR "Bad response from $patroniUrl: "
                  . $resp->decoded_content . "\n";
                next;
            }

            my @leaders = grep { $_->{role} eq 'leader' } @{ $c->{members} };

            # Check for split-brain scenario
            if ( @leaders > 1 ) {
                my $leadersList =
                  join( ', ', map { "$_->{host}:$_->{port}" } @leaders );
                print STDERR
                  "Multiple leaders detected (split-brain) from $patroniUrl"
                  . " - Leaders: $leadersList\n";
                next;
            }

            my ($leader) = @leaders;
            unless ($leader) {
                print STDERR "No leader found from $patroniUrl: "
                  . $resp->decoded_content . "\n";
                next;
            }

            # Validate leader has required fields
            unless ( defined $leader->{host} && defined $leader->{port} ) {
                print STDERR "Leader missing host or port from $patroniUrl: "
                  . $resp->decoded_content . "\n";
                next;
            }

            # Check leader health state
            if ( $leader->{state} && $leader->{state} ne 'running' ) {
                print STDERR
                  "Leader not in running state (state=$leader->{state})"
                  . " from $patroniUrl\n";
                next;
            }

            # Cache the leader info
            $cache->{leader} = {
                host => $leader->{host},
                port => $leader->{port},
                time => time()
            };

            # Reset circuit breaker on success
            delete $cache->{lastFailure};

            $args->{DataSource} =
              _buildDataSource( $originalDataSource, $leader );
            $res = 1;
            last;
        }
    }

    # If API failed, record for circuit breaker and try cached leader
    unless ($res) {
        $cache->{lastFailure} = time();
        $res = $self->_useCachedLeader( $args, $originalDataSource,
            "Patroni API unavailable" );
    }

    return $res;
}

# Use cached leader as fallback
sub _useCachedLeader {
    my ( $self, $args, $originalDataSource, $reason ) = @_;

    my $cache    = $patroniCache{$originalDataSource} || {};
    my $cacheTTL = $args->{PatroniCacheTTL}           || 60;

    if (    $cache->{leader}
        and $cache->{leader}->{time}
        and ( time() - $cache->{leader}->{time} ) < $cacheTTL )
    {
        my $age = time() - $cache->{leader}->{time};
        print STDERR "$reason, using cached leader (${age}s old)\n";
        $args->{DataSource} =
          _buildDataSource( $originalDataSource, $cache->{leader} );
        return 1;
    }
    return 0;
}

# Build DataSource string with new host/port
sub _buildDataSource {
    my ( $originalDataSource, $leader ) = @_;

    my $chain = $originalDataSource;

    # Remove existing host/port parameters
    $chain =~ s/;\s*host=[^;]+//gi;
    $chain =~ s/;\s*port=[^;]+//gi;
    $chain =~ s/\s+host=[^\s;]+//gi;
    $chain =~ s/\s+port=[^\s;]+//gi;

    # Clean up trailing semicolons
    $chain =~ s/;+$//;

    # Add new host and port
    my $separator = ( $chain =~ /:$/ ) ? '' : ';';
    return "${chain}${separator}host=$leader->{host};port=$leader->{port}";
}

1;
