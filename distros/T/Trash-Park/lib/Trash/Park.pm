###########################################
package Trash::Park;
###########################################
use strict;
use warnings;

use File::Path;
use File::Copy;
use File::Basename;
use Sysadm::Install qw(:all);
use File::Spec::Functions qw(rel2abs);
use Log::Log4perl qw(:easy);
use File::Find;
use DBI;

use vars qw($VERSION);

$VERSION = "0.03";

###########################################
sub new {
###########################################
  my($class, @options) = @_;

  my $self = {
    trash_dir => "$ENV{HOME}/.trashpark",
      # default expiration: 3 days
    expire    => 3600 * 24 * 3,
    @options
  };

  mkd "$self->{trash_dir}" 
    unless -d $self->{trash_dir};

  $self->{trash_idx_dir} = 
    "$self->{trash_dir}/index";

  bless $self, $class;

  DEBUG "Connecting to ",
        $self->{trash_idx_dir};

  $self->{dbh} = DBI->connect(
    "DBI:CSV:" .
    "f_dir=$self->{trash_idx_dir}");

  $self->_db_init();

  return $self;
}

###########################################
sub clean {
###########################################
  my($self) = @_;

  return $self->expire(-1);
}

###########################################
sub expire {
###########################################
  my($self, $timespan) = @_;

  my $sql = qq[
      DELETE FROM trash WHERE ? > move_time
  ];

  my $exptime = time() - $timespan;

  DEBUG "$sql (exptime=$exptime)";

  cd $self->{trash_idx_dir};
  $self->{dbh}->do($sql, {}, $exptime) or 
      LOGDIE "Delete failed ($sql)";
  cdback;

  return 1;
}

###########################################
sub repo {
###########################################
  my($self) = @_;

  return "$self->{trash_dir}/repo";
}

###########################################
sub trash {
###########################################
  my($self, $item) = @_;

  if(-d $item) {
    find(sub {
        $self->trash_file($_) if -f;
    }, $item);

    # Clean up symlinks, empty
    # directories etc.
    chmod 0755, $item;
    if($self->{opts}->{i}) {
      my $ans = ask "Recursively delete $item ([y]/n)?", "y";
      if($ans !~ /y/i) {
          INFO "Skipped";
          return 1;
      }
    }
    rmf $item;
  } else {
    $self->trash_file($item);
  }
}

###########################################
sub trash_file {
###########################################
  my($self, $file) = @_;

  LOGDIE "File not found: $file ($!)" unless -f $file;

      # Make it absolute
  $file = rel2abs($file);

  my $target = 
      "$self->{trash_dir}/repo$file";

  DEBUG "Moving $file to $target";

  my $target_dir = dirname($target);

  mkd($target_dir) unless -d $target_dir;

  if(-e $target) {
    my $overwrite = ask "$target " .
      "already exists. Overwrite? " .
      "[y]/n", "y";

    if($overwrite !~ /y/i) {
        WARN "Not deleting $file";
        return;
    }
  }

  my ($dev,$ino,$mode,$nlink,$uid,$gid,
      $rdev,$size,$atime,$mtime,$ctime,
      $blksize,$blocks) = stat($file);

  LOGDIE "Cannot stat $file" 
      unless defined $dev;

  if($self->{opts}->{i}) {
      my $ans = ask "Move $file to $target ([y]/n)?", "y";
      if($ans !~ /y/i) {
          INFO "Skipped";
          return 1;
      }
  }

  $self->_move_with_force($file, $target) or 
      LOGDIE "Moving $file to ",
      "$target failed ($!)";

  my $move_time = time();

  my $sql = qq[
      INSERT INTO trash
      (path, move_time, uid, mode)
      VALUES (?, $move_time, $uid, $mode)
  ];

  DEBUG "$sql (file=$file)";

  cd $self->{trash_idx_dir};
  $self->{dbh}->do($sql, {}, $file) or 
      LOGDIE "Insert failed ($sql)";
  cdback;
}

###########################################
sub history {
###########################################
  my($self, $newer_than) = @_;

  my @history = ();

  my $cond = "";

  if(defined $newer_than) {
    $cond = "WHERE move_time < $newer_than";
  }

  my $sql = qq{SELECT * from trash $cond};

  DEBUG "$sql";

  my $sth = $self->{dbh}->prepare($sql) or 
      LOGDIE $self->{dbh}->errstr();

  cd $self->{trash_idx_dir};
  $sth->execute();
  cdback;

  while(my $row = 
          $sth->fetchrow_arrayref()) {
    my($file, $move_time, 
       $uid, $mode) = @$row;
    DEBUG "Found $file, $move_time, $uid, $mode";

    push @history, Trash::Park::Element->new(
                       file      => $file,
                       move_time => $move_time,
                       uid       => $uid,
                       mode      => $mode),
  }

  return \@history;
}

###########################################
sub _move_with_force {
###########################################
  my($self, $file, $target) = @_;

  my $old_perms;
  my $dir = dirname($file);

  if($self->_movable($file, 1)) {
    # Move works fine if we don't have 
    # write permission on the file, but 
    # actually own the file. However, if 
    # the file is in a non- writable
    # directory which we own, we need to
    # change its permissions to +w first.

    if(! -w $dir) {
      DEBUG "Changing $dir 's ",
             "permissions to 0755 ",
             "temporarily";
       $old_perms = (stat($dir))[2];
         # We try, but no big deal if it
         # doesn't work, 'move' will catch
         # it.
       chmod 0755, $dir;
    }
  }

  move($file, $target) or 
      LOGDIE "Cannot move $file to ",
             "$target ($!)";

  return 1 unless $old_perms;

  DEBUG "Changing $dir 's ",
        "permissions back to ",
        sprintf("%03o", $old_perms);

  chmod $old_perms, $dir if $old_perms;
}

###########################################
sub _movable {
###########################################
  my($self, $file, $force) = @_;

  my $dir   = dirname($file);
  my $d_own = (stat($dir))[4] == $>;
  my $f_own = (stat($file))[4] == $>;
  my $f_wr  = -w $file;
  my $d_wr  = -w $dir;

  return 1 if ($f_wr or $f_own) and 
              ($d_wr or $d_own);

  return;
}

###########################################
sub _db_init {
###########################################
  my($self) = @_;

  if(! -d $self->{trash_idx_dir}) {
    mkd($self->{trash_idx_dir});
    cd $self->{trash_idx_dir};
    DEBUG "Creating db table trash ",
          "in $self->{trash_idx_dir}";

    $self->{dbh}->do(q{
      CREATE TABLE trash (
        path      char(256),  
        move_time int,
        uid       int,
        mode      int,
    )}) or die $self->{dbh}->errstr();

    cdback;
  }
}

###########################################
package Trash::Park::Element;
###########################################
use Stat::lsMode;
use base qw(Class::Accessor);

Trash::Park::Element->mk_accessors(qw(file move_time uid mode));

###########################################
sub new {
###########################################
  my($class, @options) = @_;

     # mode, move_time, user, file coming in
  my $self = { @options };

  bless $self, $class;
}

###########################################
sub as_string {
###########################################
  my($self) = @_;

  return sprintf "%s %s %10s %s",
    scalar format_mode($self->{mode} & 07777),
    nice_time($self->{move_time}),
    getpwuid($self->{uid}) || $self->{uid}, 
    $self->{file};
}

###########################################
sub nice_time {
###########################################
  my($time) = @_;

  my ($sec,$min,$hour,$mday,$mon,$year,
    $wday,$yday,$isdst) = localtime($time);

  return sprintf 
    "%d-%02d-%02d %02d:%02d:%02d",
      $year + 1900, $mon+1, $mday, $hour, 
      $min, $sec;
}


1;

__END__

=head1 NAME

Trash::Park - Store deleted files safely with querying capability

=head1 SYNOPSIS

      # Command line:
    $ trashpark some/file/somewhere.dat
    $ trashpark -l

      # API
    use Trash::Park;

    my $trasher = Trash::Park->new();

      # Move foo.dat to trash can
    $trasher->trash("foo.dat");

      # List content of trashcan
    for my $item (@{$trasher->history()}) {
        print $item->as_string(), "\n";
    }

      # Expire items with move dates older than 3 days
    $trasher->expire(3 * 24 * 3600);

=head1 DESCRIPTION

C<Trash::Park> helps removing files by hiding them in a safe location
and querying details of these parking moves.

C<Trash::Park> comes with a command line utility, C<trashpark>.

=head1 METHODS

=over 4

=item C<my $trasher = Trash::Park-E<gt>new()>

Construct a new trasher object. By default the trashing depot will be 
created under C<~/.trashpark>. An alternative location can be
specified using the C<trash_dir> parameter:

    my $trasher = Trash::Park->new(
        trash_dir => "/tmp/trashdir",
    );

The C<.trashpark> directory contains the following file structure:

    .trashpark/
        index/trash
        repo/
            some/file/somewhere/file.dat
            ...

C<index/trash> contains meta data on parked files in comma separated
format (in fact, it's a DBD::CSV database):

    # index.csv
    # file,move-date,mover,perm
    some/file/somewhere/file.dat,214289710522201,mschilli,0755

=item C<$trasher-E<gt>trash($file_or_directory)>

C<trash()> puts a file or a directory into the trash can.
Note that if you trash a directory, all files are moved to the trash
recursively. All files are stored under their full path name. However,
no hierarchical directory or link information gets preserved, only 
single (regular) files are moved, directories and symbolic link
get deleted.

=item C<$trasher-E<gt>history()>

Get a complete history of trash moves.
Returns a reference to an array of Trash::Park::Element objects,
each of which represents a trashed file:

    my $history = $trasher->history();

    for my $item (@$history) {

        print $item->file(), "\n";
        print $item->mode(), "\n";
        print $item->uid(), "\n";
        print $item->move_time(), "\n";

          # Or:
        print $item->as_string(), "\n";

          # Or, print the full path to the trashed file:
        print $trasher->repo() . $item->file(), "\n";
    }

=item C<$trasher-E<gt>expire($expire_time)>

Remove all entries from the trash can older than C<$expire_time>
in seconds.

=item C<$trasher-E<gt>clean()>

Clear out the entire trash can.

=item C<$trasher-E<gt>repo()>

Return the top directory of the the repository. This is where the
the deleted files are saved under the original path information.
If you trash a file named "/tmp/foobar", it will show up under
C<$trasher-E<gt>repo() . "/tmp/foobar">.

=back

=head1 TODO

=over 4

=item *

cd/cdback to DB dir shouldn't be necessary (check DBD::CSV).

=item *

sudo trashpark (root home dir?)

=back

=head1 LEGALESE

Copyright 2005 by Mike Schilli, 
all rights reserved. This program is free 
software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>
