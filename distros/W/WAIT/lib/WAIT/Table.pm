#                              -*- Mode: Cperl -*- 
# Table.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Thu Aug  8 13:05:10 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Mon May  8 20:20:58 2000
# Language        : CPerl
# Update Count    : 131
# Status          : Unknown, Use with caution!
#
# Copyright (c) 1996-1997, Ulrich Pfeifer
#

=head1 NAME

WAIT::Table -- Module for maintaining Tables / Relations

=head1 SYNOPSIS

  require WAIT::Table;

=head1 DESCRIPTION

=cut

package WAIT::Table;

use WAIT::Table::Handle ();
require WAIT::Parse::Base;

use strict;
use Carp;
# use autouse Carp => qw( croak($) );
use DB_File;
use Fcntl;
use LockFile::Simple ();

my $USE_RECNO = 0;

=head2 Creating a Table.

The constructor WAIT::Table-E<gt>new is normally called via the
create_table method of a database handle. This is not enforced, but
creating a table does not make any sense unless the table is
registered by the database because the latter implements persistence
of the meta data. Registering is done automatically by letting the
database handle the creation of a table.

  my $db = WAIT::Database->create(name => 'sample');
  my $tb = $db->create_table(name     => 'test',
                             access   => $access,
                             layout   => $layout,
                             attr     => ['docid', 'headline'],
                            );

The constructor returns a handle for the table. This handle is hidden by the
table module, to prevent direct access if called via Table.

=over 10

=item C<access> => I<accessobj>

A reference to an access object for the external parts (attributes) of
tuples. As you may remember, the WAIT System does not enforce that
objects are completely stored inside the system to avoid duplication.
There is no (strong) point in storing all your HTML documents inside
the system when indexing your WWW-Server.

The access object is designed to work like as a tied hash. You pass
the refernce to the object, not the tied hash though. An example
implementation of an access class that works for manpages is
WAIT::Document::Nroff.

The implementation needs to take into account that WAIT will keep this
object in a Data::Dumper or Storable database and re-use it when sman
is run. So it is not good enough if we can produce the index with it
now, when we create or actively access the table, WAIT also must be
able to retrieve documents on its own, when we are in a different
context. This happens specifically in a retrieval. To get this working
seemlessly, the access-defining class must implement a close method.
This method will be called before the Data::Dumper dump takes place.
In that moment the access-defining class must get rid of all data
structures that cannot be reconstructed via the Data::Dumper dump,
such as database handles or C pointers.

=item C<file> => I<fname>

The filename of the records file. Files for indexes will have I<fname>
as prefix. I<Mandatory>, but usually taken care of by the
WAIT::Database handle when the constructor is called via
WAIT::Database::create_table().

=item C<name> => I<name>

The name of this table. I<Mandatory>

=item C<attr> => [ I<attr> ... ]

A reference to an array of attribute names. WAIT will keep the
contents of these attributes in its table. I<Mandatory>

=item C<djk> => [ I<attr> ... ]

A reference to an array of attribute names which make up the
I<disjointness key>. Don't think about it - it's of no use yet;

=item C<layout> => I<layoutobj>

A reference to an external parser object. Defaults to a new instance
of C<WAIT::Parse::Base>. For an example implementation see
WAIT::Parse::Nroff. A layout class can be implemented as a singleton
class if you so like.

=item C<keyset> => I<keyset>

The set of attributes needed to identify a record. Defaults to all
attributes.

=item C<invindex> => I<inverted index>

A reference to an anon array defining attributes of each record that
need to be indexed. See the source of smakewhatis for how to set this
up.

=back

=cut

sub new {
  my $type = shift;
  my %parm = @_;
  my $self = {};

  # Check for mandatory attrs early
  $self->{name}     = $parm{name}     or croak "No name specified";
  $self->{attr}     = $parm{attr}     or croak "No attributes specified";

  # Do that before we eventually add '_weight' to attributes.
  $self->{keyset}   = $parm{keyset}   || [[@{$parm{attr}}]];

  $self->{mode}     = O_CREAT | O_RDWR;

  # Determine and set up subclass
  $type = ref($type) || $type;
  if (defined $parm{djk}) {
    if (@{$parm{djk}} == @{$parm{attr}}) {
      # All attributes in DK (sloppy test here!)
      $type .= '::Independent';
      require WAIT::Table::Independent;
    } else {
      $type .= '::Disjoint';
      require WAIT::Table::Disjoint;
    }
    # Add '_weight' to attributes
    my %attr;
    @attr{@{$parm{attr}}} = (1) x @{$parm{attr}};
    unshift @{$parm{attr}}, '_weight' unless $attr{'_weight'};
  }

  $self->{file}     = $parm{file}     or croak "No file specified";
  if (-d  $self->{file}){
    warn "Warning: Directory '$self->{file}' already exists\n";
  } elsif (!mkdir($self->{file}, 0775)) {
    croak "Could not 'mkdir $self->{file}': $!\n";
  }

  my $lockmgr = LockFile::Simple->make(-autoclean => 1);
  # aquire a write lock
  $self->{write_lock} = $lockmgr->lock($self->{file} . '/write')
    or die "Can't lock '$self->{file}/write'";

  $self->{djk}      = $parm{djk}      if defined $parm{djk};
  $self->{layout}   = $parm{layout} || new WAIT::Parse::Base;
  $self->{access}   = $parm{access} if defined $parm{access};
  $self->{nextk}    = 1;        # next record to insert; first record unused
  $self->{deleted}  = {};       # no deleted records yet
  $self->{indexes}  = {};

  bless $self, $type;
  # Call create_index() and create_index() for compatibility
  for (@{$self->{keyset}||[]}) {
    #carp "Specification of indexes at table create time is deprecated";
    $self->create_index(@$_);
  }
  while (@{$parm{invindex}||[]}) {
    # carp "Specification of inverted indexes at table create time is deprecated";
    my $att  = shift @{$parm{invindex}};
    my @spec = @{shift @{$parm{invindex}}};
    my @opt;

    if (ref($spec[0])) {
      carp "Secondary pipelines are deprecated\n";
      @opt = %{shift @spec};
    }
    $self->create_inverted_index(attribute => $att, pipeline  => \@spec, @opt);
  }

  $self;
  # end of backwarn compatibility stuff
}

=head2 Creating an index

  $tb->create_index('docid');

=item C<create_index>

must be called with a list of attributes. This must be a subset of the
attributes specified when the table was created. Currently this
method must be called before the first tuple is inserted in the
table!

=cut

sub create_index {
  my $self= shift;

  croak "Cannot create index for table aready populated"
    if $self->{nextk} > 1;

  require WAIT::Index;

  my $name = join '-', @_;
  $self->{indexes}->{$name} =
    new WAIT::Index file => $self->{file}.'/'.$name, attr => $_;
}

=head2 Creating an inverted index

  $tb->create_inverted_index
    (attribute => 'au',
     pipeline  => ['detex', 'isotr', 'isolc', 'split2', 'stop'],
     predicate => 'plain',
    );

=over 5

=item C<attribute>

The attribute to build the index on. This attribute may not be in the
set attributes specified when the table was created.

=item C<pipeline>

A piplines specification is a reference to an array of method names
(from package C<WAIT::Filter>) which are to be applied in sequence to
the contents of the named attribute. The attribute name may not be in
the attribute list.

=item C<predicate>

An indication which predicate the index implements. This may be
e.g. 'plain', 'stemming' or 'soundex'. The indicator will be used for
query processing. Currently there is no standard set of predicate
names. The predicate defaults to the last member of the pipeline if
omitted.

=back

Currently this method must be called before the first tuple is
inserted in the table!

=cut

sub create_inverted_index {
  my $self  = shift;
  my %parm  = @_;

  croak "No attribute specified" unless $parm{attribute};
  croak "No pipeline specified"  unless $parm{pipeline};

  $parm{predicate} ||= $parm{pipeline}->[-1];

  croak "Cannot create index for table aready populated"
    if $self->{nextk} > 1;

  require WAIT::InvertedIndex;

  # backward compatibility stuff
  my %opt = %parm;
  for (qw(attribute pipeline predicate)) {
    delete $opt{$_};
  }

  my $name = join '_', ($parm{attribute}, @{$parm{pipeline}});
  my $idx = new WAIT::InvertedIndex(file   => $self->{file}.'/'.$name,
                                    filter => [@{$parm{pipeline}}], # clone
                                    name   => $name,
                                    attr   => $parm{attribute},
                                    %opt, # backward compatibility stuff
                                   );
  # We will have to use $parm{predicate} here
  push @{$self->{inverted}->{$parm{attribute}}}, $idx;
}

sub dir {
  $_[0]->{file};
}

=head2 C<$tb-E<gt>layout>

Returns the reference to the associated parser object.

=cut

sub layout { $_[0]->{layout} }

=head2 C<$tb-E<gt>fields>

Returns the array of attribute names.

=cut


sub fields { keys %{$_[0]->{inverted}}}

=head2 C<$tb-E<gt>drop>

Must be called via C<WAIT::Database::drop_table>

=cut

sub drop {
  my $self = shift;
  if ((caller)[0] eq 'WAIT::Database') { # database knows about this
    $self->close;               # just make sure
    my $file = $self->{file};

    for (values %{$self->{indexes}}) {
      $_->drop;
    }
    unlink "$file/records";
    # $self->unlock;
    ! (!-e $file or rmdir $file);
  } else {
    croak ref($self)."::drop called directly";
  }
}

sub mrequire ($) {
  my $module = shift;

  $module =~ s{::}{/}g;
  $module .= '.pm';
  require $module;
}

sub open {
  my $self = shift;
  my $file = $self->{file} . '/records';

  mrequire ref($self);           # that's tricky eh?
  if (defined $self->{'layout'}) {
    mrequire ref($self->{'layout'});
  }
  if (defined $self->{'access'}) {
    mrequire ref($self->{'access'});
  }
  if (exists $self->{indexes}) {
    require WAIT::Index;
    for (values %{$self->{indexes}}) {
      $_->{mode} = $self->{mode};
    }
  }
  if (exists $self->{inverted}) {
    my ($att, $idx);
    for $att (keys %{$self->{inverted}}) {
      for $idx (@{$self->{inverted}->{$att}}) {
        $idx->{mode} = $self->{mode};
      }
    }
    require WAIT::InvertedIndex;
  }
  unless (defined $self->{dbh}) {
    if ($USE_RECNO) {
      $self->{dbh} = tie(@{$self->{db}}, 'DB_File', $file,
                         $self->{mode}, 0664, $DB_RECNO);
    } else {
      $self->{dbh} =
        tie(%{$self->{db}}, 'DB_File', $file,
                         $self->{mode}, 0664, $DB_BTREE);
    }
  }

  # Locking
  #
  # We allow multiple readers to coexists.  But write access excludes
  # all read access vice versa.  In practice read access on tables
  # open for writing will mostly work ;-)

  my $lockmgr = LockFile::Simple->make(-autoclean => 1);

  # aquire a write lock. We might hold one acquired in create() already
  $self->{write_lock} ||= $lockmgr->lock($self->{file} . '/write')
    or die "Can't lock '$self->{file}/write'";

  my $lockdir = $self->{file} . '/read';
  unless (-d $lockdir) {
    mkdir $lockdir, 0755 or die "Could not mkdir $lockdir: $!";
  }

  if ($self->{mode} & O_RDWR) {
    # this is a hack.  We do not check for reopening ...
    return $self if $self->{write_lock};
    
    # If we actually want to write we must check if there are any readers
    opendir DIR, $lockdir or
      die "Could not opendir '$lockdir': $!";
    for my $lockfile (grep { -f "$lockdir/$_" } readdir DIR) {
      # check if the locks are still valid.
      # Since we are protected by a write lock, we could use a pline file.
      # But we want to use the stale testing from LockFile::Simple.
      if (my $lck = $lockmgr->trylock("$lockdir/$lockfile")) {
        warn "Removing stale lockfile '$lockdir/$lockfile'";
        $lck->release;
      } else {
        $self->{write_lock}->release;
        die "Cannot write table '$file' while it's in use";
      }
    }
  } else {
    # this is a hack.  We do not check for reopening ...
    return $self if $self->{read_lock};
    
    # We are a reader. So we release the write lock
    my $id = time;
    while (-f "$lockdir/$id.lock") { # here assume ".lock" format!
      $id++;
    }
    $self->{read_lock} = $lockmgr->lock("$lockdir/$id");
    $self->{write_lock}->release;
    delete $self->{write_lock};
  }

  $self;
}

sub fetch_extern {
  my $self  = shift;

  # print "#@_", $self->{'access'}->{Mode}, "\n"; # DEBUGGING?
  if (exists $self->{'access'}) {
    mrequire ref($self->{'access'});
    $self->{'access'}->FETCH(@_);
  }
}

sub fetch_extern_by_id {
  my $self  = shift;

  $self->fetch_extern($self->fetch(@_));
}

sub _find_index {
  my $self  = shift;
  my (@att) = @_;
  my %att;
  my $name;

  @att{@att} = @att;

  KEY: for $name (keys %{$self->{indexes}}) {
      my @iat = split /-/, $name;
      for (@iat) {
        next KEY unless exists $att{$_};
      }
      return $self->{indexes}->{$name};
    }
  return undef;
}

sub have {
  my $self  = shift;
  my %parm  = @_;

  my $index = $self->_find_index(keys %parm) or return; # no index-no have

  defined $self->{db} or $self->open;
  return $index->have(@_);
}

sub insert {
  my $self  = shift;
  my %parm  = @_;

  defined $self->{db} or $self->open;

  # We should move all writing methods to a subclass to check only once
  $self->{mode} & O_RDWR or croak "Cannot insert into table opened in RD_ONLY mode";

  my $tuple = join($;, map($parm{$_} || '', @{$self->{attr}}));
  my $key;
  my @deleted = keys %{$self->{deleted}};
  my $gotkey = 0;

  if (@deleted) {
    $key = pop @deleted;
    delete $self->{deleted}->{$key};
    # Sanity check
    if ($key && $key>0) {
      $gotkey=1;
  } else {
      warn(sprintf("WAIT database inconsistency during insert ".
		   "key[%s]: Please rebuild index\n",
		   $key
		  ));
    }
  }
  unless ($gotkey) {
    $key = $self->{nextk}++;
  }
  if ($USE_RECNO) {
    $self->{db}->[$key] = $tuple;
  } else {
    $self->{db}->{$key} = $tuple;
  }
  for (values %{$self->{indexes}}) {
    unless ($_->insert($key, %parm)) {
      # duplicate key, undo changes
      if ($key == $self->{nextk}-1) {
        $self->{nextk}--;
      } else {
	# warn "setting key[$key] deleted during insert";
        $self->{deleted}->{$key}=1;
      }
      my $idx;
      for $idx (values %{$self->{indexes}}) {
        last if $idx eq $_;
        $idx->remove($key, %parm);
      }
      return undef;
    }
  }
  if (defined $self->{inverted}) {
    my $att;
    for $att (keys %{$self->{inverted}}) {
      if (defined $parm{$att}) {
        map $_->insert($key, $parm{$att}), @{$self->{inverted}->{$att}};
        #map $_->sync, @{$self->{inverted}->{$att}}
      }
    }
  }
  $key
}

sub sync {
  my $self  = shift;

  for (values %{$self->{indexes}}) {
    map $_->sync, $_;
  }
  if (defined $self->{inverted}) {
    my $att;
    for $att (keys %{$self->{inverted}}) {
      map $_->sync, @{$self->{inverted}->{$att}}
    }
  }
}

sub fetch {
  my $self  = shift;
  my $key   = shift;

  return () if exists $self->{deleted}->{$key};

  defined $self->{db} or $self->open;
  if ($USE_RECNO) {
    $self->unpack($self->{db}->[$key]);
  } else {
    $self->unpack($self->{db}->{$key});
  }
}

sub delete_by_key {
  my $self  = shift;
  my $key   = shift;

  unless ($key) {
    Carp::cluck "Warning: delete_by_key called without key. Looks like a bug in WAIT?";
    return;
  }

  return $self->{deleted}->{$key} if defined $self->{deleted}->{$key};
  my %tuple = $self->fetch($key);
  for (values %{$self->{indexes}}) {
    $_->delete($key, %tuple);
  }
  if (defined $self->{inverted}) {
    # User *must* provide the full record for this or the entries
    # in the inverted index will not be removed
    %tuple = (%tuple, @_);
    my $att;
    for $att (keys %{$self->{inverted}}) {
      if (defined $tuple{$att}) {
        map $_->delete($key, $tuple{$att}), @{$self->{inverted}->{$att}}
      }
    }
  }
  # warn "setting key[$key] deleted during delete_by_key";
  ++$self->{deleted}->{$key};
}

sub delete {
  my $self  = shift;
  my $tkey = $self->have(@_);
  # warn "tkey[$tkey]\@_[@_]";
  defined $tkey && $self->delete_by_key($tkey, @_);
}

sub unpack {
  my $self = shift;
  my $tuple = shift;
  return unless defined $tuple;

  my $att;
  my @result;
  my @tuple = split /$;/, $tuple;

  for $att (@{$self->{attr}}) {
    push @result, $att, shift @tuple;
  }
  @result;
}

sub set {
  my ($self, $iattr, $value) = @_;
  
  return unless $self->{write_lock};
  for my $att (keys %{$self->{inverted}}) {
    if ($] > 5.003) {         # avoid bug in perl up to 5.003_05
      my $idx;
      for $idx (@{$self->{inverted}->{$att}}) {
        $idx->set($iattr, $value);
      }
    } else {
      map $_->set($iattr, $value), @{$self->{inverted}->{$att}};
    }
  }

  1;
}

sub close {
  my $self = shift;

  if (exists $self->{'access'}) {
    eval {$self->{'access'}->close}; # dont bother if not opened
  }
  for (values %{$self->{indexes}}) {
    require WAIT::Index;
    $_->close();
  }
  if (defined $self->{inverted}) {
    my $att;
    for $att (keys %{$self->{inverted}}) {
      if ($] > 5.003) {         # avoid bug in perl up to 5.003_05
        my $idx;
        for $idx (@{$self->{inverted}->{$att}}) {
          $idx->close;
        }
      } else {
        map $_->close(), @{$self->{inverted}->{$att}};
      }
    }
  }
  if ($self->{dbh}) {
    delete $self->{dbh};

    if ($USE_RECNO) {
      untie @{$self->{db}};
    } else {
      untie %{$self->{db}};
    }
    delete $self->{db};
  }

  $self->unlock;
  
  1;
}

sub unlock {
  my $self = shift;

  # Either we have a read or a write lock (or we close the table already)
  # unless ($self->{read_lock} || $self->{write_lock}) {
  #   warn "WAIT::Table::unlock: Table aparently hold's no lock"
  # }
  if ($self->{write_lock}) {
    $self->{write_lock}->release();
    delete $self->{write_lock};
  }
  if ($self->{read_lock}) {
    $self->{read_lock}->release();
    delete $self->{read_lock};
  }

}

sub DESTROY {
  my $self = shift;

  warn "Table handle destroyed without closing it first"
    if $self->{write_lock} || $self->{read_lock};
}

sub open_scan {
  my $self = shift;
  my $code = shift;

  $self->{dbh} or $self->open;
  require WAIT::Scan;
  new WAIT::Scan $self, $self->{nextk}-1, $code;
}

sub open_index_scan {
  my $self = shift;
  my $attr = shift;
  my $code = shift;
  my $name = join '-', @$attr;

  if (defined $self->{indexes}->{$name}) {
    $self->{indexes}->{$name}->open_scan($code);
  } else {
    croak "No such index '$name'";
  }
}

eval {sub WAIT::Query::Raw::new} unless defined \&WAIT::Query::Raw::new;

sub prefix {
  my ($self , $attr, $prefix) = @_;
  my %result;

  defined $self->{db} or $self->open; # require layout

  for (@{$self->{inverted}->{$attr}}) {
    my $result = $_->prefix($prefix);
    if (defined $result) {
      $result{$_->name} = $result;
    }
  }
  bless \%result, 'WAIT::Query::Raw';
}

sub intervall {
  my ($self, $attr, $lb, $ub) = @_;
  my %result;

  defined $self->{db} or $self->open; # require layout

  for (@{$self->{inverted}->{$attr}}) {
    my $result = $_->intervall($lb, $ub);
    if (defined $result) {
      $result{$_->name} = $result;
    }
  }
  bless \%result, 'WAIT::Query::Raw';
}

sub search {
  my $self  = shift;
  my ($query, $attr, $cont, $raw);
  if (ref $_[0]) {
    $query = shift;
  
    $attr = $query->{attr};
    $cont = $query->{cont};
    $raw  = $query->{raw};
  } else {
    require Carp;
    Carp::cluck("Using three argument search interface is deprecated, use hashref interface instead");
    $attr = shift;
    $cont = shift;
    $raw  = shift;
    $query = {
              attr => $attr,
              cont => $cont,
              raw  => $raw,
             };
  }

  my %result;

  defined $self->{db} or $self->open; # require layout

  if ($raw) {
    for (@{$self->{inverted}->{$attr}}) {
      my $name = $_->name;
      if (exists $raw->{$name} and @{$raw->{$name}}) {
        my $scale = 1/scalar(@{$raw->{$name}});
        my %r = $_->search_raw($query, @{$raw->{$name}});
        my ($key, $val);
        while (($key, $val) = each %r) {
          if (exists $result{$key}) {
            $result{$key} += $val*$scale;
          } else {
            $result{$key}  = $val*$scale;
          }
        }
      }
    }
  }
  if (defined $cont and $cont ne '') {
    for (@{$self->{inverted}->{$attr}}) {
      my %r = $_->search($query, $cont);
      my ($key, $val);
      while (($key, $val) = each %r) {
        if (exists $result{$key}) {
          $result{$key} += $val;
        } else {
          $result{$key}  = $val;
        }
      }
    }
  }
  # sanity check for deleted documents.
  # this should not be necessary !@#$
  for (keys %result) {
    delete $result{$_} if $self->{deleted}->{$_}
  }
  %result;
}

sub hilight_positions {
  my ($self, $attr, $text, $query, $raw)  = @_;
  my %pos;

  if (defined $raw) {
    for (@{$self->{inverted}->{$attr}}) { # objects of type
                                          # WAIT::InvertedIndex for
                                          # this index field $attr
      my $name = $_->name;
      if (exists $raw->{$name}) {
        my %qt;
        grep $qt{$_}++, @{$raw->{$name}};
        for ($_->parse_pos($text)) {
          if (exists $qt{$_->[0]}) {
            $pos{$_->[1]} = max($pos{$_->[1]}, length($_->[0]));
          }
        }
      }
    }
  }
  if (defined $query) {
    for (@{$self->{inverted}->{$attr}}) {
      my %qt;

      grep $qt{$_}++, $_->parse($query);
      for ($_->parse_pos($text)) {
        if (exists $qt{$_->[0]}) {
          if (exists $pos{$_->[1]}) { # perl -w ;-)
            $pos{$_->[1]} = max($pos{$_->[1]}, length($_->[0]));
          } else {
            $pos{$_->[1]} = length($_->[0]);
          }
        }
      }
    }
  }

  \%pos;
}

sub hilight {
  my ($tb, $buf, $qplain, $qraw) = @_;
  my $layout = $tb->layout();

  my @result;

  $qplain ||= {};
  $qraw   ||= {};
  my @ttxt = $layout->tag($buf);
  while (@ttxt) {
    no strict 'refs';
    my %tag = %{shift @ttxt};
    my $txt = shift @ttxt;
    my $fld;

    my %hl;
    for $fld (grep defined $tag{$_}, keys %$qplain, keys %$qraw) {
      my $hp = $tb->hilight_positions($fld, $txt,
                                      $qplain->{$fld}, $qraw->{$fld});
      for (keys %$hp) {
        if (exists $hl{$_}) {   # -w ;-(
          $hl{$_} = max($hl{$_}, $hp->{$_});
        } else {
          $hl{$_} = $hp->{$_};
        }
      }
    }
    my $pos;
    my $qt = {_qt => 1, %tag};
    my $pl = \%tag;
    my $last = length($txt);
    my @tmp;
    for $pos (sort {$b <=> $a} keys %hl) {
      unshift @tmp, $pl, substr($txt,$pos+$hl{$pos},$last-$pos-$hl{$pos});
      unshift @tmp, $qt, substr($txt,$pos,$hl{$pos});
      $last = $pos;
    }
    push @result, $pl, substr($txt,0,$last);
    push @result, @tmp;
  }
  @result;                      # no speed necessary
}

1;
