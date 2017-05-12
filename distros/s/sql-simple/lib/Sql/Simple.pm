=head1 Sql::Simple 

An Sql statement generation and execution library (for simple tasks)

=head2 SYNOPSIS:

  Sql::Simple->setdbh($dbh);
  # select price, weight from fruit where onSale = 'true'
  my $result = Sql::Simple->query($dbh, [ qw(price, weight) ], 'fruit', { 'onSale' => 'true' });

=head2 DESCRIPTION:

This module is a re-hash of like fifty different modules already on CPAN.  TWMTODI is a good thing, but sadly this is more of the case of being tired of seeing patch submissions being rejected into similar modules.  The upside to this module is that it handles table joins rather elegantly (ie: no creation of seperate classes, config files, xml, GPS coordinates, or cat scans). The downside is probably the fact that I wrote it, as there are a few inefficient quirks to my coding style (comments appreciated). 

Of course, this module covers the basics of sql... insert, update, delete, and select's.  The ability to do things in mass is available as well, to assist you with large data maniuplations.  (taking advantage of a database that takes advantage of placeholders, and setting AutoCommit to 0). 

IMHO, this module is almost mostly DWIM.  A nice OO approach is in the works, just needed some pointers from some friends before I could break ground on it.  (I do not do a lot of web programming with perl anymore, more data transformation stuff, so this module suits me for what I do).

This module currently ONLY SUPPORTS ANSI SQL-92, there has been suggestions to make this more modular, but I think the db's will catch up before I do.

This module will only work with the following database servers (that I have personally tested so far) 

  Microsoft SQL Server 7, 2000 
    (tested via DBD::ODBC, supports full outer join)

  Sybase 12 (11 does not support ANSI SQL 92) 
    Does not support FULL OUTER JOIN

  PostgreSQL 7.3.X and above supports 
    (no FULL OUTER support)

  MySQL 3.23 and [4.1 required if you intend on using subqueries]).  
    * Notes on MySQL
      LEFT JOIN and RIGHT JOIN are not ANSI compliant.  Sql::Simple 
      isn't going to stop you from using that syntax, however, this 
      document will refer to joins in ANSI syntax only.  MySQL 4 
      treats LEFT JOIN and LEFT OUTER JOIN synonmously.  In my 
      research, it appears that certain versions of 3.23 act this 
      way as well, but do not support FULL OUTER joins as a part 
      of their syntax.  Sql::Simple does not support Union (yet). 

  Oracle 9i 
    (supports full outer join)

If there is some weird incompatability, you'll see it, as I cluck out the errors back to you by die'ing...

Here is a simple example... 

  Sql::Simple->delete($dbh, 'tablename', { 'whereColumn' => 'whereValue' });

  Instead of...

  eval {
    my $sql = 'delete from tablename where whereColumn = ?';
    my $sth = $dbh->prepare($sql);
    $sth->execute('whereValue');
    $sth->finish();
    $dbh->commit() unless ( $dbh->{'AutoCommit'} );
  };
  if ( $@ ) {
    $dbh->rollback();
    # do something to handle the exception...
  }

Ok, am I gaining you anything by using this module?  I think so.. 
1. No declaration of any of those variables into your scope
2. Code reduction
3. No SQL will sit in your perl code (perl is good at formatting text, why get in it's way?)
4. Results from other routines can easily map into the argument stream, avoiding temporary placeholders (which for me tends to gain some performance)
5. I find that Sql abstraction layers, if done properly, can make simple tasks such as these short concise statements, instead of slightly larger blocks of code that are prone to irritating syntax and scope related issues.
6. I find writing sql tedious.
7. I find writing the code to execute sql tedious.
8. It's nice to be able to generate an sql statement.  even if you intend on using your own execution methods..

=head1 "WHERE" clause structure

=head2 the generic where clause "structure" defining a constraint within a query

There is a unified function that generates clauses for all of the functions within Sql::Simple.
I figure explaining it once will make update, delete, and query a bit easier to digest. (as it is used in insert, update, delete and subqueries within query).  It is also used in the "FROM" clause within a query (specifically in the "ON" element structure).

  [
    {
      'column1' => 'value1',
      'column2' => \'is null',
      'column3' => [ 'val3-1', 'val3-2', 'val3-3' ],
    },
    {
      'column4' => {
		     'op' => 'like',
		     'val' => '%value4%'
		   },
      'column5' => {
                     'columns' => 'value5column',
		     'table' => 'value5table',
		     'where' => {
		                  'column5sub' => 'value5sub'
			        }
		   }
    }
  ]
      
This statment will generate the following clause. (or close to it, as the formatting might be off)

 (
   column1 = ? 
   AND column2 is null 
   AND column3 in (?,?,?) 
 ) OR (
   column4 like ? 
   AND column5 in ( 
     SELECT value5column FROM value5table WHERE column5sub = ? 
   )
 )

column1 is a simple "=" operator between the column name and the placeholder.
column2 is a scalar reference forcing what you want verbatim (abuse to this function is kind of expected)
column3 creates a "where in" clause which is interpreted as an OR statement

OR statement kicks in, creating another level of nesting for the next hashref

column4 creates a specific relationship, such as "greater than" or the "like" operator shown above. 
column5 creates a subquery with a where clause that can any level of depth of complexity as shown above.. (it is fully explained in the query function documentation)

Of course, if you don't have an or clause, just pass in the hash..

  {
    'column1' => 'value1'
    'column2' => 'value2'
  }

Which would generate ...

  column1 = ? AND column2 = ?

This module will "auto-magically" figure out if your argument stream contains multiple objects to execute the statement with, or if it's just one really big statement.  

(hmm, maybe I should have named this thing Sql::KindaSimple)

=head1 Logical operators

To retouch on the above, if you needed to do something like the following..

  SELECT fruit FROM produce WHERE price > 10

The "logical operator" syntax (anything besides the basic "=" operator is executed by the following)..

  Sql::Simple->query('fruit', 'produce', { 
    'price' => { 
      'op' => '>', 
      'val' => 10 
     } 
  } );

To do a "between" query simply execute the follwing.

  Sql::Simple->query('fruit', 'produce', { 
    'price' => { 
      'op' => 'between', 
      'val' => 10,
      'val2' => 20
     } 
  } );

UPDATE (0.7): If you wanted to generate a clause that allowed a value, or a couple of values, OR allow null, you can now "allowNull"

  'price' => { 
    'op' => 'between', 
    'val' => 10,
    'val2' => 20
    'allowNull' => 'true' # anything boolean true will work here
   } 

   # This generates...

   ( price between ? AND ?  OR price is null )

=head1 Variables

$DBH - (the database handle to use) You can modify this directly, or for your convenience you may call this helper method

  Sql::Simple->setdbh($dbh);

$RETURNSTH - (if "true" it returns the statement handle, and the map)

  Sql::Simple->returnsth(1); # returns a statement handle for the generated sql statement
  Sql::Simple->returnsth(0); # default (execute)

$RETURNSQL - (if "true" just return the SQL statement generated, don't actually execute it) Or use the following.

  Sql::Simple->setreturn(1); # for "return"
  Sql::Simple->setreturn(0); # for "execute" [default]

$DEBUGSQL - (if "true" warn out the SQL being executed)

  Sql::Simple->setdebug(1); # for "warn sql before execution"
  Sql::Simple->setdebug(0); # for "no warn" [default]

B<If you do not set this, this module will expect the first argument to each function call to be the database handle>

=cut

package Sql::Simple;
use vars qw($version $DBH $RETURNSQL @EXPORT @EXPORT_OK $DEBUGSQL $RETURNSTH $ASARRAY);
$VERSION = "0.07";
use strict;
use Data::Dumper;
use Carp qw(cluck croak);

use Exporter;
@EXPORT = qw($DBH $RETURNSQL $DEBUGSQL $RETURNSTH $ASARRAY);
@EXPORT_OK = qw($DBH $RETURNSQL $DEBUGSQL $RETURNSTH $ASARRAY);

=head1 Sql::Simple->delete

=head2 provide an easy interface to delete row(s) from a table.

Two methods of invocation.

1. as a list of arguments

  Sql::Simple->delete(
    databaseHandle, 
    'scalar tablename', 
    WHERE_CLAUSE_STRUCTURE (see documentation above),
  );

2. or as a hash

  Sql::Simple->delete(
    databaseHandle, 
    'table' => $tablename, 
    WHERE_CLAUSE_STRUCTURE (see documentation above),
  );

=item Examples

  create table books (
    title varchar(20)
    author varchar(20)
  )

  # set our dbh
  Sql::Simple->setdbh($dbh);
  # delete from books where title = 'Java Programming'
  Sql::Simple->delete('books', { 'title' => 'Java Programming' });

=cut

sub delete {
  my $class = shift;
  my ( $table, $where, $sth, $dbh );

  if ( ref($_[0]) eq 'DBI::db' ) {
    $dbh = shift;
  } else {
    $dbh = $DBH;
  }
  croak("No database handle given!") if ( ! $RETURNSQL && ! ref($dbh) );

  if ( scalar(@_) <= 4 ) {
    ( $table, $where ) = @_;
  } else {
    my %temp = @_;
    $table  = $temp{'table'};
    $where  = $temp{'where'};
  }
  if ( ref($where) eq 'HASH' ) {
    # hmmm........  if it's a hash.. then package it up
    $where = [ $where ];
  } elsif ( ref($where) eq 'ARRAY' && scalar(@{$where}) > 1 && &_clause('', $where->[0], []) ne &_clause('', $where->[1], []) ) {
    # if we have two elements in the inbound array, and they aren't exactly the same, then it's not a mass call, but an "OR" clause
    $where = [ $where ];
  }

  my $sql = "DELETE FROM $table";
  if ( $where ) {
    $sql .= " WHERE\n";
  } else {
    $sth = $dbh->prepare($sql);
    eval {
      $sth->execute();
    };
    $sth->finish();
    if ( $@ ) {
      $dbh->rollback() unless ( $dbh->{'Autocommit'} );
    } else {
      $dbh->commit() unless ( $dbh->{'AutoCommit'} );
    }
  }
  my $map = [];
  # generate the where clause
  $sql = &_clause($sql, $where->[0], $map);

  warn $sql if ( $DEBUGSQL );
  return $sql if ( $RETURNSQL );
  # do simple test here
  my $simple = 0;
  $simple++ if ( $sql =~ /OR\n/ );
  map { $simple++ if ( $_ ne 'VALUE' ) } @{$map};

  eval { $sth = $dbh->prepare($sql); };
  die(&cluck() . "\n" . $@) if ( $@ );
  if ( $simple == 0 ) {
    # no weirdness, just map and execute
    eval {
      foreach my $c ( 0..$#{$where} ) {
	$sth->execute( map { $where->[$c]{$_} } sort(keys(%{$where->[$c]})) );
      }
    };
    die(&cluck() . "\n" . $@) if ( $@ );
  } else {
    # use the value routine to map the data to the execution function
    eval {
      foreach my $c ( 0..$#{$where} ) {
	$sth->execute( &_value($where->[$c], $map ));
      }
    };
    die(&cluck() . "\n" . $@) if ( $@ );
  }
  $sth->finish();
  $dbh->commit() unless ( $dbh->{'AutoCommit'} );
  return;
}

=head1 Sql::Simple->update

=head2 provide an easy interface to update row(s) in a table

The "set" structure and "where" structure can also be arrayRef's of hashRefs.  This allows you to perform multiple executions on a single prepared statement handle.  This is shown in better detail in the examples

1. as a list of arguments

  Sql::Simple->update(
    databaseHandle, 
    'scalar tablename', 
    [ { 'setColumn' => 'setValue' }, { 'setColumn' => 'setValue' } ],
    [ WHERE CLAUSE STRUCTURE (see above) ]
  );

2. or as a hash

  Sql::Simple->update(
    databaseHandle, 
    'table'  => $tablename, 
    'set'    => { 'setColumn' => 'setValue' }, 
    WHERE CLAUSE STRUCTURE (see above)
  );

=item Examples

  create table produce (
    price float,
    name varchar(20),
    color varchar(10)
  )

  # set the database handle for these transactions
  Sql::Simple->setdbh($dbh);

  # set green tomatoes to 75 cents
  # update produce set price = ? where name = ? and color = ?
  Sql::Simple->update('produce', { 'price' => .75 }, 
    { 'name' => 'tomatoe', 'color' => { 'green' });

  # set olives to 1.35 and pickles to 1.50
  # update produce set price = ? where name = ?
  Sql::Simple->update('produce', 
    [ { 'price' => 1.35 },   { 'price' => 1.50 } ],
    [ { 'name' => 'olive' }, { 'name' => 'pickles' } ]
  );

  # if you have a reason (and I can't think of one) to execute 
  # update multiple times with one set value. (a where "in" is advisable)
  Sql::Simple->update('produce', { 'price' = .50 }, 
    [ { 'name' => 'lettuce' }, { 'name' => 'onions' } );

=cut

sub update {
  my $class = shift;

  my ( $table, $set, $where, $sth, $singleset, $singlewhere, $dbh );
  if ( ref($_[0]) eq 'DBI::db' ) {
    $dbh = shift;
  } else {
    $dbh = $DBH;
  }
  croak("No database handle given!") if ( ! $RETURNSQL && ! ref($dbh) );

  if ( scalar(@_) <= 5 ) {
    ( $table, $set, $where ) = @_;
  } else {
    my %temp = @_;
    $table  = $temp{'table'};
    $set    = $temp{'set'};
    $where  = $temp{'where'};
  }
  # see if there are multiple set clauses (for mass calls)
  if ( ref($set) eq 'HASH' ) {
    $singleset = 1;
    $set = [ $set ];
  } else {
    $singleset = 0 
  }
  # see if there are multiple where clauses (for mass calls)
  if ( ref($where) eq 'HASH' ) {
    $singlewhere = 1;
    $where = [ $where ];
  } elsif ( ref($where) eq 'ARRAY' && scalar(@{$where}) > 1 && &_clause('', $where->[0], []) ne &_clause('', $where->[1], []) ) {
    $singlewhere = 1;
    $where = [ $where ];
  } else {
    $singlewhere = 0;
  }

  die("multiple set clause set with one where clause, that makes no sense...") if ( ! $singleset && $singlewhere );

  my $map = [];
  my $sql = "UPDATE $table SET ";
  $sql = &_clause($sql, $set->[0], $map);
  my $where_map_start = $#{$map};
  $sql =~ s/ AND /\, /g;

  if ( $where ) {
    $sql .= "WHERE\n";
    $sql = &_clause($sql, $where->[0], $map);
  } else {
    return $sql if ( $RETURNSQL );
    $sth = $dbh->prepare($sql);
    $sth->execute( map { $set->[0]{$_} } sort(keys(%{$set->[0]})) );
    $sth->finish();
    $dbh->commit() unless ( $dbh->{'AutoCommit'} );
  } 

  # test for simpleness, so we can use the faster methods of execution
  my $simple = 0;
  $simple++ if ( $sql =~ /OR\n/ );
  map { $simple++ if ( $_ ne 'VALUE' ) } @{$map};
  warn $sql if ( $DEBUGSQL );
  return $sql if ( $RETURNSQL );
  eval { $sth = $dbh->prepare($sql); };
  die(&cluck() . "\n" . $@) if ( $@ );

  # if singleset is present just create an array to bind against, instead of recalculating..
  if ( $simple == 0 ) {
    eval {
      if ( $singleset ) {
	my @set = map { $set->[0]{$_} } sort(keys(%{$set->[0]}));
        foreach my $c ( 0..$#{$where} ) {
	  $sth->execute( @set, (map { $where->[$c]{$_} } sort(keys(%{$where->[$c]}))) );
	  #print Dumper( @set, (map { $where->[$c]{$_} } sort(keys(%{$where->[$c]}))) );
        }
      } else {
        foreach my $c ( 0..$#{$where} ) {
	  $sth->execute( (map { $set->[$c]{$_} } sort(keys(%{$set->[$c]}))), (map { $where->[$c]{$_} } sort(keys(%{$where->[$c]}))) );
	  #print Dumper( (map { $set->[$c]{$_} } sort(keys(%{$set->[$c]}))), (map { $where->[$c]{$_} } sort(keys(%{$where->[$c]}))) );
        }
      }
    };
    die(&cluck() . "\n" . $@) if ( $@ );
  } else {
    # offset for where clause in the map
    #eval {
      if ( $singleset ) {
	#my @set = map { $set->[0]{$_} } sort(keys(%{$set->[0]}));
        foreach my $c ( 0..$#{$where} ) {
	  $sth->execute( (&_value($set->[0], $map)), (&_value($where->[$c], $map, \$where_map_start)) );
	  #print Dumper( (&_value($set->[0], $map)), (&_value($where->[$c], $map, \$where_map_start)) );
        }
      } else {
        foreach my $c ( 0..$#{$where} ) {
	  $sth->execute( (&_value($set->[0], $map)), (&_value($where->[$c], $map, \$where_map_start)) );
	  #print Dumper( (&_value($set->[$c], $map)), (&_value($where->[$c], $map, \$where_map_start)) );
        }
      }
      #};
      #die(&cluck() . "\n" . $@) if ( $@ );
  }
  $sth->finish(); 
  $dbh->commit() unless ( $dbh->{'AutoCommit'} );
  return;
}

=head1 Sql::Simple->insert

=head2 provide an easy interface to insert row(s) into a table

I use this routine quite a bit, so I tried to keep it any superfluous features far away from creeping in.
Since there are so many ways to pass things into this module, I'm just going to explain things in the examples.

=item Examples

  create table users (
    id int,
    name varchar(20),
  )

  create table visitors (
    id int,
    name varchar(20),
    specialty varchar(10)
  )

  # insert into users ( ?, ? ) 
  # Executed with: 1, 'john'
  Sql::Simple->insert($dbh, 'users', [ 'id', 'name' ], [ 1, 'john' ]);

  # insert into users ( ?, ? ) 
  # Executed with: 2, 'jack'
  # Executed with: 3, 'jim'
  Sql::Simple->insert($dbh, 'users', [ 'id', 'name' ], [
							 [ 2, 'jack' ],
							 [ 3, 'jim' ],
						       ]);
Or, by using a hash directly.

  # insert into users ( ?, ? ) 
  # Executed with: 1, 'john'
  Sql::Simple->insert($dbh, 'users', { 'id' => 1, 'name' => 'john' });

  # insert into users ( ?, ? ) 
  # Executed with: 2, 'jack'
  # Executed with: 3, 'jim'
  Sql::Simple->insert($dbh, 'users', [
				       { 'id' => 2, 'name' => 'jack' },
				       { 'id' => 3, 'name' => 'jim' },
				     ]);

Lastly, a hash, but using a subquery

  # insert into users ( id, name ) 
  # ( select id, name from visitors where specialty = ? )

  # Executed with: 'basketweaving'
  Sql::Simple->insert($dbh, 'users', 
    [ qw(id name) ], 
    { 
      'columns' => [ qw(id name) ], 
      'table' => 'visitors', 
      'where' => { 'specialty' => 'basketweaving' } 
    }
  );

UPDATE 0.7: If you want to call a sql function, simply pass a scalar reference as a value for a column. (Example, to execute the "now()" function for a date..

  Sql::Simple->insert( $dbh, 'myTable', { 'columnA' => \'valueB' } );

=cut

sub insert {
  my $class = shift;
  my ( $columns, $values, $dbh );

  if ( ref($_[0]) eq 'DBI::db' ) {
    $dbh = shift;
  } else {
    $dbh = $DBH;
  }
  croak("No database handle given!") if ( ! $RETURNSQL && ! ref($dbh) );

  my ( $table, $temp, $temp2 ) = @_;

  if ( ref($temp) eq 'ARRAY' ) {
    if ( ref($temp->[0]) eq 'HASH' ) {
      $values = $temp;
      $columns = [ sort(keys(%{$temp->[0]})) ];
    } else {
      $columns = $temp;
      $values = $temp2;
    }
  } elsif ( ref($temp) eq 'HASH' ) {
    $values = [ map { $temp->{$_} } sort(keys(%{$temp})) ];
    $columns = [ sort(keys(%{$temp})) ];
  }

  my $simpleCheck;
  my $map = [];
  my $sql = "INSERT INTO $table\n( " . join(', ', @{$columns}) . " )\n";
  if ( ref($values) eq 'ARRAY' ) {
    # do a check to see if the values are hash refs..
    if ( ref($values->[0]) eq 'HASH' ) {
      if ( $values->[0]{'table'} ) {
        $values->[0]{'return'} = 2;
        my $tsql;
        ( $tsql, $map ) = Sql::Simple->query(undef, %{$values->[0]});
        $sql .= "( $tsql)";
      } else {
        # not simple if there are any values that are scalar references.. 
	$simpleCheck = grep { 1 if ( ref($_) eq 'SCALAR' ) } @{$values};
	# if it's a hash, see if any of it's memebers are scalars
	$simpleCheck += grep { 1 if ( ref($values->[0]{$_}) eq 'SCALAR' ) } keys(%{$values->[0]}) if ( ref($values->[0]) eq 'HASH' );

	if ( $simpleCheck ) {
	  $sql .= &_insert($values->[0], $map);
	} else {
          $sql .= "VALUES\n( " . join(', ', ('?') x scalar(@{$columns}) ) . ' )';
	}
      }	
    } else {
      # not simple if there are any values that are scalar references.. 
      $simpleCheck = grep { 1 if ( ref($_) && ref($_) ne 'ARRAY' ) } @{$values};

      if ( $simpleCheck ) {
        $sql .= &_insert($values, $map);
      } else {
        $sql .= "VALUES\n( " . join(', ', ('?') x scalar(@{$columns}) ) . ' )';
      }
    }
  } elsif ( ref($values) eq 'HASH' ) {
    if ( $values->{'table'} ) {
      $values->{'return'} = 2;
      my $tsql;
      ( $tsql, $map ) = Sql::Simple->query(undef, %{$values});
      $sql .= "( $tsql)";
      $values = [ $values ];
    }
  }

  warn $sql if ( $DEBUGSQL );
  return $sql if ( $RETURNSQL );

  my $sth = $dbh->prepare($sql);
  if ( ref($map) eq 'ARRAY' && scalar(@{$map}) ) {
    if ( ref($values->[0]) eq 'HASH' ) {
      if ( defined($values->[0]{'where'}) ) {
        foreach my $v ( @{$values} ) {
          $sth->execute( &_value($v->{'where'}, $map));
        }
      } else {
        foreach my $v ( @{$values} ) {
          $sth->execute( &_value($v, $map) );
        }
      }
    } else {
      $sth->execute( &_value($values, $map));
    }
  } else {
    # hmm. see if we have a single array, or an array of arrays
    if ( ref($values->[0]) eq 'ARRAY' ) {
      foreach my $v ( @{$values} ) {
	eval {
          $sth->execute(@{$v});
	};
	if ( $@ ) {
          $dbh->rollback() unless ( $dbh->{'AutoCommit'} );
	  croak($@);
	}
      }
    } else {
      if ( ref($values->[0]) eq 'HASH' ) {
	if ( $values->[0]{'table'} ) {
	  if ( ref($map) ) {
	    $sth->execute( &_value($values->[0]{'where'}, $map)  );
	  } else {
	    $sth->execute();
	  }
	} else {
	  map { 
	    my $row = $_;
	    eval {
	      $sth->execute( map { $row->{$_} } sort(keys(%{$row})) );
	    };
	    $sth->finish();
	    if ( $@ ) {
	      $dbh->rollback() unless ( $dbh->{'AutoCommit'} );
	      croak($@);
	    }
	  } @{$values};
	}
      } else {
        $sth->execute(@{$values});
      }
    }
  }
  $sth->finish();

  $dbh->commit() unless ( $dbh->{'AutoCommit'} );
  return;
}

=head1 Sql::Simple->query

=head2 Retrieve information from a table

Method invocation description.

  1. database handle (not required if "setdbh" used)
  2. A datastructure depicting what columns you wish to query for. 
    The following formats are supported:
    A. scalar of column (or columns, as it will simply interpolate 
       into the SQL to be executed)
    B. arrayRef of column or columns (or computations, such as 2 + 2 
       as 'foo')
    C. hashRef of columns (with the appropriate alias's as their values
    D. hashRef of columns, with it's value an arrayRef 
       (the keys acting as a table prefix)

    Here's some examples of the "column" data structure

    'mycolumn'
    # OR
    [ qw(mycolumn mycolumn2 mycolumn3) ],
    # OR
    {
      'mycolumn' => 'mc',
      'mycolumn2' => 'm2',
      'mycolumn3' => 'm3'
    }
    # OR
    {
      'mytable' => [ qw(mycolumn mycolumn2 mycolumn3) ]
    }

  3. A datastructure depicting what tables you wish to query against
    table => (scalar at the least is required)
      A. scalar of the table you wish to query from.
      B. hashRef of the relationships you are defining for this query.. 
         ie: table1.column1 => table2.column1 ...
      C. Array Reference of multiple tables

  4. A data structure depicting constraints in the "where" clause 
     (see complete documentation above)
  
  5. Options 
    order => (optional)
      A. a scalar value with a single column to order by
      B. an arrayRef of columns to order by, in the same alignment as given
    col =>
      A. a scalar value requesting that the result be handed as a complete 
         hash, courtesy of fetchall_hashref($col)

=item Examples: (again, tables first)

  create table fruit (
    id int,
    name varchar(20),
    cost float,
    color varchar(20)
  )

  create table plant (
    species varchar(20),
    produces int, # foreign key to fruit
  )

  create table producer (
    title varchar(20),
    top_product int # foreign key to fruit
  )
   
  # set the dbh for these transactions
  Sql::Simple->setdbh($dbh);

  # select fruit_name, fruit_cost from fruit where fruit where fruit_color = ?
  # Executed with: "red"
  Sql::Simple->query(
    [ 'name', 'cost' ], 
    'fruit', 
    { 'color' => 'red' }
  );

Simple table joins are fairly simple.

  # select fruit_name, plant_name 
  # from fruit inner join plant on fruit.fruit_id = plant.produces
  Sql::Simple->query(
    [ 'name', 'species' ], 
    { 'fruit.id' => 'plant.produces' }
  );

Complicated Table joins are only mildly more difficult (thanks to the standardization of ANSI-SQL 92)

  # select 
  #   name, species, title 
  # from 
  #   fruit 
  #   inner join plant on fruit_id = plant.produces 
  #   left outer join prodcuer on fruit.id = producer.top_product
  #     and producer.title ne 'Bad Fruit Company'
  Sql::Simple->query(
    [ 'name', 'species', 'title' ],
    [ 
      'fruit', 
      {
        'table' => 'plant'
	'on' => {
          'fruit.id' => 'plant.produces' 
        }
      },
      {
        'table' => 'producer',
	'join' => 'left outer',
	'on' => {
	  'fruit.id' => 'producer.top_product',
	  'producer.title' => {
	    'op' => 'ne',
	    'val' => 'Bad Fruit Company'
	  }
	}
      }
    ]
  );  

Ambiguity within table joins must be handled .. well, somewhat on your own.  YMMV depending on your approach.  This module B<doesn't> have your schema, so it's hard to figure out relationships. (next version might support something wacky like this).  If you do not use a table prefix in your join, Sql::Simple will interpret it as a bind variable.  The only way to get around this is by using a scalar reference. (example below)

  [
    'produce',
    {
      'table' => 'shelf_life',
      'on' => {
        'produce_id' => 'sl_produce_id'
      }
    }
  ]
  # generates " FROM produce INNER JOIN shelf_life on produce_id = ? " 
  # intead of...
  #	      " FROM produce INNER JOIN shelf_life on produce_id = sl_produce_id "

Simple enough to get around..

  [
    'produce',
    {
      'table' => 'shelf_life',
      'on' => {
        'produce_id' => \'sl_produce_id'
      }
    }
  ]
  # generates " FROM produce INNER JOIN shelf_life on produce_id = sl_produce_id "

=item Return structure Format

UPDATE 0.7:  You can specify the type of structure you want returned from a query.  The default is an array of hashref's, keyed by the column names.  (that you may have chosen with aliases).  You can get an array of arrays by calling the static method "asarray" and passing it a true or a false value.  If you want the result set executed with using "fetchall_hashref()"  simply pass the column you want after the where clause.  Eventually, I'll probably move these other fetch styles as static methods like "asarray".  

=cut

sub query {
  my $class = shift;
  my ( $columns, $table, $where, $col, $return, $order, $distinct, $dbh );

  shift unless ( $_[0] );

  if ( ref($_[0]) eq 'DBI::db' ) {
    $dbh = shift;
  } elsif ( ref($class) && ref($class->{'dbh'}) ) {
    $dbh = $class->{'dbh'};
  } else {
    $dbh = $DBH;
  }

  # pass in arguments, or a hash.. we'll take care of the rest! (umm, I hope! ;-)
  if ( grep { 1 if ( $_ eq 'table' ) } @_ ) {
    my %temp = @_;
    $table   = $temp{'table'};
    $where   = $temp{'where'};
    $columns = $temp{'columns'};
    $col     = $temp{'col'};
    $return  = $temp{'return'};
    $order   = $temp{'order'};
    $distinct= $temp{'distinct'};
  } else {
    # some day I need to make the last argument after "WHERE" just be a hash of extra options
    ( $columns, $table, $where, $col, $return, $order, $distinct ) = @_;
  }
  $return = 0 unless ( defined($return) );

  croak("No database handle given!") if ( ! $RETURNSQL && ! ref($dbh) && ! $return );

  my $sql = "SELECT ";
  if ( $distinct ) {
    $sql .= "distinct ";
  }
  my $map = [];
  my $tables = {};

  if ( ref($table) eq 'ARRAY' ) {
    &_columns($columns, \$sql);
    &_from($table, \$sql, $map, $tables);
  } elsif ( ref($table) eq 'HASH' ) {
    # only allow a single key pair
    die("Do not attempt to use a hash for more than one table join.") if ( scalar(keys(%{$table})) > 1 );
    my $ft = join('', keys(%{$table}));
    die("No complex joins in simple hash queries") if ( ref($table->{$ft}) );
    &_columns($columns, \$sql);
    $sql .= "FROM " . substr($ft, 0, index($ft, '.')) . " INNER JOIN " . substr($table->{$ft}, 0, index($table->{$ft}, '.')) . " ON $ft = $table->{$ft} ";
  } elsif ( $table ) {
    &_columns($columns, \$sql, $table);
    $sql .= "FROM $table ";
  } else {
    &_columns($columns, \$sql, $table);
  }

  # DAMN IT.. fix the code so it doesn't add a prefix onto columns that have parens

  unless ( $where || scalar(@{$map})) {
    warn $sql if ( $DEBUGSQL );
    return ( $sql ) if ( $return || $RETURNSQL );
    my $sth = $dbh->prepare($sql);
    $sth->execute();

    # save the statement handle and return it (if in an object, and state is on)
    if ( ref($class) && $class->{'state'} ) {
      $class->{'sth'} = $sth;
      return $sth;
    }

    if ( $col && ! ref($col) ) {
      my $res = $sth->fetchall_hashref($col);
      $sth->finish();
      return($res);
    } else {
      my @outbound;
      while ( my $row = $sth->fetchrow_hashref() ) {
	push(@outbound, $row);
      }
    
      $sth->finish();
      return(\@outbound);
    }
  } 
  # the most important line is the _clause generation.. as it is possibly recursing 
  # multiple times, possibly to this function as well generating subqueries or whatnot.
  if ( $where ) {
    $sql .= 'WHERE ';
    $sql = &_clause($sql, $where, $map);
  }

  $sql .= " ORDER BY " . join(', ', @{$order}) if ( $order );
  # I don't remember what this is for...
  $sql .= join(' ', @{$col}) if ( ref($col) eq 'ARRAY' );

  # if the return variable is set.. return it..
  return ( $sql, $map ) if ( $return == 2 );
  warn $sql if ( $DEBUGSQL );
  return ( $sql ) if ( $return == 1 || $RETURNSQL );

  my $sth;
  $sth = $dbh->prepare($sql);

  # do the simple check thing
  my $simple = 0;
  $simple++ if ( $sql =~ /OR\n/ );
  map { $simple++ if ( $_ ne 'VALUE' ) } @{$map};

  # if there is a join clause
  if ( scalar(keys(%{$tables})) > 0 ) {

    # peel off the first table, since it is just a scalar
    my $t = shift(@{$table});
    my $d = -1;
    my $c = \$d;
    $sth->execute( 
      map { 
	if ( $_->{'on'} ) {
	  &_value($_->{'on'}, $map, $c);
	} elsif ( $_ ) {
	  &_value($_, $map, $c);
	}
      } ( @{$table}, $where )
    );
    unshift(@{$table}, $t);
  } else {
    if ( $simple == 0 ) {
      # if it's simple.. then key off the where hash
      eval {
	$sth->execute( map { $where->{$_} } sort(keys(%{$where})) );
      };
    } elsif ( ! $where ) {
      # if there is no where clause (which seems to happen in every test script I write, just execute it flat)
      eval {
	$sth->execute();
      };
    } else {
      eval {
	$sth->execute( (&_value($where, $map)) );
      };
    }
    if ( $@ ) {
      die(cluck() . "\n" . $@);
    }
  }

  # save the statement handle and return it (if in an object, and state is on)
  if ( ref($class) && $class->{'state'} ) {
    $class->{'sth'} = $sth;
    return $sth;
  }

  # if there is a column defined for a fetchall
  if ( $col && ! ref($col) ) {
    # declare $res in the current scope
    my $res = $sth->fetchall_hashref($col);
    $sth->finish();
    return($res);
  } else {
    my @outbound;
    while ( my $row = $sth->fetchrow_hashref() ) {
      push(@outbound, $row);
    }
  
    $sth->finish();
    return(\@outbound);
  }
}

sub execute {
  my $class = shift;
  my $dbh;

  if ( ref($_[0]) eq 'DBI::db' ) {
    $dbh = shift;
  } elsif ( ref($class) && ref($class->{'dbh'}) ) {
    $dbh = $class->{'dbh'};
  } else {
    $dbh = $DBH;
  }
  my ( $sql, $struct, $col ) = @_;

  warn $sql if ( $DEBUGSQL );

  my $sth = $dbh->prepare($sql);
  if ( $sql =~ /^[\s\n]*select/i ) {
    if ( $struct ) {
      # ok, here we need to scan the structure and see if we need to do bindparams
      $sth->execute(@{$struct});
    } else {
      $sth->execute();
    }
    if ( ref($class) ) {
      $class->{'sth'} = $sth;
      return $sth;
    } else {
      if ( $ASARRAY ) {
        my $result = $sth->fetchall_arrayref();
        $sth->finish();
        return($result);
      } elsif ( $col ) {
	my $result = $sth->fetchall_hashref($col);
	$sth->finish();
	return($result);
      } else {
	my @outbound;
	while ( my $row = $sth->fetchrow_hashref() ) {
	  push(@outbound, $row);
	}
	$sth->finish();
	return(\@outbound);
      }
    }
  } else {
    if ( ref($struct->[0]) eq 'ARRAY' ) {
      foreach my $s ( @{$struct} ) {
        $sth->execute(@{$s});
      }
    } else {
      $sth->execute(@{$struct});
    }
  }
  $sth->finish();
}

sub execute_procedure {
  my $class = shift;
  my ( $dbh, $sql );

  if ( ref($_[0]) eq 'DBI::db' ) {
    $dbh = shift;
  } elsif ( ref($class) && ref($class->{'dbh'}) ) {
    $dbh = $class->{'dbh'};
  } else {
    $dbh = $DBH;
  }
  my ( $procedure, $arguments, $types, $col ) = @_;

  $sql = $procedure;
  # generate the sql statement (for the procedure, hmm. not going to go down the bound parameter road)
  if ( ref($arguments) eq 'ARRAY' && scalar(@{$arguments}) > 0 ) {

    foreach my $a ( 0..$#{$arguments} ) {
      if ( defined($arguments->[$a]) && $types->{$a} eq 'number' ) { # they said it's a number
        $sql .= ' ' . $arguments->[$a] . ",";
      } elsif ( defined($arguments->[$a]) && $types->{$a} eq 'string' ) { # they said it's a string
        $sql .= " '" . $arguments->[$a] . "',";
      } elsif ( $arguments->[$a] =~ /^\-?\d+\.?\d*$/ ) { # it looks like a number
        $sql .= ' ' . $arguments->[$a] . ",";
      } elsif ( defined($arguments->[$a]) ) { # it's a string, quote it
        $sql .= " '" . $arguments->[$a] . "',";
      } elsif ( ! defined($arguments->[$a]) ) { # it's null
        $sql .= " NULL,";
      }
    }
    $sql =~ s/\,$//;
  }
  
  warn $sql if ( $DEBUGSQL );
  return $sql if ( $RETURNSQL );
  #warn $sql;
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  if ( $col ) {
    my $result = $sth->fetchall_hashref($col);
    $sth->finish();
    return($result);
  } else {
    my @outbound;
    while ( my $row = $sth->fetchrow_hashref() ) {
      push(@outbound, $row);
    }
    $sth->finish();
    return(\@outbound);
  }
}

#######################################################################
# internal functions

sub _insert {
  my ( $values, $map ) = @_;

  my $sql .= "VALUES\n( ";
  if ( ref($values) eq 'ARRAY' ) {
    foreach my $c ( @{$values} ) {
      if ( ref($c) ) {
        $sql .= ${$c} . ", "; #$sql .= "'" . ${$c} . "', "; # by placing quotes around the escaped data, we don't provide support functions (maybe provide support for quoted strings as an "op"
	push(@{$map}, 'SCALAR');
      } else {
	$sql .= '?, ';
	push(@{$map}, 'VALUE');
      }
    }
  } else {
    foreach my $k ( sort(keys(%{$values})) ) {
      if ( ref($values->{$k}) ) {
	$sql .= ${$values->{$k}} . ', ';
	push(@{$map}, 'SCALAR');
      } else {
	$sql .= '?, ';
	push(@{$map}, 'VALUE');
      }
    }
  }
  $sql =~ s/, $/ \)/;
  return $sql;
}

sub _columns {
  my ( $columns, $sql, $tab ) = @_;

  $tab .= '.' if ( $tab );

  if ( ref($columns) eq 'HASH' ) {
    # columns as a hash are treated as an alias list
    foreach my $k ( sort(keys(%{$columns})) ) {
      if ( defined($columns->{$k}) ) {
	if ( $k =~ /[\s\.]/ ) {
	  if ( ref($columns->{$k}) eq 'ARRAY' ) {
	    # allow hashes for alias later on (within the array)
	    ${$sql} .= join(' ', map{ $k . '.' . $_ . ',' } @{$columns->{$k}} ) . ' ';
	  } else {
            ${$sql} .= "$k as $columns->{$k}, "; 
	  }
	} else {
	  if ( ref($columns->{$k}) eq 'ARRAY' ) {
	    ${$sql} .= join(' ', map{ $k . '.' . $_ . ',' } @{$columns->{$k}} ) . ' ';
	  } else {
            ${$sql} .= "$tab$k as $columns->{$k}, "; 
	  }
	}
      } else {
	if ( $k =~ /[\s\.]/ ) {
          ${$sql} .= $k . ', ';
	} else {
          ${$sql} .= $tab . $k . ', ';
	}
      }
    }
  } elsif ( ref($columns) eq 'ARRAY' ) {
    # array references are simple concatenations
    ${$sql} .= join(', ', map { ( $_ =~ /[\s\.]/ ) ? $_ : $tab . $_; } @{$columns}) . ' ';
  } else {
    # if we have more than one column in the string..
    if ( $columns =~ /[\s\,]/ ) {
      # attach the table as a prefix if there is no prefix for that column
      ${$sql} .= join(', ', map { ( $_ =~ /\s\.]/ ) ? $_ : $tab . $_; } split(/, ?/, $columns)) . ' ';
    } else {
      # if no spaces or commas scalars are just loaded without any translation
      ${$sql} .= $columns . ' ';
    }
  }
  ${$sql} =~ s/\, $/ /;
}

# this will iterate through all the tables
sub _from {
  my ( $struct, $sql, $map, $tables ) = @_;

  ${$sql} .= "FROM " . $struct->[0];
  $tables->{$struct->[0]} = 1;

  foreach my $s ( @{$struct} ) {
    if ( ref($s) eq 'HASH' ) {
      # get the table and the join type into the statement
      ${$sql} .= "\n" . ( ( $s->{'join'} ) ? uc($s->{'join'}) . ' JOIN ' : 'INNER JOIN ' ) . "$s->{'table'} ON ";

      # push the table into the table hash
      $tables->{$s->{'table'}} = 1;

      if ( ref($s->{'on'}) eq 'HASH' ) {
	# loop over all the relationships
	&_clause($sql, $s->{'on'}, $map, $tables);
      } elsif ( ref($s->{'on'}) eq 'ARRAY' ) {
	foreach my $a ( @{$s->{'on'}} ) {
	  &_clause($sql, $a, $map, $tables);
	}
      }
    } else {
      ${$sql} .= ',' . $s . ' ' if ( $s ne $struct->[0] );
    }
  }
}

sub _clause {
  my ( $tsql, $where, $map, $from ) = @_;
  # Ok, we were passed an array, this is an or clause.. concatenate the individual pieces by calling 
  # this function with the pieces.. after all the recursion it'll allow me to close the parens, and add
  # an OR clause at the end.. (after the last element, we'll trim it off)..

  my $sql;
  if ( ref($tsql) ) {
    $sql = $tsql;
  } else {
    $sql = \$tsql;
  }

  if ( ref($where) eq 'ARRAY' ) {
    foreach my $wa ( @{$where} ) {
      ${$sql} .= "( ";
      ${$sql} .= "\n" if ( ref($wa) eq 'ARRAY' );
      ${$sql} = &_clause($sql, $wa, $map);
      ${$sql} .= ") "; 
      ${$sql} .= "\n" if ( ref($wa) eq 'ARRAY' );
      ${$sql} .= "OR\n";
    }
    ${$sql} =~ s/OR\n$//;
    ${$sql} =~ s/AND\n$//;
    return ${$sql};
  }
  # ok, wasn't called with an array ref, so it must be a hash, loop over the keys, and start mapping out the
  # "map" structure so mass calls won't be so damn painful when we're iterating through the execution loop
  # handling the different sub structures will alter the mapping appropriately (you can see that we call
  # the query function when subqueries kick in.. yay for indirection!)
  foreach my $w ( sort(keys(%{$where})) ) {
    if ( ref($where->{$w}) eq 'HASH' ) {
      if ( $where->{$w}{'table'} ) {
	$where->{$w}{'return'} = 2;
	my ( $msql, $mstack ) = Sql::Simple->query(undef, %{$where->{$w}});
	${$sql} .= "$w in ( $msql ) AND ";
	my $tmp_map = [];
	# recursively process the underlying structure
	&_clause(undef, $where->{$w}{'where'}, $tmp_map);
	# then tie it back into the current structure
	push(@{$map}, $tmp_map);
      } else {

        if ( $where->{$w}{'allowNull'} ) {
          ${$sql} .= " ( ";
        }

        # if the value is an array
	if ( ref($where->{$w}{'val'}) eq 'ARRAY' ) {
	  ${$sql} .= $w . ' ' . $where->{$w}{'op'} . ' ( ' . join(',', ('?') x scalar(@{$where->{$w}{'val'}}) ) . ' ) ';
	  push(@{$map}, 'HASH-ARRAY' );
        } elsif ( ref($where->{$w}{'val'}) eq 'SCALAR') { 
	  # bloody hack.. I need to be able to throw an = sign if there is whitespace ie: IS NULL (vs. a scalar ref table join)
	  ${$sql} .= $w . ( ( ${$where->{$w}} =~ /\s/ ) ? ' ' : ' = ' ) . ${$where->{$w}};
	  push(@{$map}, 'SCALAR');
	} elsif ( defined($where->{$w}{'val2'}) ) {
	  ${$sql} .= $w . ' ' . $where->{$w}{'op'} . ' ? AND ? ';
	  push(@{$map}, 'VAL2');
	} else {
	  ${$sql} .= $w . ' ' . $where->{$w}{'op'} . ' ? ';
	  push(@{$map}, 'VAL');
	}

        if ( $where->{$w}{'allowNull'} ) {
          ${$sql} .= " OR $w is null ) ";
        }
        ${$sql} .= " AND ";
      }
    } else {
      if ( ref($where->{$w}) eq 'ARRAY' ) {
	${$sql} .= $w . ' in (' . join(',', ('?') x scalar(@{$where->{$w}}) ) . ') AND ';
	push(@{$map}, 'ARRAY');
      } elsif ( ref($where->{$w}) eq 'SCALAR') { 
        ${$sql} .= $w . ( ( ${$where->{$w}} =~ /\s/ ) ? ' ' : ' = ' ) . ${$where->{$w}} . ' AND ';
	push(@{$map}, 'SCALAR');
      } else {
	# from clause construct.  sort of a hack.  if we are in a from clause, and the from clause has a prefix 
	# (with a dot as a seperator) as a table name, then we're dealing with a table join
	if ( $from && $from->{substr($w, 0, index($w, '.'))} && $from->{substr($where->{$w}, 0, index($where->{$w}, '.'))} ) {
	  ${$sql} .= "$w = $where->{$w} AND ";
	  push(@{$map}, 'SCALAR');
	} else {
	  ${$sql} .= $w . ' = ? AND ';
	  push(@{$map}, 'VALUE');
	}
      }
    }
  }

  ${$sql} =~ s/AND $//;

  return ${$sql};
}

# I guess I should explain having a seperate function for getting the values out of a structure for execution.
# In my mind, the following function is a little less of an impact CPU wise than the above function.. Writing a "map"
# of the structure, and simply using it to loop over the various elements has to be a little less stressful than
# having to figure out the exact path of hoops to jump through to get the list of arguments to the execution list.
# the "map" structure is just meant to help this module quickly figure out where the data is, it doesn't have to discover
# it on every pass (using ref tests)..

sub _value {
  my ( $value, $map, $c ) = @_;

  my @outbound;
  unless ( $c ) {
    # Hmmm.. since the map needs to increment every time, we'll start at -1..
    # notice that it's a ref to a scalar.. as this will allow me to maintain state
    # when dealing with multiple levels of nested "OR" clauses
    my $counter = -1;
    $c = \$counter;
  }

  if ( ref($value) eq 'HASH' ) {
    return map {
      ${$c}++;

      if ( $map->[${$c}] eq 'VALUE' ) {
	$value->{$_};
      } elsif ( $map->[${$c}] eq 'ARRAY' ) {
	@{$value->{$_}};
      } elsif ( $map->[${$c}] eq 'VAL2' ) {
	( $value->{$_}{'val'}, $value->{$_}{'val2'} );
      } elsif ( $map->[${$c}] eq 'VAL' ) {
	$value->{$_}{'val'};
      } elsif ( $map->[${$c}] eq 'HASH-ARRAY' ) {
        @{$value->{$_}{'val'}};

      } elsif ( $map->[${$c}] eq 'SCALAR' ) {
	# do nothing ...
      } elsif ( ref($map->[${$c}]) ) {
	# a little recursion didn't hurt anyone.. (the current value in the map structures is obviously an array,
	# sooo, we'll be simply passing a reference to the current position, so this routine will think it's a totally
	# new structure to parse (phew!)
	&_value($value->{$_}{'where'}, $map->[${$c}])
      }
    } sort(keys(%{$value}));
  } elsif ( ref($value) eq 'ARRAY' ) {
    # map stays the same, but $c is simply a reference to the current entry within the map
    if ( ref($value->[0]) ne 'SCALAR' ) {
      return map { 
        my @temp = &_value($_, $map, $c); 
        @temp;
      } @{$value};
    } else {
      # insert is being called (with a scalar)
      return grep {
        ${$c}++;
	$_ if ( $map->[${$c}] eq 'VALUE' );
      } @{$value};
    }
  } 
}

####
# easier "set" for DBH
sub setdbh {
  my $class = shift;
  $DBH = shift;
}

####
# return the dbh
sub getdbh {
  return $DBH;
}

####
# easier "set" for RETURNSQL

sub setreturn {
  my $class = shift;
  $RETURNSQL = shift;
}

sub setReturn {
  my $class = shift;
  $RETURNSQL = shift;
}

sub setdebug {
  my $class = shift;
  $DEBUGSQL = shift;
}

sub setDebug {
  my $class = shift;
  $DEBUGSQL = shift;
}

sub returnsth {
  my $class = shift;
  $RETURNSTH = shift;
}

sub asarray {
  my $class = shift;
  $ASARRAY = shift;
}

sub asArray {
  my $class = shift;
  $ASARRAY = shift;
}

#################################################################################
# object code

sub new {
  my ( $class, $dbh, $state ) = @_;

  return bless( { 'dbh' => $dbh, 'state' => $state || 1 } );
}

=head1 state

The state function controls how the stateful subroutines act in a OO environment.  As class based functions, you are returned the entire result set as one large data structure.  With larger data sets, you may wish to iterate through them one at a time, to avoid massive memory consumption.  If this is set to "true", then any direct query will save the statement handle to the object.  You can call all of the various DBI routines from here, or simply call the other helper methods.

Here is a quick example of how you would deal with Sql::Simple through the OO interface.

  my $obj = new Sql::Simple( DBI->connect('dbi:ODBC:instance', 'username', 'password') );
  my $result = $s->query(qw(name density), 'minerals')->fetchall_arrayref();

  my $sth = $obj->query(qw(color taste durability), 'fruit');
  while ( my @row = $sth->fetchrow() ) {
    # do something...
  }
  $sth->finish();
=cut

=cut

sub state {
  my ( $self, $state ) = @_;
  ( $state ) ? $self->{'state'} = $state : return $self->{'state'};
}

my @ofunctions = qw(column table where order);

my @functions = qw(fetchall_arrayref fetchrow_arrayref fetchrow fetchall_hashref fetchrow_hashref fetchrow_array err rows bind_columns fetch dump_results);

foreach my $field (@functions) {
  my $sub = q {
    sub [[field]] {
      my $self = shift;
      return $self->{'sth'}->[[field]]();
    }
  };

  $sub =~ s/\[\[field\]\]/$field/g;
  eval $sub;

  if ($@) {
    die $@;
  }
}

sub sth {
  my ( $self ) = @_;
  return $self->{'sth'};
}

sub finish {
  my ( $self ) = @_;
  $self->{'sth'}->finish() and delete($self->{'sth'}) if ( ref($self) && ref($self->{'sth'}) );
}

=head1 BUGS:

I sure hope there are no bugs, feel free to drop me a line if you run into anything I need to be concerned with.

=head1 Acknowledgements:

The author of XML::Simple (use it all the time).
Paul Lindner, Garth Webb, Kevin Moffatt, Chuck McLean, Intelligent Software Solutions (www.iswsolutions.com)

=head1 TODO:

 1. Figure out a good way of handling prefix's for columns.. (ugh)
 2A. store pre-computed sql and map (in object or possibly global via mod_perl or serialized in mldbm or whatever)
 2B. Be able to pass in the precomputed information as arguments to functions.. (partially done, with the execute method)

=head1 See also:

 DBI (manpage)
 Sql::* (lots of similar modules to this)

Specifically, take a look at DBIx::Abstract and Sql::Abstract.  I was rather astonished when I released this module today to find out there was another module that had such similar capabilities.  Great minds must think alike ;-).  After reviewing the modules, I can say that DBIx::Abstract and Sql::Simple have very little in common, but it does fill a niche that Sql::Simple does not.  Sql::Abstract however, does have nearly identical syntax on a few of the method calls, and has support for some of the features that I tout in Sql::Simple. (I'm not apologizing for writing this module, I like what it has done for me, 

I'm not going to write a bullet background paper iterating over every feature this module has and doesn't have in comparison but I will cover the major differences.

=item ANSI SQL 92 join support

This feature, combined with the fact that the "clause" for the join is directly tied to the same code that generates a where clause is probably the biggest difference.  This feature is available in all aspects of Sql::Simple, not just the query method (as any sub query made in insert, update, or delete simply recursively call the query method to build it's data set).  

=item Execution

Sql::Abstract right now is better suited for a web environment where you would want to write your own custom handlers to handle errors.  Once an OO interface is added to Sql::Simple, that may be reason enough to switch.  Right now, Sql::Simple is capable of returning the completed Sql statement back to the user, not really all that different from Sql::Abstract.. ie:

  $Sql::Simple::RETURNSQL = 1;
  my $sth = $dbh->prepare(Sql::Simple->query('id', 'fruit', { 'name' => 'apple' }));

Similar to.

  my $sql = SQL::Abstract->new;
  my ( $sth, @bind ) = $sql->select('fruit', ['id'], { 'name' => 'apple' });

=item Mass Execution

The main reason I wrote this module was to simplify the "I need to insert 10,000 records, but not use BCP, because I need it to hit the rules etc.".  With that said, the ability to pass in an array ref of hash refs into the insert routine, is fairly nice (or an array ref of columns, and an arrayref of arrayrefs of values).  Or be able to mass update quickly.  

=item Summary

Umm, TMTOWTDI, or whatever.  Use what suits you, the only real personal preference issue I have is that the variables are out of order in Sql::Abstract.  I'd rather see it line up with an actual SQL query.  IE: select COLUMNS from TABLE where CLAUSE, instead of TABLE, COLUMNS, WHERE

=head1 COPYRIGHT:

The Sql::Simple module is Copyright (c) 2004 Ryan Alan Dietrich. The Sql::Simple module is free software; you can redistribute it and/or modify it under the same terms as Perl itself with the exception that it cannot be placed on a CD-ROM or similar media for commercial distribution without the prior approval of the author.

=head1 AUTHOR:

Sql::Simple by Ryan Alan Dietrich <ryan@dietrich.net>

Contributions (thanks!) from the following.

Mark Stosberg, Miguel Manso, Tiago Almeida

=cut

1;
