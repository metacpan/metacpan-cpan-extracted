=head1 NAME

Tie::Table - Maps relational tables into hashes

=head1 SYNOPSIS

  use DBI;
  $dbh=DBI->connect(...);

  use Tie::Table;

  $database=new Tie::Table::DB(
    dbh         =>   $dbh,
      # DBI Database handler
    seq_mode =>   "ora",
      # Sequence handling mode
      # "ora": "select seqence.currval from dual";
      # "pg" : "select sequence.last_value";
      # db systems, which doesn't support sequences currently
      # doesn't supported (insert won't work)
    prepare_cached => 0,
      # Can use "prepare_cached" method of the DBI?
      # This causes problems for me, and that's why the
      # default is now 0. This param is not mandatory.
  );

  # You can use connect hash to specify connect parameters directly.
  # In this case you doesn't need to specify "dbh" parameter:
  # $database=new Tie::Table::DB( 
  #   connect=> [$data_source, $username, $auth, \%attr],
  #   seq_currval => ...
  # );
                          
  $company=$database->new_table (
    table => "company",    # Table name, mandatory
    key   => "id",         # Primary Key for the table
    seq   => "seq_company",# Sequence name for key field generation.
                           # Mandatory only if "insert" is in use
  );

  # $database->new_table(...)
  #   is the same as
  # new Tie::Table ( db => $database, ... )

  $user  =$database->new_table (
    table => "users",
    key   => "id",
    seq   => "seq_users",
    ref   => { company_id => [ $company, "user" ] },
      # This can be used for connecting tables.
      # This is similar to the SQL phrase:
      # 
      # .. company_id  int references company (id),
      #
      # only the key field can be referenced.
  );

  %company_14_users= % {$company->{14}->user };

  # All user IDs
  keys %$user;

  # Sets Company #14 Data:
  $company_14 = $company->{14};
  $company_14->{tax_num} = "123456";
  $company_14->{phone1} = "+42456245546";
  $company_14->write;

  # Wrong example:
  # $company->{14}->{tax_num} = "123456"
  # $company->{14}->write;
  # This doesn't work, because it always create a new Row object, 
  #   and the cache is stored per object.

  # Select a sub-relation
  $table=$user->select("company_id = ?",$id);

  # Select with constraint
  $user->constraint( company_id => $id );

  # Inserting a new record
  $id=$company->insert(
    { name=>"abc", 
      phone1=>"30/123567", 
      mobile=>"20/1234" } );
  if ($id) { print "Id: $id\n"; } else { print "Insert failed: "; };

  # Inserting or replacing a record with a specified id;
  $company->{1456} = { name => "abc", phone1=>"30/123456" };

  # Delete record
  delete $company->{13};
  %{ $company->{13} }=();

  # Select and constraint with returning only one row (the first):

  $row = $user->select1("age > ? and parent_id = ? ",18,175);

  $user_row_by_name = $user->constraint1( name => "Ms. Jackson" );
  $user_row_by_name = $user->by( name => "Ms. Jackson" ); # by == constraint1

  # Changing key order

  @keys = keys %{ $table->order("group desc") };

=head1 DESCRIPTION

This class is designed for mapping a table into a perl hash, which has keys (these are the primary keys of the table), and the values are the rows, represented by a hash.

=head2 Basic Usage

You can create Tie::Table objects for tables. You must specify a parameter hash to the constructor, which has the following keys:

=over 4

=item db

This is a reference to a Tie::Table::DB module. Normally you create a new Tie::Table object by the method of the "new_table" of a Tie::Table::DB instance, then you may not specify this.

=item table

Specifies the table name

=item key

Specifies the primary key. This must be specified, so if you don't have primary keys in your table, you cannot use the Tie::Table (for the whole table. You can use it for a subset of rows specified by the "constraint" param).

=item seq

If you want to use "insert" with self-incremental keys, you must specify this. Database servers, which doesn't implement sequences (mySQL) currently not supported.

=item ref

Creating a 1:N reference. The value is a hash reference, where the keys are database fields, and the values contains the reference information in an array reference:

ref => {
  field1 => [ $table1, "function1" ],
  field2 => [ $table2, "function2" ],
};

In the example above you can use the reference field (company_id) from the "user" table to query the company in which the user work: $company_name = $user->{17}->company_id->{name}.

function1 is the name of the function, which can be used for the back-reference, eg. can be used to determine the user-ids in one company: @user_ids= keys %{ $company->{45}->users }. "users" is the function name in this example.

=item where

Specifies a "where" condition for selecting id-s, so you can select a subset of keys with this. Also available with the "search" function:

@user_ids= keys %{ $table->search("age > 25") };

or 

$table=new Tie::Table (table => "table", where => "age > 25");
@user_ids=keys %$table;

=item constraint

This is similar to "select", but it can be used only for equality test. 
The main advantage is that it can be used for deletion and insertion. 
If you insert something into a table, which has constraint parameter, all 
the values in the constraint hash is set in the new record. 
This constraint is used internally, when somebody creates a back reference 
by a back-reference function.

=item order

This parameter describes the key-retrieval order. The value of the parameter
is appended to an "order by" parameter to the sql query, which retrieves the
keys from the database.

=back 4

=head2 Tie::Table methods

There are predefined methods, which can be called on table objects:

=over 4

=item select $sql, @parameters

Creates a new table object with "select" parameter appended to the existing
one, for example:

    $selected_table = $table->select("age > ?", 18);

The result is also a Tie::Table object.

=item constraint

Creates a new table object with "constraint" parameters set. This is similar
to the select method,but this only usable for equality relations:

    $selected_table = $table->constraint( age => 18 );

If you insert into the $selected_table, then the "age" parameter automatically
set to "18".

=item select1, constraint1 and by

These are variations of "select" and "constraint". The only difference is that
you will return only the first row of the result if more than one row matched.

These syntax are good if you know that at most 1 row is returned by the
select, for example when you have more than one unique indices on the table.

"by" is a short version of "constraint1", only a syntactic sugar:

    $ms_jackson_row = $user->by( name => "Ms. Jackson" );

=item order $name

Sets the "order" parameter on the table and returns it as a new object, e.g:

    my $ordered_table = $table->order("group_name desc");

If you call keys on %$ordered_table, then the key order will appropriate. If
the $table already has an order parameter, then it will be overwritten.

=item key $key

Sets the "key" parameter on the table and returns it as a new object. Useful
for tables, which are used as an N:N relation, e.g., the table is the
following:

    create table rel_user_day (
        id      int primary key serial,
        user_id int not null references users (id),
        day_id  int not null references day (id)
    );

The tablemap table-declaration is the following:

    $database->new_table(
        table => "rel_user_day",
        key   => "id",
        ref   => {
            user_id => [ $tables->{user}, "days" ],
            day_id  => [ $tables->{day},  "users" ],
        }
    );

Then your key is "id", but you can temporarily change the keys if you want
to get the day_id-s for a user by the following command:

    $user_day_hash = $tables->{user}->{$user_id}->days->key("day_id");

    then you will get the day_id-s by keys %$user_day_hash

=back

=head2 Tie::Table::Row methods

=over 4

=item write

This method must be called when the user is finished modifying the record,
e.g:

    my $record = $table->{$id};

    $record->{name} = "Blah";
    $record->{street} = "Headway";
    $record->write;

=back

=head2 References

There is two kind of reference in this module. All two are set up by "ref" parameter in the table. If you use a "ref" parameter, then the "back_ref" is automatically created in the other table (if not already exists).

=over 4

=item ref

$user->company_id gives a Tie::Table::Row record, which is a ROW in the company table. Each hash keys are field names.

=item back_ref

$company->users gives a Tie::Table object, which is a COLLECTION of rows (represented by a hash), which gives back the employees of the companies. (you can use "keys ..." expression for the ids).

=back 4

=head2 Caching

All the sql queries are cached in this module. This must be rethought, 
because sometimes it is not the best solution.
I want some extra parameter for caching in the newer versions. Now all the 
query results are cached for 10 seconds. This value can be tuned by setting
the Tie::Table::CACHE_SECS variable.

The global cache object is $Tie::Table::cache, and it can be invalidated by the 
$Tie::Table::cache->invalidate_cache call.

The cache is hierarchical (it is stored in tree structure). If you want to
invalidate the whole cache, you can call:

    $Tie::Table::cache->invalidate_cache([])

If you want to invalidate only one table, you can call:

    $Tie::Table::cache->invalidate_cache(["table_name"])

No other syntax currently supported.

=head2 Performance

This module is NOT the most efficient method for getting data from the database. It is written to avoid endless sql-query-typing with minimal performance loss.

The module uses two kind of sql queries:

=over 4

=item select key from table

This is used for querying all the keys from a table. This can be affected by the "constraint" and the "where" parameter.

=item select * from table where id=1234

This is used for querying all the fields of one row. This can be affected by the "constraint" parameter, but not thw "where".

=back 4

Sometimes querying the whole table is more effective, (when you have enough memory), but currently it is only a planned parameter.

=head2 BUGS AND LIMITATIONS

=over 4

=item *

The current implementation cannot handle tables, which is used to express a
relationship between two data. These tables normally have two foreign key
fields. If you want to use them with that module, then you need to add a
unique identifier for each row. For examply by using postgresql and if your
table looks like this:

You can write the following definition for this table (assumed that users and
day tables are already defined):

=item *

This module is now usable for one purpose. I have profiled it, and I've found 
that the "read_data" function is the most time-consuming. This must be 
handled by re-organizing the cache.

=item *

Caching can be set globally right now (by $Tie::Table::CACHE_SECS) but it must
be more fine-grained in the future.

=back

=head1 COPYRIGHT

Copyrigh (c) 2000 Balázs Szabó (dLux)
All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

dLux <dlux@kapu.hu>

=cut

package Tie::Table::DB;
use strict;
require Storable;
use DBI;
use Carp qw(confess cluck);
use vars qw($DEBUG);

sub new { my ($o,%param)=@_;
  my $s=\%param;
  bless ($s,$o);
  if (exists $s->{connect}) {
    $s->{dbh}=DBI->connect(@{ $s->{connect} });
  };
  confess "Not enough parameter" if !$s->{dbh};
  $s->set_seq_mode($s->{seq_mode});
  return $s;
};

sub sql { my ($s,$sql,@array)=@_;
  my $sth;
  eval {
    if (ref($sql) eq 'ARRAY') {
      $sth=$s->{prepare_cached} ? 
        $s->{dbh}->prepare_cached($sql->[0]) :
        $s->{dbh}->prepare($sql->[0]);
    } else {
      $sth=$s->{dbh}->prepare($sql);
    };
    cluck $s->{dbh}->errstr if $s->{dbh}->err || $DEBUG;
    $sth->execute(map { ref($_) ? "$_" : $_ } @array); # hack for overloaded objects
  };
  return $sth if $s->{quiet};
  if ($s->{dbh}->err || $@ || $DEBUG) {
    $sql="@$sql" if ref($sql) eq 'ARRAY';
    cluck "$@ ".$s->{dbh}->errstr."\nQUERY: \"$sql\"".
      (@array ? " Parameters: ".join(",",@array) : "")."\n";
  };
  return $sth;
};

sub set_seq_mode { my ($s,$mode)=@_;
  $s->{seq_query}=
    $mode eq 'ora' ? "select %s.currval from dual;" :
    $mode eq 'pg'  ? "select %s.last_value" :
    undef;
};

sub select_currval { my ($s,$sequence)=@_;
  cluck "No sequence handling installed!" if !$s->{seq_query};
  return $s->sql([sprintf($s->{seq_query},$sequence)]);
};

sub new_table { my ($s,@params)=@_;
  return new Tie::Table( db=> $s, @params );
};

package Tie::Table;
use strict;
use Carp qw(confess cluck);
use vars qw($DEBUG $VERSION $cache);

$VERSION='1.1.2';

sub cache { $Tie::Table::cache; };

sub new { my ($o,%param)=@_;
  my $s={};
  bless($s,$o);
  confess "Not enough Parameter"
    if !exists $param{table} || !exists $param{key} || !exists $param{db};
  tie (%$s,"Tie::Table::TIE",$s,%param);
  (tied %$s)->make_back_refs;
  return $s;
};

sub write { my ($ss)=@_; my $s=tied %$ss;
  my @r=values %{ $s->{dirty_rows} };
  foreach my $r (@r) { $r->write; };
};

sub write_cascade { my ($ss)=@_; my $s=tied %$ss;
  $ss->write;
  foreach my $v (values %{ $s->{param}->{back_ref} }) { 
    $v->[0]->write_cascade;
  };
};

sub select { my ($ss,$sql,@par)=@_; my $s=tied %$ss;
  my $p=$s->clone_param();
  $p->{"where"}= exists $p->{"where"} ?
    "(".$p->{"where"}.") and ($sql)" : $sql;
  push @{ $p->{"query_param"} },@par;
  return new Tie::Table(%$p);
};

sub order { my ($ss,$fieldlist) = @_; my $s = tied %$ss;
    my $p = $s->clone_param();
    $p->{"order"} = $fieldlist;
    return new Tie::Table(%$p);
}

sub key { my ($ss,$new_key) = @_; my $s = tied %$ss;
    my $p = $s->clone_param();
    $p->{key} = $new_key;
    delete $p->{back_ref}; # must not use back_ref, because the key is changed!
    delete $p->{seq};      # must not use the sequence
    return new Tie::Table(%$p);
}

sub constraint { my ($ss,%cons)=@_; my $s=tied %$ss;
  my $p=$s->clone_param();
  foreach my $i (keys %cons) {
    $p->{"constraint"}->{$i}=$cons{$i};
  };
  return new Tie::Table(%$p);
};

sub _first_val {
    my $key = (keys %{$_[0]})[0];
    return defined $key ? $_[0]->{$key} : undef;
}
sub select1 { 
    _first_val &select;
}

sub constraint1 {
    _first_val &constraint;
}

*by = *constraint1;

sub insert { my ($ss,$data)=@_; my $s=tied %$ss;
  my $key_field=$s->{param}->{key};
  confess "Specify \"seq\" if you want to insert"
    if !exists $s->{param}->{seq} && 
        !exists $data->{$key_field} && 
        !exists $s->{param}->{constraint}->{$key_field};
  $ss->insert_row($data);
};

sub insert_row { my ($ss,$data)=@_; my $s=tied %$ss;
  my $key_field=$s->{param}->{key};
  my $constraint=$s->{param}->{"constraint"};
  my $db=$s->{param}->{db};
  if ($constraint) {
    foreach my $k (keys %$constraint) {
      $data->{$k}=$constraint->{$k};
    };
  };
  my (@sql1,@sql2,@data);
  foreach my $k (keys %$data) {
    push @sql1,$k;
    push @sql2,"?";
    push @data,$data->{$k};
  };
  $db->sql(["insert into ".$s->{param}->{table}." (".
    join(",",@sql1).") values (".join(",",@sql2).")"],@data);
  cache->invalidate_cache([$s->{param}->{table}]);
  return undef if $db->{dbh}->err;
  if (!exists $data->{$key_field}) {
    my $sth=$db->select_currval($s->{param}->{seq});
    my ($seq)=$sth->fetchrow;
    $sth->finish;
    return $seq;
  } else {
    return $data->{$key_field};
  };
};

sub delete { my ($ss,$key)=@_; my $s=tied %$ss;
  my $constraint=$s->{param}->{"constraint"};
  my $db=$s->{param}->{db};
  my $cons; my @cons;
  if ($constraint) {
    foreach my $k (keys %$constraint) {
      $cons.=" and $k=?";
      push @cons,$constraint->{$k};
    };
  };
  $db->sql(["delete from ".$s->{param}->{table}." where ".
    $s->{param}->{key}."=?".$cons],$key,@cons);
  cache->invalidate_cache([$s->{param}->{table}]);
  foreach my $v (values %{ $s->{param}->{back_ref} || {} }) {
    # Invalidate every back-referenced table
    cache->invalidate_cache([ tied(%{$v->[0]})->{param}->{table} ]);
  };
};

#####################################
package Tie::Table::TIE;
use strict;
use Carp qw(confess cluck);
use vars qw($DEBUG);
use UNIVERSAL qw(isa);

sub cache { $Tie::Table::cache; };
sub TIEHASH { my ($o,$main_obj,%param)=@_;
  my $s={
    param    =>\%param,
    main_obj =>$main_obj,
    dirty_row=>{},
  };
  $s->{param}->{back_ref} ||= {};
  bless ($s,$o);
  return $s;
};

sub make_back_refs { my ($s)=@_;
  my $main_obj=$s->{main_obj};
  if (exists $s->{param}->{"ref"}) {
    foreach my $k (keys %{ $s->{param}->{"ref"} }) {
      my ($ref_table,$function)=@{ $s->{param}->{"ref"}->{$k} };
      (tied %$ref_table)->{param}->{back_ref}->{$function} ||= [$main_obj,$k];
        # write only when no data is already written to it
    };
  };
};

sub FIRSTKEY { my ($s)=@_;
  my (@where,@qp,@path);
  push @path,$s->{param}->{table},$s->{param}->{key},"__all_keys__";
  my $constraint=$s->{param}->{constraint};
  if ($constraint) {
    foreach my $k (sort keys %$constraint) {
      push @where,"$k=?";
      push @path,$k,$constraint->{$k};
      push @qp,$constraint->{$k};
    };
  };
  if (exists $s->{param}->{"where"}) {
    push @where, $s->{param}->{"where"};
    push @path,"where ".$s->{param}->{where},@{ $s->{param}->{"query_param"} };
    push @qp, @{ $s->{param}->{"query_param"} };
  };
  my $order_by = $s->{param}->{"order"};
  my $array=cache->get_array($s->{param}->{db},[@path],
    "select ".$s->{param}->{key}." from ".$s->{param}->{table}.
    (@where ? " where ".join(" and ",@where) : "").
    ($order_by ? " order by $order_by" : ""), [@qp]
  );
  $s->{keys}=$array;
  return $s->{keys}->[0]->[0];
};

sub NEXTKEY { my ($s,$lastkey)=@_;
  my $key= ++$s->{keycount};
  return undef if !exists $s->{"keys"};
  if ($key >= @{ $s->{"keys"} }) {
    delete $s->{keycount};
    delete $s->{"keys"};
    return undef;
  };
  return $s->{"keys"}->[$key]->[0];
};

sub STORE { my ($s,$key,$val)=@_;
    $val = {} if !defined $val;
    die "Cannot insert non-hashref value to a table" if !isa($val,'HASH');
    if (my $row = $s->FETCH($key)) { # key already exists
        $row->{$_} = $val->{$_} foreach keys %$val;
        $row->write;
        return $row;
    } else {
        my %val = (%$val, $s->{param}->{key} => $key);
        $s->{main_obj}->insert_row(\%val);
        return $s->FETCH($key);
    }
};

# delete $hash->{key};
sub DELETE { my ($s,$key)=@_;
  my $main_obj=$s->{main_obj};
  $main_obj->delete($key);
};

# CLEAR: %{ $hash->{key} }=();
sub CLEAR { &DELETE; };

sub FETCH { my ($s,$key)=@_;
  return new Tie::Table::Row( $s, $key);
};

sub EXISTS { &FETCH; };

sub clone_param { my ($s)=@_;
  my $p=$s->{param};
  my $r; %$r=%$p;
  foreach my $k (qw(constraint query_param)) {
    $r->{$k}=Storable::dclone($p->{$k}) if exists $p->{$k};
  };
  return $r;
};

#####################################
package Tie::Table::Row;
use strict;
use Carp qw(confess cluck);
use vars qw($DEBUG $AUTOLOAD);

sub cache { $Tie::Table::cache; };

sub new { my ($o,$table,$key)=@_;
  my $s={};
  bless $s,$o;
  return tie(%$s,"Tie::Table::Row::TIE",$table,$key) ? $s : undef;
};

sub write { my ($ss)=@_; my $s=tied %$ss;
  my $param=$s->{table}->{param};
  my $db=$param->{db};
  my $key_field=$param->{key};
  my $key_value=$s->{data}->{$key_field};
  my $table=$param->{table};
  my $sql="update $table set ";
  my @sql; my @data;
  foreach my $k (keys %{ $s->{newdata} }) {
    push @sql, "$k=?";
    push @data,$s->{newdata}->{$k};
  };
  my $constraint=$param->{"constraint"};
  my @where="$key_field=?";
  push @data,$key_value;
  if ($constraint) {
    foreach my $k (keys %$constraint) {
      push @where,"$k=?";
      push @data,$constraint->{$k};
    };
  };
  if (@sql) {
    $db->sql(["update $table set ".join(",",@sql)." where ".
      join(" and ",@where)],@data);
    cache->invalidate_cache([ $table ]);
  };
  $s->{newdata}={};
  delete $s->{table}->{dirty_rows}->{$key_value};
};

sub AUTOLOAD { my ($ss)=@_; my $s=tied %$ss;
  my ($sub) = $AUTOLOAD =~ /.*::(.*)/o;
  my $param=$s->{table}->{param};
  my $back_ref=$param->{back_ref};
  my $ref=$param->{'ref'};
  if (exists $back_ref->{$sub}) {
    my $param=(tied %{ $back_ref->{$sub}->[0] })->clone_param();
    $param->{"constraint"}->{ $back_ref->{$sub}->[1] }= $s->{key};
    return new Tie::Table (%$param);
  } elsif (exists $ref->{$sub}) {
    return undef if !exists $s->{data}->{$sub};
    return new Tie::Table::Row( tied %{ $ref->{$sub}->[0] }, 
      $s->{data}->{ $sub });
  };
};

sub DESTROY {}; # Don't bother AUTOLOAD for it...

#####################################
package Tie::Table::Row::TIE;
use strict;
use Carp qw(confess cluck);
use vars qw($DEBUG);

sub cache { $Tie::Table::cache; };

sub TIEHASH { my ($o,$table,$key)=@_;
  my $s={
    table=>$table,
    key=>$key,
    data=>undef,
    newdata=>undef,
  };
  bless $s,$o;
  $s->read_data;
  return $s->{data} ? $s : undef;
};

sub read_data { my ($s)=@_;
  my ($where,$path,$val);
  my $param=$s->{table}->{param};
  if (! ($path=$s->{cache_path})) {
    my $key=$s->{key};
    push @$path,$param->{table},$param->{key},$key;
    my $constraint=$param->{"constraint"};
    if ($constraint) {
      foreach my $k (sort keys %$constraint) {
        push @$path,$k,$constraint->{$k};
      };
    };
    push @$path,$param->{"where"},$param->{"query_param"};
    $s->{cache_path}=$path;
  };
  $s->{data}=cache->cache_hit($path);
  if (!$s->{data}) {
    if (!$s->{query}) {
      my $key=$s->{key};
      my $constraint=$param->{"constraint"};
      push @$where,$param->{key}."=?";
      push @$val,$key;
      if ($constraint) {
        foreach my $k (sort keys %$constraint) {
          push @$where,"$k=?";
          push @$val,$constraint->{$k};
        };
      };
      if (my $wh = $param->{where}) {
        push @$where, ,"($wh)";
        push @$val, @{ $param->{"query_param"} }
      }
      $s->{query}=[$where,$val];
    } else {
      ($where,$val)=@{ $s->{query} };
    };
    $s->{data}=cache->get_hash_directly($param->{db},
      $path, "select * from ".$param->{table}." where ".
      join(" and ",@$where), [@$val]
    );
  };
};

sub FETCH { my ($s,$key)=@_;
  if (exists $s->{newdata}->{$key}) {
    return $s->{newdata}->{$key}
  } else {
    $s->read_data;
    cluck "Invalid Tie::Table Key!" if !exists $s->{data}->{$key};
    return $s->{data}->{$key};
  };
};

sub STORE { my ($s,$key,$value)=@_;
  my $key_field=$s->{table}->{param}->{key};
  confess "Cannot modify a key value" if $key eq $key_field;
  $s->{table}->{dirty_rows}->{ $s->{data}->{$key_field} }=$s;
  $s->{newdata}->{$key}=$value;
};

sub DELETE { my ($s,$key)=@_;
  return undef;
};

sub CLEAR { my ($s)=@_;
  return undef;
};

sub EXISTS { my ($s,$key)=@_;
  return exists $s->{data}->{$key};
};

sub FIRSTKEY { my ($s)=@_;
  my $a= scalar keys %{$s->{data}};
  each %{$s->{data}};
};

sub NEXTKEY { my ($s,$lastkey)=@_;
  each %{$s->{data}};
};

#####################################
package Tie::Table::Cache;
use strict;
use Carp qw(confess cluck);
use vars qw($DEBUG $CACHE_SECS $CACHE_EXPIRE_PERIOD);
$CACHE_SECS=10;          # How much time a data is valid in the cache
$CACHE_EXPIRE_PERIOD=300;# How often visit through the cache for expired entries

sub new { my ($o)=@_;
  my $s={};
  bless ($s,$o);
  return $s;
};

sub get_array{ my ($s,$db,$cache_path,$sql,$params)=@_;
  $s->expire_cache;
  my $a=$s->cache_hit($cache_path);
  return $a if $a;
  $a=[];
  my $sth=$db->sql([$sql],@$params);
  while (my @row=$sth->fetchrow) {
    push @$a,[@row];
  };
  $sth->finish;
  $s->cache_write($a,$cache_path);
  return $a;
};

sub get_hash { my ($s,$db,$cache_path,$sql,$params)=@_;
  $s->expire_cache;
  my $h=$s->cache_hit($cache_path);
  return  $h if $h;
  &get_hash_directly;
};

sub get_hash_directly { my ($s,$db,$cache_path,$sql,$params)=@_;
  $s->expire_cache;
  my $h;
  my $sth=$db->sql([$sql],@$params);
  $h=$sth->fetchrow_hashref;
  $sth->finish;
  $s->cache_write($h,$cache_path);
  return $h;
};

sub cache_hit{ my ($s,$path)=@_;
  return undef if !exists $s->{cache};
  my $walk=$s->{cache};
  for (my $i=0; $i<@$path; $i++) {
    my $key=$path->[$i];
    return undef if !exists $walk->[0]->{$key};
    $walk=$walk->[0]->{$key};
  };
  return undef if $walk->[1]<time;
  return $walk->[2];
};

sub invalidate_cache { my ($s,$path)=@_;
  if (! @$path ) { $s->{cache}=[{},0,undef]; return; };
  my $walk=$s->{cache};
  for (my $i=0; $i<@$path-1; $i++) {
    my $k=$path->[$i];
    return if !exists $walk->[0]->{$k};
    $walk=$walk->[0]->{$k};
  };
  $walk->[0]->{ $path->[-1] }=[{},0,undef];
};

sub expire_cache { my ($s)=@_;
  return if $s->{expire_time}>time;
  $s->expire_cache_what($s->{cache});
  $s->{expire_time}=time+$CACHE_EXPIRE_PERIOD;
};

sub expire_cache_what { my ($s,$what)=@_;
  my $keep_me=1;
  if ($what->[1] <time) {
    $keep_me=0;
    $what->[2]=undef;
  };
  my @k=keys %{ $what->[0] };
  foreach my $k (@k) {
    my $keep_it=$s->expire_cache_what($what->[0]->{$k});
    delete $what->[0]->{$k} if !$keep_it;
    $keep_me ||= $keep_it;
  };
  return $keep_me;
};

sub cache_write { my ($s,$data,$path)=@_;
  $s->{cache}=[{},0,undef] if !exists $s->{cache};
  my $walk=$s->{cache};
  for (my $i=0; $i<@$path; $i++) {
    my $k=$path->[$i];
    $walk->[0]->{$k}=[{},0,undef] if !exists $walk->[0]->{$k};
    $walk=$walk->[0]->{$k};
  };
  $walk->[1]=time;
  $walk->[2]=$data;
};

$Tie::Table::cache=new Tie::Table::Cache;

1;
