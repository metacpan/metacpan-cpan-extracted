package TheSchwartz::Simple;

use strict;
use 5.8.1;
our $VERSION = '0.05';

use Carp;
use Scalar::Util qw( refaddr );
use Storable;
use TheSchwartz::Simple::Job;

sub new {
    my $class = shift;
    my ($dbhs) = @_;
    $dbhs = [$dbhs] unless ref $dbhs eq 'ARRAY';
    bless {
        databases => $dbhs,
        _funcmap  => {},
        prefix    => "",
    }, $class;
}

sub insert {
    my $self = shift;

    my $job;
    if ( ref $_[0] eq 'TheSchwartz::Simple::Job' ) {
        $job = $_[0];
    }
    else {
        $job = TheSchwartz::Simple::Job->new_from_array(@_);
    }
    $job->arg( Storable::nfreeze( $job->arg ) ) if ref $job->arg;

    for my $dbh ( @{ $self->{databases} } ) {
        my $jobid;
        eval {
            $job->funcid( $self->funcname_to_id( $dbh, $job->funcname ) );
            $job->insert_time(time);

            my $row = $job->as_hashref;
            my @col = keys %$row;

            my $sql = sprintf 'INSERT INTO %sjob (%s) VALUES (%s)',
                $self->{prefix},
                join( ", ", @col ), join( ", ", ("?") x @col );

            my $sth = $dbh->prepare_cached($sql);
            my $i = 1;
            for my $col (@col) {
                $sth->bind_param(
                    $i++,
                    $row->{$col},
                    _bind_param_attr( $dbh, $col ),
                );
            }
            $sth->execute();

            $jobid = _insert_id( $dbh, $sth, "job", "jobid" );
        };

        return $jobid if defined $jobid;
    }

    return;
}

sub funcname_to_id {
    my ( $self, $dbh, $funcname ) = @_;

    my $dbid = refaddr $dbh;
    unless ( exists $self->{_funcmap}{$dbid} ) {
        my $sth
            = $dbh->prepare_cached("SELECT funcid, funcname FROM $self->{prefix}funcmap");
        $sth->execute;
        while ( my $row = $sth->fetchrow_arrayref ) {
            $self->{_funcmap}{$dbid}{ $row->[1] } = $row->[0];
        }
        $sth->finish;
    }

    unless ( exists $self->{_funcmap}{$dbid}{$funcname} ) {
        ## This might fail in a race condition since funcname is UNIQUE
        my $sth = $dbh->prepare_cached(
            "INSERT INTO $self->{prefix}funcmap (funcname) VALUES (?)");
        eval { $sth->execute($funcname) };

        my $id = _insert_id( $dbh, $sth, "funcmap", "funcid" );

        ## If we got an exception, try to load the record again
        if ($@) {
            my $sth = $dbh->prepare_cached(
                "SELECT funcid FROM $self->{prefix}funcmap WHERE funcname = ?");
            $sth->execute($funcname);
            $id = $sth->fetchrow_arrayref->[0]
                or croak "Can't find or create funcname $funcname: $@";
        }

        $self->{_funcmap}{$dbid}{$funcname} = $id;
    }

    $self->{_funcmap}{$dbid}{$funcname};
}

sub _insert_id {
    my ( $dbh, $sth, $table, $col ) = @_;

    my $driver = $dbh->{Driver}{Name};
    if ( $driver eq 'mysql' ) {
        return $dbh->{mysql_insertid};
    }
    elsif ( $driver eq 'Pg' ) {
        return $dbh->last_insert_id( undef, undef, undef, undef,
            { sequence => join( "_", $table, $col, 'seq' ) } );
    }
    elsif ( $driver eq 'SQLite' ) {
        return $dbh->func('last_insert_rowid');
    }
    else {
        croak "Don't know how to get last insert id for $driver";
    }
}

sub list_jobs {
    my ( $self, $arg ) = @_;

    die "No funcname" unless exists $arg->{funcname};

    my @options;
    push @options, {
        key   => 'run_after',
        op    => '<=',
        value => $arg->{run_after}
    } if exists $arg->{run_after};
    push @options, {
        key   => 'grabbed_until',
        op    => '<=',
        value => $arg->{grabbed_until}
    } if exists $arg->{grabbed_until};

    if ( $arg->{coalesce} ) {
        $arg->{coalesce_op} ||= '=';
        push @options, {
            key   => 'coalesce',
            op    => $arg->{coalesce_op},
            value => $arg->{coalesce}
        };
    }

    my @jobs;
    for my $dbh ( @{ $self->{databases} } ) {
        eval {
            my $funcid = $self->funcname_to_id( $dbh, $arg->{funcname} );

            my $sql   = "SELECT * FROM $self->{prefix}job WHERE funcid = ?";
            my @value = ($funcid);
            for (@options) {
                $sql .= " AND $_->{key} $_->{op} ?";
                push @value, $_->{value};
            }

            my $sth = $dbh->prepare_cached($sql);
            $sth->execute(@value);
            while ( my $ref = $sth->fetchrow_hashref ) {
                push @jobs, TheSchwartz::Simple::Job->new($ref);
            }
        };
    }

    return @jobs;
}

sub _bind_param_attr {
    my ( $dbh, $col ) = @_;

    return if $col ne 'arg';

    my $driver = $dbh->{Driver}{Name};
    if ( $driver eq 'Pg' ) {
        return { pg_type => DBD::Pg::PG_BYTEA() };
    }
    elsif ( $driver eq 'SQLite' ) {
        return DBI::SQL_BLOB();
    }
    return;
}

sub prefix {
    my $self = shift;

    $self->{prefix} = shift if @_;
    return $self->{prefix};
}


1;
__END__

=encoding utf-8

=for stopwords TheSchwartz DBI schwartz

=head1 NAME

TheSchwartz::Simple - Lightweight TheSchwartz job dispatcher using plain DBI

=head1 SYNOPSIS

  use DBI;
  use TheSchwartz::Simple;

  my $dbh = DBI->connect(...);
  my $client = TheSchwartz::Simple->new([ $dbh ]);
  $client->prefix("theschwartz_"); # optional
  my $job_id = $client->insert('funcname', $arg);

  my $job = TheSchwartz::Simple::Job->new;
  $job->funcname("WorkerName");
  $job->arg({ foo => "bar" });
  $job->uniqkey("uniqkey");
  $job->run_after( time + 60 );
  $client->insert($job);

  my @jobs = $client->list_jobs({ funcname => 'funcname' });
  for my $job (@jobs) {
      print $job->jobid;
  }

=head1 DESCRIPTION

TheSchwartz::Simple is yet another interface to insert a new job into
TheSchwartz database using plain DBI interface.

This module is solely created for the purpose of injecting a new job
from web servers without loading additional TheSchwartz and
Data::ObjectDriver modules onto your system. Your schwartz job worker
processes will still need to be implemented using the full featured
TheSchwartz::Worker module,

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@cpan.orgE<gt>

=head1 COPYRIGHT

Six Apart, Ltd. 2008-

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<TheSchwartz>

=cut
