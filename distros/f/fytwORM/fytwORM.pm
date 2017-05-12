package fytwORM;

use strict;
no strict "refs";
our $VERSION = "0.0.1";

use Carp;

my $columns = {};
our $AUTOLOAD;

sub new {
    my $class = shift;
    my $self = {
        _internal => {
            db_obj => shift,
            class  => $class,
            name   => shift || lc((split(/::/, $class))[-1])
        }
    };
    return undef if ( ! $self->{'_internal'}{'db_obj'} );
    bless $self;
    if ( @_ ) {
        $self->select(@_);
        return undef if ( ! $self->{'_internal'}{'from_db'} );
    }
    $columns = \%{$class."::columns"};
    map { 
        push @{$self->{'_internal'}{'PK'}}, $_ if ( $columns->{$_}{'PK'} )  
    } sort keys %{$columns};

    return $self;
}

sub select {
    my $self = shift;
    my $args = shift;
    my $opts = shift;

    my $sql = $self->{'_internal'}{'sql'};

    if ( ! $sql ) {
        $sql = "
            select 
        " . join(", ", keys %{$columns}) . " 
            from  
        " . $self->{'_internal'}{'name'};

        if ( scalar(keys%{$args}) > 0 ) {
            $sql .= " where " . join(" and ", map { "$_ = ?" } sort keys %{$args} );
        }

        if ( $opts->{'order_by'} ) {
            $sql .= " order by " . join(", ", $opts->{'order_by'});
        }
    }

    my $ret;
    eval {
        my $dbh = $args->{'dbh'} || $self->{'_internal'}{'db_obj'}->connect();
        my $sth = $dbh->prepare($sql);
        $sth->execute(map { $args->{$_} } sort keys %{$args} );
        while ( my $row = $sth->fetchrow_hashref ) {
            if ( ! $self->{'_internal'}{'from_db'} && ! $opts->{'no_pop'} ) {
                map { $self->{$_} = $row->{$_} } keys %{$columns};
                $self->{'_internal'}{'from_db'} = 1;
            }
            push @{$ret}, $row;
        }
    };
    confess "DB error: $@ [$sql]" if ( $@ );

    $self->{'_internal'}{'sql'} = undef;
    return $ret;
}

sub insert {
    my $self = shift;
    my $args = shift;
    my $opts = shift;

    my $sql = $self->{'_internal'}{'sql'};
    if ( ! $sql ) { 
        $sql = "
            insert into " . $self->{'_internal'}{'name'} . "
                ( " . join(", ", sort keys %{$columns}) . " )
            values
                ( " . join(", ", map {$columns->{$_}{'default'} || "?"} sort keys %{$columns}) . " )";
    }

    my @query_args;
    if ( $self->{'_internal'}{'sql'} ) {
        @query_args = map { $args->{$_} } sort keys %{$args};
    }
    else {
        map { push @query_args, $self->{$_} if ( ! $columns->{$_}{'default'} ) } sort keys %{$columns};
    }

    my $ret;
    eval {
        my $dbh = $args->{'dbh'} || $self->{'_internal'}{'db_obj'}->connect();
        my $sth = $dbh->prepare($sql);
        $sth->execute(@query_args);

        if ( $sth->{NUM_OF_FIELDS} ) {
            while ( my $row = $sth->fetchrow_hashref ) {
                push @{$ret}, $row;
            }
        }
    };
    confess "DB error: $@ [$sql]" if ( $@ );

    $self->{'_internal'}{'sql'} = undef;
    return $ret;
}

sub update {
    my $self = shift;
    my $args = shift;
    my $opts = shift;

    my $sql = $self->{'_internal'}{'sql'};
    if ( ! $sql ) {
        $sql =  "
            update " . $self->{'_internal'}{'name'} . " set " 
            .   join(", ", 
                    grep { $_ } 
                    map { 
                        "$_ = ?" if ( $columns->{$_}{'perms'} eq 'rw' ) 
                    } sort keys %{$columns} 
                )
            . " where " .
            join(" and ", 
                map { "$_ = ?" } @{$self->{'_internal'}{'PK'}}
            );
    }

    my @query_args;
    if ( $self->{'_internal'}{'sql'} ) {
        @query_args = map { $args->{$_} } sort keys %{$args};
    }
    else {
        map { push @query_args, $self->{$_} if ( ! $columns->{$_}{'PK'} ) } sort keys %{$columns};
        map { push @query_args, $self->{$_} } @{$self->{'_internal'}{'PK'}};
    }

    my $ret;
    eval {
        my $dbh = $args->{'dbh'} || $self->{'_internal'}{'db_obj'}->connect();
        my $sth = $dbh->prepare($sql);
        $sth->execute(@query_args);

        if ( $sth->{NUM_OF_FIELDS} ) {
            while ( my $row = $sth->fetchrow_hashref ) {
                push @{$ret}, $row;
            }
        }
    };
    confess "DB error: $@ [$sql]" if ( $@ );

    $self->{'_internal'}{'sql'} = undef;
    return $ret;
}

sub delete {
    my $self = shift;
    my $args = shift;
    my $opts = shift;

    my $sql = $self->{'_internal'}{'sql'};
    if ( ! $sql ) {
        $sql =  "
            delete from " . $self->{'_internal'}{'name'} . " where "
            . join(" and ", map { "$_ = ?" } @{$self->{'_internal'}{'PK'}} );
        ;
    }

    my @query_args;
    if ( $self->{'_internal'}{'sql'} ) {
        @query_args = map { $args->{$_} } sort keys %{$args};
    }
    else {
        @query_args = map { $self->{$_} } @{$self->{'_internal'}{'PK'}};
    }

    my $ret;
    eval {
        my $dbh = $args->{'dbh'} || $self->{'_internal'}{'db_obj'}->connect();
        my $sth = $dbh->prepare($sql);
        $sth->execute(@query_args);

        if ( $sth->{NUM_OF_FIELDS} ) {
            while ( my $row = $sth->fetchrow_hashref ) {
                push @{$ret}, $row;
            }
        }
    };
    confess "DB error: $@ [$sql]" if ( $@ );

    $self->{'_internal'}{'sql'} = undef;
    return $ret;
}

sub save {
    my $self = shift;
    if ( $self->{'_internal'}{'from_db'} ) {
        return $self->update(@_);
    }
    else {
        return $self->insert(@_);
    }
}

sub sql {
    my $self = shift;
    $self->{'_internal'}{'sql'} = shift;
}

sub AUTOLOAD {
    my $self = shift;
    (my $method = $AUTOLOAD) =~ s/.*:://;
    confess "$method not implemented" if ( ! defined $columns->{$method} );
    $self->{$method} = shift if ( $columns->{$method}{'perms'} eq 'rw' && @_ );
    return $self->{$method};
}

1;
__END__

=head1 NAME

fytwORM - f%#k you thats why ORM, an ORM that doesn't do a lot and doesn't care that you don't like it.

=head1 SYNOPSIS

  package Foo;
  our %columns = (
    'foo' => {
        nulls   => 0,
        PK      => 1,
        default => 'default',
        perms   => 'r'
    },
    'bar' => {
        nulls   => 0,
        perms   => 'rw'
    },
    'baz' => {
        nulls   => 0,
        perms   => 'rw',
        FK      => 'Foo::Bar'
    }
  );
  use base 'fytwORM';
  1;

=head1 DESCRIPTION

This is meant to be a bare minimum ORM used for prototyping / proof of concepts.  In other words
meant to make concepts quick to develop, and then you can move on to something else.  It will provide
objects to your tables that can be manipulated and saved back, easy syntax to get out of your way, and
really nothing else, you probably won't like it.

fytwORM will not look up the definition of a table on the fly, they need added to the package inheriting
from fytwORM.  Helper script(s) are provided to create modules for you to use with fytwORM.

fytwORM will not try to figure out if a query is going to work or not.  It will send them to the DB and
errors will be returned to you courtesy of confess.

=head2 METHODS

=over 4

=item new($db_obj, $table)

C<$db_obj> is an object that provides access to your database.  It should provide a connect method that
returns a DBI object or equivalent.  connect will be called each time you call select, insert, etc. so the object
should cache its connection, do pooling, whatever.

If C<$table> is not passed, the package inheriting from fytwORM will have its package name split apart and 
fytwORM will assume that the table name it is supposed to use is the lowercase version of the last part of 
the name.  ex. if you have Foo::Bar::Baz the table name will be baz.

=item select($args, $opts)

runs a select on the objects table for all the columns in the table.  The first result sent back is
populated into $self.  All the rows are pushed onto an array ref and returned to you.

$args is a hash ref of column => value that will be used in the where clause.  Not passing any args
results in no where clause.

$opts is a hash ref of options that have various uses.  At the moment they are:

  order_by = array of items to order by, used blindly so you can do things like 
  $opts->{'order_by'} = [ "foo", "lower(bar)", "baz desc nulls first" ]

  no_pop = setting to true will cause fytwORM to not populate the object with the return
  of the query, it will still pass the results back to you.

=item insert($args, $opts)

like select but does an insert

if $args is not passed, the where clause will be "where <PK> = $self->{<PK>}"

=item update($args, $opts)

like select but does an update

if $args is not passed, the where clause will be "where <PK> = $self->{<PK>}"

=item delete($args, $opts)

like select but does a delete

=item save()

Will attempt to save the object back to the DB.  If this object was pulled from the DB to 
begin with, update will be called, if not, then insert is used.

Any arguments passed to save will be passed along to insert or update.

=item sql($sql)

Call with valid SQL.  Will set an internal "flag" with the SQL provided, and on the next call to 
select, insert, update or delete fytwORM will use your SQL instead of what it would normally generate.

=back

=cut
