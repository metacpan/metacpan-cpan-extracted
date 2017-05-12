package  perfSONAR_PS::DB::SQL::QueryBuilder;

use strict;
use warnings;
use Carp;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(build_select build_where_clause);

our $VERSION = '0.09';

use constant PRIVATE_PREFIX     => '__xrdbopriv';
use constant META_ATTR_NAME     => PRIVATE_PREFIX . '_meta';
use constant ON_SAVE_ATTR_NAME  => PRIVATE_PREFIX . '_on_save';
use constant LOADED_FROM_DRIVER => PRIVATE_PREFIX . '_loaded_from_driver';
use constant FLAG_DB_IS_PRIVATE => PRIVATE_PREFIX . '_db_is_private';
use constant MODIFIED_COLUMNS   => PRIVATE_PREFIX . '_modified_columns';
use constant SET_COLUMNS        => PRIVATE_PREFIX . '_set_columns';
use constant STATE_IN_DB        => PRIVATE_PREFIX . '_in_db';
use constant STATE_LOADING      => PRIVATE_PREFIX . '_loading';
use constant STATE_SAVING       => PRIVATE_PREFIX . '_saving';
use constant STATE_CLONING      => STATE_SAVING;

our %OP_MAP = 
(  
  similar      => 'SIMILAR TO',
  match        => '~',
  imatch       => '~*',
  regex        => 'REGEXP',
  regexp       => 'REGEXP',
  like         => 'LIKE',
  ilike        => 'ILIKE',
  rlike        => 'RLIKE',
  is           => 'IS',
  is_not       => 'IS NOT',
  lt           => '<',
  le           => '<=',
  ge           => '>=',
  gt           => '>',
  ne           => '<>',
  eq           => '=',
  '&'          => '&',
  ''           => '=',
  sql          => '=',
  in_set       => 'ANY IN SET',
  any_in_set   => 'ANY IN SET',
  all_in_set   => 'ALL IN SET',
  in_array     => 'ANY IN ARRAY',
  any_in_array => 'ANY IN ARRAY',
  all_in_array => 'ALL IN ARRAY',
);

@OP_MAP{map { $_ . '_sql' } keys %OP_MAP} = values(%OP_MAP);

our $Strict_Ops = 0;

our %Op_Arg_PassThru = map { $_ => 1 } 
  qw(similar match imatch regex regexp like ilike rlike in_set any_in_set all_in_set
     in_array any_in_array all_in_array);

BEGIN { eval { require DBI::Const::GetInfoType }; }
use constant SQL_DBMS_VER => $DBI::Const::GetInfoType::GetInfoType{'SQL_DBMS_VER'} || 18;

sub build_where_clause {
    my $arg = shift;
    $arg->{where_only} = 1;
    return build_select($arg);
 
 }

sub build_select {
  my $args  = shift;

  my $dbh          = $args->{'dbh'};
  my $tables       = $args->{'tables'} || Carp::croak "Missing 'tables' argument";
  my $tables_sql   = $args->{'tables_sql'} || $tables;
  my $logic        = delete $args->{'logic'} || 'AND';
  my $columns      = $args->{'columns'};  
  my $all_columns  = $args->{'all_columns'} || {};
  my $query_arg    = delete $args->{'query'};
  my $sort_by      = delete $args->{'sort_by'};
  my $group_by     = delete $args->{'group_by'};
  my $limit_suffix = delete $args->{'limit_suffix'};
  my $limit_prefix = delete $args->{'limit_prefix'} || '';
  my $distinct     = delete $args->{'distinct'} ? 'DISTINCT ' : '';
  my $select       = $args->{'select'};
  my $where_only   = delete $args->{'where_only'};
  my $clauses_arg  = delete $args->{'clauses'};  
  my $pretty       = '1';
  my $joins        = $args->{'joins'};
  my $hints        = $args->{'hints'} || {};
  my $set          = delete $args->{'set'};
  my $table_map    = delete $args->{'table_map'} || {};
  my $bind_params  = $args->{'bind_params'};
  my $from_and_where_only = delete $args->{'from_and_where_only'};
  my $allow_empty_lists   = $args->{'allow_empty_lists'};
  my $unique_aliases = $args->{'unique_aliases'};
  my $table_aliases  = exists $args->{'table_aliases'} ? 
    $args->{'table_aliases'} : ($args->{'table_aliases'} = 1);

  if($args->{'limit'})
  {
    $limit_suffix = 'LIMIT ' . delete $args->{'limit'};
  }

  $all_columns = $columns  unless(%$all_columns);

  $logic = " $logic"  unless($logic eq ',');

  $args->{'_depth'}++;

  unless($args->{'dbh'})
  {
     Carp::croak "Missing 'dbh' argument";
  }

  my $do_bind = wantarray;

  my(@bind, @clauses);

  my %query;

  if($query_arg)
  {
    for(my $i = 0; $i <= $#$query_arg; $i++)
    {
      if($query_arg->[$i] =~ /^(?:and|or)$/i)
      {
        my $query = $query_arg->[$i + 1];

        unless(ref $query && @$query)
        {
          $i++;
          next;
        }

        my($sql, $bind);

        if($do_bind)
        {
          ($sql, $bind) =
            build_select(%{$args}, 
                         where_only => 1,
                         query => $query,
                         logic => uc $query_arg->[$i],
                         table_map => $table_map,
                         set => $set);

          push(@bind, @$bind);
        }
        else
        {
          $sql =
            build_select( %{$args}, 
                         where_only => 1,
                         query => $query,
                         logic => uc $query_arg->[$i],
                         table_map => $table_map,
                         set => $set);
        }

        if($pretty)
        {
          my $pad     = '  ' x $args->{'_depth'};
          my $sub_pad = '  ' x ($args->{'_depth'} - 1);

          for($sql)
          {
            s/\A //;
            s/^ +$//g;
            s/\s*\Z//;
          }

          push(@clauses, "(\n" . $sql . "\n" . "$pad)");
        }
        else
        {
          push(@clauses, "($sql)");
        }

        $i++;
      }
      elsif(my $ref = ref $query_arg->[$i])
      {
        if($ref eq 'SCALAR')
        {
          push(@clauses, ${$query_arg->[$i]});
        }
        elsif($ref eq 'ARRAY')
        {
          my $list = $query_arg->[$i];

          no warnings 'uninitialized';
          unless(ref $list->[0] eq 'SCALAR')
          {
            Carp::croak "Invalid array reference argument: [ @$list ] - ",
                        "Expected a reference to a scalar followed by zero or more ",
                        "bind arguments";
          }

          push(@clauses, ${$list->[0]});

          if($do_bind)
          {
            push(@bind, @$list[1 .. $#$list]);
            push(@$bind_params, undef); # need to offset this list with empty items
          }
        }
      }
      else
      {
        push(@{$query{$query_arg->[$i]}}, $query_arg->[$i + 1]);
        $i++;
      }
    }
  }

  my $query_is_sql = $args->{'query_is_sql'};

  $select   = join(', ', map { ref $_ eq 'SCALAR' ? $$_ : $_ } @$select)    if(ref $select);
  $sort_by  = join(', ', map { ref $_ eq 'SCALAR' ? $$_ : $_ } @$sort_by)   if(ref $sort_by);
  $group_by = join(', ', @$group_by)  if(ref $group_by);

  my($not, $op, @select_columns, %column_count);

  foreach my $table (@$tables)
  {
    next  unless($columns->{$table});

    foreach my $column (@{$columns->{$table}})
    {
      $column_count{$column}++;
    }
  }

  my $multi_table = @$tables > 1 ? 1 : 0;
  my $table_num = 1;

  if($multi_table)
  {
    $table_aliases = 1;
  }
  else
  {
    $table_aliases = $multi_table  unless(defined $table_aliases);
  }

  my($db, %proto, $do_bind_params); # db object and prototype objects used for formatting values

  foreach my $table (@$tables)
  {
    my $table_tn    = $table_num;
    my $table_alias = 't' . $table_num++;

    #next  unless($all_columns->{$table} ||= $columns->{$table});

    my($classes, $meta, $obj_class, $obj_meta);

     
    $bind_params = undef  unless($do_bind_params);

    my $query_only_columns = 0;
    my $my_columns     = $columns->{$table};
    my $all_my_columns = $all_columns->{$table} ||= $my_columns;
 

    my %select_columns = map { $_ => 1 } @$my_columns;

    foreach my $column (@$all_my_columns)
    {
      my $fq_column     = "$table.$column";
      my $short_column  = "$table_alias.$column";
      my $unique_column = "${table_alias}_$column";
      my $rel_column    =  $table_map->{$table_tn} ?
        "$table_map->{$table_tn}.$column" : '';

      my $fq_column_trimmed;

      TRIM:
      {
        (my $t = $table) =~ s/^[^.]+\.//;
        $fq_column_trimmed = "$t.$column";
      }

      # Avoid duplicate clauses if the table name matches the relationship name
      $rel_column = ''  if($rel_column eq $fq_column);

      my $method = $obj_meta ? $obj_meta->column_rw_method_name($column) : undef;

      unless($query_only_columns || !$select_columns{$column})
      {
        if($table_aliases)
        {
          push(@select_columns,   ($unique_aliases ? "$short_column AS ${table_alias}_$column" : $short_column));
        }
        else
        {
          push(@select_columns,  $column);
        }
      }

      foreach my $column_arg (grep { exists $query{$_} } map { ($_, "!$_") } 
                              ($column, $fq_column, $fq_column_trimmed, $short_column,
                               $rel_column, $unique_column, 
                              (defined $method && $method ne $column ? $method : ())))
      {
        $not = (index($column_arg, '!') == 0) ? 'NOT' : '';

        # Deflate/format values using prototype objects
        foreach my $val (@{$query{$column_arg}})
        {
          my $col_meta;

          my $val_ref    = ref $val;
          my $scalar_ref = $val_ref eq 'SCALAR';

          if(($column_arg eq $column || $column_arg eq "!$column") &&    ($column_count{$column} || 0) > 1)
          {
            if($args->{'no_ambiguous_columns'})
            {
              Carp::croak "Column '$column' is ambiguous; it appears in ",
                          "$column_count{$column} tables.  Use a fully-qualified ",
                          "column name instead (e.g., $fq_column or $short_column)";
            }
            else # unprefixed columns are considered part of t1
            {
              next  unless($table_alias eq 't1');
            }
          }

          my $placeholder = $col_meta ? $col_meta->query_placeholder_sql($db) : '?';
          my $sql_column = $table_aliases ? $short_column :
                           $db ? $db->auto_quote_column_name($column) : $column;

          if($val_ref)
          {
            $val = $$val  if($scalar_ref);

            push(@clauses, _build_clause($dbh, $sql_column, $op, $val, $not, 
                                         undef, ($do_bind ? \@bind : undef),
                                         $db, $col_meta, $scalar_ref, $set, 
                                         $placeholder, $bind_params, 
                                         $allow_empty_lists));
          }
          elsif(!defined $val)
          {
            no warnings 'uninitialized';            

            if($set)
            {
              push(@clauses, "$sql_column = NULL");
            }
            elsif($op eq 'IS' || $op eq 'IS NOT')
            {
              push(@clauses, ($not ? 'NOT(' : '') . "$sql_column IS " .
                             ($op eq 'IS NOT' ? 'NOT ' : '') . 'NULL' .
                             ($not ? ')' : ''));
            }
            else
            {
              push(@clauses, ("$sql_column IS " . (($not || $op eq '<>') ? "NOT " : '') . 'NULL'));
            }
          }
          else
          {
            if($col_meta && $db && $col_meta->should_inline_value($db, $val))
            {
              push(@clauses, ($not ? "$not($sql_column = $val)" : "$sql_column = $val"));
            }
            elsif($do_bind)
            {
              push(@clauses, ($not ? "$not($sql_column = $placeholder)" : "$sql_column = $placeholder"));
              push(@bind, $val);

              if($do_bind_params)
              {
                push(@$bind_params, $col_meta->dbi_bind_param_attrs($db));
              }
            }
            else
            {
              push(@clauses, ($not ? "$not($sql_column = " . $dbh->quote($val) . ')' :
                              "$sql_column = " . $dbh->quote($val)));
            }
          }
        }
        delete $query{$column_arg};
      }
    }
  }

  if(%query)
  {
    my $s = (scalar keys %query > 1) ? 's' : '';
    Carp::croak "Invalid query parameter$s: ", join(', ', sort keys %query);
  }

  if($clauses_arg)
  {
    push(@clauses, @$clauses_arg);
  }

  my $where;

  if($pretty)
  {
    my $pad = '  ' x $args->{'_depth'};
    $where = join("$logic\n", map { "$pad$_" } @clauses);
  }
  else
  {
    $where = join("$logic\n", map { "  $_" } @clauses);
  }

  my $qs;

  my $nested_joins = (exists $args->{'nested_joins'}) ?    delete $args->{'nested_joins'} :  1;

  if(!$where_only)
  {
    my $from_tables_sql;

    # XXX: Undocumented "joins" parameter is an array indexed by table
    # alias number.  Each value is a hashref that contains a key 'type'
    # that contains the join type SQL, and 'conditions' that contains a
    # ref to an array of join conditions SQL.
    #
    # If this parameter is passed, then every table except t1 that has 
    # a join type and condition will be joined with an explicit JOIN
    # statement.  Otherwise, an inplicit inner join will be used.
    if($joins && @$joins)
    {
      my $i = 1;
      my($primary_table, @normal_tables, @joined_tables, @nested);

      foreach my $table (@$tables)
      {
        # Main table gets treated specially
        if($i == 1)
        {
          #$primary_table = "  $tables_sql->[$i - 1] t$i";
        
          $primary_table = "  $tables_sql->[$i - 1] t$i";
          

          $i++;
          next;
        }
        elsif(!$joins->[$i])
        {
          
          push(@normal_tables, "  $tables_sql->[$i - 1] t$i");
          
          $i++;
          next;
        }

        Carp::croak "Missing join type for table '$table'"
          unless($joins->[$i]{'type'});

        Carp::croak "Missing join conditions for table '$table'"
          unless($joins->[$i]{'conditions'});

        if($nested_joins)
        {
          if(my $parent_tn = $joins->[$i]{'parent_tn'})
          {
            push(@{$nested[$parent_tn]}, $i);
          }
          else
          {
            $nested[$i] = [];
          }
        }
        else
        {
      
            push(@joined_tables, 
                 "  $joins->[$i]{'type'} $tables_sql->[$i - 1] t$i ON (" .
                 join(' AND ', @{$joins->[$i]{'conditions'}}) . ")");
         
        }

        $i++;
      }

      if($nested_joins)
      {
        my @seen;

        for($i = 1; $i <= $#nested; $i++)
        {
          next  if($seen[$i]++);

          my $children = $nested[$i];

          next  unless($children);

          if(@$children)
          {
            push(@joined_tables, _build_nested_join($joins, \@nested, $i, $tables_sql, $db, \@seen));
          }
          else
          {
            
              push(@joined_tables, 
                   "  $joins->[$i]{'type'} $tables_sql->[$i - 1] t$i ON (" .
                   join(' AND ', @{$joins->[$i]{'conditions'}}) . ")");
           
          }
        }
      }

      # XXX: This sucks
      my $driver = $dbh->{'Driver'}{'Name'};

      if($driver eq 'mysql' && @normal_tables &&
         ($dbh->get_info(SQL_DBMS_VER) =~ /5\.\d+\.(?:1[2-9]|[2-9]\d)/))
      {
        # MySQL 5.0.12 and later require the implicitly joined tables
        # to be grouped with parentheses or explicitly joined.

        # Explicitly joined:
        #$from_tables_sql = 
        #  join(" JOIN\n",  $primary_table, @normal_tables) . "\n" . 
        #  join("\n", @joined_tables);

        # Grouped by parens:
        $from_tables_sql = 
          "  (\n" . join(",\n  ", "  $primary_table", @normal_tables) . "\n  )\n" .
          join("\n", @joined_tables);
      }
      elsif($driver eq 'SQLite')
      {
        # SQLite 1.12 seems to demand that explicit joins come last. 
        # Older versions seem to like it too, so we'll doit that way
        # for SQLite in general.

        # Primary table first, then implicit joins, then explicit joins
        $from_tables_sql = 
          join(",\n", $primary_table, @normal_tables) .
          join("\n", @joined_tables);
      }
      else
      {
        # Primary table first, then explicit joins, then implicit inner joins
        $from_tables_sql =
          join("\n", $primary_table, @joined_tables) .
               (@normal_tables ? ",\n" . join(",\n", @normal_tables) : '');
      }
    }
    else
    {
      my $i = 0;

      my $oracle_hack = $dbh->{'Driver'}{'Name'} eq 'Oracle' && $limit_prefix;

      if($db)
      {
        $from_tables_sql = $table_aliases ?
          join(",\n", map 
          {
            $i++;
            '  ' . $db->format_table_with_alias($_, "t$i", $hints->{"t$i"} || ($i == 1 ? $hints : undef))
          } @$tables_sql) :
          '  ' . (($oracle_hack || keys %$hints) ? 
            $db->format_table_with_alias($tables_sql->[0], "t1", $hints->{'t1'} || $hints) :
            $tables_sql->[0]);
      }
      else
      {
        $from_tables_sql = $table_aliases ?
          join(",\n", map { $i++; "  $_ t$i" } @$tables_sql) :
          "  $tables_sql->[0]";
      }
    }

    $select ||= join(",\n", map { "  $_" } @select_columns);

    if($from_and_where_only)
    {
      $qs = "$from_tables_sql\n";
    }
    else
    {
      if($limit_prefix !~ /^SELECT /)
      {
        $qs = "SELECT $limit_prefix$distinct\n$select\nFROM\n$from_tables_sql\n";
      }
      else
      {
        $qs = "${limit_prefix}SELECT$distinct\n$select\nFROM\n$from_tables_sql\n";
      }
    }
  }

  if($where)
  {
    if($where_only)
    {
      $qs = ' ' . $where;
    }
    else
    {
      $qs .= "WHERE\n" . $where;
    }
  }

  $qs .= "\nGROUP BY " . $group_by if($group_by);
  $qs .= "\nORDER BY " . $sort_by  if($sort_by);
  $qs .= "\n" . $limit_suffix      if(defined $limit_suffix);

  

  return wantarray ? ($qs, \@bind) : $qs;
}

sub _build_clause
{
  my($dbh, $field, $op, $vals, $not, $field_mod, $bind, $db, $col_meta,
     $force_inline, $set, $placeholder, $bind_params, $allow_empty_lists) = @_;

  #if(ref $vals eq 'ARRAY' && @$vals == 1)
  #{
  #  $vals = $vals->[0];
  #}

  if(ref $vals eq 'SCALAR')
  {
    $force_inline = 1;
    $vals = $$vals;
  }

  if(!defined $op && ref $vals eq 'HASH' && keys(%$vals) == 1)
  {
    my $op_arg = (keys(%$vals))[0];

    if($op_arg =~ s/_?sql$//)
    {
      $force_inline = 1;
    }

    unless($op = $OP_MAP{$op_arg})
    {
      if($Strict_Ops)
      {
        Carp::croak "Unknown comparison operator: $op_arg";
      }
      else { $op = $op_arg }
    }
  }
  else { $op ||= '=' }

  my $ref;

  # XXX: This sucks
  my $driver = $db ? $db->driver : '';

  unless($ref = ref($vals))
  {
    $field = $field_mod  if($field_mod);

    my $should_inline = 
      ($db && $col_meta && $col_meta->should_inline_value($db, $vals));

    if(defined($vals))
    {
      if($bind && !$should_inline && !$force_inline)
      {
        push(@$bind, $vals);

        if($bind_params)
        {
          push(@$bind_params, $col_meta->dbi_bind_param_attrs($db));
        }

        if($op eq 'ANY IN SET' || $op eq 'ALL IN SET')
        {
          if($driver eq 'mysql')
          {
            return ($not ? "$not(" : '') . 
                   "FIND_IN_SET($placeholder, $field) > 0" . ($not ? ')' : '');
          }
          else
          {
            return ($not ? "$not " : '') . "$placeholder IN $field ";
          }
        }
        elsif($op eq 'ANY IN ARRAY' || $op eq 'ALL IN ARRAY')
        {
          return $not ? "NOT ($placeholder = ANY($field))" : "$placeholder = ANY($field)";
        }
        else
        {
          return ($not ? "$not(" : '') . "$field $op $placeholder"  . ($not ? ')' : '');
        }
      }

      if($op eq 'ANY IN SET' || $op eq 'ALL IN SET')
      {
        if($driver eq 'mysql')
        {
          return ($not ? "$not(" : '') . 'FIND_IN_SET(' . 
                 (($should_inline || $force_inline) ? $vals : $dbh->quote($vals)) . 
                 ", $field) > 0" . ($not ? ')' : '');
        }
        else
        {
          return ($not ? "$not(" : '') . 
                 (($should_inline || $force_inline) ? $vals : $dbh->quote($vals)) .
                 " IN $field " . ($not ? ')' : '');
        }
      }
      elsif($op eq 'ANY IN ARRAY' || $op eq 'ALL IN ARRAY')
      {
        my $qval = ($should_inline || $force_inline) ? $vals : $dbh->quote($vals);
        return $not ? "NOT ($qval = ANY($field)) " : "$qval = ANY($field) ";
      }
      else
      {
        return ($not ? "$not(" : '') . "$field $op " .
               (($should_inline || $force_inline) ? $vals : 
                                                   $dbh->quote($vals)) . 
               ($not ? ')' : '');
      }
    }

    no warnings 'uninitialized';
    if($set)
    {
      return "$field = NULL";
    }
    elsif($op eq 'IS' || $op eq 'IS NOT')
    {
      return ($not ? 'NOT(' : '') . "$field IS " .
             ($op eq 'IS NOT' ? 'NOT ' : '') . 'NULL' . ($not ? ')' : '');
    }
    else
    {
      return "$field IS " . (($not || $op eq '<>') ? 'NOT ' : '') . 'NULL';
    }
  }

  if($ref eq 'ARRAY')
  {
    if(!@$vals)
    {
      Carp::croak "Empty list not allowed for $field query parameter"
        unless($allow_empty_lists);
    }
    else
    {
      if($op eq '=')
      {
        my @new_vals;

        foreach my $val (@$vals)
        {
          my $should_inline = 
            ($db && $col_meta && $col_meta->should_inline_value($db, $val));

          if($should_inline || $force_inline)
          {
            push(@new_vals, $val);
          }
          elsif(ref $val eq 'SCALAR')
          {
            push(@new_vals, $$val);
          }
          else
          {
            if($bind)
            {
              if(defined $val)
              {
                push(@$bind, $val);
                push(@new_vals, $placeholder);

                if($bind_params)
                {
                  push(@$bind_params, $col_meta->dbi_bind_param_attrs($db));
                }
              }
              else
              {
                push(@new_vals, 'NULL');
              }
            }
            else
            {
              push(@new_vals, $dbh->quote($val));
            }
          }
        }

        return "$field " . ($not ? "$not " : '') . 'IN (' . join(', ', @new_vals) . ')';
      }
      elsif($op =~ /^(A(?:NY|LL)) IN (SET|ARRAY)$/)
      {
        my $sep = ($1 eq 'ANY') ? 'OR ' : 'AND ';
        my $field_sql = ($2 eq 'SET') ? "IN $field" : "= ANY($field)";

        if($bind)
        {
          return  ($not ? "$not " : '') . '(' . 
          join($sep, map
          {
            push(@$bind, $_);
            if($bind_params)
            {
              push(@$bind_params, $col_meta->dbi_bind_param_attrs($db));
            }
            "$placeholder $field_sql "
          }
          (ref $vals ? @$vals : ($vals))) . ')';
        }

        return  ($not ? "$not " : '') . '(' . 
        join($sep, map
        {
          $dbh->quote($_) . " $field_sql "
        }
        (ref $vals ? @$vals : ($vals))) . ')';
      }

      if($bind)
      {
        my @new_vals;

        foreach my $val (@$vals)
        {
          my $should_inline = 
            ($db && $col_meta && $col_meta->should_inline_value($db, $val));

          if($should_inline || $force_inline)
          {
            push(@new_vals, $val);
          }
          else
          {
            push(@$bind, $val);
            push(@new_vals, $placeholder);

            if($bind_params)
            {
              push(@$bind_params, $col_meta->dbi_bind_param_attrs($db));
            }
          }
        }

        return '(' . join(' OR ', map { ($not ? "$not(" : '') . "$field $op $_" .
                                        ($not ? ')' : '') } @new_vals) . ')';
      }

      return '(' . join(' OR ', map 
      {
        ($not ? "$not(" : '') . "$field $op " . 
        (($force_inline || ($db && $col_meta && $col_meta->should_inline_value($db, $_))) ? $_ : $dbh->quote($_)) .
        ($not ? ')' : '')
      }
      @$vals) . ')';
    }

    return;
  }
  elsif($ref eq 'HASH')
  {
    my($sub_op, $field_mod, @clauses);

    $field_mod = delete $vals->{'field'}  if(exists $vals->{'field'});

    my $all_in = ($op eq 'ALL IN SET' || $op eq 'ALL IN ARRAY') ? 1 : 0;
    my $any_in = ($op eq 'ANY IN SET' || $op eq 'ANY IN ARRAY') ? 1 : 0;

    foreach my $raw_op (keys(%$vals))
    {
      $sub_op = $OP_MAP{$raw_op} || Carp::croak "Unknown comparison operator: $raw_op";

      my $ref_type = ref($vals->{$raw_op});

      if(!$ref_type || $ref_type eq 'SCALAR')
      {
        push(@clauses, _build_clause($dbh, $field, $sub_op, $vals->{$raw_op}, $not, $field_mod, $bind, $db, $col_meta, $force_inline, $set, $placeholder, $bind_params));
      }
      elsif($ref_type eq 'ARRAY')
      {
        my $tmp_not = $all_in ? 0 : $not;

        foreach my $val (@{$vals->{$raw_op}})
        {
          push(@clauses, _build_clause($dbh, $field, $sub_op, $val, $tmp_not, $field_mod, $bind, $db, $col_meta, $force_inline, $set, $placeholder, $bind_params));
        }
      }
      else
      {
        Carp::croak "Don't know how to handle comparison operator '$raw_op' " .
                    ($col_meta ? ' for column ' . $col_meta->name : '') . 
                    ": $vals->{$raw_op}";
      }
    }

    if($all_in)
    {
      if($not)
      {
        return 'NOT(' . join(' AND ', @clauses) . ')';
      }
      else
      {
        return @clauses == 1 ? $clauses[0] : ('(' . join(' AND ', @clauses) . ')');
      }
    }
    elsif($any_in)
    {
      if($not)
      {
        return join(' AND ', @clauses);
      }
      else
      {
        return @clauses == 1 ? $clauses[0] : ('(' . join(' OR ', @clauses) . ')');
      }    
    }
    else
    {
      return @clauses == 1 ? $clauses[0] : ('(' . join(' OR ', @clauses) . ')');
    }
  }

  Carp::croak "Don't know how to handle comparison" .
              ($col_meta ? ' for column ' . $col_meta->name : '') . 
              ": $vals";
}

sub _build_nested_join
{
  my($joins, $nested, $i, $tables_sql, $db, $seen) = @_;

  $seen->[$i] = 1;

  if($nested->[$i] && @{$nested->[$i]})
  {
    my $join_sql;

    if($joins->[$i])
    {
      my $child_num = 0;

      $join_sql = "  $joins->[$i]{'type'} (";

      if($db)
      {
        $join_sql .=
          $db->format_table_with_alias($tables_sql->[$i - 1], "t$i", 
                                       $joins->[$i]{'hints'});
      }
      else
      {
        $join_sql .= "$tables_sql->[$i - 1] t$i";
      }

      foreach my $child_tn (@{$nested->[$i]})
      {
        $join_sql .= _build_nested_join($joins, $nested, $child_tn, $tables_sql, $db, $seen);
      }

      $join_sql .=  ") ON (" . join(' AND ', @{$joins->[$i]{'conditions'}}) . ")";
      return $join_sql;
    }
    else
    {
      foreach my $child_tn (@{$nested->[$i]})
      {
        $join_sql .= _build_nested_join($joins, $nested, $child_tn, $tables_sql, $db, $seen);
      }

      return $join_sql;
    }
  }
  else
  {
    if($db)
    {
      return  "  $joins->[$i]{'type'} " .
        $db->format_table_with_alias($tables_sql->[$i - 1], "t$i", 
                                     $joins->[$i]{'hints'}) .
        " ON (" . join(' AND ', @{$joins->[$i]{'conditions'}}) . ")";
    }
    else
    {
      return 
        "  $joins->[$i]{'type'} $tables_sql->[$i - 1] t$i ON (" .
        join(' AND ', @{$joins->[$i]{'conditions'}}) . ")";
    }
  }
}

sub _format_value
{
  my($db, $store, $param, $object, $col_meta, $get_method, $set_method, 
     $value, $asis, $depth, $allow_empty_lists) = @_;

  $depth ||= 1;

  my $val_ref = ref $value;

  if(!$val_ref || $asis)
  {
    unless(ref $store eq 'HASH' && $Op_Arg_PassThru{$param})
    {
      if($col_meta->manager_uses_method)
      {
        $object->$set_method($value);
        $value = $object->$get_method();
      }
      elsif(defined $value)
      {
        my $parsed_value = $col_meta->parse_value($db, $value);

        # XXX: Every column class should support parse_error(), but for now
        # XXX: the undef check should cover those that don't
        if(defined $value && !defined $parsed_value) #|| $col_meta->parse_error)
        {
          Carp::croak $col_meta->parse_error;
        }

        $value = $col_meta->format_value($db, $parsed_value)
          if(defined $value);
      }
    }
  }
  elsif($val_ref eq 'ARRAY')
  {
    Carp::croak "Empty list not allowed for $param query parameter"
      unless(@$value || $allow_empty_lists);

    if($asis || $col_meta->type eq 'array' ||
       ($col_meta->type eq 'set' && $depth == 1))
    {
      $value = _format_value($db, $value, undef, $object, $col_meta, $get_method, $set_method, $value, 1, $depth + 1, $allow_empty_lists);
    }
    elsif($col_meta->type ne 'set')
    {
      my @vals;

      foreach my $subval (@$value)
      {
        _format_value($db, \@vals, undef, $object, $col_meta, $get_method, $set_method, $subval, 0, $depth + 1, $allow_empty_lists);
      }

      $value = \@vals;
    }
  }
  elsif($val_ref eq 'HASH')
  {
    foreach my $key (keys %$value)
    {
      next  if($key =~ /_?sql$/); # skip inline values
      _format_value($db, $value, $key, $object, $col_meta, $get_method, $set_method, $value->{$key}, 0, $depth + 1, $allow_empty_lists);
    }
  }
  else
  {
    if($col_meta->manager_uses_method)
    {
      $object->$set_method($value);
      $value = $object->$get_method();
    }
    elsif(defined $value)
    {
      my $parsed_value = $col_meta->parse_value($db, $value);

      # XXX: Every column class should support parse_error(), but for now
      # XXX: the undef check should cover those that don't
      if(defined $value && !defined $parsed_value) #|| $col_meta->parse_error)
      {
        Carp::croak $col_meta->parse_error;
      }

      $value = $col_meta->format_value($db, $parsed_value)
        if(defined $value);
    }
  }

  if(ref $store eq 'HASH')
  {
    defined $param || die "Missing param argument for hashref storage";
    $store->{$param} = $value;
  }
  elsif(ref $store eq 'ARRAY')
  {
    push(@$store, $value);
  }
  else { die "Don't know how to store $value in $store" }

  return $value;
}

1;

__END__

=head1 NAME

perfSONAR_PS::DB::SQL::QueryBuilder - Build SQL queries based on DB engine type and supplied perl data structure, this was taken away from Rose::DB framework
                                  Original name of this packege is Rose::DB::Object::QueryBuilder

=head1 SYNOPSIS

    use perfSONAR_PS::DB::SQL::QueryBuilder qw(build_select);

    # Build simple query
    $sql = build_select
    ({
      dbh     => $dbh,
      select  => 'COUNT(*)',
      tables  => [ 'articles' ],
      columns => { articles => [ qw(id category type title date) ] },
      query   =>
      [
        category => [ 'sports', 'science' ],
        type     => 'news',
        title    => { like => [ '%million%', 
                                '%resident%' ] },
      ],
      query_is_sql => 1});

    $sth = $dbh->prepare($sql);
    $dbh->execute;
    $count = $sth->fetchrow_array;

    ...

    # Return query with placeholders, plus bind values
    ($sql, $bind) = build_select
    ({
      dbh     => $dbh,
      tables  => [ 'articles' ],
      columns => { articles => [ qw(id category type title date) ] },
      query   =>
      [
        category => [ 'sports', 'science' ],
        type     => 'news',
        title    => { like => [ '%million%', 
                                '%resident%' ] },
      ],
      query_is_sql => 1,
      sort_by      => 'title DESC, category',
      limit        => 5
      });

    $sth = $dbh->prepare($sql);
    $dbh->execute(@$bind);

    while($row = $sth->fetchrow_hashref) { ... }

    ...

    # Coerce query values into the right format
    ($sql, $bind) = build_select
    ({
     dbh     => $dbh,
     tables  => [ 'articles' ],
      columns => { articles => [ qw(id category type title date) ] },
      classes => { articles => 'Article' },
      query   =>
      [
        type     => 'news',
        date     => { lt => 'now' },
        date     => { gt => DateTime->new(...) },
      ],
      sort_by      => 'title DESC, category',
      limit        => 5
      });

    $sth = $dbh->prepare($sql);
    $dbh->execute(@$bind);

=head1 DESCRIPTION

C<perfSONAR_PS::DB::SQL::QueryBuilder> is used to build SQL queries.  It (optionally) exports two functions: C<build_select()> and C<build_where_clause()>.

=head1 FUNCTIONS

=over 4

=item B<build_select PARAMS>

Returns an SQL "select" query string (in scalar context) or an SQL "select" query string with placeholders
 and a reference to an array of bind values (in list context) constructed based on PARAMS.  Valid PARAMS are described below.

=over 4

=item B<clauses CLAUSES>

A reference to an array of extra SQL clauses to add to the "WHERE" portion of the query string.  This is the obligatory "escape hatch" for clauses that are not supported by arguments to the C<query> parameter.

=item B<columns HASHREF>

A reference to a hash keyed by table name, each of which points to a reference to an array of the names of the columns in that table.  Example:

    $sql = build_select({columns => 
                        {
                          table1 => [ 'col1', 'col2', ... ],
                          table2 => [ 'col1', 'col2', ... ],
                          ...
                        }
			});

This argument is required.


=item B<dbh DBH>

A C<DBI> database handle already connected to the correct database.  If this argument is omitted, an attempt will be made to extract a database handle from the C<db> argument.  If this fails, or if there is no C<db> argument, a fatal error will occur.

=item B<group_by CLAUSE>

A fully formed SQL "GROUP BY ..." clause, sans the words "GROUP BY", or a reference to an array of strings to be joined with a comma and appended to the "GROUP BY" clause.

=item B<limit NUMBER>

A number to use in the "LIMIT ..." clause.

=item B<logic LOGIC>

A string indicating the logic that will be used to join the statements in the WHERE clause.  Valid values for LOGIC are "AND" and "OR".  If omitted, it defaults to "AND".

=item B<pretty BOOL>

If true, the SQL returned will have slightly nicer formatting.


=item B<query PARAMS>

The query parameters, passed as a reference to an array of name/value pairs, scalar references, or array references.  PARAMS may include an arbitrary list of selection parameters used to modify the "WHERE" clause of the SQL select statement.  Any query parameter that is not in one of the forms described below will cause a fatal error.

Valid selection parameters are described below, along with the SQL clause they add to the select statement.

Simple equality:

    'NAME'  => "foo"        # COLUMN = 'foo'
    '!NAME' => "foo"        # NOT(COLUMN = 'foo')

    'NAME'  => [ "a", "b" ] # COLUMN IN ('a', 'b')
    '!NAME' => [ "a", "b" ] # COLUMN NOT(IN ('a', 'b'))

Is/is not null:

    'NAME'  => undef            # COLUMN IS NULL
    '!NAME' => undef            # COLUMN IS NOT NULL

    'NAME'  => { eq => undef }  # COLUMN IS NULL
    'NAME'  => { ne => undef }  # COLUMN IS NOT NULL

Comparisons:

    NAME => { OP => "foo" } # COLUMN OP 'foo'

    # (COLUMN OP 'foo' OR COLUMN OP 'goo')
    NAME => { OP => [ "foo", "goo" ] }

If a value is a reference to a scalar, that scalar is "inlined" without any quoting.

    'NAME' => \"foo"        # COLUMN = foo
    'NAME' => [ "a", \"b" ] # COLUMN IN ('a', b)

Undefined values are translated to the keyword NULL when included in a multi-value comparison.

    'NAME' => [ "a", undef ] # COLUMN IN ('a', NULL)

"OP" can be any of the following:

    OP                  SQL operator
    -------------       ------------
    similar             SIMILAR TO
    match               ~
    imatch              ~*
    regex, regexp       REGEXP
    like                LIKE
    ilike               ILIKE
    rlike               RLIKE
    is                  IS
    is_not              IS NOT
    ne                  <>
    eq                  =
    lt                  <
    gt                  >
    le                  <=
    ge                  >=

Set operations:

    ### Informix (default) ###

    # A IN COLUMN
    'NAME' => { in_set => 'A' } 

    # NOT(A IN COLUMN)
    '!NAME' => { in_set => 'A' } 

    # (A IN COLUMN OR B IN COLUMN)
    'NAME' => { in_set => [ 'A', 'B'] } 
    'NAME' => { any_in_set => [ 'A', 'B'] } 

    # NOT(A IN COLUMN) AND NOT(B IN COLUMN)
    '!NAME' => { in_set => [ 'A', 'B'] } 
    '!NAME' => { any_in_set => [ 'A', 'B'] } 

    # (A IN COLUMN AND B IN COLUMN)
    'NAME' => { all_in_set => [ 'A', 'B'] } 

    # NOT(A IN COLUMN AND B IN COLUMN)
    '!NAME' => { all_in_set => [ 'A', 'B'] } 

    ### MySQL (requires db parameter)  ###

    # FIND_IN_SET(A, COLUMN) > 0
    'NAME' => { in_set => 'A' } 

    # NOT(FIND_IN_SET(A, COLUMN) > 0)
    '!NAME' => { in_set => 'A' } 

    # (FIND_IN_SET(A, COLUMN) > 0 OR FIND_IN_SET(B, COLUMN) > 0)
    'NAME' => { in_set => [ 'A', 'B'] } 
    'NAME' => { any_in_set => [ 'A', 'B'] } 

    # NOT(FIND_IN_SET(A, COLUMN) > 0) AND NOT(FIND_IN_SET(B, COLUMN) > 0)
    '!NAME' => { in_set => [ 'A', 'B'] } 
    '!NAME' => { any_in_set => [ 'A', 'B'] } 

    # (FIND_IN_SET(A, COLUMN) > 0 AND FIND_IN_SET(B, COLUMN) > 0)
    'NAME' => { all_in_set => [ 'A', 'B'] } 

    # NOT(FIND_IN_SET(A, COLUMN) > 0 AND FIND_IN_SET(B, COLUMN) > 0)
    '!NAME' => { all_in_set => [ 'A', 'B'] } 

Array operations:

    # A = ANY(COLUMN)
    'NAME' => { in_array => 'A' } 

    # NOT(A = ANY(COLUMN))
    '!NAME' => { in_array => 'A' } 

    # (A = ANY(COLUMN) OR B = ANY(COLUMN))
    'NAME' => { in_array => [ 'A', 'B'] } 
    'NAME' => { any_in_array => [ 'A', 'B'] } 

    # NOT(A = ANY(COLUMN) OR B = ANY(COLUMN))
    '!NAME' => { in_array => [ 'A', 'B'] } 
    '!NAME' => { any_in_array => [ 'A', 'B'] } 

    # (A = ANY(COLUMN) AND B = ANY(COLUMN))
    'NAME' => { all_in_array => [ 'A', 'B'] } 

    # NOT(A = ANY(COLUMN) AND B = ANY(COLUMN))
    '!NAME' => { all_in_array => [ 'A', 'B'] } 

Any of these operations described above can have "_sql" appended to indicate that the corresponding values are to be "inlined" (i.e., included in the SQL query as-is, with no quoting of any kind).  This is useful for comparing two columns.  For example, this query:

    query => [ legs => { gt_sql => 'eyes' } ]

would produce this SQL:

    SELECT ... FROM animals WHERE legs > eyes

where "legs" and "eyes" are both left unquoted.

The same NAME string may be repeated multiple times.  (This is the primary reason that the query is a reference to an I<array> of name/value pairs, rather than a reference to a hash, which would only allow each NAME once.)  Example:

    query =>
    [
      age => { gt => 10 },
      age => { lt => 20 },
    ]

The string "NAME" can take many forms, each of which eventually resolves to a database column (COLUMN in the examples above).

Literal SQL can be included by providing a reference to a scalar:

    \'mycol > 123'

To use placeholders and bind values, pass a reference to an array containing a scalar reference to the literal SQL with placeholders as the first item, followed by a list of values to bind:

    [ \'mycol > ?' => 123 ]

=over 4

=item C<column>

A bare column name.  If the query includes more than one table, the column name may be ambiguous if it appears in two or more tables.  In that case, a fatal error will occur.  To solve this, use one of the less ambiguous forms below.

=item C<table.column>

A column name and a table name joined by a dot.  This is the "fully qualified" column name.

=item C<tN.column>

A column name and a table alias joined by a dot.  The table alias is in the form "tN", where "N" is a number starting from 1.  See the documentation for C<tables> parameter above to learn how table aliases are assigned to tables.

=item Any of the above prefixed with "!"

This indicates the negation of the specified condition.

=back

If C<query_is_sql> is false or omitted, then NAME can also take on these additional forms:

=over 4

 
=item C<!method>

This indicates the negation of the specified condition.

=back

Un-prefixed column or method names that are ambiguous (i.e., exist in more than one of the tables being queried) are considered to be part of the primary table ("t1").

Finally, in the case of apparently intractable ambiguity, like when a table name is the same as another table's alias, remember that you can always use the "tn_"-prefixed column name aliases, which are unique within a given query.

All of these clauses are joined by C<logic> (default: "AND") in the final query.  Example:

    $sql = build_select
    ( {
      dbh     => $dbh,
      select  => 'id, title',
      tables  => [ 'articles' ],
      columns => { articles => [ qw(id category type title) ] },
      query   =>
      [
        category => [ 'sports', 'science' ],
        type     => 'news',
        title    => { like => [ '%million%', 
                                '%resident%' ] },
      ],
      query_is_sql => 1
      });

The above returns an SQL statement something like this:

    SELECT id, title FROM articles WHERE
      category IN ('sports', 'science')
      AND
      type = 'news'
      AND
      (title LIKE '%million%' OR title LIKE '%resident%')
    LIMIT 5

Nested boolean logic is possible using the special keywords C<and> and C<or> (case insensitive).  Example:

    $sql = build_select
    ({
     
      dbh     => $dbh,
      select  => 'id, title',
      tables  => [ 'articles' ],
      columns => { articles => [ qw(id category type title) ] },
      query   =>
      [
        or =>
        [
          and => [ category => undef, type => 'aux' ],
          category => [ 'sports', 'science' ],
        ],
        type     => 'news',
        title    => { like => [ '%million%', 
                                '%resident%' ] },
      ],
      query_is_sql => 1
      });

which returns an SQL statement something like this:

    SELECT id, title FROM articles WHERE
      (
        (
          category IS NULL AND
          type = 'aux'
        ) 
        OR category IN ('sports', 'science')
      )
      AND
      type = 'news'
      AND
      (title LIKE '%million%' OR title LIKE '%resident%')

The C<and> and C<or> keywords can be used multiple times within a query (just like all other NAME specifiers described earlier) and can be arbitrarily nested.

If you have a column named "and" or "or", you'll have to use the fully-qualified (table.column) or alias-qualified (tN.column) forms in order to address that column.
 
 

Example:

    $dt = DateTime->new(year => 2001, month => 1, day => 31);

    $sql = build_select
    ({
      dbh      => $dbh,
      select  => 'id, category',
      tables  => [ 'articles' ],
      columns => { articles => [ qw(id category type date) ] },
      classes => { articles => 'Article' },
      query   =>
      [
        type  => 'news',
        date  => { lt => '12/25/2003 8pm' },
        date  => { gt => $dt },
      ],
      sort_by => 'id DESC, category',
      limit   => 5
      });

The above returns an SQL statement something like this:

    SELECT id, category FROM articles WHERE
      type = 'news'
      AND
      date < '2003-12-25 20:00:00'
      AND
      date > '2001-01-31 00:00:00'
    ORDER BY id DESC, category
    LIMIT 5

Finally, here's an example using more than one table:

    $dt = DateTime->new(year => 2001, month => 1, day => 31);

    $sql = build_select
    ({
      dbh      => $dbh,
      tables  => [ 'articles', 'categories' ],
      columns =>
      {
        articles   => [ qw(id name category_id date) ],
        categories => [ qw(id name description) ],
      },
   
      query   =>
      [
        '!t1.name' => { like => '%foo%' },
        t2.name    => 'news',
        date       => { lt => '12/25/2003 8pm' },
        date       => { gt => $dt },
      ],
      clauses =>
      [
        't1.category_id = t2.id',
      ],
      sort_by      => 'articles.name DESC, t2.name',
      limit        => 5
      });

The above returns an SQL statement something like this:

    SELECT
      t1.id,
      t1.name,
      t1.category_id,
      t1.date,
      t2.id,
      t2.name,
      t2.description
    FROM
      articles   t1,
      categories t2
    WHERE
      t1.category_id = t2.id
      AND
      NOT(t1.name LIKE '%foo%')
      AND
      t2.name = 'news'
      AND
      t1.date < '2003-12-25 20:00:00'
      AND
      t1.date > '2001-01-31 00:00:00'
    ORDER BY articles.name DESC, t2.name
    LIMIT 5

=item B<query_is_sql BOOL>

If omitted, this boolean flag is false.  If true, then the values of the C<query> parameters are taken as literal strings that are suitable for direct use in SQL queries.  Example:

    $sql = build_select
    (
      query_is_sql => 1,
      query =>
      [
        date => { lt => '2003-12-25 20:00:00' },
      ],
      ...
    );

Here the date value "2003-12-25 20:00:00" must be in the format that the current database expects for columns of that data type.
 

Here a L<DateTime> object and a loosely formatted date are passed as values.  
Provided the L<Rose::DB::Object>-derived object method that services the "date" column can handle such values, they will be parsed and formatted as appropriate for the current database.

The advantage of this approach is that the query values do not have to be so rigorously specified, nor do they have to be in a database-specific format.

The disadvantage is that all of this parsing and formatting is done for every query value, and that adds additional overhead to each call.

Usually, this overhead is dwarfed by the time required for the database to service the query, and, perhaps more importantly, the reduced maintenance headache and busywork required to properly format all query values.

=item B<select COLUMNS>

The names of the columns to select from the table.  COLUMNS may be a string of comma-separated column names, or a reference to an array of column names.  If this parameter is omitted, it defaults to all of the columns in all of the tables participating in the query (according to the value of the C<columns> argument).

=item B<sort_by [ CLAUSE | ARRAYREF ]>

A fully formed SQL "ORDER BY ..." clause, sans the words "ORDER BY", or a reference to an array of strings to be joined with a comma and appended to the "ORDER BY" clause.

If an item in the referenced array is itself a reference to a scalar, then that item will be dereferenced and passed through unmodified.

=item B<tables TABLES>

A reference to an array of table names.  This argument is required.  A fatal error will occur if it is omitted.

If more than one table is in the list, then each table is aliased to "tN", where N is an ascending number starting with 1.  The tables are numbered according to their order in TABLES.  Example:

    $sql = build_select(tables => [ 'foo', 'bar', 'baz' ], ...);

    print $sql;

    # SELECT ... FROM
    #   foo AS t1,
    #   bar AS t2,
    #   baz AS t3
    # ...

Furthermore, if there is no explicit value for the C<select> parameter and if the C<unique_aliases> parameter is set to true, then each selected column is aliased with a "tN_" prefix in a multi-table query.  Example:

    SELECT
      t1.id    AS t1_id,
      t1.name  AS t1_name,
      t2.id    AS t2_id,
      t2.name  AS t2_name
    FROM
      foo AS t1,
      bar AS t2
    WHERE
      ...

These unique aliases provide a technique of last resort for unambiguously addressing a column in a query clause.

=item C<unique_aliases BOOL>

If true, then each selected column will be given a unique alias by prefixing it with its table alias and an underscore.  The default value is false.  See the documentation for the C<tables> parameter above for an example.

=back

=item B<build_where_clause PARAMS>

This works the same as the C<build_select()> function, except that it only returns the "WHERE" clause of the SQL query, sans the word "WHERE" and prefixed with a single space.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com) - original author and maintaner of Rose::DB framework where this package is originated
Maxim Grigoriev, 2008,  maxim_at_fnal_dot_gov ( mods to detach from Rose::DB framework)

=head1 COPYRIGHT

Copyright (c) 2007 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
