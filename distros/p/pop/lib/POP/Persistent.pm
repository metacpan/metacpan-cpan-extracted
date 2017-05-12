=head1 CLASS
Name:	POP::Persistent
Desc:	This is the persistent base class for POP.  It handles all of the
	persistence logic by using a tied hash implementation to intercept
	all attribute fetches and stores.  The basic algorithm is to update
	the changed attribute on a store, and reload the object from
	persistence on fetch if any attribute has been changed by another
	process since the last load.  There are a number of additional
	optimizations.  See the POP documentation for more details.
=cut
require 5.005;
package POP::Persistent;

$VERSION = do{my(@r)=q$Revision: 1.16 $=~/d+/g;sprintf '%d.'.'%02d'x$#r,@r};

use strict;
use vars qw/@ISA $pid_factory %CLASSES %OBJECTS %LOCKED $VERSION
	$POP_UPDATE_VERSION_GRANULARITY 
	  $POP_UPDATE_VERSION_ON_CHANGE
	  $POP_UPDATE_VERSION_ON_COMMIT
	$POP_TRANSACTION_MODE
	  $POP_TRANSACTION_ANSI
	  $POP_TRANSACTION_AUTO
	$POP_ISOLATION_DIRTY_READ $POP_ISOLATION_COMMITTED_READ
	$POP_ISOLATION_REPEATABLE_READ $POP_ISOLATION_CURRENT/;
use Tie::Hash;
use DBI;
use POP::Carp;
use POP::Environment;
use Devel::WeakRef;
use POP::Lazy_object;
use POP::Lazy_object_list;
use POP::Lazy_object_hash;
use POP::List;
use POP::Hash;
use POP::Pid_factory;
use POP::POX_parser;

# Avoid "used only once" warnings
*main::POP_UPDATE_VERSION_GRANULARITY =
*main::POP_UPDATE_VERSION_GRANULARITY = *POP_UPDATE_VERSION_GRANULARITY;
$main::POP_UPDATE_VERSION_ON_COMMIT =
$main::POP_UPDATE_VERSION_ON_COMMIT = $POP_UPDATE_VERSION_ON_COMMIT = 0;
$main::POP_UPDATE_VERSION_ON_CHANGE =
$main::POP_UPDATE_VERSION_ON_CHANGE = $POP_UPDATE_VERSION_ON_CHANGE = 1;

*main::POP_TRANSACTION_MODE =
*main::POP_TRANSACTION_MODE = *POP_TRANSACTION_MODE;
$main::POP_TRANSACTION_ANSI =
$main::POP_TRANSACTION_ANSI = $POP_TRANSACTION_ANSI = 0;
$main::POP_TRANSACTION_AUTO =
$main::POP_TRANSACTION_AUTO = $POP_TRANSACTION_AUTO = 1;

$main::POP_ISOLATION_DIRTY_READ =
$main::POP_ISOLATION_DIRTY_READ = $POP_ISOLATION_DIRTY_READ = 1;
$main::POP_ISOLATION_COMMITTED_READ =
$main::POP_ISOLATION_COMMITTED_READ = $POP_ISOLATION_COMMITTED_READ = 2;
$main::POP_ISOLATION_REPEATABLE_READ =
$main::POP_ISOLATION_REPEATABLE_READ = $POP_ISOLATION_REPEATABLE_READ = 3;
$main::POP_ISOLATION_CURRENT =
$main::POP_ISOLATION_CURRENT = $POP_ISOLATION_CURRENT = 4;

@ISA = qw/Tie::StdHash/;

my $pid_factory = POP::Pid_factory->new;

# %OBJECTS is our object "cache"; we don't want to interfere with
# normal ref-counting, so we use the convenient Devel::WeakRef::Table :)
tie(%OBJECTS, 'Devel::WeakRef::Table') or croak "object cache tie failed";

# This is used to parse the XML class definition files:
my $parser = POP::POX_parser::->new();

my $dsn;
if ($POP_DBI_DRIVER eq 'Sybase') {
  $dsn = "dbi:Sybase:server=$POP_DB_SERVER;database=$POP_DB_DB";
} else {
  croak "Unknown driver [$POP_DBI_DRIVER]";
}
my $dbh = DBI->connect($dsn, $POP_DB_USER, $POP_DB_PASSWD,
		     { RaiseError => 1,
		       AutoCommit => 0 }) or
  croak "Couldn't connect to [$dsn]: $DBI::errstr";

sub main::POP_COMMIT {
  if ($POP_UPDATE_VERSION_GRANULARITY != $POP_UPDATE_VERSION_ON_CHANGE) {
    for (values %LOCKED) {
      $_->_POP__Persistent_update_version;
    }
  }
  %LOCKED = ();
  $dbh->commit;
}

sub main::POP_ROLLBACK {
  %LOCKED = ();
  $dbh->rollback;
}

sub main::POP_ISOLATION {
  my $level = shift;
  if ($level == $POP_ISOLATION_DIRTY_READ) {
    $dbh->do("set transaction isolation level 0");
  } elsif ($level == $POP_ISOLATION_COMMITTED_READ) {
    $dbh->do("set transaction isolation level 1");
  } elsif ($level == $POP_ISOLATION_REPEATABLE_READ) {
    $dbh->do("set transaction isolation level 3");
  } else {
    croak "Unknown isolation level [$level]";
  }
}

sub _POP__Persistent_cache_class {
  unless ($CLASSES{$_[0]}) {
    my $class = $_[0];
    my $class_def_file = &POP::POX_parser::pox_find($class);
    unless ($class_def_file) {
      croak "Couldn't find POX for [$class]. POP_POXLIB=($POP_POXLIB)";
    }
    $CLASSES{$class} = $parser->parse($class_def_file);
  }
}
 
sub new {
  my $class = shift;
  _POP__Persistent_cache_class($class);
  my $pid;
  if (@_ & 1) { # Odd number of parameters
    $pid = shift;
  }
  my %this = @_;
  my $this = bless \%this, $class;
  if ($pid) { # Pid supplied to constructor
    if ($OBJECTS{$pid}) {
      return $OBJECTS{$pid};
    }
    $this->_POP__Persistent_restore_from_pid($pid);
  } else { # Create a new object; nothing supplied to constructor
    $pid = $this->{'_pop__persistent_pid'} = &_POP__Persistent_new_pid;
    # call our calling classes' initializing routine, if it exists.
    if ($this->can('initialize')) {
      $this->initialize;
    }
    $dbh->do("exec OBJECTS#NEW $pid");
    $LOCKED{$pid} = $this;
    $this->_POP__Persistent_store_all;
  }
  tie(%this, $class, %this);
  $OBJECTS{$pid} = $this;
  return $this;
}

sub DESTROY {
  my $this = shift;
  my $tied = tied %$this;
  untie %$this if $tied;
}

sub TIEHASH {
  my $class = shift;
  my $this = bless {@_}, $class;
  return $this;
}

sub FETCH {
  my($this, $key) = @_;
  my $ver;
  if ($LOCKED{$this->{'_pop__persistent_pid'}}) {
    return $this->{$key};
  } else {
    my $ver = $this->_POP__Persistent_get_version;
    if ($ver != $this->{'_pop__persistent_version'}) {
      $this->{'_pop__persistent_version'} = $ver;
      $this->_POP__Persistent_load;
    }
    return $this->{$key};
  }
}

sub _POP__Persistent_get_version {
  my $this = shift;
  my $sth = $dbh->prepare("exec OBJECTS#VER $this->{'_pop__persistent_pid'}");
  $sth->execute;
  if (my @row = $sth->fetchrow) {
    return $row[0];
  } else {
    throw "Object deleted.";
  }
}

sub _POP__Persistent_update_version {
  my $this = shift;
  $this = tied %$this if tied %$this;
  my $sth = $dbh->prepare("exec OBJECTS#UPD $this->{'_pop__persistent_pid'}");
  $sth->execute;
  if (my @row = $sth->fetchrow) {
    $this->{'_pop__persistent_version'} = $row[0];
  } else {
    throw "Object deleted.";
  }
}

sub STORE {
  # @subkeys is used when it's actually a collection underneath us
  # informing us that something's changed.  See POP::Hash::STORE and
  # POP::Lazy_object_hash::STORE.
  my($this, $key, $value, @subkeys) = @_;
  $this->{$key} = $value unless @subkeys;
  my $pid = $this->{'_pop__persistent_pid'};
  if (!$LOCKED{$pid} ||
	$POP_UPDATE_VERSION_GRANULARITY == $POP_UPDATE_VERSION_ON_CHANGE) {
    $this->_POP__Persistent_update_version;
  }
  eval {
    $this->_POP__Persistent_store_attr($key, @subkeys);
  };
  if ($@) {
    croak "STORE on [$pid] {$key} failed: $@";
  }
  if ($POP_TRANSACTION_MODE == $POP_TRANSACTION_AUTO) {
    &::POP_COMMIT;
  } else {
    $LOCKED{$pid} = $this;
  }
  return $value;
}

sub delete {
  my $this = shift;
  my $pid = $this->pid;
  eval {
    my $class_def = $CLASSES{ref $this};
    my $proc = $class_def->{'abbr'} || lc($class_def->{'name'});
    my $sth = $dbh->prepare("exec ${proc}#DEL $pid");
    $sth->execute;
    if (($sth->fetchrow)[0] == 1) { # Object still referenced
      croak "object still referenced";
    }
  };
  if ($@) {
    croak "delete on [$pid] failed: $@";
  } else {
    delete $LOCKED{$pid};
    untie %$this;
    $this = undef;
  }
}

sub pid {
  my $this = shift;
  if (my $tied = tied $this) {
    $this = $tied;
  }
  return $this->{'_pop__persistent_pid'};
}

sub all {
  my($this, @attr) = @_;
  if (my $tied = tied $this) {
    $this = $tied;
  }
  my %opts;
  # Pull off leading hash ref of options:
  if (UNIVERSAL::isa($attr[0], 'HASH')) {
    %opts = %{shift @attr};
  }
  my $where_clause;
  my $class = ref $this ? ref $this : $this;
  _POP__Persistent_cache_class($class);
  if ($opts{'where'}) {
    $where_clause =
	$this->_POP__Persistent_compute_where_clause($opts{'where'});
  }
  my $isolation_level = ' at isolation read uncommitted';
  if (my $iso = $opts{'isolation'}) {
    if ($iso == $POP_ISOLATION_CURRENT) {
      $isolation_level = '';
    } elsif ($iso == $POP_ISOLATION_COMMITTED_READ) {
      $isolation_level = ' at isolation read committed';
    } elsif ($iso == $POP_ISOLATION_REPEATABLE_READ) {
      $isolation_level = ' at isolation serializable';
    } elsif ($iso != $POP_ISOLATION_DIRTY_READ) {
      croak "Unknown isolation level [$iso]";
    }
  }
  my $c = $CLASSES{$class};
  my $lc_name = $c->{'abbr'} || lc($c->{'name'});
  my(@abbr, @type);
  unless (@attr) {
    @attr = ('pid');
  }
  foreach my $attr (@attr) {
    if ($attr eq 'pid') {
      push(@abbr, 'pid');
      push(@type, 'pidtype');
    } elsif (my $a = $c->{'attributes'}{$attr}) {
      if ($a->{'list'} || $a->{'hash'}) {
        croak "Cannot select multi-valued attribute for return";
      }
      push(@abbr, $a->{'dbname'});
      push(@type, $a->{'type'});
    } elsif (my $p = $c->{'participants'}{$attr}) {
      push(@abbr, $p->{'dbname'});
      push(@type, $p->{'type'});
    } else {
      croak "Unknown attribute [$attr]";
    }
  }
  my $select_cols = join ',',@abbr;
  my $ob_name;
  if ($opts{'sort'}) {
    $ob_name = $c->{'attributes'}{$opts{'sort'}}{'dbname'} ||
		$c->{'participants'}{$opts{'sort'}}{'dbname'};
  } else {
    $ob_name = 'pid';
  }
  my $sth = $dbh->prepare(
    "select $select_cols from $lc_name $where_clause order by $ob_name".
    $isolation_level);
  $sth->execute;
  my $result = $sth->fetchall_arrayref;
  $sth->finish;
  my @return;
  $#return = $#{$result};
  for (my $i; $i < @$result; $i++) {
    my $row = $result->[$i];
    if (@$row > 1) {
      for (my $j; $j<@$row; $j++) {
	push(@{$return[$i]},
	  &_POP__Persistent_type_from_db($type[$j], $row->[$j]));
      }
    } else {
      $return[$i] = &_POP__Persistent_type_from_db($type[0], $row->[0]);
    }
  }
  return wantarray ? @return : \@return;
}

sub _POP__Persistent_compute_where_clause {
  my($this, $where) = @_;
  # Where clauses should be supplied like this:
  # [ [ ATTR, OP, VALUE ], CONNECTOR, [ATTR, OP, VALUE] ]
  # where OP is one of {'=', '>', '<', '>=', '<=', '!='}
  # and CONNECTOR is one of {'AND', 'OR'}
  # ( yeah, I know this is incomplete, but it's a start )
  my $sql = 'where ';
  my $class = ref $this ? ref $this : $this;
  my $c = $CLASSES{$class};
  foreach my $expr_or_conn (@$where) {
    if (ref $expr_or_conn) {
      my($attr, $op, $val) = @$expr_or_conn;
      if (exists $c->{'attributes'}{$attr} && (
	  $c->{'attributes'}{$attr}{'list'} ||
	  $c->{'attributes'}{$attr}{'hash'})) {
	croak "Cannot use multi-valued attribute in where clause";
      }
      if (exists $c->{'attributes'}{$attr}) {
        $val = &_POP__Persistent_type_to_db(
	  $c->{'attributes'}{$attr}{'type'}, $val);
        $sql .= "$c->{'attributes'}{$attr}{'dbname'} $op $val";
      } elsif (exists $c->{'participants'}{$attr}) {
        $val = &_POP__Persistent_type_to_db(
	  $c->{'participants'}{$attr}{'type'}, $val);
        $sql .= "$c->{'participants'}{$attr}{'dbname'} $op $val";
      } else { croak "[$attr] is neither an attribute nor a participant" }
    } else {
      $sql .= " $expr_or_conn ";
    }
  }
  return $sql;
}

sub _POP__Persistent_new_pid {
#  my $this = shift;
#  my $class = ref $this || $this;
  my $new_pid = $pid_factory->next;
  return $new_pid;
}

sub _POP__Persistent_restore_from_pid {
  my($this, $pid) = @_;
  $this->{'_pop__persistent_pid'} = $pid;
  $this->{'_pop__persistent_version'} = $this->_POP__Persistent_get_version;
  $this->_POP__Persistent_load;
}

sub _POP__Persistent_load {
  my $this = shift;
  my $class_def = $CLASSES{ref $this};
  my $pid = $this->pid;
  my $proc = $class_def->{'abbr'} || lc($class_def->{'name'});
  eval {
    my $sth = $dbh->prepare("exec ${proc}#GET $pid");
    $sth->execute;
    my $result = $sth->fetchall_arrayref();
    $sth->finish;
    unless (@$result > 0) {
      croak "Object [$pid] not found.";
    }
    my $i;
    # NOTE - we do rely on the hash-walking ordering being the same
    # between $class_def here and poxdb.
    foreach (values %{$class_def->{'participants'}},
	     values %{$class_def->{'scalar_attributes'}}) {
      $this->{$_->{'name'}} =
        &_POP__Persistent_type_from_db($_->{'type'}, $result->[0][$i++]);
    }
    # now the list ones...
    foreach my $att (values %{$class_def->{'list_attributes'}}) {
      next if $this->{'_pop__persistent_mv_attr_vers'}{$att->{'name'}} ==
	      $result->[0][$i++];
      $this->{'_pop__persistent_mv_attr_vers'}{$att->{'name'}} =
	 $result->[0][$i-1];
      my $name = $att->{'abbr'} || lc($att->{'name'});
      $sth = $dbh->prepare("exec ${proc}#GET\@$name $pid");
      $sth->execute();
      my $list_result = $sth->fetchall_arrayref();
      $sth->finish;
      $this->{$att->{'name'}} = $this->_POP__Persistent_list_from_db(
	$att->{'type'}, $att->{'name'}, map {$_->[0]} @$list_result);
    }
    # now the hash ones...
    foreach my $att (values %{$class_def->{'hash_attributes'}}) {
      next if $this->{'_pop__persistent_mv_attr_vers'}{$att->{'name'}} ==
	      $result->[0][$i++];
      $this->{'_pop__persistent_mv_attr_vers'}{$att->{'name'}} =
	 $result->[0][$i-1];
      my $name = $att->{'abbr'} || lc($att->{'name'});
      $sth = $dbh->prepare("exec ${proc}#GET\@$name $pid");
      $sth->execute();
      my $list_result = $sth->fetchall_arrayref();
      $sth->finish;
      $this->{$att->{'name'}} = $this->_POP__Persistent_hash_from_db(
	$att->{'val_type'},
	$att->{'name'},
	{map {&_POP__Persistent_type_from_db($att->{'key_type'}, $_->[0]),
	     $_->[1]} @$list_result});
    }
  };
  if ($@) {
    croak "load of [$pid] failed: $@";
  }
}

sub _POP__Persistent_store_attr {
  my($this, $key, @subkeys) = @_;
  my $pid = $this->pid;
  my $class_def = $CLASSES{ref $this};
  my $attr = $class_def->{'attributes'}{$key} ||
		$class_def->{'participants'}{$key};
  my $proc = $class_def->{'dbname'};
  my $name = $attr->{'dbname'};
  if ($attr->{'hash'}) {
    if (@subkeys) {
     for my $subkey (@subkeys) {
      $subkey = &_POP__Persistent_type_to_db($attr->{'key_type'}, $subkey);
      $dbh->do("exec ${proc}#DEL\@$name $pid, $subkey");
      # Yuck. This isn't so good. this has shared knowledge with
      # hash_to_db and Lazy_object_hash
      if ($attr->{'val_type'} =~ /::/) {
	$dbh->do("exec ${proc}#SET\@$name $pid, $subkey, ".
	  $this->{$key}{$subkey}->pid);
      } else {
	$dbh->do("exec ${proc}#SET\@$name $pid, $subkey, ".
	  &_POP__Persistent_type_to_db($attr->{'val_type'},
					$this->{$key}{$subkey}));
      }
     }
    } else {
      $dbh->do("exec ${proc}#DEL\@$name $pid");
      my %values =
      &_POP__Persistent_hash_to_db($attr->{'key_type'},
				   $attr->{'val_type'},
				   $this->{$key});
      while (my($k, $v) = each %values) {
        $dbh->do("exec ${proc}#SET\@$name $pid, $k, $v");
      }
    }
    my $sth = $dbh->prepare("exec ${proc}#VER\@$name $pid");
    $sth->execute();
    $this->{'_pop__persistent_mv_attr_vers'}{$attr->{'name'}} =
	($sth->fetch)[0]->[0];
    $sth->finish();
  } elsif ($attr->{'list'}) {
    if (@subkeys) {
     for my $subkey (@subkeys) {
      $dbh->do("exec ${proc}#DEL\@$name $pid, $subkey");
      # Yuck. This isn't so good. this has shared knowledge with
      # list_to_db and Lazy_object_list
      if ($attr->{'type'} =~ /::/) {
	$dbh->do("exec ${proc}#SET\@$name $pid, ".$this->{$key}[$subkey]->pid.
		 ", $subkey");
      } else {
	$dbh->do("exec ${proc}#SET\@$name $pid, ".
	  &_POP__Persistent_type_to_db($attr->{'type'}, $this->{$key}[$subkey]).
	  ", $subkey");
      }
     }
    } else {
      $dbh->do("exec ${proc}#DEL\@$name $pid");
      my @values =
        &_POP__Persistent_list_to_db($attr->{'type'}, $this->{$key});
      for (my $i = 0; $i < @values; $i++) {
        $dbh->do("exec ${proc}#SET\@$name $pid, $values[$i], $i");
      }
    }
    my $sth = $dbh->prepare("exec ${proc}#VER\@$name $pid");
    $sth->execute();
    $this->{'_pop__persistent_mv_attr_vers'}{$attr->{'name'}} =
	($sth->fetch)[0]->[0];
    $sth->finish();
  } else {
    $dbh->do("exec ${proc}#SET\$$name $pid, ".
	&_POP__Persistent_type_to_db($attr->{'type'}, $this->{$key}));
  }
}

sub _POP__Persistent_store_all {
  my($this, $attr) = @_;
  my $pid = $this->pid;
  my $class_def = $CLASSES{ref $this};
  my $proc = $class_def->{'abbr'} || lc($class_def->{'name'});
  eval {
    $dbh->do("exec ${proc}#SET ".
      join(', ', $pid,
	(map {&_POP__Persistent_type_to_db($_->{'type'}, $this->{$_->{'name'}})}
	    values %{$class_def->{'participants'}},
            values %{$class_def->{'scalar_attributes'}}),
        map {$this->{'_pop__persistent_mv_attr_vers'}{$_}||0}
	    keys %{$class_def->{'list_attributes'}},
	    keys %{$class_def->{'hash_attributes'}}));
    foreach (keys %{$class_def->{'list_attributes'}},
	     keys %{$class_def->{'hash_attributes'}}) {
      $this->_POP__Persistent_store_attr($_);
    }
  };
  if ($@) {
    croak "store-all of [$pid] failed: $@";
  } 
}

sub _POP__Persistent_list_to_db {
  my($type, $elems) = @_;
  if ($type =~ /::/) {
    if (tied @$elems) {
      return (tied @$elems)->PIDS;   
    } else {
      return map {ref $_ ? $_->pid : $_} @$elems;
    }
  }
  return map {&_POP__Persistent_type_to_db($type, $_)} @$elems;
}

sub _POP__Persistent_list_from_db {
  my($this, $type, $name) = splice(@_,0,3);
  my @temp;
  if ($type =~ /::/) {
    # Embedded object.
    tie(@temp, 'POP::Lazy_object_list', $type, $name, $this, @_);
  } else {
    tie(@temp, 'POP::List', $name, $this,
      map {&_POP__Persistent_type_from_db($type, $_)} @_);
  }
  return \@temp;
}

sub _POP__Persistent_hash_to_db {
  my($key_type, $val_type, $elems) = @_;
  if ($val_type =~ /::/) {
    if (tied %$elems) {
      return (tied %$elems)->PIDS;   
    } else {
      my %ret;
      while (my($k,$v) = each %$elems) {
        $ret{&_POP__Persistent_type_to_db($key_type, $k)} =
	  (ref $v ? $v->pid : 0);
      }
      return wantarray ? %ret : \%ret;
    }
  }
  my %ret;
  while (my($k,$v) = each %$elems) {
    $ret{&_POP__Persistent_type_to_db($key_type, $k)} =
      &_POP__Persistent_type_to_db($val_type, $v);
  }
  return wantarray ? %ret : \%ret;
}

sub _POP__Persistent_hash_from_db {
  my($this, $val_type, $name, $elems) = @_;
  my %temp;
  if ($val_type =~ /::/) {
    # Embedded object.
    tie(%temp, 'POP::Lazy_object_hash', $val_type, $name, $this, $elems);
  } else {
    foreach (keys %$elems) {
      $elems->{$_} = &_POP__Persistent_type_from_db($val_type, $elems->{$_});
    }
    tie(%temp, 'POP::Hash', $name, $this, $elems)
  }
  return wantarray ? %temp : \%temp;
}

sub _POP__Persistent_type_from_db {
  my($type, $val) = @_;
  if ($type =~ /::/) {
    # Embedded object. We just get the pid back from the db, so tie it;
    # on its first access, $temp will be replaced with the actual object
    if ($val) {
      my $temp;
      tie($temp, 'POP::Lazy_object', \$temp, $type, $val);
      return \$temp;
    } else {
      return \do{my $a};
    }
  }
  if ($type =~ /^numeric/ || $type eq 'pidtype' || $type eq 'int') {
    return $val;
  } elsif ($type eq 'datetime') {
    return &_POP__Persistent_date_from_db($val);
  } elsif ($type =~ /^(?:var)?char/) {
    return &_POP__Persistent_char_from_db($val);
  } elsif ($type eq 'text' || $type eq 'bit') {
    return $val;
  } else {
    croak "unknown type [$type]";
  }
  $val;
}

sub _POP__Persistent_type_to_db {
  my($type, $val) = @_;
  if ($type =~ /::/) {
    # Be careful not to restore a lazy-load object if we don't want to:
    if (tied $val) {
      return (tied $val)->pid;
    } elsif (ref $val && UNIVERSAL::isa($val, __PACKAGE__))  {
      return $val->pid;
    } elsif (ref $val eq 'REF' &&
	     ref $$val &&
	     UNIVERSAL::isa($$val, __PACKAGE__)) {
      return ($$val)->pid;
    } else {
      # Hmm, should be an object, but there's nothing there.
      # croak "[$val] is not an object";
      return 0;
    }
  }
  if ($type =~ /^numeric/ || $type eq 'pidtype' || $type eq 'int') {
    return &_POP__Persistent_num_to_db($val);
  } elsif ($type eq 'datetime') {
    return &_POP__Persistent_date_to_db($val);
  } elsif ($type =~ /^(?:var)?char\((\d+)\)$/) {
    return &_POP__Persistent_char_to_db($val, $1);
  } elsif ($type eq 'text') {
    return &_POP__Persistent_text_to_db($val);
  } elsif ($type eq 'bit') {
    return &_POP__Persistent_bit_to_db($val);
  } else {
    croak "unknown type [$type]";
  }
  $val;
}

sub _POP__Persistent_char_from_db {
  my($val) = @_;
  if (defined($val)) {
    $val =~ s/^\s+//;
    $val =~ s/\s+$//;
  }
  $val;
}

sub _POP__Persistent_char_to_db {
  my($val, $width) = @_;
  if (!defined($val) or $val eq '') {
    return "NULL";
  }
  if (length($val) > $width) {
    # XXX Do we want a warning here?
    substr($val, $width) = '';
  }
  $val =~ s/"/""/g;
  qq,"$val",;
}

sub _POP__Persistent_text_to_db {
  my($val) = @_;
  if (!defined($val) or $val eq '') {
    return "NULL";
  }
  $val =~ s/"/""/g;
  qq,"$val",;
}

sub _POP__Persistent_bit_to_db {
  my($val) = @_;
  return $val ? '1' : '0';
}

sub _POP__Persistent_num_to_db {
  my($val) = @_;
  if (!defined($val)) {
    return "NULL";
  } 
  0+$val;
}

sub _POP__Persistent_date_from_db {
  my($val) = @_;
  qq,"$val",;
}

sub _POP__Persistent_date_to_db {
  my($val) = @_;
  $val;
}

$VERSION = $VERSION;
