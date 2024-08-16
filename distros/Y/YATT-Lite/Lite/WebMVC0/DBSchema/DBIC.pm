package YATT::Lite::WebMVC0::DBSchema::DBIC; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

use base qw(YATT::Lite::WebMVC0::DBSchema);
use fields qw(DBIC cf_DBIC);

use YATT::Lite::Util::AsBase qw/_import_as_base/;

use Scalar::Util qw/weaken/;
require DBIx::Class::Core;

sub DBIC_SCHEMA {'YATT::Lite::WebMVC0::DBSchema::DBIC::DBIC_SCHEMA'}

use YATT::Lite::Types
  ([Table => -fields => [qw(cf_package cf_components)]]
   , [Column => -fields => [qw(cf_dbic_opts)]]
  );

use YATT::Lite::Util qw(globref define_const lexpand terse_dump);

sub dbic {
  (my MY $schema) = @_;
  $schema->{DBIC} //= do {
      if ($schema->{cf_debug}) {
	print STDERR "INFO: DBSchema($schema) DBIC->connect"
	  , ", class = $schema->{cf_DBIC}\n";
      }
      weaken($schema); # !! This is very important to avoid memleak!
      $schema->{cf_DBIC}->connect(sub {$schema->make_connection});
    };
}

sub connect {
  my MY $schema = ref $_[0] ? shift->clone : shift->new;
  $schema->{DBIC} = $schema->{cf_DBIC}->connect(@_);
  if ($schema->{cf_debug}) {
    print STDERR "INFO: DBSchema($schema)::connect"
      ,", class = $schema->{cf_DBIC}\n";
  }
  $schema;
}

sub disconnect {
  (my MY $schema, my ($msg)) = @_;
  $schema->reset;
  $schema->SUPER::disconnect($msg);
}

sub reset {
  (my MY $self) = @_;
  $self->SUPER::reset;
  delete $self->{DBIC};
}

sub txn_do {
  (my MY $schema, my $sub) = splice @_, 0, 2;
  $schema->dbic->txn_do($sub, @_ ? @_ : $schema->{DBIC});
}

sub startup {
  (my MY $schema, my (@apps)) = @_;
  unless ($schema->{cf_DBIC}) {
    croak "DBIC classname parameter is empty!";
  }
  unless ($schema->{cf_DBIC} =~ /::/) {
    croak "DBIC classname MUST has '::'! $schema->{cf_DBIC}";
  }
  $schema->SUPER::startup(@apps);
  $schema->build_dbic($schema->{cf_DBIC});
  if (my (@args) = $schema->{cf_DBH}
      || lexpand($schema->{cf_connection_spec})) {
    $schema->connect(@args);
  }
}

sub default_dbi_attr {
  (shift->SUPER::default_dbi_attr, AutoCommit => 1);
}

sub import {
  YATT::Lite::Util::AsBase::parse_args(\@_, scalar caller);
  return unless @_ >= 2;
  goto &build_dbic;
}

# use YATT::Lite::WebMVC0::DBSchema::DBIC $pkg => @desc;
#
# $pkg                 ISA DBIC_SCHEMA (ISA DBIx::Class::Schema)
# ${pkg}::Result::$tab ISA DBIx::Class::Core

# XXX: Make sure build_dbic is callable many times.
sub build_dbic {
  my ($class_or_obj, $DBIC) = splice @_, 0, 2;
  (my $myPkg, my MY $schema) = do {
    if (ref $class_or_obj) {
      (ref $class_or_obj, $class_or_obj);
    } else {
      ($class_or_obj, $class_or_obj->new(@_));
    }
  };

  $DBIC //= caller() . '::DBIC';
  {
    my $sym = globref($DBIC, undef);
    unless (*{$sym}{CODE}) {
      define_const($sym, $DBIC);
    }
  }

  # DBIC->YATT_DBSchema holds YATT::Lite::WebMVC0::DBSchema::DBIC instance.
  {
    my $sym = globref($DBIC, 'YATT_DBSchema');
    unless (*{$sym}{CODE}) {
      *$sym = sub {
	my $dbic = shift;
	print STDERR "DEBUG: DBIC->YATT_DBSchema is called\n"
	  if $schema->{cf_debug};
	# Class method として呼んだときは, schema に set しない。
	$schema->{DBIC} ||= $dbic
	  if defined $dbic and ref $dbic; # XXX: weaken??
	$schema;
      };
    }
  }
  $schema->{cf_DBIC} = $DBIC;

  *{globref($DBIC, 'ISA')} = [$myPkg->DBIC_SCHEMA];
  $myPkg->add_inc($DBIC);

  foreach my Table $tab (@{$schema->{table_list}}) {
    # XXX: 正確には rowClass よね、これって。
    # XXX: じゃぁ ResultSet の方は作らなくてよいのか?
    my $tabClass = $tab->{cf_package}
      = join('::', $DBIC, Result => $tab->{cf_name});
    *{globref($tabClass, 'ISA')} = ['DBIx::Class::Core'];
    $myPkg->add_inc($tabClass);

    my Column $pk;
    my @comp = (qw/Core/, lexpand($tab->{cf_components}));

    if ($tab->{cf_view}) {
      $tabClass->load_components(@comp);
      $tabClass->table_class('DBIx::Class::ResultSource::View');
      # ------------- (order is important!) ----------------
      $tabClass->table($tab->{cf_name});
      $tabClass->result_source_instance->view_definition($tab->{cf_view});
      $tabClass->result_source_instance->is_virtual($tab->{cf_virtual} ? 1 : 0);
    } else {
      $pk = $schema->get_table_pk($tab);
      push @comp, qw(PK::Auto) if $pk and $pk->{cf_autoincrement};
      $tabClass->load_components(@comp);
      $tabClass->table($tab->{cf_name});
    }

    my @constraints = lexpand($tab->{chk_unique});
    {
      my @colSpecs;
      foreach my Column $col (@{$tab->{col_list}}) {
	# dbic_opts;
	my %dbic_opts = (data_type => $col->{cf_type}
                         , ($col->{cf_autoincrement} ? (is_auto_increment => 1) : ())
			 , map(defined $_ ? %$_ : (), $col->{cf_dbic_opts}));
	push @colSpecs, $col->{cf_name} => \%dbic_opts;
	push @constraints, [$col->{cf_name}] if $col->{cf_unique};
      }
      $tabClass->add_columns(@colSpecs);
    }
    $tabClass->set_primary_key($schema->get_table_pk($tab)) if $pk;
    foreach my $uniq (@constraints) {
      my $ixname = join("_", $tabClass, @$uniq);
      print STDERR <<END if $schema->{cf_verbose};
-- $tabClass->add_unique_constraint($ixname, [@{[join ", ", @$uniq]}])
END
      $tabClass->add_unique_constraint($ixname, $uniq);
    }
  }
  # Relationship の設定と、 register_class の呼び出し。
  foreach my Table $tab (@{$schema->{table_list}}) {
    my $tabClass = $tab->{cf_package};
    foreach my $rel ($schema->list_relations($tab->{cf_name})) {
      my ($relType, @relOpts) = @$rel;
      if (my $sub = $myPkg->can("add_relation_$relType")) {
	$sub->($myPkg, $schema, $tab, @relOpts);
	next;
      }

      my ($relName, $fkName, $fTabName) = @relOpts;
      unless (defined $fTabName) {
	croak "Foreign table is empty for $tab->{cf_name} $relType $relName $fkName";
      }
      my $fTab = $schema->{table_dict}{$fTabName};
      # table の package 名が確定するまで、relation の設定を遅延させたいから。
      print STDERR <<END if $schema->{cf_verbose};
-- $tabClass->$relType($relName, $fTab->{cf_package}, @{[terse_dump($fkName)]})
END
      eval {
	$tabClass->$relType($relName, $fTab->{cf_package}, $fkName);
      };
      if ($@) {
	die "Relationship Error in: $relType $relName, foreign="
	  .$fTab->{cf_package}.": $@";
      }
    }
    # register_class は Relationship 設定が済んでからじゃないとダメ?
    $DBIC->register_class($tab->{cf_name}, $tabClass);
  }

  $schema;
}

# XXX: 上と被っているので、まとめるべし。
sub add_relation_many_to_many {
  (my $myPkg, my MY $schema, my Table $tab
   , my ($relName, $fkName, $tabName)) = @_;
  my $relType = 'many_to_many';
  my $tabClass = $tab->{cf_package};
  print STDERR <<END if $schema->{cf_verbose};
-- $tabClass->$relType($relName, $tabName, @{[terse_dump($fkName)]})
END
  eval {
    $tabClass->$relType($relName, $tabName, $fkName)
  };
  if ($@) {
    die "Relationship Error in: $relType ($relName, $tabName, $fkName)".$@;
  }
}

*deploy = *ensure_created; *deploy = *ensure_created;
sub ensure_created {
  (my MY $self, my $dbic) = @_;
  $dbic ||= $self->{DBIC};
  $dbic->storage->dbh_do
    (sub {
       (my ($storage, $dbh), my MY $self) = @_;
       $self->ensure_created_on($dbh);
     }, $self)
}

# XXX: delegate は、やりすぎだったかもしれない。
sub add_delegate {
  my ($pack) = shift;
  my ($alias, $dbic_method) = do {
    if (@_ == 2) {
      @_;
    } else {
      ($_[0], $_[0]);
    }
  };
  *{globref($pack, $alias)} = sub {
    my MY $self = shift;
    $self->dbic->$dbic_method(@_);
  };
}

foreach my $name (keys %DBIx::Class::Schema::) {
  next unless $name =~ /^[a-z]\w*$/;
  next unless *{$DBIx::Class::Schema::{$name}}{CODE};
  next if MY->can($name);
  MY->add_delegate($name);
}

MY->add_delegate(model => 'resultset');

{
  package YATT::Lite::WebMVC0::DBSchema::DBIC::DBIC_SCHEMA;
  use base qw(DBIx::Class::Schema);
  use Carp;
  # XXX: Should this hold (weakened) ref to DBSchema?

  # Aid to migrate from YATT_DBSchema->to_zzz methods.
  sub to_find {
    my ($dbic, $tabName, $keyCol, $rowidCol) = @_;
    my $rs = $dbic->resultset($tabName);
    my $dbh = $dbic->storage->dbh;
    unless (defined $keyCol) {
      sub { $rs->find(@_) }
    } elsif (ref $keyCol eq 'ARRAY') {
      my (@sql, @cols, @atts);
      foreach (@$keyCol) {
	push @atts, $_ and next if ref $_ eq 'HASH';
	push @sql, do {
	  if (ref $_) {
	    my ($col, @comp) = @$_;
	    unless (@comp) {
	      push @cols, $col;
	      $col . ' = ?';
	    } elsif (@comp == 1) {
	      $dbh->quote_identifier($col) . ' = ' . $dbh->quote($comp[0]);
	    } elsif (@comp % 2 == 0) {
	      my @sql = $dbh->quote_identifier($col);
	      while (my ($kw, $value) = splice @comp, 0, 2) {
		push @sql, $kw, $dbh->quote($value);
	      }
	      join " ", @sql;
	    } else {
	      croak "Invalid column spec: $col, @comp";
	    }
	  } elsif (/\?/) {
	    my ($col) = /^(\w+)/
	      or croak "Can't extract colname from colspec: $_";
	    push @cols, $col;
	    $_;
	  } else {
	    push @cols, $_;
	    $dbh->quote_identifier($_) . ' = ?';
	  }
	}
      }
      my $sql = join " AND ", @sql;
      sub {
	my (@value) = @_;
	unless (@value == @cols) {
	  croak "bind param length mismatch for $sql!(@{[scalar @value]})";
	}
	my $row = $rs->search(\ [$sql, zip(\@cols, \@value)], @atts)->single
	  or return undef;
	$row->id;
      };
    } elsif (not defined $rowidCol) {
      sub {
	my ($value) = @_;
	my $row = $rs->find({$keyCol => $value})
	  or return undef;
	$row->id;
      };
    } else {
      sub {
	my ($value) = @_;
	my $row = $rs->find({$keyCol => $value})
	  or return undef;
	$row->get_column($rowidCol);
      };
    }
  }

  sub to_insert {
    my ($dbic, $tabName, @fields) = @_;
    my $rs = $dbic->resultset($tabName);
    unless (my ($pkCol, @morePkCol) = $rs->result_source->primary_columns) {
      # If primary key is not defined, row obj is returned.
      $dbic->to_insert_obj($tabName, @fields);
    } elsif (@morePkCol) {
      croak "table '$tabName' has multiple pk col, use to_insert_obj() please!";
    } else {
      sub {
	my %rec;
	@rec{@fields} = @_;
	my $row = $rs->new(\%rec)->insert;
	$row->get_column($pkCol);
      }
    }
  }

  # This returns row object, not primary key.
  sub to_insert_obj {
    my ($dbic, $tabName, @fields) = @_;
    my $rs = $dbic->resultset($tabName);
    sub {
      my %rec;
      @rec{@fields} = @_;
      $rs->new(\%rec)->insert;
    };
  }

  sub to_encode {
    my ($dbic, $tabName, $keyCol, @otherCols) = @_;
    my $to_find = $dbic->to_find($tabName, $keyCol);
    my $to_ins = $dbic->to_insert($tabName, $keyCol, @otherCols);

    sub {
      my ($value, @rest) = @_;
      $to_find->($value) || $to_ins->($value, @rest);
    };
  }

  sub to_fetch {
    my ($dbic, $tabName, $keyColList, $resColList, @rest) = @_;
    my $sql = $dbic->YATT_DBSchema
      ->sql_to_fetch($tabName, $keyColList, $resColList, @rest);
    my $storage = $dbic->storage;
    # XXX: dbh_do
    my $sth;
    sub {
      my (@value) = @_;
      $sth ||= $storage->dbh->prepare($sql);
      $sth->execute(@value);
      $sth;
    }
  }

  sub zip {
    my @res;
    for (my $i = 0; $i < @{$_[0]}; $i++) {
      push @res, [map {$_->[$i]} @_];
    }
    wantarray ? @res : \@res;
  }
}

use YATT::Lite::Breakpoint ();
YATT::Lite::Breakpoint::break_load_dbschema_dbic();

1;
