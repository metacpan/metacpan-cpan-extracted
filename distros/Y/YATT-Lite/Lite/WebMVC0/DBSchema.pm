package YATT::Lite::WebMVC0::DBSchema; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use File::Basename;
use version;

use base qw/YATT::Lite::Object
	    YATT::Lite::Util::CmdLine
	  /;
use YATT::Lite::MFields
  (qw/_table_list _table_dict _dbtype
	       DBH
	       user
	       auth
	       connection_spec
	       connect_atstart
	       verbose
	       NULL
	       name
	       no_header
	       auto_create
	       coltype_map

	       after_dbinit
	       group_writable

	       is_clone
	       debug
	       on_destroy

	       _role_dict
	     /);

use YATT::Lite::Types
  ([Item => fields => [qw/_not_configured
			  name/]
    , [Table => fields => [qw/_pk _chk_unique
			      _chk_index _chk_check
			      _col_list _col_dict
			      _relation_list _relation_dict
			      _reference_dict
			      _initializer
			      view virtual
			      trigger_after_delete
			    /]]
    , [Column => fields => [qw/type
			       hidden
			       unique
			       indexed
			       primary_key
			       autoincrement

			       default
			       null

			       usage
			       label
			       max_length
			     /]]]
);

use YATT::Lite::Util qw/coalesce globref ckeval terse_dump lexpand
			shallow_copy
		       /;

#========================================
DESTROY {
  my MY $self = shift;
  if (my $sub = $self->{on_destroy}) {
    $sub->($self);
  }
  $self->disconnect("from DBSchema->DESTROY");
}
sub disconnect {
  (my MY $schema, my $msg) = @_;
  $msg ||= "";
  if (my $dbh = delete $schema->{DBH}) {
    # XXX: is_clone
    $dbh->commit unless $dbh->{AutoCommit};
    $dbh->disconnect;
    print STDERR "DEBUG: DBSchema->disconnect $msg $schema, had dbh $dbh\n"
      if $schema->{debug};
  } else {
    print STDERR "DEBUG: DBSchema->disconnect $msg $schema, without dbh\n"
      if $schema->{debug};
  }
}

#========================================

sub new {
  my $pack = shift;
  $pack->parse_import(\@_, \ my %opts);
  my MY $self = $pack->SUPER::new(%opts);
  $self->init_schema;
  $self->add_schema(@_) if @_;
  $self->verify_schema;
  $self;
}

sub clone {
  my MY $orig = shift;
  croak "Can't clone non-object: $orig" unless ref $orig;
  my MY $new = bless {}, ref($orig);
  foreach my $k (keys %$orig) {
    my $v = $orig->{$k};
    # shallow_copy with pass-thru flag.
    $new->{$k} = ref $v ? shallow_copy($v, 1) : $v;
  }
  $new->reset;
  $new->{is_clone} = 1;
  $new->configure(@_) if @_;
  print STDERR "DEBUG: dbschema clone, now=$new\n" if $new->{debug};
  $new;
}

sub reset {
  (my MY $self) = @_;
  if (my $dbh = delete $self->{DBH}) {
    $dbh->disconnect if $self->{is_clone};
  }
}

sub is_known_role {
  (my MY $self, my $class) = @_;
  $class //= caller;
  $self->{_role_dict}{$class}++;
}

# Extension hook.
sub init_schema {}

sub add_schema {
  (my MY $self) = shift;
  foreach my $item (@_) {
    if (ref $item) {
      $self->add_table(@$item);
    } else {
      croak "Invalid schema item: $item";
    }
  }
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

#########################################
sub after_connect {
  my MY $self = shift;
  $self->ensure_created_on($self->{DBH}) if $self->{auto_create};
}

sub dbinit_sqlite {
  (my MY $self, my $sqlite_fn) = @_;
  chmod 0664, $sqlite_fn if $self->{group_writable} // 1;
}

#========================================

sub startup {
  (my MY $schema, my (@apps)) = @_;
  foreach my $app (@apps) {
    # XXX: logging?
    my $sub = $app->can("backend_startup")
      or next;
    $sub->($app, $schema);
  }

  if ($schema->{connect_atstart}) {
    $schema->make_connection;
  }
}

#========================================

sub has_connection { my MY $schema = shift; $schema->{DBH} }

sub dbh {
  (my MY $schema) = @_;
  $schema->{DBH} // $schema->make_connection;
}

#
# Quasi-option to configure $when and @spec at once.
#
sub configure_connect {
  (my MY $schema, my $config) = @_;
  my ($when, @spec) = @$config;
  $schema->{connection_spec} = \@spec;
  $schema->{connect_atstart} = $schema->parse_connect_when($when);
}

sub parse_connect_when {
  (my MY $schema, my $when) = @_;
  if ($when =~ /^at_?start$/i) {
    1;
  } elsif ($when =~ /^on_?demand$/i) {
    0;
  } else {
    croak "Unknown connection timing: '$when'";
  }
}

sub configure_dbtype {
  (my MY $schema, my $value) = @_;
  $schema->{_dbtype} = $value;
}

#
# This must fill DBH.
#
sub make_connection {
  (my MY $schema) = shift;
  my ($spec) = @_ ? @_ : $schema->{connection_spec};
  unless (defined $spec) {
    croak "connection_spec is empty";
  }
  if (ref $spec eq 'ARRAY' or not ref $spec) {
    $schema->connect_to(lexpand($spec));
  } elsif (ref $spec eq 'CODE') {
    $spec->($schema);
  } else {
    croak "Unknown connection spec obj: $spec";
  }
  print STDERR "DEBUG: dbh for $schema=$schema->{DBH}"
    , ($schema->{debug} >= 2 ? Carp::longmess() : ()), "\n\n"
      if $schema->{debug};
  $schema->{DBH};
}

#----------------------------------------
sub connect_to {
  (my MY $schema, my ($dbtype, @args)) = @_;
  if ($dbtype =~ /^dbi:/i) {
    $schema->connect_to_dbi($dbtype, @args);
  } elsif (my $sub = $schema->can("connect_to_\L$dbtype")) {
    $schema->{_dbtype} = lc($dbtype);
    $sub->($schema, @args);
  } else {
    croak sprintf("%s: Unknown dbtype: %s", MY, $dbtype);
  }
}

sub dbtype_of_dbi_dsn {
  (my MY $schema, my $dbi) = @_;
  my ($driver) = $dbi =~ m{^dbi:([^:]+):}i
    or croak "Unknown driver spec in DBI DSN! $dbi";
  $driver;
}

sub connect_to_dbi {
  (my MY $schema, my ($dbi, @args)) = @_;
  my $driver = $schema->dbtype_of_dbi_dsn($dbi);
  $schema->{_dbtype} = lc($driver);
  if (my $sub = $schema->can("connect_to_\L$driver")) {
    $sub->($schema, $dbi, @args);
  } else {
    $schema->dbi_connect($dbi, @args);
  }
}

#----------------------------------------

sub connect_to_sqlite {
  (my MY $schema, my ($dsn_or_sqlite_fn, %opts)) = @_;
  require DBD::SQLite; my $minver = version->parse("1.30_02");

  my ($sqlite_fn, $dbi_dsn) = do {
    if ($dsn_or_sqlite_fn =~ /^dbi:SQLite:(?:dbname=)?(.*)$/i) {
      ($1, $dsn_or_sqlite_fn);
    } else {
      ($dsn_or_sqlite_fn, "dbi:SQLite:dbname=$dsn_or_sqlite_fn");
    }
  };
  unless (delete $opts{RO}) {
    $opts{sqlite_use_immediate_transaction} = 1
      if version->parse($DBD::SQLite::VERSION) >= $minver;
  }
  $schema->{_dbtype} //= 'sqlite';
  my $first_time = not -e $sqlite_fn;
  $schema->{auto_create} //= 1;
  $schema->dbi_connect($dbi_dsn, undef, undef, %opts);
  $schema->dbinit_sqlite($sqlite_fn) if $first_time;
  $schema;
}

sub dbi_connect {
  (my MY $schema, my ($dbi_dsn, $user, $auth, %attr)) = @_;
  my %default = $schema->default_dbi_attr;
  $attr{$_} //= $default{$_} for keys %default;
  require DBI;
  my $dbh = $schema->{DBH} = DBI->connect($dbi_dsn, $user, $auth, \%attr);
  $schema->after_connect;
  $schema;
}

sub default_dbi_attr {
  (RaiseError => 1, PrintError => 0, AutoCommit => 1);
}

#----------------------------------------

#
# ./lib/MyModel.pm create sqlite data/myapp.db3
#
sub create {
  (my MY $schema, my @spec) = @_;
  # $schema->dbh() will call ensure_created_on when auto_create is on.
  my $dbh = $schema->{DBH} || $schema->make_connection(\@spec);
  #
  $schema->ensure_created_on($dbh) unless $schema->{auto_create};
  $schema;
}

sub sql_schema {
  (my MY $schema) = @_;
  my @sql;
  foreach my Table $table ($schema->list_tables(raw => 1)) {
    foreach my $create ($schema->sql_create_table($table)) {
      push @sql, $create;
    }
  }
  foreach my Table $view ($schema->list_views(raw => 1)) {
    push @sql, "CREATE VIEW $view->{name}\nAS $view->{view}";
  }
  @sql;
}

sub ensure_created_on {
  (my MY $schema, my $dbh) = @_;
  # Carp::cluck("ensure_created is called");

  $schema->dbtype_try_invoke('begin_create');

  my (@sql, @created);
  foreach my Table $table ($schema->list_tables(raw => 1)) {
    next if $schema->has_table($table->{name}, $dbh);
    push @created, $table;
    foreach my $create ($schema->sql_create_table($table)) {
      unless ($schema->{verbose}) {
      } elsif ($schema->{verbose} >= 2) {
	print STDERR "-- $table->{name} --\n$create\n\n"
      } elsif ($schema->{verbose} and $create =~ /^create table /i) {
	print STDERR "CREATE TABLE $table->{name}\n";
      }
      push @sql, $create;
    }
  }
  foreach my Table $view ($schema->list_views(raw => 1)) {
    next if $schema->has_view($view->{name}, $dbh);
    next if $view->{virtual};
    if ($schema->{verbose}) {
      print STDERR "CREATE VIEW $view->{name}\n";
    }
    push @sql, "CREATE VIEW $view->{name}\nAS $view->{view}";
  }
  $dbh->do($_) for @sql;
  if (@created) {
    foreach my Table $tab (@created) {
      $schema->ensure_table_populated($dbh, $tab);
    }
  }
  if (@sql) {
    $dbh->commit unless $dbh->{AutoCommit};
  }
  @created;
}

sub ensure_table_populated {
  (my MY $schema, my $dbh, my Table $tab) = @_;
  foreach my $init (lexpand($tab->{_initializer})) {
    my ($colSpec, @values) = @$init;
    my $sql = $schema->sql_to_insert($tab->{name}, @$colSpec);
    my $ins = $dbh->prepare($sql);
    foreach my $record (@values) {
      if (grep {ref $_ eq 'SCALAR'} @$record) {
	my ($sql, $values) = $schema->sql_and_values_to_insert_expr
	  ($tab->{name}, $colSpec, $record);
	my @vals = $schema->expand_codevalue($tab, $values);
	print STDERR $sql, "\n -- (", join(",", @vals), ")\n"
	  if $schema->{verbose};
	$dbh->do($sql, undef, @vals);
      } else {
	my @vals = $schema->expand_codevalue($tab, $record);
	print STDERR $sql, "\n -- (", join(",", @vals), ")\n"
	  if $schema->{verbose};
	$ins->execute(@vals);
      }
    }
  }
}

sub sqlite_begin_create {
  (my MY $schema) = @_;
  # To speedup create statements.
  my $dbh = $schema->dbh;
  if ($dbh->{AutoCommit}) {
    $dbh->do("PRAGMA synchronous = OFF");
  }
}

sub expand_codevalue {
  (my MY $schema, my $tab, my $record) = @_;
  map {ref $_ ? $_->($schema, $tab) : $_} @$record;
}

sub has_table { shift->has_type(table => @_); }
sub has_view  { shift->has_type(view => @_); }

sub has_type {
  (my MY $schema, my ($type, $table, $dbh)) = @_;
  if ($$schema{_dbtype}
      and my $sub = $schema->can("$$schema{_dbtype}_has_type")) {
    $sub->($schema, $type, $table, $dbh);
  } else {
    $dbh ||= $schema->dbh;
    $dbh->tables("", "", $table, uc($type));
  }
}

sub dbtype_try_invoke {
  (my MY $schema, my ($method, @args)) = @_;
  return unless $schema->{_dbtype};
  my $sub = $schema->can("$schema->{_dbtype}_$method")
    or return;
  $sub->($schema, @args);
}

sub sqlite_has_type {
  (my MY $schema, my ($type, $name, $dbh)) = @_;
  my ($found) = $dbh->selectrow_array(<<'END', undef, $type, $name)
select name from sqlite_master where type = ? and name = ?
END

    or return undef;
  $found;
}

sub tables {
  my MY $schema = shift;
  keys %{$schema->{_table_dict}};
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

sub _list_items {
  (my MY $self, my $opts) = splice @_, 0, 2;
  $opts->{raw} ? @_ : map {
    my Item $item = $_;
    $item->{name}
  } @_;
}

sub list_tables {
  (my MY $self, my %opts) = @_;
  $self->_list_items(\%opts, grep {
    my Table $tab = $_;
    not $tab->{view}
  } @{$self->{_table_list}});
}

sub list_views {
  (my MY $self, my %opts) = @_;
  $self->_list_items(\%opts, grep {
    my Table $tab = $_;
    $tab->{view}
  } @{$self->{_table_list}});
}

sub list_relations {
  (my MY $self, my ($tabName, %opts)) = @_;
  my Table $tab = $self->{_table_dict}{$tabName}
    or return;
  if ($opts{raw}) {
    @{$tab->{_relation_list}}
  } else {
    map {
      (my ($relType, $relName, $fkName), my Table $subTab) = @$_;
      $fkName //= do {
	if (my Column $pk = $self->get_table_pk($subTab)
	    || $self->get_table_pk($tab)) {
	  $pk->{name};
	}
      };
      [$relType, $relName, $fkName, $subTab->{name}];
    } @{$tab->{_relation_list}};
  }
}

sub list_table_columns {
  (my MY $self, my ($tabName, %opts)) = @_;
  my Table $tab = $self->{_table_dict}{$tabName}
    or return;
  $self->_list_items(\%opts, @{$tab->{_col_list}});
}

sub get_table {
  (my MY $self, my $name) = @_;
  $self->{_table_dict}{$name} //= do {
    push @{$self->{_table_list}}
      , my Table $tab = $self->Table->new(name => $name);
    $tab->{_not_configured} = 1;
    $tab;
  };
}

sub get_table_pk {
  (my MY $self, my ($tabName, %opts)) = @_;
  my Table $tab = ref $tabName ? $tabName : $self->{_table_dict}{$tabName};
  my $pkinfo = $tab->{_pk};
  return unless $pkinfo;
  if (wantarray) {
    $self->_list_items(\%opts, ref $pkinfo eq 'ARRAY' ? @$pkinfo : $pkinfo);
  } else {
    ref $pkinfo eq 'ARRAY' ? $pkinfo->[0] : $pkinfo
  }
}

sub add_table {
  my MY $self = shift;
  my ($name, $opts, @colpairs) = @_;
  my Table $tab = $self->get_table($name);
  return $tab if @_ == 1;
  if ($tab and not $tab->{_not_configured}) {
    croak "Duplicate definition of table $name";
  }
  delete $tab->{_not_configured};
  $self->extend_table(@_);
}

sub extend_table {
  my MY $self = shift;
  my ($name, $opts, @colpairs) = @_;
  my Table $tab = $self->get_table($name);
  $tab->configure(lhexpand($opts)) if $opts;
  while (@colpairs) {
    # colName => [colSpec]
    # [check => args]
    unless (ref $colpairs[0]) {
      my ($col, $desc) = splice @colpairs, 0, 2;
      $self->add_table_column($tab, $col, ref $desc ? @$desc : $desc);
    } else {
      my ($method, @args) = @{shift @colpairs};
      $method =~ s/^-//;
      # XXX: [has_many => @tables]
      if (my ($relType, @relSpec) = $self->known_rels($method, undef, @args)) {
	$self->add_table_relation($tab, undef, $relType => \@relSpec, @args);
      } else {
	my $sub = $self->can("add_table_\L$method")
	  or croak "Unknown table option '$method' for table $name";
	$sub->($self, $tab, @args);
      }
    }
  }

  $tab;
}

sub add_table_primary_key {
  (my MY $self, my Table $tab, my @args) = @_;
  if ($tab->{_pk} and @args) {
    croak "Duplicate PK definition. old $tab->{_pk}";
  }
  $tab->{_pk} = [map {$tab->{_col_dict}{$_}} @args];
}

sub add_table_unique {
  (my MY $self, my Table $tab, my @cols) = @_;
  # XXX: 重複検査, 有無検査
  push @{$tab->{_chk_unique}}, [@cols];
}

sub add_table_index {
  (my MY $self, my Table $tab, my @cols) = @_;
  # XXX: 重複検査, 有無検査
  push @{$tab->{_chk_index}}, [@cols];
}

# -opt は引数無フラグ、又は [-opt, ...] として可変長オプションに使う
sub add_table_relation {
  (my MY $self, my Table $tab, my Column $fkCol
   , my ($relType, $relSpec, $item, $fkName, $atts)) = @_;
  unless (defined $item) {
    croak "Undefined relation spec for table $tab->{name}";
  }

  #
  # [-has_many => 'table.key']
  #
  $fkName = $1 if not ref $item and $item =~ s/\.(\w+)$//;

  my Table $subTab = ref $item ? $self->add_table(@$item)
    : $self->get_table($item);
  my $relName = $relSpec->[0] // lc($subTab->{name});
  $fkName //= $relSpec->[1] // $fkCol->{name}
    // $subTab->{_reference_dict}{$tab->{name}};
  if ($tab->{_relation_dict}{$relName}) {
    croak "Conflicting relation! $tab->{name}.$relName";
  }
  push @{$tab->{_relation_list}}
    , $tab->{_relation_dict}{$relName}
      = [$relType => $relName, $fkName, $subTab];
}

sub add_table_column {
  (my MY $self, my Table $tab, my ($colName, $type, @colSpec)) = @_;
  if ($tab->{_col_dict}{$colName}) {
    croak "Conflicting column name $colName for table $tab->{name}";
  }
  # $tab.$colName is encoded by $refTab.pk
  if (ref $type) {
    croak "Deprecated column spec in $tab->{name}.$colName";
  } elsif (not defined $type) {
    Carp::cluck "Column type $tab->{name}.$colName is undef";
  }

  my (@opt, @rels);
  while (@colSpec) {
    unless (defined (my $key = shift @colSpec)) {
      croak "Undefined colum spec for $tab->{name}.$colName";
    } elsif (ref $key) {
      my ($method, @args) = @$key;
      $method =~ s/^-//;
      # XXX: [has_many => @tables]
      # XXX: [unique => k1, k2..]
      if (my ($relType, @relSpec)
	  = $self->known_rels($method, $colName, @args)) {
	push @rels, [$relType => \@relSpec, @args];
      } else {
	croak "Unknown method $method";
      }
    } elsif ($key =~ /^-/) {
      push @opt, $key => 1;
    } else {
      push @opt, $key, shift @colSpec;
    }
  }
  push @{$tab->{_col_list}}, ($tab->{_col_dict}{$colName})
    = (my Column $col) = $self->Column->new
      (@opt, name => $colName, type => $type);
  $tab->{_pk} = $col if $col->{primary_key};

  $self->add_table_relation($tab, $col, @$_) for @rels;

  # XXX: Validation: name/option conflicts and others.
  $col;
}

sub add_table_values {
  (my MY $self, my Table $tab, my ($colspec, @values)) = @_;
  push @{$tab->{_initializer}}, [$colspec, @values];
}

sub verify_schema {
  (my MY $self) = @_;
  my @not_configured;
  foreach my Table $tab (lexpand($self->{_table_list})) {
    if ($tab->{_not_configured}) {
      push @not_configured, $tab->{name};
      next;
    }
    # foreach my Column $col (lexpand($tab->{_col_list})) { }
  }
  if (@not_configured) {
    croak "Some tables are not configure, possibly spellmiss!: @not_configured";
  }
}

{
  my %known_rels = qw(has_many 1 has_one 1 belongs_to 1
		      many_to_many 1 might_have 1
		    );
  sub known_rels {
    (my MY $self, my ($desc, $myColName, @args)) = @_;
    # ['-has_many:rel:fk' => 'table']
    # has_many   ..fk is their_fk
    # belongs_to ..fk is our_fk
    my ($relType, $relName, $fkName) = split /:/, $desc, 3;
    return unless $known_rels{$relType};
    ($relType, $relName, $fkName || $myColName)
  }
}

#========================================

sub sql_create {
  (my MY $schema, my %opts) = @_;
  $schema->foreach_tables_do('sql_create_table', \%opts)
}

sub default_dbtype {'sqlite'}
sub sql_create_table {
  (my MY $schema, my Table $tab, my $opts) = @_;
  my (@cols, @indices);
  my $dbtype = $opts->{_dbtype} || $schema->{_dbtype} || $schema->default_dbtype;
  my $sub = $schema->can($dbtype.'_sql_create_column')
    || $schema->can('sql_create_column');

  my $pk_ok;
  foreach my Column $col (@{$tab->{_col_list}}) {
    $pk_ok = 1 if $col->{primary_key};
    push @cols, $sub->($schema, $tab, $col, $opts);
    push @indices, $col if $col->{indexed};
  }

  # Multi column primary key(...)
  # XXX: conflict clause
  if (not $pk_ok and $tab->{_pk}) {
    push @cols, "PRIMARY KEY(".join(", ", map {
      my Column $col = $_;
      $col->{name}
    } @{$tab->{_pk}}).")";
  }

  # Other unique(...)
  foreach my $constraint (lexpand($tab->{_chk_unique})) {
    push @cols, sprintf q{unique(%s)}, join(", ", @$constraint);
  }

  # XXX: SQLite specific.
  # XXX: MySQL ENGINE(TYPE) = ...
  push my @create
    , sprintf qq{CREATE TABLE %s\n(%s)}, $tab->{name}
      , join "\n, ", @cols;

  foreach my Column $ix (@indices) {
    push @create
      , sprintf q{CREATE INDEX %1$s_%2$s on %1$s(%2$s)}
	, $tab->{name}, $ix->{name};
  }

  foreach my $colnames (lexpand($tab->{_chk_index})) {
    my $ixname = join "_", $tab->{name}, @$colnames;
    push @create, sprintf(q{CREATE INDEX %s on %s(%s)}
			  , $tab->{name}
			  , join("_", $tab->{name}, @$colnames)
			  , join(",", @$colnames));
  }

  # after delete on user for each row begin
  if (my $trigger = $tab->{trigger_after_delete}) {
    push @create, map {
      qq{CREATE TRIGGER $_ AFTER DELETE ON $tab->{name}}
	. qq{ FOR EACH ROW } . $schema->sql_compound_trigger($trigger->{$_});
    } keys %$trigger;
  }

  wantarray ? @create : join(";\n", @create);
}

# XXX: text => varchar(80)
sub map_coltype {
  (my MY $schema, my $typeName) = @_;
  $schema->{coltype_map}{$typeName} // $typeName;
}

sub sql_create_column {
  (my MY $schema, my Table $tab, my Column $col, my $opts) = @_;
  # XXX: primary key ASC/DESC
  join(" ", $col->{name}
       , $schema->map_coltype($col->{type})
       , ($col->{primary_key} ? "primary key" : ())
       , ($col->{unique} ? "unique" : ())
       , ($col->{autoincrement} ? "auto_increment" : ()));
}

sub sqlite_sql_create_column {
  (my MY $schema, my Table $tab, my Column $col, my $opts) = @_;
  unless (defined $col->{type}) {
    croak "Column type is not yet defined! $tab->{name}.$col->{name}"
  } elsif ($col->{type} =~ /^int/i && $col->{primary_key}) {
    "$col->{name} integer primary key"
  } else {
    $schema->sql_create_column($tab, $col, $opts);
  }
}

sub sql_compound_trigger {
  (my MY $schema, my $item) = @_;
  my $sub = $schema->can($$schema{_dbtype}.'_sql_compound_trigger')
    or croak "Compound trigger for $$schema{_dbtype} is not yet implemented";
  $sub->($schema, $item);
}

sub mysql_sql_compound_trigger {
  (my MY $schema, my $item) = @_;
  unless (ref $item) {
    $item
  } elsif (@$item == 1) {
    $item->[0]
  } else {
    "BEGIN ".join("; ", @$item). "; END";
  }
}

sub sqlite_sql_compound_trigger {
  (my MY $schema, my $item) = @_;
  "BEGIN ".join("; ", ref $item ? @$item : $item). "; END";
}

sub sql_drop {
  shift->foreach_tables_do
    (sub {
       (my Table $tab) = @_;
       qq{drop table $tab->{name}};
     })
}

sub foreach_tables_do {
  (my MY $self, my $method, my $opts) = @_;
  my $code = ref $method ? $method : sub {
    $self->$method(@_);
  };
  my @result;
  my $wantarray = wantarray;
  foreach my Table $tab (@{$self->{_table_list}}) {
    push @result, map {
      $wantarray ? $_ . "\n" : $_
    } $code->($tab, $opts);
   }
  wantarray ? @result : join(";\n", @result);
}

########################################
# Below is poorman's CRUD closure generator(instead of ORM).


sub to_encode {
  (my MY $self, my $tabName, my $keyCol, my @otherCols) = @_;

  my $to_find = $self->to_find($tabName, $keyCol);
  my $to_ins = $self->to_insert($tabName, $keyCol, @otherCols);

  sub {
    my ($value, @rest) = @_;
    $to_find->($value) || $to_ins->($value, @rest);
  };
}

# to_fetchall は別途用意する
sub to_find {
  (my MY $self, my ($tabName, $keyCol, $rowidCol)) = @_;
  my $sql = $self->sql_to_find($tabName, $keyCol, $rowidCol);
  print STDERR "-- $sql\n" if $self->{verbose};
  my $sth;
  sub {
    my ($value) = @_;
    $sth ||= $self->dbh->prepare($sql);
    $sth->execute($value);
    my ($rowid) = $sth->fetchrow_array
      or return;
    $rowid;
  };
}

sub to_fetch {
  (my MY $self, my ($tabName, $keyColList, $resColList, @rest)) = @_;
  my $sql = $self->sql_to_fetch($tabName, $keyColList, $resColList, @rest);
  print STDERR "-- $sql\n" if $self->{verbose};
  my $sth;
  sub {
    my (@value) = @_;
    $sth ||= $self->dbh->prepare($sql);
    $sth->execute(@value);
    $sth;
  };
}

sub to_insert {
  (my MY $self, my ($tabName, @fields)) = @_;
  my $sql = $self->sql_to_insert($tabName, @fields);
  print STDERR "-- $sql\n" if $self->{verbose};
  my $sth;
  sub {
    my (@value) = @_;
    $sth ||= $self->dbh->prepare($sql);
    # print STDERR "-- inserting @value to $sql\n";
    $sth->execute(@value);
    $self->dbh->last_insert_id('', '', '', '');
  };
}

sub sql_to_find {
  (my MY $self, my ($tabName, $keyCol, $rowidCol)) = @_;
  my Table $tab = $self->{_table_dict}{$tabName}
    or croak "No such table: $tabName";
  # XXX: col name check.
  $rowidCol ||= $self->rowid_col($tab);
  <<END;
select $rowidCol from $tabName where $keyCol = ?
END
}

sub sql_to_fetch {
  (my MY $self, my ($tabName, $keyColList, $resColList, %opts)) = @_;
  my $group_by = delete $opts{group_by};
  my $order_by = delete $opts{order_by};
  my Table $tab = $self->{_table_dict}{$tabName}
    or croak "No such table: $tabName";
  # XXX: col name check... いや、式かもしれないし。
  my $cols = $resColList ? join(", ", lexpand $resColList) : '*';
  my $where = do {
    unless (defined $keyColList) {
      undef;
    } elsif (not ref $keyColList) {
      "$keyColList = ?"
    } elsif (ref $keyColList eq 'ARRAY') {
      join " AND ", map {"$_ = ?"} @$keyColList
    } elsif (ref $keyColList eq 'SCALAR') {
      # RAW SQL
      $$keyColList;
    } else {
      die "Not yet implemented!";
    }
  };
  if ($group_by) {
    $where .= " GROUP BY $group_by";
  }
  if ($order_by) {
    $where .= " ORDER BY $order_by";
  }
  qq|select $cols from $tabName| . (defined $where ? " where $where" : "");
}


sub sql_to_insert {
  (my MY $self, my ($tabName, @fields)) = @_;
  sprintf qq{INSERT INTO $tabName(%s) VALUES(%s)}
    , join(", ", @fields)
      , join(", ", map {'?'} @fields);
}

sub sql_and_values_to_insert_expr {
  (my MY $self, my ($tabName, $colNames, $valsOrExprs)) = @_;
  my (@values);
  my @exprs = map {
    if (ref $_) {
      $$_;
    } else {
      push @values, $_;
      '?'
    }
  } @$valsOrExprs;
  my $sql = sprintf qq{INSERT INTO $tabName(%s) VALUES(%s)}
    , join(", ", @$colNames), join(", ", @exprs);

  ($sql, \@values);
}


sub default_rowid_col { 'rowid' }
sub rowid_col {
  (my MY $schema, my Table $tab) = @_;
  if (my Column $pk = $tab->{_pk}) {
    $pk->{name}
  } else {
    # XXX: dbtype dispatch
    $schema->default_rowid_col;
  }
}

########################################

sub add_inc {
  my ($pack, $callpack) = @_;
  $callpack =~ s{::}{/}g;
  $INC{$callpack . '.pm'} = 1;
}

########################################

use YATT::Lite::XHF::Dumper;

sub cmd_deploy {
  (my MY $schema) = @_;
  local $schema->{verbose} = 1;
  my $dbh = $schema->dbh;
  local $dbh->{AutoCommit};
  $schema->ensure_created_on($dbh);
  $dbh->commit;
}

sub cmd_schema {
  (my MY $schema) = @_;
  print $schema->dump_xhf(map {
    $schema->info_tableobj($_);
  } @{$schema->{_table_list}}), "\n";
}

sub info_tableobj {
  (my MY $schema, my Table $tab) = @_;
  [$tab->{name}, undef, map {
    $schema->info_columnobj($_);
   } @{$tab->{_col_list}}];
}

sub info_columnobj {
  (my MY $schema, my Column $col) = @_;
  ($col->{name}, $col->{type});
}

sub cmd_help {
  my ($self) = @_;
  my $pack = ref($self) || $self;
  my @opts = do {
    if (my $sub = $pack->can('cf_list')) {
      $sub->($pack);
    } else {
      ();
    }
  };
  require YATT::Lite::Util::FindMethods;
  my @methods = YATT::Lite::Util::FindMethods::FindMethods
    ($pack, , sub {s/^cmd_//});
  die <<END;
Usage: @{[basename($0)]} [--opt=value] <command> [--opt=value] [<args>]

Available commands are:
  @{[join("\n  ", @methods)]}

All options(might not usefull) are:
  @{[join "\n  ", map {"--$_"} @opts]}
END

}

#========================================

sub ymd_hms {
  my ($pack, $time, $as_utc) = @_;
  my ($S, $M, $H, $d, $m, $y) = map {
    $as_utc ? gmtime($_) : localtime($_)
  } $time;
  sprintf q{%04d-%02d-%02d %02d:%02d:%02d}, 1900+$y, $m+1, $d, $H, $M, $S;
}

sub lhexpand {
  return unless defined $_[0];
  ref $_[0] eq 'HASH' ? %{$_[0]}
    : ref $_[0] eq 'ARRAY' ? @{$_[0]}
      : croak "Invalid option: $_[0]";
}

use YATT::Lite::Breakpoint ();
YATT::Lite::Breakpoint::break_load_dbschema();

1;
