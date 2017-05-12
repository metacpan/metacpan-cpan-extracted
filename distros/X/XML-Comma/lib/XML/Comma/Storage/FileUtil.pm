##
#
#    Copyright 2001, AllAfrica Global Media
#
#    This file is part of XML::Comma
#
#    XML::Comma is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    For more information about XML::Comma, point a web browser at
#    http://xml-comma.org, or read the tutorial included
#    with the XML::Comma distribution at docs/guide.html
#
##

package XML::Comma::Storage::FileUtil;

use XML::Comma::Util qw( dbg random_an_string );
use File::Path;
use File::Spec;
my $lockfilename = '.lock';

# pass this a directory and a max. dies on error. returns new id on
# success, or undef on overflow.
sub next_sequential_id {
  my ( $class, $store, $dir, $extension, $max ) = @_;
  # does directory exist -- if not, try to create it
  if  ( ! (-w $dir) ) {
    $class->make_directory ( $store, $dir, 1 );
  }
  die "bad storage directory: $dir\n"  if  ! (-d $dir and -w $dir);
  # "lock" using the wait_for_hold() method
  my $lfn = File::Spec->catfile ( $dir, $lockfilename );
  XML::Comma->lock_singlet()->wait_for_hold ( $lfn );
  # open to append (so that we can easily read and write)
  my $lock;
  if ( ! open($lock, "+< $lfn") ) {
      die "can't open lockfile '$lfn': $!\n";
  }
  # get current id
  my $id = <$lock>;
  # increment, check limit
  $id++;
  if ( $id > $max ) {
    XML::Comma->lock_singlet()->release_hold ( $lfn );
    return;
  }
  # write to file
  seek ( $lock, 0, 0 );
  print $lock "$id\n";
  # unlock
  close ( $lock );
  XML::Comma->lock_singlet()->release_hold ( $lfn );
  return $id;
}

# for symmetry and convenience, takes the same args as
# next_sequential_id 
#
# FIX: do we need to worry about locking, here, to avoid over-filling
# some subdirectory down the chain? Or does locking need to happen at
# a level above this routine?
sub current_sequential_id {
  my ( $class, $store, $dir, $extension, $max ) = @_;
  # does directory exist -- if not return undef
  return  if  ! (-r $dir);
  my $lfn = File::Spec->catfile ( $dir, $lockfilename );
  my $lock;
  if ( ! open($lock, "< $lfn") ) {
    die "can't open lockfile '$lfn': $!\n";
  }
  my $id = <$lock>;
  close  ( $lock );
  return $id;
}

# glob and take last one
#    my @files = glob ( File::Spec->catfile($dir,"*".$extension) );
#    if ( @files ) {
#      my ( $volume, $directories, $file ) = File::Spec->splitpath ( $files[-1] );
#      if ( $file ) {
#        $file =~ m:(.*)($extension):;
#        return $1;
#      } else {
#        @dirs = File::Spec->splitdir ( $directories );
#        return $dirs[-1];
#      }
#    } else {
#      return;
#    }
#  }

# returns a list of 'id-fragments' in this directory (lopping off
# extensions, etc.) acts almost exactly like current_sequential_id,
# except that it generates a list, rather than a single value. again,
# for symmetry and convenience, takes the same args as
# next_sequential_id. the $store and $max arguments are not used, and
# can be passed as an empty-string or undef.
sub directory_glob {
  my ( $class, $store, $dir, $extension, $max ) = @_;
  # does directory exist -- if not return undef
  return  if  ! (-r $dir);
  # glob
  my @munged;
  my @files = glob ( File::Spec->catfile($dir,"*".$extension) );
  foreach ( @files ) {
    my ( $volume, $directories, $file ) = File::Spec->splitpath ( $_ );
    if ( $file ) {
      $file =~ m:(.*)($extension):;
      push @munged, $1;
    } else {
      @dirs = File::Spec->splitdir ( $directories );
      push @munged, $dirs[-1];
    }
  }
  return @munged;
}

sub next_in_list {
  my ( $class, $array, $target, $direction ) = @_;
  # standard binary search
  my ( $low, $high ) = ( 0, $#$array );
  while ( $low < $high ) {
    use integer;
    my $current = ($low+$high)/2;
    if ( $array->[$current] lt $target ) {
      $low = $current + 1;
    } else {
      $high = $current;
    }
  }
  $low++  if  $array->[$low] lt $target;
  # finished search - $low now points at the target, if the target was
  # found in the array, or at the next element after where the target
  # "would have been"
  if ( $direction and $direction < 0 ) {
    return  ($low > 0) ? $array->[$low-1] : undef;
  } else {
    if ( $low > $#$array ) {
      return;
    } elsif ( $array->[$low] eq $target ) {
      return ( $low < $#$array ) ? $array->[$low+1] : undef;
    } else {
      return $array->[$low];
    }
  }
}

sub next_in_directory {
  my ( $class, $dir, $current, $extension, $direction ) = @_;
  my @globs = $class->directory_glob ( '', $dir, $extension ) or return;
  if ( $extension ) {
    $current = substr ( $current, 0, index($current,$extension) );
  }
  return $class->next_in_list ( \@globs, $current, $direction );
}

# like next_in_directory, but handles overflows up the path
sub next_in_dir_path {
  my ( $class, $base_dir, $dir, $current, $extension, $direction ) = @_;
  $direction ||= 1;
  my $next = $class->next_in_directory
    ( $dir, $current, $extension, $direction );
  return File::Spec->catfile($dir,$next.$extension)  if  defined $next;
  # if the simple thing didn't work, we need to split the directories
  # and walk up the path
  my $rel_dir = File::Spec->abs2rel ( $dir, $base_dir );
  my @up_dirs = ( $base_dir, File::Spec->splitdir($rel_dir) );
  my ( $popped, $pop_counter ) = ( pop(@up_dirs), 0 );
  while ( @up_dirs ) {
    my $n = $class->next_in_directory
      ( File::Spec->catdir(@up_dirs),
        $popped,
        '',
        $direction );
    if ( defined $n ) {
      push @up_dirs, $n;
      last;
    }
    $popped = pop(@up_dirs); $pop_counter++;
  }

  return  if  ! @up_dirs;
  my $reconstruct = File::Spec->catdir ( @up_dirs );

  foreach ( 1..$pop_counter ) {
    my @glob = $class->directory_glob ( '', $reconstruct, '' );
    $reconstruct = File::Spec->catdir
      ( $reconstruct, $glob[ ($direction > -1) ? 0 : -1 ] );
  }
  my @last = $class->directory_glob ( '', $reconstruct, $extension );
  return File::Spec->catdir
    ( $reconstruct, $last[ ($direction > -1) ? 0 : -1 ] . $extension );
}

# assumes that 'extention'ed files only exist at the end of the dir tree
sub first_or_last_down_dir_path {
  my ( $class, $path, $extension, $last ) = @_;
  return  if  ! (-d $path);
  $last ||= 0; $last = -1  if  $last;
  while ( -d $path ) {
    my @globs;
    # first try with extension
    if ( $extension ) {
      @globs = $class->directory_glob ( '', $path, $extension );
    }
    # okay, if we didn't get anything from that, try un-extensioned
    if ( ! @globs ) {
      @globs = $class->directory_glob ( '', $path, '' );
    }
    # return undef if we didn't find anything, here (anomalous case)
    if ( ! @globs ) {
      return;
    }
    $path = File::Spec->catdir ( $path, $globs[$last] );
  }
  return $path . $extension || '';
}

# pass this a store object, a directory and a boolean make_lockfile
# flag. creates the directory, if necessary. creates the lockfile, if
# it creates the directory, and if that's requested. sets permissions
# on anything it creates.
sub make_directory {
  my ( $class, $store, $path, $make_lock ) = @_;
  return if ( -w $path );
  my @createds = mkpath ( $path, 0, 0777 );
  die "could not make directory '$path': $!\n"  unless  @createds;
  # XML::Comma::Log->warn ( "created: " . join("\n", @createds) );
  chmod $store->dir_permissions(), @createds;
  if ( $make_lock ) {
    my $lfn = File::Spec->catfile ( $path, $lockfilename );
    open ( my $lock, ">$lfn" ) ||
      die "could not create lockfile '$lfn': $!\n"; 
    close ( $lock );
    chmod $store->file_permissions(), $lfn;
  }
}


sub read_file {
  my ( $class, $location ) = @_;
  open ( my $file, "<$location" ) ||
    die "could not open file '$location':$!\n";
  local $/ = undef;
  my $string = <$file>;
  close ( $file );
  return $string;
}

sub write_file {
  my ( $class, $location, $block, $permissions ) = @_;
  open ( my $file, ">$location" ) ||
    die "could not open file '$location': $!\n";
  print $file $block;
  close $file;
  chmod $permissions, $location;
}


sub create_randnamed_file {
  my ( $class, $dir, $stub, $extension, $permissions ) = @_;
  # try to create a new filename, but make sure to check that it's not
  # already in use
  my $filename;
  while ( 1 ) {
    $filename = File::Spec->catfile
      ( $dir,
        ($stub||'') . random_an_string(8) . ($extension||'') );
    last  if  ! (-r $filename);
  }
  open ( my $file, ">$filename" ) || die "couldn't create '$filename': $!\n";
  close ( $file );
  chmod $permissions, $filename;
  return $filename;
}

1;

