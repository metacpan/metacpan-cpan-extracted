package Tie::RDBM::Cached;
use strict;
use warnings;
use vars qw($VERSION @ISA);
use Tie::RDBM;
use Carp;
$VERSION = '0.03';
@ISA = qw(Tie::RDBM);

sub TIEHASH {
    my $type = shift;
    my $class = ref($type) || $type;
    my ($dsn,$opt) = ref($_[0]) ? (undef,$_[0]) : @_;
    my $self  = $class->SUPER::TIEHASH($dsn,$opt);
    
    $self->{cache_size} = $opt->{cache_size};
    $self->{cache} = _create_cache($opt->{cache_type});
    
    bless ($self, $class);
    return $self;
}

sub FETCH {
    my($self,$key) = @_;
    if($self->{'cache_size'} > 0) {
        if($self->{'cache'}->{$key}) {
            return $self->{'cache'}->{$key};
        }
    }  
    return $self->SUPER::FETCH($key);
}

sub STORE {
    my($self,$key,$value) = @_;
    if($self->{'cache_size'} > 0) {
        $self->{'cache'}->{$key} = $value; 
        
        if( keys %{ $self->{'cache'} } <= $self->{'cache_size'} ) {
            return;
        }else {
            $self->_flush_cache();
            return;
        }
    }
    return $self->SUPER::STORE($key,$value);
}

sub EXISTS {
    my($self,$key) = @_;
    if($self->{'cache'}->{$key}) {
        # We must return a true value
        return 1;
    } 
    return $self->SUPER::EXISTS($key);
}

sub commit {
    my $self = shift;
    $self->_flush_cache();
}  

sub _flush_cache {
    my $self = shift;
    my ($key,$value);
    while ( ($key, $value) = each %{ $self->{'cache'} } ) {
        my $frozen = 0;
        if (ref($value) && $self->{'canfreeze'}) {
            $frozen++;
            $value = $self->SUPER::nfreeze($value);
        }

        if ($self->{'brokenselect'}) {
           $self->EXISTS($key) ? $self->SUPER::_update($key,$value,$frozen)
                                       : $self->SUPER::_insert($key,$value,$frozen);
        }else {
           $self->SUPER::_update($key,$value,$frozen) || $self->SUPER::_insert($key,$value,$frozen);
        }
    }
    if($self->{'insert'}) { $self->{'insert'}->finish; }
    if($self->{'update'}) { $self->{'update'}->finish; }

    $self->SUPER::commit();
    
    %{ $self->{'cache'}} = ();
    return;
}

sub DELETE {
    my($self,$key) = @_;
    if( $self->{'cache'}->{$key} ) {
        delete($self->{'cache'}->{$key} );
    }    
    $self->SUPER::DELETE($key);
}

sub CLEAR {
    my $self = shift;
    $self->{'cache'} = ();
    $self->SUPER::CLEAR();
}

sub FIRSTKEY {
    my $self = shift;
    if( keys %{ $self->{'cache'} } > 0) {
        $self->_flush_cache();
    }
    $self->SUPER::FIRSTKEY();
}

sub NEXTKEY {
    my $self = shift;
    if( keys %{ $self->{'cache'} } > 0) {
        $self->_flush_cache();
    }
    $self->SUPER::NEXTKEY();
}

sub DESTROY {
    my $self = shift;
    $self->{'cache'} = ();
    $self->SUPER::DESTROY();
}

sub _create_cache {
    my ($type) = @_;
    if ($type eq 'HASH') {
        return {};
    }
    return {};
}
# XXXX Need to finish this.
sub _berkeley_closure {
    my $self = shift;
    return sub {
                 my $key = shift;
                 if (@_) { $self->{$key} = shift }
                 return    $self->{$key};
               };
}


1;
__END__

=head1 NAME

Tie::RDBM::Cached - Tie hashes to relational databases.

=head1 SYNOPSIS

=head1 DESCRIPTION

In addition to Tie::RDBM this module provides a caching method for fast 
updates to data. This can be EASILY achieved by the user with a little 
effort without resorting to this module. I wrote the module because I like 
the interface to the hash and once done forever usefull. Luckily for me 
Lincoln D. Stein done most of the hard work in Tie::RDBM.

For more information please see the Documentation for Tie::RDBM. I will 
document where this module adds functionality to the base class or deviates 
from base class usage. 

Please note that where you see "Tie::RDBM::Cached" in the documentation that 
the functionality or action may be inherited from Tie::RDBM.

=head1 TIEING A DATABASE

   tie %VARIABLE,Tie::RDBM::Cached,DSN [,\%OPTIONS]

You tie a variable to a database by providing the variable name, the
tie interface (always "Tie::RDBM::Cached"), the data source name, and an
optional hash reference containing various options to be passed to the
module and the underlying database driver.

The data source may be a valid DBI-style data source string of the
form "dbi:driver:database_name[:other information]", or a
previously-opened database handle.  See the documentation for DBI and
your DBD driver for details.  Because the initial "dbi" is always
present in the data source, Tie::RDBM::Cached will automatically add it 
for you.

The options array contains a set of option/value pairs.  If not
provided, defaults are assumed.  The options with defaults are:

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

   tie(%h,Tie::RDBM::Cached,{db=>'dbi:mysql:test',create=>1};

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
key and value fields, Tie::RDBM::Cached can try to add the required fields to
the table.  Currently it does this by the drastic expedient of
DROPPING the table entirely and creating a new empty one.  If the drop
option is set to true, Tie::RDBM::Cached will perform this radical
restructuring.  Otherwise tie() will fail with a fatal error.  "drop"
implies "create".  This option defaults to false.

=item autocommit [1] 

If set to a true value, the "autocommit" option causes the database
driver to commit after every SQL statement. 

NOTE, This options not operate the same as the "$dbh->{AutoCommit}" 
option associated with a DBI database handle. During certain operations 
on the Tied Hash the data must be flushed from the Cache and committed to 
the database. What it does do is ensure that when the records are flushed 
they are not committed individually. When set to 0, only after the last 
record has been flushed from the cache will the data be committed or if you 
call the commit() method explicitly.  

The autocommit option defaults to true.

=item DEBUG [0]

When the "DEBUG" option is set to a true value the module will echo
the contents of SQL statements and other debugging information to
standard error.


=item cache_type ['HASH']

You will eventually have a choice between using a HASH or a BerkeleyDB
file as the cache.


=item cache_size [0]

This option allows you to specify the size the cache will be allowed 
to grow to before it is committed to the database. 

=back

=head1 USING THE TIED ARRAY

The standard fetch, store, keys(), values() and each() functions will
work as expected on the tied array.  In addition, the following
methods are available on the underlying object, which you can obtain
with the standard tie() operator:

=over 4

=item commit()

   (tied %h)->commit();

This function has been overridden. It will flush the cache then commit to 
the database, otherwise it performs the same function as the base class.
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

=head1 PERFORMANCE

What is the performance hit when you use this module?  This is very
dependant on how you are using the data. If you are doing raw inserts
of large amounts of data then I don't recommend using this module
because the hit performance is quite dramatic. If however you are
doing a large amount of updates on the data and most of the updates
will fall inside the cache then this module can increase the
performance of these operations considerably compared with Tie::RDBM. 

Unfortunately deletes do not offer any gain in performance when using
this module. The reason for the performance drop is because when using
a hash tied to a database we need to check for existance before we can
carry out an insert or update. This adds an extra SQL statement to the
operation. There is also a performance hit using "Tie".

The following code will show you roughly how I tested the performance.
It is not a definitive guide and you should carry out your own tests.

 my $update_counter = 50000;
 my $rand_counter = 10000;
 my $cache_size = 0;
 my $counter = 0;
 
 my %HASH;
 while($counter < $update_counter) {
     $random = int(rand($rand_counter));
     $HASH{$counter} = $random;
     $counter++;
 }
 my ($key, $value);
 $start_time = new Benchmark;
 while( ($key, $value) = each %HASH ) {
     $CACHE{$value} = $key; 
 }
 tied(%CACHE)->commit;
 $end_time = new Benchmark;
 $difference = timediff($end_time, $start_time);
 print "\nIt took Tie::RDBM::Cached ", timestr($difference), "\n\n"; 


The "%CACHE" hash in the code is the tied hash. The same code was used for 
both Tie::RDBM and Tie::RDBM::Cached. The following code was used for the 
DBI test.

 my $dbh = &get_db_handle();
 my $sql = qq{ update robot_state set value_state = ? where key_ip_address = ? };
 my $sth = $dbh->prepare( $sql ); 
 my $sql2 = qq{ insert into robot_state( key_ip_address , value_state ) values( ? ,? )};
 my $sth2 = $dbh->prepare( $sql2 );
 my $i;
 
 my %HASH;
 while($counter < $update_counter) {
     $random = int(rand($rand_counter));
     $HASH{$counter} = $random;
     $counter++;
 }
 my ($key, $value);
 $start_time = new Benchmark;
 while( ($key, $value) = each %HASH ) {
     eval {
         $i = $sth->execute($value,$key);
     };
     if ($i eq '0E0') {
         eval {
             $sth2->execute($key, $value);
         };
         if($@) { print "Error\n $@"; exit 1; };
     }
 }
 $dbh->commit();
 $end_time = new Benchmark;
 $difference = timediff($end_time, $start_time);
 print "\nIt took Raw DBI ", timestr($difference), "\n\n";
 
You will notice above that the DBI may need to carry out more than one 
statement. I have made the first statement an update rather than an 
insert because the majority of operations will be updates. There is no 
scientific reasoning behind the numbers I chose for the cache_size and 
the amount of times to go over the loop. I recommend experimenting with 
these if you are really interested. 

Between each test the table was "truncated" and "vacuum analysed". This 
was to ensure that the order of the tests would have no bearing on the 
results. 

Test where carried out using Postgres 7.3.2 with $dbi->{AutoCommit} = 0" 
during the tests.

=head2 Results

I carried out the tests for the DBI and Tie::RDBM 3 times so that a 
system average can be guaged. For the Tie::RDBM::Cached I carried 
out the test three times and selected two slowest for display here. 
These tests were carried out on an Athlon XP1700 1Gb RAM.

RAW DBI
It took Raw DBI 64 wallclock secs (20.87 usr +  1.65 sys = 22.52 CPU)
It took Raw DBI 66 wallclock secs (21.59 usr +  1.76 sys = 23.35 CPU)
It took Raw DBI 65 wallclock secs (20.85 usr +  2.05 sys = 22.90 CPU)

Tie::RDBM
It took Tie::RDBM 5100 wallclock secs (78.66 usr +  3.86 sys = 82.52 CPU)
It took Tie::RDBM 4214 wallclock secs (80.84 usr +  4.26 sys = 85.10 CPU)
It took Tie::RDBM 4192 wallclock secs (85.77 usr +  4.31 sys = 90.08 CPU)

The method I used to test the DBI is not particularly flattering. If 
we fill a hash with the data prior to doing the updates the DBI will 
come out on top every time. Take the time to try it and you will see 
just how fast the DBI can operate.

Tie::RDBM::Cached with Cache size = 0
It took Tie::RDBM::Cached 983 wallclock secs (48.26 usr +  2.28 sys = 50.54 CPU)
It took Tie::RDBM::Cached 988 wallclock secs (50.84 usr +  2.44 sys = 53.28 CPU)
It took Tie::RDBM::Cached 985 wallclock secs (51.62 usr +  2.67 sys = 54.29 CPU)

Cache size = 1000
It took Tie::RDBM::Cached 74 wallclock secs (40.87 usr +  1.71 sys = 42.58 CPU)
It took Tie::RDBM::Cached 78 wallclock secs (42.58 usr +  1.65 sys = 44.23 CPU)
It took Tie::RDBM::Cached 79 wallclock secs (43.29 usr +  1.82 sys = 45.11 CPU)

Cache size = 2000
It took Tie::RDBM::Cached 74 wallclock secs (39.94 usr +  1.79 sys = 41.73 CPU)
It took Tie::RDBM::Cached 80 wallclock secs (41.36 usr +  1.87 sys = 43.23 CPU)
It took Tie::RDBM::Cached 75 wallclock secs (42.70 usr +  1.42 sys = 44.12 CPU)

Cache size = 4000
It took Tie::RDBM::Cached 65 wallclock secs (35.69 usr +  1.68 sys = 37.37 CPU)
It took Tie::RDBM::Cached 73 wallclock secs (38.51 usr +  1.50 sys = 40.01 CPU)
It took Tie::RDBM::Cached 72 wallclock secs (38.81 usr +  1.39 sys = 40.20 CPU)

Cache size = 8000
It took Tie::RDBM::Cached 46 wallclock secs (26.29 usr +  1.28 sys = 27.57 CPU)
It took Tie::RDBM::Cached 48 wallclock secs (28.01 usr +  1.31 sys = 29.32 CPU)
It took Tie::RDBM::Cached 48 wallclock secs (28.32 usr +  1.22 sys = 29.54 CPU)
 
Cache size = 12000
It took Tie::RDBM::Cached 27 wallclock secs (15.95 usr +  0.56 sys = 16.51 CPU)
It took Tie::RDBM::Cached 30 wallclock secs (16.99 usr +  0.67 sys = 17.66 CPU)
It took Tie::RDBM::Cached 34 wallclock secs (17.99 usr +  0.63 sys = 18.62 CPU)

We can see straight away that with a small cache size there is little performance 
gain at all.

= head2 Note On Performance

Raw DBI will be much quicker than this module particularly if you write your 
own cache for updates. I am only being lazy writing this module.

=head1 TO DO LIST

   - New features upon request ;-)

=head1 BUGS

Of that I am sure.

=head1 AUTHOR

Harry Jackson, harry@hjackson.org

=head1 COPYRIGHT

  Copyright (c) 2003, Harry Jackson

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AVAILABILITY

The latest version can be obtained from CPAN:

=head1 SEE ALSO

perl(1), Tie::RDBM, DBI(3)

=cut
