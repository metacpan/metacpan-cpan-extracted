=head1 NAME

XAO::DO::FS::Glue::Connect_SQL - basic SQL connection

=head1 SYNOPSIS

Only provides pure virtual methods that are overriden in actual drivers.

=head1 DESCRIPTION

=head1 METHODS

=over

=cut

###############################################################################
package XAO::DO::FS::Glue::Connect_SQL;
use strict;
use XAO::Objects;
use XAO::Utils;

use base XAO::Objects->load(objname => 'Atom');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Connect_SQL.pm,v 2.1 2007/05/09 21:03:09 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

=item sql_connect (%)

Establishes a connection to the database engine given. Arguments are:

 dsn        => data source name (DBI:dbname:options)
 user       => optional user name
 password   => optional password

=cut

sub sql_connect ($%) {
    my $self=shift;
    throw $self ((caller(0))[3])." - pure virtual method called";
}

###############################################################################

=item sql_connected ()

Returns true if the database connection is currently established.

=cut

sub sql_connected ($) {
    return shift->{'sql'} ? 1 : 0;
}

###############################################################################

=item sql_disconnect ()

Closes connection to the database.

=cut

sub sql_disconnect ($) {
    my $self=shift;
    throw $self ((caller(0))[3])." - pure virtual method called";
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
    throw $self ((caller(0))[3])." - pure virtual method called";
}

sub sql_do_no_error ($$;@) {
    my ($self,$query)=@_;
    throw $self ((caller(0))[3])." - pure virtual method called";
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
    throw $self ((caller(0))[3])." - pure virtual method called";
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
    throw $self ((caller(0))[3])." - pure virtual method called";
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
    throw $self ((caller(0))[3])." - pure virtual method called";
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
    throw $self ((caller(0))[3])." - pure virtual method called";
}

###############################################################################

=item sql_first_row ($)

An optimisation method -- returns a reference to the first row and
finished the query.

 my $qr=$self->sql_execute("SELECT a,b,c FROM t WHERE d=?",$uid);
 my $row=$self->sql_first_row($qr);

There is no need to call sql_finish() after sql_first_row().

=cut

sub sql_first_row ($$) {
    my ($self,$qr)=@_;
    my $row=$self->sql_fetch_row($qr);
    $self->sql_finish($qr);
    return $row;
}

###############################################################################

=item sql_prepare ($)

Prepares a query for subsequent execution using sql_execute()
method. Guaranteed to return a reference of some sort. Example:

 my $pq=$self->sql_prepare("SELECT a,b FROM c WHERE d=?");
 $self->sql_execute($pq,123);

=cut

sub sql_prepare ($$) {
    my ($self,$query)=@_;
    throw $self ((caller(0))[3])." - pure virtual method called";
}

###############################################################################
1;
__END__

=back

=head1 AUTHORS

Copyright (c) 2005,2007 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Further reading:
L<XAO::FS>,
L<XAO::DO::FS::Glue>.

=cut
