#                              -*- Mode: Perl -*- 
# $Basename: Database.pm $
# $Revision: 1.14 $
# Author          : Ulrich Pfeifer
# Created On      : Thu Aug  8 09:44:13 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sat Apr 15 16:15:29 2000
# Language        : CPerl
# 
# (C) Copyright 1996-2000, Ulrich Pfeifer
# 

=head1 NAME

WAIT::Database - Module fo maintaining WAIT databases

=head1 SYNOPSIS

  require WAIT::Database;

=head1 DESCRIPTION

The modules handles creating, opening, and deleting of databases and
tables.

=cut

package WAIT::Database;

use strict;
use FileHandle ();
use File::Path qw(rmtree);
use WAIT::Table ();
use Fcntl;
use Carp; # will use autouse later
use LockFile::Simple ();

# use autouse Carp => qw( croak($) );
my ($HAVE_DATA_DUMPER, $HAVE_STORABLE);

BEGIN {
  eval { require Data::Dumper };
  $HAVE_DATA_DUMPER = 1 if $@ eq '';
  eval { require Storable };
  $HAVE_STORABLE    = 1 if $@ eq ''; 
  $HAVE_DATA_DUMPER || $HAVE_STORABLE ||
    die "Could not find Data::Dumper nor Storable";
  $Storable::forgive_me = 1;
}


=head2 Constructor create

  $db = WAIT::Database->create(
                               name      => <name>,
                               directory => <dir>
                              );

Create a new database.

=over 10

=item B<name> I<name>

mandatory

=item B<directory> I<directory>

Directory which should contain the database (defaults to the current
directory).

=item B<uniqueatt> I<true>

If given, the database will require unique attributes over all tables.

The method will croak on failure.

=back

=cut

sub create {
  my $type = shift;
  my %parm = @_;
  my $self = {};
  my $dir  = $parm{directory} || '.';
  my $name = $parm{name};

  unless ($name) {
    croak("No name specified");
  }

  unless (-d $dir){
    croak("Directory '$dir' does not exits: $!");
  }

  if (-d "$dir/$name") {
    warn "Warning: Directory '$dir/$name' already exists";
  } else {
    unless (mkdir "$dir/$name", 0775) {
      croak("Could not mkdir '$dir/$name': $!");
    }
  }

  $self->{name}      = $name;
  $self->{file}      = "$dir/$name";
  $self->{uniqueatt} = $parm{uniqueatt};
  $self->{mode}      = O_CREAT;
  my $lockmgr = LockFile::Simple->make(-autoclean => 1);
  # aquire a write lock
  $self->{write_lock} = $lockmgr->lock("$dir/$name/write")
    or die "Can't lock '$dir/$name/write'";
  bless $self => ref($type) || $type;
}


=head2 Constructor open

  $db = WAIT::Database->open(
                             name => "foo",
                             directory => "bar"
                            );

Open an existing database I<foo> in directory I<bar>.

=cut

sub open {
  my $type    = shift;
  my %parm    = @_;
  my $dir     = $parm{directory} || '.';
  my $name    = $parm{name} or croak "No name specified";
  my $catalog = "$dir/$name/catalog";
  my $meta    = "$dir/$name/meta";
  my $self;

  if ($HAVE_STORABLE and -e $catalog
      and (!-e $meta or -M $meta >= -M $catalog)) {
    $self = Storable::retrieve($catalog);
  } else {
    return undef unless -f $meta;

    $self = do $meta;
    unless (defined $self) {
      warn "do '$meta' did not work. Mysterious! Reverting to eval `cat $meta`";
      sleep(4);
      $self = eval `cat $meta`;
    }
  }

  return unless defined $self;
  $self->{mode} = (exists $parm{mode})?$parm{mode}:(O_CREAT | O_RDWR);

  if ($self->{mode} & O_RDWR) {
    # Locking: We do not care about read access since write is atomic.
    my $lockmgr = LockFile::Simple->make(-autoclean => 1);
    
    # aquire a write lock
    $self->{write_lock} = $lockmgr->lock("$dir/$name/write")
      or die "Can't lock '$dir/$name/write'";
  }

  $self;
}


=head2 C<$db-E<gt>dispose;>

Dispose a database. Remove all associated files. This may fail if the
database or one of its tables is still open. Failure will be indicated
by a false return value.

=cut

sub dispose {
  my $dir;

  if (ref $_[0]) {               # called with instance
    croak "Database readonly" unless $_[0]->{mode} & (O_CREAT | O_RDWR);
    $dir = $_[0]->{file};
    $_[0]->close;
  } else {
    my $type = shift;
    my %parm = @_;
    my $base = $parm{directory} || '.';
    my $name = $parm{name}       || croak "No name specified";
    $dir = "$base/$name";
  }
  croak "No such database '$dir'" unless -e "$dir/meta";

  #warn "Running rmtree on dir[$dir]";
  my $ret = rmtree($dir, 0, 1);
  #warn "rmtree returned[$ret]";
  $ret;
}


=head2 C<$db-E<gt>close;>

Close a database saving all meta data after closing all associated tables.

=cut

sub close {
  my $self = $_[0];
  my $file = $self->{file};
  my $table;
  my $did_save;
  
  for $table (values %{$self->{tables}}) {
    $table->close if ref($table);
  }
  return 1 unless $self->{mode} & (O_RDWR | O_CREAT);

  my $lock = delete $self->{write_lock}; # Do not store lock objects

  if ($HAVE_DATA_DUMPER) {
    my $fh   = new FileHandle "> $file/meta.$$";
    if ($fh) {
      my $dumper = new Data::Dumper [$self],['self'];
      $fh->print('my ');
      $fh->print($dumper->Dumpxs);
      $fh->close;
      $did_save = rename "$file/meta.$$", "$file/meta";
    } else {
      croak "Could not open '$file/meta' for writing: $!";
      # never reached: return unless $HAVE_STORABLE;
    }
  }

  if ($HAVE_STORABLE) {
    if (!eval {Storable::store($self, "$file/catalog.$$")}) {
      unlink "$file/catalog.$$";
      croak "Could not open '$file/catalog.$$' for writing: $!";
      # never reached: return unless $did_save;
    } else {
      $did_save = rename "$file/catalog.$$", "$file/catalog";
    }
  }

  $lock->release;
  
  undef $_[0];
  $did_save;
}


=head2 C<$db-E<gt>create_table(name =E<gt>> I<tname>, ... C<);>

Create a new table with name I<tname>. All parameters are passed to
C<WAIT::Table-E<gt>new> together with a filename to use. See
L<WAIT::Table> for which attributes are required. The method returns a
table handle (C<WAIT::Table::Handle>).

=cut

sub create_table {
  my $self = shift;
  my %parm = @_;
  my $name = $parm{name} or croak "create_table: No name specified";
  my $attr = $parm{attr} or croak "create_table: No attributes specified";
  my $file = $self->{file};

  croak "Database readonly" unless $self->{mode} & (O_CREAT | O_RDWR);

  if (defined $self->{tables}->{$name}) {
    die "Table '$name' already exists";
  }

  if ($self->{uniqueatt}) {
    for (@$attr) {      # attribute names must be uniqe
      if ($self->{attr}->{$_}) {
        croak("Attribute '$_' is not unique")
      }
    }
  }
  $self->{tables}->{$name} = WAIT::Table->new(file     => "$file/$name",
                                              database => $self,
                                              %parm);
  unless (defined $self->{tables}->{$name}) {# fail gracefully
    delete $self->{tables}->{$name};
    return undef;
  }

  if ($self->{uniqueatt}) {
    # remember table name for each attribute
    map ($self->{attr}->{$_} = $name, @$attr);
  }
  WAIT::Table::Handle->new($self, $name);
}


=head2 C<$db-E<gt>table(name =E<gt>> I<tname>C<);>

Open a new table with name I<tname>. The method
returns a table handle (C<WAIT::Table::Handle>).

=cut

sub sync {
  my $self = shift;

  for (values %{$self->{tables}}) {
     $_->sync;
  }
}

sub table {
  my $self = shift;
  my %parm = @_;
  my $name = $parm{name} or croak "No name specified";

  if (defined $self->{tables}->{$name}) {
    if (exists $parm{mode}) {
      $self->{tables}->{$name}->{mode} = $parm{mode};
    } else {
      $self->{tables}->{$name}->{mode} = $self->{mode};
    }
    WAIT::Table::Handle->new($self,$name);
  } else {
    croak "No such table '$name'";
  }
}


=head2 C<$db-E<gt>drop(name =E<gt>> I<tname>C<);>

Drop the table named I<tname>. The table should be closed before
calling B<drop>.

=cut

sub drop_table {
  my $self = shift;
  my %parm = @_;
  my $name = $parm{name} or croak "No name specified";

  croak "Database readonly" unless $self->{mode} & (O_CREAT | O_RDWR);
  if (!defined $self->{tables}->{$name}) {
    croak "Table '$name' does not exist";
  }
  $self->{tables}->{$name}->drop;

  if ($self->{uniqueatt}) {
    # recycle attribute names
    for (keys %{$self->{attr}}) {
      delete $self->{attr}->{$_} if $self->{attr}->{$_} eq $name;
    }
  }
  undef $self->{tables}->{$name}; # Call WAIT::Table::DESTROY here;
  1;
}


1;


=head1 AUTHOR

Ulrich Pfeifer E<lt>F<pfeifer@ls6.informatik.uni-dortmund.de>E<gt>

=cut


