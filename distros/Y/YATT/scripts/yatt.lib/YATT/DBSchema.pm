package YATT::DBSchema;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

use File::Basename;
use YATT::Util::CmdLine;

use base qw(YATT::Class::Configurable);
use YATT::Fields (qw(schemas tables cf_DBH
		     cf_user
		     cf_auth
		     ^cf_connection_spec
		     ^cf_verbose
		   )
		  , ['^cf_dbtype' => 'sqlite']
		  , ['^cf_NULL' => '']
		  , ['^cf_name' => 'DBSchema']
		  , qw(
			cf_no_header
			cf_auto_create
			cf_as_base
		     )
		 );

use YATT::Types [Item => [qw(cf_name)]];

use YATT::Types -base => Item
  , [Table => [qw(pk raw_create chk_unique chk_index chk_check colNames)]
     , [Column => [qw(colnum
		      cf_type
		      cf_hidden
		      cf_unique
		      cf_indexed
		      cf_decode_depth
		      cf_encoded_by
		      cf_updated
		      cf_primary_key
		      cf_auto_increment
		    )]]];
use YATT::Util::Symbol;
use YATT::Util qw(coalesce);
require YATT::Inc;

#----------------------------------------

sub YATT::DBSchema::Table::rowid_spec {
  (my Table $tab, my $schema) = @_;
  if (my Column $pk = $tab->{pk}) {
    $pk->{cf_name}
  } else {
    $schema->rowid_col;
  }
}

sub rowid_col { 'rowid' }

#========================================
# Class Hierarchy in case of 'package YourSchema; use YATT::DBSchema':
#
#   YATT::DBSchema (or its subclass)
#    ↑
#   YourSchema::DBSchema  (holds singleton $SCHEMA and &SCHEMA)
#    ↑
#   YourSchema
#

sub import {
  my ($pack) = shift;
  return unless @_;
  my MY $schema = $pack->define(@_);

  $schema->export_and_rebless_with(caller);
}

sub export_and_rebless_with {
  (my MY $schema, my ($callpack)) = @_;

  # Allocate new class.
  my $classFullName = join("::", $callpack, $schema->name);
  YATT::Inc->add_inc($classFullName);
  eval sprintf q{use strict; package %s; use base qw(%s)}
    , $classFullName, ref $schema;
  # MY->add_isa($classFullName, $pack);
  eval qq{use strict; package $callpack; use base qw($classFullName)}
    if $schema->{cf_as_base};
  # MY->add_isa($callpack, $classFullName);

  my $glob = globref($classFullName, "SCHEMA");
  *{$glob} = \ $schema;
  define_const($glob, $schema);

  $schema->export_to($callpack);

  $schema->rebless_with($callpack)
    if $schema->{cf_as_base};
}

sub export_to {
  (my MY $schema, my ($callpack)) = @_;
  # Install to caller
  define_const(globref($callpack, $schema->name), $schema);
  # XXX: special new for singleton. (for schema->new->run)
  *{globref($callpack, 'new')} = sub {
    shift;
    $schema->configure(@_) if @_;
    $schema;
  };
}

#========================================
sub DESTROY {
  my MY $schema = shift;
  if ($schema->{cf_DBH}) {
    # XXX: sqlite specific commit.
    $schema->{cf_DBH}->commit;
  }
}

#========================================

sub define {
  my ($pack) = shift;
  $pack->parse_import(\@_, \ my %opts);
  my MY $self = $pack->new(%opts);
  foreach my $item (@_) {
    if (ref $item) {
      $self->add_table(@$item);
    } else {
      croak "Invalid schema item: $item";
    }
  }
  $self;
}

sub parse_import {
  my ($pack, $list, $opts) = @_;
  # -bool_flag
  # key => value
  for (; @$list; shift @$list) {
    last if ref $list->[0];
    if ($list->[0] =~ /^-(\w+)/) {
      $opts->{$1} = 1;
    } else {
      croak "Option value is missing for $list->[0]"
	unless @$list >= 2;
      $opts->{$list->[0]} = $list->[1];
      shift @$list;
    }
  }
}

#========================================

sub has_connection {
  my MY $schema = shift;
  $schema->{cf_DBH}
}

sub dbh {
  (my MY $schema, my $spec) = @_;
  unless ($schema->{cf_DBH}) {
    unless (defined ($spec ||= $schema->connection_spec)) {
      croak "connection_spec is empty";
    }
    if (ref $spec eq 'ARRAY') {
      $schema->connect_to(@$spec);
    } elsif (ref $spec eq 'CODE') {
      $schema->{cf_DBH} = $spec->($schema);
    } else {
      croak "Unknown connection spec obj: $spec";
    }
  };

  $schema->{cf_DBH}
}

sub connect_to {
  (my MY $schema, my ($dbtype)) = splice @_, 0, 2;
  if (my $sub = $schema->can("connect_to_$dbtype")) {
    $sub->($schema, @_);
  } else {
    croak sprintf("%s: Unknown dbtype: %s", MY, $dbtype);
  }
}

sub connect_to_sqlite {
  (my MY $schema, my ($dbname, $rwflag)) = @_;
  my $ro = defined $rwflag && $rwflag =~ /ro/i;
  my $dbi_dsn = "dbi:SQLite:dbname=$dbname";
  $schema->{cf_auto_create} = 1;
  $schema->connect_to_dbi
    ($dbi_dsn, undef, undef
     , RaiseError => 1, PrintError => 0, AutoCommit => $ro);
}

sub connect_to_dbi {
  (my MY $schema, my ($dbi_dsn, $user, $auth, %param)) = @_;
  map {$param{$$_[0]} = $$_[1] unless defined $param{$$_[0]}}
    ([RaiseError => 1], [PrintError => 0], [AutoCommit => 0]);
  require DBI;
  if ($dbi_dsn =~ m{^dbi:(\w+):}) {
    $schema->configure(dbtype => lc($1));
  }
  my $dbh = $schema->{cf_DBH} = DBI->connect($dbi_dsn, $user, $auth, \%param);
  $schema->create if $schema->{cf_auto_create};
  $dbh;
}

#
# ./lib/MyApp.pm create sqlite data/myapp.db3
#
sub create {
  (my MY $schema, my @spec) = @_;
  my $dbh = $schema->dbh(@spec ? \@spec : ());
  foreach my Table $table (@{$schema->{schemas}}) {
    next if $schema->has_table($table->{cf_name}, $dbh);
    foreach my $create ($schema->sql_create_table($table)) {
      print STDERR "$create\n" if $schema->{cf_verbose};
      $dbh->do($create);
    }
  }
}

sub has_table {
  (my MY $schema, my ($table, $dbh)) = @_;
  $dbh ||= $schema->dbh;
  $dbh->tables("", "", $table, 'TABLE');
}

sub tables {
  my MY $schema = shift;
  keys %{$schema->{tables}};
}

sub has_column {
  (my MY $schema, my ($table, $column, $dbh)) = @_;
  my $hash = $schema->columns_hash($table, $dbh || $schema->dbh);
  exists $hash->{$column};
}

sub columns_hash {
  (my MY $schema, my ($table, $dbh)) = @_;
  $dbh ||= $schema->dbh;
  my $sth = $dbh->prepare("select * from $table limit 0");
  $sth->execute;
  my %hash = %{$sth->{NAME_hash}};
  \%hash;
}

sub drop {
  (my MY $schema) = @_;
  foreach my $sql ($schema->sql_drop) {
    $schema->dbh->do($sql);
  }
}

#========================================

sub add_table {
  (my MY $self, my ($name, $opts, @columns)) = @_;
  $self->{tables}{$name} ||= do {
    push @{$self->{schemas}}
      , my Table $tab = $self->Table->new;

    $tab->{cf_name} = $name;
    if (@columns) {
      # XXX: 拡張の余地あり
      $tab->{raw_create} = $opts;
      my $fields = $tab->fields_hash;
      foreach my $desc (@columns) {
	if (ref (my $kw = $desc->[0])) {
	  unless ($fields->{my $fname = "chk_$$kw"}) {
	    croak "Invalid column constraint $kw for table $name";
	  } else {
	    push @{$tab->{$fname}}, [@{$desc}[1 .. $#$desc]];
	  }
	} else {
	  my ($col, $type, @desc) = @$desc;
	  $self->add_table_column($tab, $col, $type, map {
	    if (/^-(\w+)/) {
	      $1 => 1
	    } else {
	      $_
	    }
	  } @desc);
	}
      }
    } elsif (not ref $opts) {
      # $opts is used as column type.
      # XXX: SQLite specific.
      $self->add_table_column($tab, $name . 'no', 'integer'
			      , primary_key => 1);
      $self->add_table_column($tab, $name, $opts
			      , unique => 1);
    } else {
      die "Unknown table desc $name $opts";
    }
    $tab;
  };
}

sub add_table_column {
  (my MY $self, my Table $tab, my ($colName, $type, @opts)) = @_;
  if ($tab->{colNames}{$colName}) {
    croak "Conflicting column name $colName for table $tab->{cf_name}";
  }
  push @{$tab->{Column}}, my Column $col = $self->Column->new(@opts);
  $tab->{colNames}{$colName} = $col->{colnum} = @{$tab->{Column}};

  $col->{cf_hidden} = ($colName =~ s/^-//
		      || $col->{cf_auto_increment});
  $col->{cf_name} = $colName;
  # if ref $type, else
  $col->{cf_type} = do {
    if (ref $type) {
      $col->{cf_encoded_by} = $self->add_table(@$type);
      # XXX: SQLite specific.
      'int'
    } else {
      $type
    }
  };
  if ($col->{cf_primary_key}) {
    $tab->{pk} = $col;
  }
  # XXX: Validation: name/option conflicts and others.
  $col;
}

#========================================

sub sql_create {
  (my MY $schema, my %opts) = @_;
  $schema->foreach_tables_do('sql_create_table', \%opts)
}

sub sql_create_table {
  (my MY $schema, my Table $tab, my $opts) = @_;
  my (@cols, @indices);
  my $dbtype = $opts->{dbtype} || $schema->dbtype;
  my $sub = $schema->can($dbtype.'_sql_create_column')
    || $schema->can('sql_create_column');
  foreach my Column $col (@{$tab->{Column}}) {
    push @cols, $sub->($schema, $tab, $col, $opts);
    push @indices, $col if $col->{cf_indexed};
  }
  foreach my $constraint (map {$_ ? @$_ : ()} $tab->{chk_unique}) {
    push @cols, sprintf q{unique(%s)}, join(", ", @$constraint);
  }

  # XXX: SQLite specific.
  push my @create
    , sprintf qq{CREATE TABLE %s\n(%s)}, $tab->{cf_name}
      , join "\n, ", @cols;

  foreach my Column $ix (@indices) {
    push @create
      , sprintf q{CREATE INDEX %1$s_%2$s on %1$s(%2$s)}
	, $tab->{cf_name}, $ix->{cf_name};
  }

  # insert が有っても、構わない。
  push @create, map {$_ ? @$_ : ()} $tab->{raw_create};

  wantarray ? @create : join(";\n", @create);
}

# XXX: text => varchar(80)
sub map_coltype {
  (my MY $schema, my $typeName) = @_;
}

sub sql_create_column {
  (my MY $schema, my Table $tab, my Column $col, my $opts) = @_;
  join(" ", $col->{cf_name}
       , $col->{cf_type}
       , ($col->{cf_primary_key} ? "primary key" : ())
       , ($col->{cf_unique} ? "unique" : ())
       , ($col->{cf_auto_increment} ? "auto_increment" : ()));
}

sub sqlite_sql_create_column {
  (my MY $schema, my Table $tab, my Column $col, my $opts) = @_;
  if ($col->{cf_type} =~ /^int/i && $col->{cf_primary_key}) {
    "$col->{cf_name} integer primary key"
  } else {
    $schema->sql_create_column($tab, $col, $opts);
  }
}

sub sql_drop {
  shift->foreach_tables_do
    (sub {
       (my Table $tab) = @_;
       qq{drop table $tab->{cf_name}};
     })
}

sub foreach_tables_do {
  (my MY $self, my $method, my $opts) = @_;
  my $code = ref $method ? $method : sub {
    $self->$method(@_);
  };
  my @result;
  my $wantarray = wantarray;
  foreach my Table $tab (@{$self->{schemas}}) {
    push @result, map {
      $wantarray ? $_ . "\n" : $_
    } $code->($tab, $opts);
   }
  wantarray ? @result : join(";\n", @result);
}

#========================================

sub sql_insert {
  (my MY $schema, my ($tabName, @fields)) = @_;
  my Table $tab = $schema->{tables}{$tabName}
    or croak "No such table: $tabName";
  my (@insNames, @insEncs);
  foreach my Column $col (@fields ? (map {
    unless (my $colno = $tab->{colNames}{$_}) {
      die "No such column $_ in $tabName\n";
    } else {
      $tab->{Column}[$colno - 1];
    }
  } @fields) : @{$tab->{Column}}) {
    push @insNames, $col->{cf_name} unless $col->{cf_hidden};
    if (my Table $encTab = $col->{cf_encoded_by}) {
      push @insEncs, [$#insNames => $encTab->{cf_name}];
    }
  }

  my $sql = <<END;
INSERT INTO $tabName(@{[join ", ", @insNames]})
values(@{[join ", ", map {q|?|} @insNames]})
END

  wantarray ? ($sql, @insEncs) : $sql;
}

sub to_insert {
  (my MY $schema, my ($tabName, $fields)) = @_;
  my $dbh = $schema->dbh;
  my ($sql, @insEncs) = $schema->sql_insert
    ($tabName, do {
      unless ($fields) {
	()
      } elsif (ref $fields) {
	@$fields
      } else {
	$fields
      }
    });
  print STDERR "$sql\n" if $schema->{cf_verbose};
  my $sth = $dbh->prepare($sql);
  # ここで encode 用の sql/sth も生成せよと?
  my @encoder;
  foreach my $item (@insEncs) {
    my ($i, $table) = @$item;
    push @encoder, [$schema->to_encode($table, $dbh), $i];
  }
  my $rowid = $schema->{tables}{$tabName}->rowid_spec($schema);
  sub {
    my (@values) = @_;
    foreach my $enc (@encoder) {
      $enc->[0]->(\@values, $enc->[1]);
    }
    $sth->execute(@values);
    $dbh->last_insert_id(undef, undef, $tabName, $rowid);
  }
}

sub to_encode {
  (my MY $schema, my ($encDesc, $dbh)) = @_;
  $dbh ||= $schema->dbh;
  my ($table, $column) = ref $encDesc ? @$encDesc : ($encDesc, $encDesc);
  my Table $tab = $schema->{tables}{$table};
  my $rowid = $tab->rowid_spec($schema);
  my $check_sql = <<END;
select $rowid from $table where $column = ?
END
  print STDERR "$check_sql\n" if $schema->{cf_verbose};

  my $ins_sql = <<END;
INSERT INTO $table($column) values(?)
END
  print STDERR "$ins_sql\n" if $schema->{cf_verbose};

  # XXX: sth にまでするべきか。prepare_cached 廃止案。
  sub {
    my ($list, $nth) = @_;
    my ($rowid) = do {
      my $check = $dbh->prepare_cached($check_sql);
      $dbh->selectrow_array($check, {}, $list->[$nth]);
    };
    unless (defined $rowid) {
      my $ins = $dbh->prepare_cached($ins_sql, undef, 1);
      $ins->execute($list->[$nth]);
      $rowid = $dbh->last_insert_id(undef, undef, $table, $rowid);
    }
    $list->[$nth] = $rowid;
  }
}

#========================================

sub sql {
  (my MY $self, my ($mode, $table)) = splice @_, 0, 3;
  unshift @_, $self->parse_params(\@_);
  $self->can("sql_${mode}")->($self, $table, @_);
}

# XXX: explain を。 cf_explain で？
sub cmd_select {
  my MY $self = shift;
  $self->parse_opts(\@_, \ my %opts);
  my $table = shift;
  $self->parse_opts(\@_, \ %opts);
  $self->configure(%opts) if %opts;
  $self->parse_params(\@_, \ my %param);
  my ($sth, $bind) = do {
    if (my $sub = $self->can("select_$table")) {
      # XXX: select_zzz は execute してはいけない
      $sub->($self, \%param, @_);
    } elsif ($sub = $self->can("sql_select_$table")) {
      $self->dbh->prepare($sub->($self, \%param));
    } else {
      $self->prepare_select($table, \@_, %param);
    }
  };
  $sth->execute($bind ? @$bind : @_);
  my $null = $self->NULL;
  my $format = $self->can('tsv_with_null');
  print $format->($null, @{$sth->{NAME}}) unless $self->{cf_no_header};
  while (my (@res) = $sth->fetchrow_array) {
    print $format->($null, @res);
  }
}

sub select {
  (my MY $schema, my ($tabName, $columns, %param)) = @_;

  my $is_text = delete $param{text};
  my $separator = delete $param{separator} || "\t";
  ($is_text, $separator) = (1, "\t") if delete $param{tsv};

  my (@fetch) = grep {delete $param{$_}} qw(hashref arrayref array);
  die "Conflict! @fetch" if @fetch > 1;

  my ($sth, $bind) = $schema->prepare_select($tabName, $columns, %param);

  if ($is_text) {
    # Debugging aid.
    my $null = $schema->NULL;
    my $header; $header = $schema->format_line($sth->{NAME}, $separator, $null)
      if $schema->{cf_no_header};
    my $res = $sth->fetchall_arrayref
      or return;
    join("", defined $header ? $header : ()
	 , map { $schema->format_line($_, $separator, $null) } @$res)
  } else {
    my $method = $fetch[0] || 'arrayref';
    $sth->execute($bind ? @$bind : ());
    $sth->can("fetchrow_$method")->($sth);
  }
}

# XXX: to_selectrow/selectall に分ければいいかも？
sub to_select {
  (my MY $schema, my ($tabName, $columns, %params)) = @_;
  my $type = do {
    my (@fetch) = grep {delete $params{$_}} qw(hashref arrayref array);
    die "Conflict! @fetch" if @fetch > 1;
    $fetch[0] || 'arrayref';
  };
  my ($sth, $bind) = $schema->prepare_select($tabName, $columns, %params);
  my $sub = sub {
    $sth->execute($bind ? @$bind : @_);
    my $method = wantarray ? "fetchall_$type" : "fetchrow_$type";
    $sth->$method;
  };
  wantarray ? ($sub, ($bind ? $bind : ())) : $sub;
}

# 後は fetchrow するだけ、の sth を返す。
sub to_fetch {
  (my MY $schema, my ($tabName, $columns, %params)) = @_;
  my ($sth, $bind) = $schema->prepare_select($tabName, $columns, %params);
  $sth->execute($bind ? @$bind : ());
  $sth;
}

# $sth 返しなのは、$sth->{NAME} を取りたいから。でも、単純なケースでは不便よね。
sub prepare_select {
  (my MY $schema, my ($tabName, $columns, %params)) = @_;
  my ($sql, $bind) = $schema->sql_select($tabName, \%params
					 , ref $columns ? @$columns : $columns);
  my $sth = $schema->dbh->prepare($sql);
  wantarray ? ($sth, ($bind ? $bind : ())) : $sth;
}

sub sql_decode {
  (my MY $schema, my Table $tab
   , my ($selJoins, $depth, $alias, $until)) = @_;
  $depth = 0 unless defined $depth;
  $alias ||= $tab->{cf_name};
  my @selCols;
  foreach my Column $col (@{$tab->{Column}}) {
    my Table $enc = $col->{cf_encoded_by};
    if ($depth || $enc) {
      # primary key は既に積まれている。
      push @selCols, "$alias.$col->{cf_name}"
	unless $col->{cf_primary_key};
    } else {
      push @selCols, $col->{cf_name};
    }

    if ($enc && $depth < coalesce($until, 1)) {
      # alias と rowid と…
      my $enc_alias = $col->{cf_name};
      push @$selJoins, "\nLEFT JOIN $enc->{cf_name} $enc_alias"
	. " on $alias.$col->{cf_name}"
	  . " = $enc_alias." . $enc->rowid_spec($schema);

      push @selCols, $schema->sql_decode
	($enc, $selJoins, $depth + 1, $col->{cf_name}
	 , $col->{cf_decode_depth});
    }
  }
  @selCols;
}

sub sql_join {
  (my MY $schema, my ($tabName, $params)) = @_;

  if (my $sub = $schema->can("sql_select_$tabName")) {
    return $sub->($schema, $params);
  }

  my Table $tab = $schema->{tables}{$tabName}
    or croak "No such table: $tabName";

  my @selJoins = $tab->{cf_name};
  my @selCols  = $schema->sql_decode($tab, \@selJoins);

  my (@appendix, @bind);
  if (my $where = delete $params->{where}) {
    push @appendix, do {
      if (ref $where) {
	require SQL::Abstract;
	(my $stmt, @bind) = SQL::Abstract->new->where($where);
	$stmt;
      } else {
	$where;
      }
    };
  }

  {
    if ($params->{offset} and not $params->{limit}) {
      die "offset needs limit!";
    }

    foreach my $kw (qw(group_by order_by limit offset)) {
      if (my $val = delete $params->{$kw}) {
	push @appendix, join(" ", map(do {s/_/ /; $_}, uc($kw)), $val);
      }
    }

    die "Unknown param(s) for select $tabName: "
      , join(", ", map {"$_=" . $params->{$_}} keys %$params) if %$params;
  }

  (\@selCols, \@selJoins, \@appendix, @bind ? \@bind : ());
}

sub sql_select {
  (my MY $schema, my ($tabName, $params)) = splice @_, 0, 3;

  my $raw = delete $params->{raw};
  my $colExpr = do {
    if (@_) {
      join(", ", @_);
    } elsif ($raw) {
      '*';
    }
  };

  my ($selCols, $selJoins, $where, $bind)
    = $schema->sql_join($tabName, $params);

  my $sql = join("\n", sprintf(q{SELECT %s FROM %s}
			       , $colExpr || join(", ", @$selCols)
			       , $raw ? $tabName : join("", @$selJoins))
		 , @$where);

  wantarray ? ($sql, (defined $bind ? $bind : ())) : $sql;
}

#----------------------------------------

sub indexed {
  (my MY $schema, my ($tabName, $colName, $value, $params)) = @_;
  my $dbh = delete $params->{dbh} || $schema->dbh;
  my $sql = $schema->sql_indexed($tabName, $colName);
  $dbh->selectrow_hashref($sql, undef, $value);
}

sub sql_indexed {
  (my MY $schema, my ($tabName, $colName)) = @_;
  <<"END";
select _rowid_, * from $tabName where $colName = ?
END
}

sub format_line {
  (my MY $schema, my ($rec, $separator, $null)) = @_;
  join($separator, map {
    unless (defined $_) {
      $null
    } elsif ((my $val = $_) =~ s/[\t\n]/ /g) {
      $val
    } else {
      $_
    }
  } @$rec). "\n";
}

#========================================

sub to_update {
  (my MY $schema, my ($tabName, $colName)) = @_;
  my $sql = $schema->sql_update($tabName, $colName);
  print STDERR "$sql\n" if $schema->{cf_verbose};
  my $sth = $schema->dbh->prepare($sql);
  sub {
    my ($colValue, $rowId) = @_;
    $sth->execute($colValue, $rowId);
  }
}

sub sql_update {
  (my MY $schema, my ($tabName, $colName)) = @_;
  my $rowid = $schema->{tables}{$tabName}->rowid_spec($schema);
  "UPDATE $tabName SET $colName = ? WHERE $rowid = ?";
}

########################################

sub tsv_with_null {
  my $null = shift;
  join("\t", map {defined $_ ? $_ : $null} @_). "\n";
}


########################################

sub run {
  my $pack = shift;
  $pack->cmd_help unless @_;
  my MY $obj = $pack->new(MY->parse_opts(\@_));
  my $cmd = shift || "help";
  $obj->configure(MY->parse_opts(\@_));
  my $method = "cmd_$cmd";
  if (my $sub = $obj->can("cmd_$cmd")) {
    $sub->($obj, @_);
  } elsif ($sub = $obj->can($cmd)) {
    my @res = $sub->($obj, @_);
    exit 1 unless @res;
    unless (@res == 1 and defined $res[0] and $res[0] eq "1") {
      if (grep {defined $_ && ref $_} @res) {
	require Data::Dumper;
	print Data::Dumper->new([$_])->Indent(0)->Terse(1)->Dump
	  , "\n" for @res;
      } else {
	print join("\n", @res), "\n";
      }
    }
  } else {
    die "No such method $cmd for $pack\n";
  }
  $obj->DESTROY; # To make sure committed.
}

sub cmd_help {
  my ($self) = @_;
  my $pack = ref($self) || $self;
  my $stash = do {
    my $pkg = $pack . '::';
    no strict 'refs';
    \%{$pkg};
  };
  my @methods = sort grep s/^cmd_//, keys %$stash;
  die "Usage: @{[basename($0)]} method args..\n  "
    . join("\n  ", @methods) . "\n";
}

#========================================

sub ymd_hms {
  my ($pack, $time, $as_utc) = @_;
  my ($S, $M, $H, $d, $m, $y) = map {
    $as_utc ? gmtime($_) : localtime($_)
  } $time;
  sprintf q{%04d-%02d-%02d %02d:%02d:%02d}, 1900+$y, $m+1, $d, $H, $M, $S;
}

1;
# -for_dbic
# -for_sqlengine
# -for_sqlt

