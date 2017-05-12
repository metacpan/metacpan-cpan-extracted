package Tie::RDBM;

use strict;
use vars qw($VERSION %Types);
use Carp;
use DBI;
$VERSION = '0.73';

# %Types is used for creating the data table if it doesn't exist already.
# You may want to edit this.
%Types = (    # key          value          frozen    freeze  keyless
    'mysql'    => [qw/ varchar(127)  longblob       tinyint   1          0 /],
    'mSQL'     => [qw/ char(255)     char(255)      int       0          0 /],
    'Pg'       => [qw/ varchar(127)  varchar(2000)  int       0          0 /],
    'Sybase'   => [qw/ varchar(255)  varbinary(255) tinyint   1          0 /],
    'Oracle'   => [qw/ varchar(255)  varchar2(2000) integer   1          0 /],
    'CSV'      => [qw/ varchar(255)  varchar(255)   integer   1          1 /],
    'Informix' => [qw/ nchar(120)    nchar(2000)    integer   0          0 /],
    'Solid'    => [qw/ varchar(255)  varbinary(2000) integer  1          0 /],
    'ODBC'     => [qw/ varchar(255)  varbinary(2000) integer   1         0 /],
    'default'  => [qw/ varchar(255)  varchar(255)   integer   0          0 /],    #others
);

# list drivers that do run-time binding correctly
my %CAN_BIND = (
    'mysql'    => 1,
    'mSQL'     => 1,
    'Oracle'   => 1,
    'Pg'       => 1,
    'Informix' => 1,
    'Solid'    => 1,
    'ODBC'     => 1,
);

# Default options for the module
my %DefaultOptions = (
    'table'      => 'pdata',
    'key'        => 'pkey',
    'value'      => 'pvalue',
    'frozen'     => 'pfrozen',
    'user'       => '',
    'password'   => '',
    'autocommit' => 1,
    'create'     => 0,
    'drop'       => 0,
    'DEBUG'      => 0,
);

sub TIEHASH {
    my $class = shift;
    my ( $dsn, $opt ) = ref( $_[0] ) ? ( undef, $_[0] ) : @_;
    $dsn ||= $opt->{'db'};

    croak "Usage tie(%h,Tie::RDBM,<DBI_data_source>,\%options)" unless $dsn;
    if ($opt) {
        foreach ( keys %DefaultOptions ) {
            $opt->{$_} = $DefaultOptions{$_} unless exists( $opt->{$_} );
        }
    }
    else {
        $opt = \%DefaultOptions;
    }

    my ( $dbh, $driver );

    if ( UNIVERSAL::isa( $dsn, 'DBI::db' ) ) {
        $dbh    = $dsn;
        $driver = $dsn->{Driver}{Name};
    }
    else {
        $dsn = "dbi:$dsn" unless $dsn =~ /^dbi/;
        ($driver) = $dsn =~ /\w+:(\w+)/;

        # Try to establish connection with data source.
        delete $ENV{NLS_LANG} if $driver eq 'Oracle';    # allow 8 bit connections?
        $dbh = DBI->connect(
            $dsn,
            $opt->{user},
            $opt->{password},
            {
                AutoCommit => $opt->{autocommit},
                PrintError => 0,
                ChopBlanks => 1,
                Warn       => 0
            }
        );
        croak "TIEHASH: Can't open $dsn, $DBI::errstr" unless $dbh;
    }

    # A variety of shinanegans to handle freeze/thaw option.
    # We will serialize references if:
    # 1. The database driver supports binary types.
    # 2. The database table has a boolean field to indicate that a value is frozen.
    # 3. The Storable module is available.
    # we also check that "primary key" is recognized
    my $db_features = $Types{$driver} || $Types{'default'};
    my ($canfreeze) = $db_features->[3];
    my ($keyless)   = $db_features->[4];
    my ($haveStorable) = eval 'require Storable;';
    Storable->import(qw/nfreeze thaw/) if $haveStorable;
    $canfreeze &&= $haveStorable;

    # Check that the indicated table exists.  If it doesn't,
    # try to create it....

    # This query tests that a table with the correct fields is present.
    # I would prefer to use a where clause of 1=0 but some dumb drivers (mSQL)
    # treat this as a syntax error!!!
    my $q            = "select * from $opt->{table} where $opt->{key}=''";
    my $sth          = $dbh->prepare($q);
    my $structure_ok = 0;
    local ($^W) = 0;    # uninitialized variable problem
    if ( defined($sth) && $sth->execute() ne '' ) {

        # At least the key field exists.  Check whether the others do too.
        my (%field_names);
        grep( $field_names{ lc($_) }++, @{ $sth->{NAME} } );
        $structure_ok++ if $field_names{ $opt->{'value'} };
        $canfreeze &&= $field_names{ $opt->{'frozen'} };
    }

    unless ($structure_ok) {

        unless ( $opt->{'create'} || $opt->{'drop'} ) {
            my $err = $DBI::errstr;
            $dbh->disconnect;
            croak "Table $opt->{table} does not have expected structure and creation forbidden: $err";
        }

        $dbh->do("drop table $opt->{table}") if $opt->{'drop'};

        my ( $keytype, $valuetype, $frozentype ) = @{$db_features};
        my (@fields) = (
            $keyless ? "$opt->{key}    $keytype" : "$opt->{key}    $keytype primary key",
            "$opt->{value}  $valuetype"
        );
        push( @fields, ( $keyless ? "$opt->{frozen} $frozentype" : "$opt->{frozen} $frozentype not null" ) )
          if $canfreeze;
        $q = "create table $opt->{table} (" . join( ',', @fields ) . ")";
        warn "$q\n" if $opt->{DEBUG};
        $dbh->do($q) || do {
            my $err = $DBI::errstr;
            $dbh->disconnect;
            croak("Can't initialize data table: $err");
          }
    }

    return bless {
        'dbh'          => $dbh,
        'table'        => $opt->{'table'},
        'key'          => $opt->{'key'},
        'value'        => $opt->{'value'},
        'frozen'       => $opt->{'frozen'},
        'canfreeze'    => $canfreeze,
        'brokenselect' => $driver eq 'mSQL' || $driver eq 'mysql',
        'canbind'      => $CAN_BIND{$driver},
        'DEBUG'        => $opt->{DEBUG},
    }, $class;
}

sub FETCH {
    my ( $self, $key ) = @_;

    # this is a hack to avoid doing an unnecessary SQL select
    # during an each() loop.
    return $self->{'cached_value'}->{$key}
      if exists $self->{'cached_value'}->{$key};

    # create statement handler if it doesn't already exist.
    my $cols = $self->{'canfreeze'} ? "$self->{'value'},$self->{'frozen'}" : $self->{'value'};
    my $sth = $self->_run_query( 'fetch', <<END, $key );
select $cols from $self->{table} where $self->{key}=?
END
    my $result = $sth->fetchrow_arrayref();
    $sth->finish;
    return undef unless $result;
    $self->{'canfreeze'} && $result->[1] ? thaw( $result->[0] ) : $result->[0];
}

sub STORE {
    my ( $self, $key, $value ) = @_;

    my $frozen = 0;
    if ( ref($value) && $self->{'canfreeze'} ) {
        $frozen++;
        $value = nfreeze($value);
    }

    # Yes, this is ugly.  It is designed to minimize the number of SQL statements
    # for both database whose update statements return the number of rows updated,
    # and those (like mSQL) whose update statements don't.
    my ($r);
    if ( $self->{'brokenselect'} ) {
        return $self->EXISTS($key)
          ? $self->_update( $key, $value, $frozen )
          : $self->_insert( $key, $value, $frozen );
    }

    return $self->_update( $key, $value, $frozen ) || $self->_insert( $key, $value, $frozen );
}

sub DELETE {
    my ( $self, $key ) = @_;
    my $sth = $self->_run_query( 'delete', <<END, $key );
delete from $self->{table} where $self->{key}=?
END
    croak "Database delete statement failed: $DBI::errstr" if $sth->err;
    $sth->finish;
    1;
}

sub CLEAR {
    my $self = shift;
    my $dbh  = $self->{'dbh'};
    my $sth  = $self->_prepare( 'clear', "delete from $self->{table}" );
    $sth->execute();
    croak "Database delete all statement failed: $DBI::errstr" if $dbh->err;
    $sth->finish;
}

sub EXISTS {
    my ( $self, $key ) = @_;
    my $sth = $self->_run_query( 'exists', <<END, $key );
select $self->{key} from $self->{table} where $self->{key}=?
END
    croak "Database select statement failed: $DBI::errstr" unless $sth;
    $sth->fetch;
    my $rows = $sth->rows;
    $sth->finish;
    $rows >= 1;
}

sub FIRSTKEY {
    my $self = shift;

    delete $self->{'cached_value'};
    if ( $self->{'fetchkeys'} ) {
        $self->{'fetchkeys'}->finish();    # to prevent truncation in ODBC driver
        delete $self->{'fetchkeys'};
    }

    my $sth = $self->_prepare( 'fetchkeys', $self->{'canfreeze'} ? <<END1 : <<END2);
select $self->{'key'},$self->{'value'},$self->{'frozen'} from $self->{'table'}
END1
select $self->{'key'},$self->{'value'} from $self->{'table'}
END2

    $sth->execute() || croak "Can't execute select statement: $DBI::errstr";
    my $ref = $sth->fetch();
    return defined($ref) ? $ref->[0] : undef;
}

sub NEXTKEY {
    my $self = shift;

    # no statement handler defined, so nothing to iterate over
    return wantarray ? () : undef unless my $sth = $self->{'fetchkeys'};
    my $r = $sth->fetch();
    if ( !$r ) {
        $sth->finish;
        delete $self->{'cached_value'};
        return wantarray ? () : undef;
    }
    my ( $key, $value ) = ( $r->[0], $r->[2] ? thaw( $r->[1] ) : $r->[1] );
    $self->{'cached_value'}->{$key} = $value;
    return wantarray ? ( $key, $value ) : $key;
}

sub DESTROY {
    my $self = shift;
    foreach (qw/fetch update insert delete clear exists fetchkeys/) {
        $self->{$_}->finish if $self->{$_};
    }
    $self->{'dbh'}->disconnect() if $self->{'dbh'};
}

sub commit {
    $_[0]->{'dbh'}->commit();
}

sub rollback {
    $_[0]->{'dbh'}->rollback();
}

# utility routines
sub _update {
    my ( $self, $key, $value, $frozen ) = @_;
    my ($sth);
    if ( $self->{'canfreeze'} ) {
        $sth = $self->_run_query(
            'update',
            "update $self->{table} set $self->{value}=?,$self->{frozen}=? where $self->{key}=?",
            $value, $frozen, $key
        );
    }
    else {
        $sth = $self->_run_query(
            'update',
            "update $self->{table} set $self->{value}=? where $self->{key}=?",
            $value, $key
        );
    }
    croak "Update: $DBI::errstr" unless $sth;
    $sth->rows > 0;
}

sub _insert {
    my ( $self, $key, $value, $frozen ) = @_;
    my ($sth);
    if ( $self->{'canfreeze'} ) {
        $sth = $self->_run_query(
            'insert',
            "insert into $self->{table} ($self->{key},$self->{value},$self->{frozen}) values (?,?,?)",
            $key, $value, $frozen
        );
    }
    else {
        $sth = $self->_run_query(
            'insert',
            "insert into $self->{table} ($self->{key},$self->{value}) values (?,?)",
            $key, $value
        );
    }
    ( $sth && $sth->rows ) || croak "Update: $DBI::errstr";
}

sub _run_query {
    my $self = shift;
    my ( $tag, $query, @bind_variables ) = @_;
    if ( $self->{canbind} ) {
        my $sth = $self->_prepare( $tag, $query );
        return undef unless $sth->execute(@bind_variables);
        return $sth;
    }

    # if we get here, then we can't bind, so we replace ? with escaped parameters
    $query =~ s/\?/$self->{'dbh'}->quote(shift(@bind_variables))/eg;
    my $sth = $self->{'dbh'}->prepare($query);
    return undef unless $sth && $sth->execute;
    return $sth;
}

sub _prepare ($$$) {
    my ( $self, $tag, $q ) = @_;
    unless ( exists( $self->{$tag} ) ) {
        return undef unless $q;
        warn $q, "\n" if $self->{DEBUG};
        my $sth = $self->{'dbh'}->prepare($q);
        croak qq/Problems preparing statement "$q": $DBI::errstr/ unless $sth;
        $self->{$tag} = $sth;
    }
    else {
        $self->{$tag}->finish if $q;    # in case we forget
    }
    $self->{$tag};
}

1;
__END__

=head1 NAME

Tie::RDBM - Tie hashes to relational databases

=head1 SYNOPSIS

  use Tie::RDBM;
  tie %h,'Tie::RDBM','mysql:test',{table=>'Demo',create=>1,autocommit=>0};
  $h{'key1'} = 'Some data here';
  $h{'key2'} = 42;
  $h{'key3'} = { complex=>['data','structure','here'],works=>'true' };
  $h{'key4'} = new Foobar('Objects work too');
  print $h{'key3'}->{complex}->[0];
  tied(%h)->commit;
  untie %h;

=head1 DESCRIPTION

This module allows you to tie Perl associative arrays (hashes) to SQL
databases using the DBI interface.  The tied hash is associated with a
table in a local or networked database.  One field of the table becomes the
hash key, and another becomes the value.  Once tied, all the standard
hash operations work, including iteration over keys and values.

If you have the Storable module installed, you may store arbitrarily
complex Perl structures (including objects) into the hash and later
retrieve them.  When used in conjunction with a network-accessible
database, this provides a simple way to transmit data structures
between Perl programs on two different machines.

=head1 TIEING A DATABASE

   tie %VARIABLE,Tie::RDBM,DSN [,\%OPTIONS]

You tie a variable to a database by providing the variable name, the
tie interface (always "Tie::RDBM"), the data source name, and an
optional hash reference containing various options to be passed to the
module and the underlying database driver.

The data source may be a valid DBI-style data source string of the
form "dbi:driver:database_name[:other information]", or a
previously-opened database handle.  See the documentation for DBI and
your DBD driver for details.  Because the initial "dbi" is always
present in the data source, Tie::RDBM will automatically add it for
you.

The options array contains a set of option/value pairs.  If not
provided, defaults are assumed.  The options are:

=over 4

=item user ['']

Account name to use for database authentication, if necessary.
Default is an empty string (no authentication necessary).

=item password ['']

Password to use for database authentication, if necessary.  Default is
an empty string (no authentication necessary).

=item db ['']

The data source, if not provided in the argument.  This allows an
alternative calling style:

   tie(%h,Tie::RDBM,{db=>'dbi:mysql:test',create=>1};

=item table ['pdata']

The name of the table in which the hash key/value pairs will be
stored.

=item key ['pkey']

The name of the column in which the hash key will be found.  If not
provided, defaults to "pkey".

=item value ['pvalue']

The name of the column in which the hash value will be found.  If not
provided, defaults to "pvalue".

=item frozen ['pfrozen']

The name of the column that stores the boolean information indicating
that a complex data structure has been "frozen" using Storable's
freeze() function.  If not provided, defaults to "pfrozen".  

NOTE: if this field is not present in the database table, or if the
database is incapable of storing binary structures, Storable features
will be disabled.

=item create [0]

If set to a true value, allows the module to create the database table
if it does not already exist.  The module emits a CREATE TABLE command
and gives the key, value and frozen fields the data types most
appropriate for the database driver (from a lookup table maintained in
a package global, see DATATYPES below).

The success of table creation depends on whether you have table create
access for the database.

The default is not to create a table.  tie() will fail with a fatal
error.

=item drop [0]

If the indicated database table exists, but does not have the required
key and value fields, Tie::RDBM can try to add the required fields to
the table.  Currently it does this by the drastic expedient of
DROPPING the table entirely and creating a new empty one.  If the drop
option is set to true, Tie::RDBM will perform this radical
restructuring.  Otherwise tie() will fail with a fatal error.  "drop"
implies "create".  This option defaults to false.

A future version of Tie::RDBM may implement a last radical
restructuring method; differences in DBI drivers and database
capabilities make this task harder than it would seem.

=item autocommit [1]

If set to a true value, the "autocommit" option causes the database
driver to commit after every store statement.  If set to a false
value, this option will not commit to the database until you
explicitly call the Tie::RDBM commit() method.

The autocommit option defaults to true.

=item DEBUG [0]

When the "DEBUG" option is set to a true value the module will echo
the contents of SQL statements and other debugging information to
standard error.

=back

=head1 USING THE TIED ARRAY

The standard fetch, store, keys(), values() and each() functions will
work as expected on the tied array.  In addition, the following
methods are available on the underlying object, which you can obtain
with the standard tie() operator:

=over 4

=item commit()

   (tied %h)->commit();

When using a database with the autocommit option turned off, values
that are stored into the hash will not become permanent until commit()
is called.  Otherwise they are lost when the application terminates or
the hash is untied.

Some SQL databases don't support transactions, in which case you will
see a warning message if you attempt to use this function.

=item rollback()

   (tied %h)->rollback();

When using a database with the autocommit option turned off, this
function will roll back changes to the database to the state they were
in at the last commit().  This function has no effect on database that
don't support transactions.

=back

=head1 DATABASES AND DATATYPES

Perl is a weakly typed language.  Databases are strongly typed.  When
translating from databases to Perl there is inevitably some data type
conversion that you must worry about.  I have tried to keep the
details as transparent as possible without sacrificing power; this
section discusses the tradeoffs.

If you wish to tie a hash to a preexisting database, specify the
database name, the table within the database, and the fields you wish
to use for the keys and values.  These fields can be of any type that
you choose, but the data type will limit what can be stored there.
For example, if the key field is of type "int", then any numeric value
will be a valid key, but an attempt to use a string as a key will
result in a run time error.  If a key or value is too long to fit into
the data field, it will be truncated silently.

For performance reasons, the key field should be a primary key, or at
least an indexed field.  It should also be unique.  If a key is
present more than once in a table, an attempt to fetch it will return
the first record found by the SQL select statement.

If you wish to store Perl references in the database, the module needs
an additional field in which it can store a flag indicating whether
the data value is a simple or a complex type.  This "frozen" field is
treated as a boolean value.  A "tinyint" data type is recommended, but
strings types will work as well.

In a future version of this module, the "frozen" field may be turned
into a general "datatype" field in order to minimize storage.  For
future compatability, please use an integer for the frozen field.

If you use the "create" and/or "drop" options, the module will
automatically attempt to create a table for its own use in the
database if a suitable one isn't found.  It uses information defined
in the package variable %Tie::RDBM::Types to determine what kind of
data types to create.  This variable is indexed by database driver.
Each index contains a four-element array indicating what data type to
use for each of the key, value and frozen fields, and whether the
database can support binary types.  Since I have access to only a
limited number of databases, the table is currently short:

   Driver     Key Field      Value Field     Frozen Field  Binary?

   mysq       varchar(127)   longblob        tinyint       1
   mSQL       char(255)      char(255)       int           0
   Sybase     varchar(255)   varbinary(255)  tinyint       1
   default    varchar(255)   varbinary(255)  tinyint       1

The "default" entry is used for any driver not specifically
mentioned.  

You are free to add your own entries to this table, or make
corrections.  Please send me e-mail with any revisions you make so
that I can share the wisdom.

=head1 STORABLE CAVEATS

Because the Storable module packs Perl structures in a binary format,
only those databases that support a "varbinary" or "blob" type can
handle complex datatypes.  Furthermore, some databases have strict
limitations on the size of these structures.  For example, SyBase and
MS SQL Server have a "varbinary" type that maxes out at 255 bytes.
For structures larger than this, the databases provide an "image" type
in which storage is allocated in 2K chunks!  Worse, access to this
image type uses a non-standard SQL extension that is not supported by
DBI.

Databases that do not support binary fields cannot use the Storable
feature.  If you attempt to store a reference to a complex data type
in one of these databases it will be converted into strings like
"HASH(0x8222cf4)", just as it would be if you tried the same trick
with a conventional tied DBM hash.  If the database supports binary
fields of restricted length, large structures may be silently
truncated.  Caveat emptor.

It's also important to realize the limitations of the Storable
mechanism.  You can store and retrieve entire data structures, but you
can't twiddle with individual substructures and expect them to persist
when the process exits.  To update a data structure, you must fetch it
from the hash, make the desired modifications, then store it back into
the hash, as the example below shows:

B<Process #1:>
   tie %h,'Tie::RDBM','mysql:Employees:host.somewhere.com',
                   {table=>'employee',user=>'fred',password=>'xyzzy'};
   $h{'Anne'} = { office=>'999 Infinity Drive, Rm 203',
                  age    =>  29,
                  salary =>  32100 };
   $h{'Mark'} = { office=>'000 Iteration Circle, Rm -123',
                  age    =>  32,
                  salary =>  35000 };

B<Process #2:>
   tie %i,'Tie::RDBM','mysql:Employees:host.somewhere.com',
                   {table=>'employee',user=>'george',password=>'kumquat2'};
   foreach (keys %i) {
      $info = $i{$_};
      if ($info->{age} > 30) {
         # Give the oldies a $1000 raise
         $info->{salary} += 1000;  
         $i{$_} = $info;
      }
   }

This example also demonstrates how two Perl scripts running on
different machines can use Tie::RDBM to share complex data structures
(in this case, the employee record) without resorting to sockets,
remote procedure calls, shared memory, or other gadgets

=head1 PERFORMANCE

What is the performance hit when you use this module?  It can be
significant.  I used a simple benchmark in which Perl parsed a 6180
word text file into individual words and stored them into a database,
incrementing the word count with each store.  The benchmark then read
out the words and their counts in an each() loop.  The database driver
was mySQL, running on a 133 MHz Pentium laptop with Linux 2.0.30.  I
compared Tie::RDBM, to DB_File, and to the same task using vanilla DBI
SQL statements.  The results are shown below:

              STORE       EACH() LOOP
  Tie::RDBM     28 s        2.7  s
  Vanilla DBI   15 s        2.0  s
  DB_File        3 s        1.08 s

During stores, there is an approximately 2X penalty compared to
straight DBI, and a 15X penalty over using DB_File databases.  For the
each() loop (which is dominated by reads), the performance is 2-3
times worse than DB_File and much worse than a vanilla SQL statement.
I have not investigated the bottlenecks.

=head1 TO DO LIST

   - Store strings, numbers and data structures in separate
     fields for space and performance efficiency.

    - Expand data types table to other database engines.

    - Catch internal changes to data structures and write them into
      database automatically.

=head1 BUGS

Yes.

=head1 AUTHOR

Lincoln Stein, lstein@w3.org

=head1 COPYRIGHT

  Copyright (c) 1998, Lincoln D. Stein

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AVAILABILITY

The latest version can be obtained from:
   
   http://www.genome.wi.mit.edu/~lstein/Tie-DBM/

=head1 SEE ALSO

perl(1), DBI(3), Storable(3)

=cut
