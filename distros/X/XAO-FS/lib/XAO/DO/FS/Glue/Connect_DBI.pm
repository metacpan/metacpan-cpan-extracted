=head1 NAME

XAO::DO::FS::Glue::Connect_DBI - DBI/DBD base for XAO::FS drivers

=head1 SYNOPSIS

 use XAO::Objects;
 use base XAO::Objects->load(objname => 'FS::Glue::SQL_DBI');

 sub foo {
    my $self=shift;
    $self->sql_connect(
        dsn      => 'DBI:mysql:test_fs',
        user     => 'test',
        password => 'test',
    );
 }

=head1 DESCRIPTION

This module provides a base for all XAO::FS SQL drivers that choose to
be based on DBI/DBD foundation.

=head1 METHODS

=over

=cut

###############################################################################
package XAO::DO::FS::Glue::Connect_DBI;
use strict;
use XAO::Objects;
use XAO::Utils;
use DBI;

use base XAO::Objects->load(objname => 'FS::Glue::Connect_SQL');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Connect_DBI.pm,v 2.2 2008/02/21 02:22:15 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

=item sql_connect (%)

Establishes a connection to the database engine given. Arguments are:

 dsn        => standard DBI data source
 user       => optional user name
 password   => optional password

=cut

sub sql_connect ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    if(%$args) {
        $self->{'dsn'}=$args->{'dsn'} || throw $self "sql_connect - no 'dsn' given";
        $self->{'user'}=$args->{'user'};
        $self->{'password'}=$args->{'password'};
    }

    $self->{'sql'}=DBI->connect(
        $self->{'dsn'},
        $self->{'user'},
        $self->{'password'},
    ) || throw $self "sql_connect - can't connect to dsn='$self->{'dsn'}'";
}

###############################################################################

=item sql_connected ()

Checks and returns true if the database connection is currently
established.

=cut

sub sql_connected ($) {
    my $self=shift;
    ### dprint "Sql_connected: ".join('|',caller(1));

    return undef unless $self->{'sql'};

    my $rc=eval { $self->{'sql'}->do('select 1') };

    return $rc ? 1 : 0;
}

###############################################################################

=item sql_disconnect ()

Closes connection to the database.

=cut

sub sql_disconnect ($) {
    my $self=shift;

    $self->{'sql'}->disconnect if $self->{'sql'};
}

###############################################################################

=item sql_do ($;@)

Sends a single query to the database with no anticipation of any
results. Can take arguments just the way prepare/execute do.

It is allowed to call sql_do() with an array reference in the second
argument.

=cut

sub sql_do ($$;@) {
    my ($self,$query,@values)=@_;

    ### use Data::Dumper;
    if(@values && ref $values[0]) {
        ### dprint "SQL: $query";
        ### dprint Dumper($values[0]);
        $self->{'sql'}->do($query,undef,@{$values[0]}) ||
            throw $self "sql_do - SQL error: ".$self->{'sql'}->errstr;
    }
    else {
        ### dprint "SQL: $query";
        ### dprint Dumper(\@values);
        $self->{'sql'}->do($query,undef,@values) ||
            throw $self "sql_do - SQL error: ".$self->{'sql'}->errstr;
    }
}

sub sql_do_no_error ($$;@) {
    my ($self,$query)=@_;

    ### dprint "Sql_do_no_error($query): ".join('|',caller(1));

    $self->{'sql'}->do($query);

    ### dprint "Sql_do_no_error($query): DONE";
}

###############################################################################

=item sql_execute ($;@)

Executes a previously prepared statement optionally substituting some
values, see sql_prepare(). Example:

 my $pq=$self->sql_prepare("SELECT a,b FROM c WHERE d=?");
 foreach my $value (1..10) {
     $self->sql_execute($pq,$i);
     ...
 }

As a shortcut it can also accept a text query in the first argument
instead of manually calling sql_prepare() first. It is suggested to do
so whenever you plan to call sql_execute() just once.

It is allowed to call sql_execute() with an array reference in the
second argument.

Returns a piece of data that should be passed into sql_fetch_row()
method.

When done sql_finish() should be called with the return value of
sql_execute() as a parameter.

=cut

sub sql_execute ($$;@) {
    my ($self,$pq,@values)=@_;

    $pq=$self->sql_prepare($pq) unless ref $pq;

    ### use Data::Dumper;
    ### dprint "Executed with: ".Dumper(@values && ref($values[0]) ? $values[0] : \@values);

    $pq->execute(@values && ref($values[0]) ? @{$values[0]} : @values) ||
        throw $self "sql_execute - SQL error: ".$pq->errstr;

    return $pq;
}

###############################################################################

=item sql_fetch_row ($)

Returns a reference to an array containing next retrieved row. Example:

 my $qr=$self->sql_execute("SELECT a,b FROM c");
 my $row=$self->sql_fetch_row($qr);

Don't forget to call sql_finish() when you're done.

=cut

sub sql_fetch_row ($$) {
    my ($self,$qr)=@_;
    return $qr->fetchrow_arrayref;
}

###############################################################################

=item sql_finish ($)

Frees up whatever internal structures might be occupied as a result of
the previous call to sql_execute(). Example:

 my $qr=$self->sql_execute("SHOW TABLES");
 ...
 $self->sql_finish($qr);

=cut

sub sql_finish ($$) {
    my ($self,$qr)=@_;
    $qr->finish;
}

###############################################################################

=item sql_first_column ($)

An optimisation method -- returns a reference to the array containing
all first elements of each row of the results set. Example:

 my $qr=$self->sql_execute("SELECT unique_id FROM a");
 my $ids=$self->sql_first_column($qr);

There is no need to call sql_finish() after sql_first_column().

=cut

sub sql_first_column ($$) {
    my ($self,$qr)=@_;
    my @col;
    while(my $row=$qr->fetchrow_arrayref) {
        push @col,$row->[0];
    }
    $qr->finish;
    return \@col;
}

###############################################################################

=item sql_first_row ($)

An optimisation method -- returns a reference to the first row and
finished the query.

 my $qr=$self->sql_execute("SELECT a,b,c FROM t WHERE d=?",$uid);
 my $row=$self->sql_first_row($qr);

There is no need to call sql_finish() after sql_first_row().

=cut

###############################################################################

=item sql_prepare ($)

Prepares a query for subsequent execution using sql_execute()
method. Guaranteed to return a reference of some sort. Example:

 my $pq=$self->sql_prepare("SELECT a,b FROM c WHERE d=?");
 $self->sql_execute($pq,123);

=cut

sub sql_prepare ($$) {
    my ($self,$query)=@_;
    ### dprint "SQL_PREPARE: $query";
    return $self->{'sql'}->prepare($query) ||
        throw $self "sql_prepare - SQL error: ".$self->{'sql'}->errstr;
}

###############################################################################

sub need_unlock_on_error ($) {
    return 1;
}

###############################################################################
1;
__END__

=back

=head1 AUTHORS

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Further reading:
L<XAO::FS>,
L<XAO::DO::FS::Glue>.

=cut
