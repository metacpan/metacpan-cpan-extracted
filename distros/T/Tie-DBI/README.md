[![](https://github.com/toddr/Tie-DBI/workflows/linux/badge.svg)](https://github.com/toddr/Tie-DBI/actions) [![](https://github.com/toddr/Tie-DBI/workflows/macos/badge.svg)](https://github.com/toddr/Tie-DBI/actions) [![](https://github.com/toddr/Tie-DBI/workflows/windows/badge.svg)](https://github.com/toddr/Tie-DBI/actions)

# NAME

Tie::DBI - Tie hashes to DBI relational databases

# SYNOPSIS

    use Tie::DBI;
    tie %h,'Tie::DBI','mysql:test','test','id',{CLOBBER=>1};

    tie %h,'Tie::DBI',{db       => 'mysql:test',
                     table    => 'test',
                     key      => 'id',
                     user     => 'nobody',
                     password => 'ghost',
                     CLOBBER  => 1};

    # fetching keys and values
    @keys = keys %h;
    @fields = keys %{$h{$keys[0]}};
    print $h{'id1'}->{'field1'};
    while (($key,$value) = each %h) {
      print "Key = $key:\n";
      foreach (sort keys %$value) {
          print "\t$_ => $value->{$_}\n";
      }
    }

    # changing data
    $h{'id1'}->{'field1'} = 'new value';
    $h{'id1'} = { field1 => 'newer value',
                  field2 => 'even newer value',
                  field3 => "so new it's squeaky clean" };

    # other functions
    tied(%h)->commit;
    tied(%h)->rollback;
    tied(%h)->select_where('price > 1.20');
    @fieldnames = tied(%h)->fields;
    $dbh = tied(%h)->dbh;

# DESCRIPTION

This module allows you to tie Perl associative arrays (hashes) to SQL
databases using the DBI interface.  The tied hash is associated with a
table in a local or networked database.  One column becomes the hash
key.  Each row of the table becomes an associative array, from which
individual fields can be set or retrieved.

# USING THE MODULE

To use this module, you must have the DBI interface and at least one
DBD (database driver) installed.  Make sure that your database is up
and running, and that you can connect to it and execute queries using
DBI.

## Creating the tie

    tie %var,'Tie::DBI',[database,table,keycolumn] [,\%options]

Tie a variable to a database by providing the variable name, the tie
interface (always "Tie::DBI"), the data source name, the table to tie
to, and the column to use as the hash key.  You may also pass various
flags to the interface in an associative array.

- database

    The database may either be a valid DBI-style data source string of the
    form "dbi:driver:database\_name\[:other information\]", or a database
    handle that has previously been opened.  See the documentation for DBI
    and your DBD driver for details.  Because the initial "dbi" is always
    present in the data source, Tie::DBI will add it for you if necessary.

    Note that some drivers (Oracle in particular) have an irritating habit
    of appending blanks to the end of fixed-length fields.  This will
    screw up Tie::DBI's routines for getting key names.  To avoid this you
    should create the database handle with a **ChopBlanks** option of TRUE.
    You should also use a **PrintError** option of true to avoid complaints
    during STORE and LISTFIELD calls.  

- table

    The table in the database to bind to.  The table must previously have
    been created with a SQL CREATE statement.  This module will not create
    tables for you or modify the schema of the database.

- key

    The column to use as the hash key.  This column must prevoiusly have
    been defined when the table was created.  In order for this module to
    work correctly, the key column _must_ be declared unique and not
    nullable.  For best performance, the column should be also be declared
    a key.  These three requirements are automatically satisfied for
    primary keys.

It is possible to omit the database, table and keycolumn arguments, in
which case the module tries to retrieve the values from the options
array.  The options array contains a set of option/value pairs.  If
not provided, defaults are assumed.  The options are:

- user

    Account name to use for database authentication, if necessary.
    Default is an empty string (no authentication necessary).

- password

    Password to use for database authentication, if necessary.  Default is
    an empty string (no authentication necessary).

- db

    The database to bind to the hash, if not provided in the argument
    list.  It may be a DBI-style data source string, or a
    previously-opened database handle.

- table

    The name of the table to bind to the hash, if not provided in the
    argument list.

- key

    The name of the column to use as the hash key, if not provided in the
    argument list.

- CLOBBER (default 0)

    This controls whether the database is writable via the bound hash.  A
    zero value (the default) makes the database essentially read only.  An
    attempt to store to the hash will result in a fatal error.  A CLOBBER
    value of 1 will allow you to change individual fields in the database,
    and to insert new records, but not to delete entire records.  A
    CLOBBER value of 2 allows you to delete records, but not to erase the
    entire table.  A CLOBBER value of 3 or higher will allow you to erase
    the entire table.

        Operation                       Clobber      Comment

        $i = $h{strawberries}->{price}     0       All read operations
        $h{strawberries}->{price} += 5     1       Update fields
        $h{bananas}={price=>23,quant=>3}   1       Add records
        delete $h{strawberries}            2       Delete records
        %h = ()                            3       Clear entire table
        undef %h                           3       Another clear operation

    All database operations are contingent upon your access privileges.
    If your account does not have write permission to the database, hash
    store operations will fail despite the setting of CLOBBER.

- AUTOCOMMIT (default 1)

    If set to a true value, the "autocommit" option causes the database
    driver to commit after every store statement.  If set to a false
    value, this option will not commit to the database until you
    explicitly call the Tie::DBI commit() method.

    The autocommit option defaults to true.

- DEBUG (default 0)

    When the DEBUG option is set to a non-zero value the module will echo
    the contents of SQL statements and other debugging information to
    standard error.  Higher values of DEBUG result in more verbose (and
    annoying) output.

- WARN (default 1)

    If set to a non-zero value, warns of illegal operations, such as
    attempting to delete the value of the key column.  If set to a zero
    value, these errors will be ignored silently.

- CASESENSITIV (default 0)

    If set to a non-zero value, all Fieldnames are casesensitiv. Keep
    in mind, that your database has to support casesensitiv Fields if
    you want to use it.

# USING THE TIED ARRAY

The tied array represents the database table.  Each entry in the hash
is a record, keyed on the column chosen in the tie() statement.
Ordinarily this will be the table's primary key, although any unique
column will do.

Fetching an individual record returns a reference to a hash of field
names and values.  This hash reference is itself a tied object, so
that operations on it directly affect the database.

## Fetching information

In the following examples, we will assume a database table structured
like this one:

                    -produce-
    produce_id    price   quantity   description

    strawberries  1.20    8          Fresh Maine strawberries
    apricots      0.85    2          Ripe Norwegian apricots
    bananas       1.30    28         Sweet Alaskan bananas
    kiwis         1.50    9          Juicy New York kiwi fruits
    eggs          1.00   12          Farm-fresh Atlantic eggs

We tie the variable %produce to the table in this way:

    tie %produce,'Tie::DBI',{db    => 'mysql:stock',
                           table => 'produce',
                           key   => 'produce_id',
                           CLOBBER => 2 # allow most updates
                           };

We can get the list of keys this way:

    print join(",",keys %produce);
       => strawberries,apricots,bananas,kiwis

Or get the price of eggs thusly:

    $price = $produce{eggs}->{price};
    print "The price of eggs = $price";
        => The price of eggs = 1.2

String interpolation works as you would expect:

    print "The price of eggs is still $produce{eggs}->{price}"
        => The price of eggs is still 1.2

Various types of syntactic sugar are allowed.  For example, you can
refer to $produce{eggs}{price} rather than $produce{eggs}->{price}.
Array slices are fully supported as well:

    ($apricots,$kiwis) = @produce{apricots,kiwis};
    print "Kiwis are $kiwis->{description};
        => Kiwis are Juicy New York kiwi fruits

    ($price,$description) = @{$produce{eggs}}{price,description};
        => (2.4,'Farm-fresh Atlantic eggs')

If you provide the tied hash with a comma-delimited set of record
names, and you are **not** requesting an array slice, then the module
does something interesting.  It generates a single SQL statement that
fetches the records from the database in a single pass (rather than
the multiple passes required for an array slice) and returns the
result as a reference to an array.  For many records, this can be much
faster.  For example:

     $result = $produce{apricots,bananas};
         => ARRAY(0x828a8ac)

     ($apricots,$bananas) = @$result;
     print "The price of apricots is $apricots->{price}";
         => The price of apricots is 0.85

Field names work in much the same way:

     ($price,$quantity) = @{$produce{apricots}{price,quantity}};
     print "There are $quantity apricots at $price each";
         => There are 2 apricots at 0.85 each";

Note that this takes advantage of a bit of Perl syntactic sugar which
automagically treats $h{'a','b','c'} as if the keys were packed
together with the $; pack character.  Be careful not to fall into this
trap:

     $result = $h{join( ',', 'apricots', 'bananas' )};
         => undefined

What you really want is this:

     $result = $h{join( $;, 'apricots', 'bananas' )};
         => ARRAY(0x828a8ac)

## Updating information

If CLOBBER is set to a non-zero value (and the underlying database
privileges allow it), you can update the database with new values.
You can operate on entire records at once or on individual fields
within a record.

To insert a new record or update an existing one, assign a hash
reference to the record.  For example, you can create a new record in
%produce with the key "avocados" in this manner:

    $produce{avocados} = { price       => 2.00,
                           quantity    => 8,
                           description => 'Choice Irish avocados' };

This will work with any type of hash reference, including records
extracted from another table or database.

Only keys that correspond to valid fields in the table will be
accepted.  You will be warned if you attempt to set a field that
doesn't exist, but the other fields will be correctly set.  Likewise,
you will be warned if you attempt to set the key field.  These
warnings can be turned off by setting the WARN option to a zero value.
It is not currently possible to add new columns to the table.  You
must do this manually with the appropriate SQL commands.

The same syntax can be used to update an existing record.  The fields
given in the hash reference replace those in the record.  Fields that
aren't explicitly listed in the hash retain their previous values.  In
the following example, the price and quantity of the "kiwis" record
are updated, but the description remains the same:

    $produce{kiwis} = { price=>1.25,quantity=>20 };

You may update existing records on a field-by-field manner in the
natural way:

    $produce{eggs}{price} = 1.30;
    $produce{eggs}{price} *= 2;
    print "The price of eggs is now $produce{eggs}{price}";
        => The price of eggs is now 2.6.

Obligingly enough, you can use this syntax to insert new records too,
as in $produce{mangoes}{description}="Sun-ripened Idaho mangoes".
However, this type of update is inefficient because a separate SQL
statement is generated for each field.  If you need to update more
than one field at a time, use the record-oriented syntax shown
earlier.  It's much more efficient because it gets the work done with
a single SQL command.

Insertions and updates may fail for any of a number of reasons, most
commonly:

- 1. You do not have sufficient privileges to update the database
- 2. The update would violate an integrity constraint, such as
making a non-nullable field null, overflowing a numeric field, storing
a string value in a numeric field, or violating a uniqueness
constraint.

The module dies with an error message when it encounters an error
during an update.  To trap these erorrs and continue processing, wrap
the update an eval().

## Other functions

The tie object supports several useful methods.  In order to call
these methods, you must either save the function result from the tie()
call (which returns the object), or call tied() on the tie variable to
recover the object.

- connect(), error(), errstr()

    These are low-level class methods.  Connect() is responsible for
    establishing the connection with the DBI database.  Errstr() and
    error() return $DBI::errstr and $DBI::error respectively.  You may
    may override these methods in subclasses if you wish.  For example,
    replace connect() with this code in order to use persistent database
    connections in Apache modules:

        use Apache::DBI;  # somewhere in the declarations
        sub connect {
        my ($class,$dsn,$user,$password,$options) = @_;
           return Apache::DBI->connect($dsn,$user,
                                       $password,$options);
        }
         

- commit()

        (tied %produce)->commit();

    When using a database with the autocommit option turned off, values
    that are stored into the hash will not become permanent until commit()
    is called.  Otherwise they are lost when the application terminates or
    the hash is untied.

    Some SQL databases don't support transactions, in which case you will
    see a warning message if you attempt to use this function.

- rollback()

        (tied %produce)->rollback();

    When using a database with the autocommit option turned off, this
    function will roll back changes to the database to the state they were
    in at the last commit().  This function has no effect on database that
    don't support transactions.

- select\_where()

        @keys=(tied %produce)->select_where('price > 1.00 and quantity < 10');

    This executes a limited form of select statement on the tied table and
    returns a list of records that satisfy the conditions.  The argument
    you provide should be the contents of a SQL WHERE clause, minus the
    keyword "WHERE" and everything that ordinarily precedes it.  Anything
    that is legal in the WHERE clause is allowed, including function
    calls, ordering specifications, and sub-selects.  The keys to those
    records that meet the specified conditions are returned as an array,
    in the order in which the select statement returned them.

    Don't expect too much from this function.  If you want to execute a
    complex query, you're better off using the database handle (see below)
    to make the SQL query yourself with the DBI interface.

- dbh()

        $dbh = (tied %produce)->dbh();
        

    This returns the tied hash's underlying database handle.  You can use
    this handle to create and execute your own SQL queries.

- CLOBBER, DEBUG, WARN

    You can get and set the values of CLOBBER, DEBUG and WARN by directly
    accessing the object's hash:

        (tied %produce)->{DEBUG}++;

    This lets you change the behavior of the tied hash on the fly, such as
    temporarily granting your program write permission.  

    There are other variables there too, such as the name of the key
    column and database table.  Change them at your own risk!

# PERFORMANCE

What is the performance hit when you use this module rather than the
direct DBI interface?  It can be significant.  To measure the
overhead, I used a simple benchmark in which Perl parsed a 6180 word
text file into individual words and stored them into a database,
incrementing the word count with each store.  The benchmark then read
out the words and their counts in an each() loop.  The database driver
was mySQL, running on a 133 MHz Pentium laptop with Linux 2.0.30.  I
compared Tie::RDBM, to DB\_File, and to the same task using vanilla DBI
SQL statements.  The results are shown below:

                UPDATE         FETCH
    Tie::DBI      70 s        6.1  s
    Vanilla DBI   14 s        2.0  s
    DB_File        3 s        1.06 s

There is about a five-fold penalty for updates, and a three-fold
penalty for fetches when using this interface.  Some of the penalty is
due to the overhead for creating sub-objects to handle individual
fields, and some of it is due to the inefficient way the store and
fetch operations are implemented.  For example, using the tie
interface, a statement like $h{record}{field}++ requires as much as
four trips to the database: one to verify that the record exists, one
to fetch the field, and one to store the incremented field back.  If
the record doesn't already exist, an additional statement is required
to perform the insertion.  I have experimented with cacheing schemes
to reduce the number of trips to the database, but the overhead of
maintaining the cache is nearly equal to the performance improvement,
and cacheing raises a number of potential concurrency problems.

Clearly you would not want to use this interface for applications that
require a large number of updates to be processed rapidly.

# BUGS

# BUGS

The each() call produces a fatal error when used with the Sybase
driver to access Microsoft SQL server. This is because this server
only allows one query to be active at a given time.  A workaround is
to use keys() to fetch all the keys yourself.  It is not known whether
real Sybase databases suffer from the same problem.

The delete() operator will not work correctly for setting field values
to null with DBD::CSV or with DBD::Pg.  CSV files do not have a good
conception of database nulls.  Instead you will set the field to an
empty string.  DBD::Pg just seems to be broken in this regard.

# AUTHOR

Lincoln Stein, lstein@cshl.org

# COPYRIGHT

    Copyright (c) 1998, Lincoln D. Stein

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

# AVAILABILITY

The latest version can be obtained from:

    http://www.genome.wi.mit.edu/~lstein/Tie-DBI/
    

# SEE ALSO

perl(1), DBI(3), Tie::RDBM(3)
