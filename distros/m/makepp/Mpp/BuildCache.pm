# $Id: BuildCache.pm,v 1.53 2016/09/12 20:33:41 pfeiffer Exp $
#
# Possible improvements:
#
# o We need to handle .o files properly, doing a string substitution on the
#   path.  Maybe .a files too?	I don't know.  Do we really?  This would
#   eliminate the considerable space savings possible with links.  The user
#   should get to decide if he wants this.
# o .lo files and .la files should never be exported to a cache.
# o Why do we write out a separate build_info file with a recalculated
#   signature.  When is it expected to differ, and how can we generalize this,
#   so that we can link the existing build_info file to and from the cache?
#

=head1 NAME

Mpp::BuildCache -- subroutines for handling the makepp build cache

=head1 SYNOPSIS

    $bc = new Mpp::BuildCache("/path/to/build_cache", $create_flags_hash);
    $bc->cache_file($file_info_of_file_to_archive, $file_key);
    $bc_entry = $bc->lookup_file($file_key);

    $build_info = $bc_entry->build_info;
    $bc_entry->copy_from_cache($output_finfo);

=head1 The Mpp::BuildCache package

The Mpp::BuildCache is a cache system that makepp uses to store the results
of compilation so that they can be used later.	If a file with the same
input signature is needed, it can be fetched again immediately instead
of rebuilt.  This can cut down compilation time significantly in a
number of cases.  For example:

=over 4

=item *

Suppose you compile all files in your program for optimization.	 Then
you find a bug and you recompile for debug.  Then you fix the bug and
you want to recompile for optimization.	 Most of the source files
haven't changed, but you just wiped out all the F<.o> files when you
turned off optimization, so without a build cache you'd have to
recompile everything.  With the build cache, an extra copy of the file
was made and stored in the cache, so it can be fetched again, instead of
recompiling.

=item *

Suppose you have checked out several copies of your sources into several
different directory trees, and have made small modifications to each
tree.  Now most of the files are the same across the directory trees, so
when you compile another directory tree, it can fetch most of the
compiled files from the build cache created when you built the first
directory tree.

=item *

Suppose you have 5 developers all working on approximately the same set
of sources.  Once again, most of their files will be identical.	 If one
person compiles a file, the remaining developers can fetch the file from
the build cache rather than compiling it for themselves.

=back

=head2 Cache format

The cache is actually a directory hierarchy where the filename of each
file is the build cache key.  For example, if the build cache key of a
file is C<0123456789abcdef>, the actual file name might be
F<01/234/56789abcdef_xyz.o>.  On some file systems, performance suffers
if there are too many files per directory, so Mpp::BuildCache can
automatically break them up into directories as shown.

It remembers the key that it was given, which is presumably some sort of hash
of all the inputs that went into building the file.  Mpp::BuildCache does remember
the build info structure for the file.  This is intended to help in the very
rare case where there is a collision in the key, and several files have the
same key.  Mpp::BuildCache cannot store multiple files with the same key, but by
storing the build information it is at least possible to determine that the
given file is the wrong file.

=head2 Use of Mpp::File

We do not use the Mpp::File class to store information about the files in the
build cache.  The reason is that we don't want to waste the memory storing all
the results.  Typically things are looked up once in the build cache and never
examined again, so it's a waste of memory to build up the Mpp::File structures
for them.  For this reason, for any files in the build cache directories, we
do the stat and other operations directly instead of calling the Mpp::File
subroutines.

We do use the Mpp::File subroutines for files stored elsewhere, however.

=cut

package Mpp::BuildCache;
use strict;
use Mpp::File;
use Mpp::FileOpt;
use Mpp::Cmds ();
use Mpp::Signature::md5;
use Sys::Hostname;
use POSIX qw(:errno_h S_ISREG);

BEGIN {
  eval { $_ = ESTALE };		# Not defined on Win ActiveState.
  if( $@ ) {
    no warnings;
    *ESTALE = sub() { -1 };
  }
}


our $force_copy;		# Don't link from BC.
our $global;			# Build cache specified on command line or with global keyword.
our $md5check;			# Check the MD5 signature of entries
our $options_file = 'build_cache_options.pl';
our $error_hook;
our $hits = 0;			# Number of the files changed that were imported from a build cache.

=head2 new Mpp::BuildCache("/path/to/cache");

Opens an existing build cache.

=cut

our $used;			# Is a BC in use?

sub new {
  my( $class, $build_cache_dir, $self ) = @_;

  $build_cache_dir = file_info $build_cache_dir;
  my $absolute_build_cache_dir = absolute_filename $build_cache_dir;

  $self ||= do "$absolute_build_cache_dir/$options_file";
				# Load the creation options.
  ref $self or
    die "Can't load `$absolute_build_cache_dir/$options_file': $!\n";

  @$self{qw(DEV ACCESS_PERMISSIONS)} =
    @{stat_array $build_cache_dir}[Mpp::File::STAT_DEV, Mpp::File::STAT_MODE];
  $self->{ACCESS_PERMISSIONS} &= 0777;
				# Use the current directory protections as the
				# proper mask.
  $self->{MKDIR_OPT} = sprintf '-pm%o', $self->{ACCESS_PERMISSIONS};

  $self->{DIRNAME} = $absolute_build_cache_dir;

  $used = 1;
  bless $self, $class;
}

=head2 cache_file

   $build_cache->cache_file($file_info, $file_key, $build_info);

Copies or links the file into the build cache with the given file key.	Also
the build information is stored alongside the file so that when it is
retrieved we can verify that in fact it is exactly what we want.

Returns a true value if the operation succeeded, false if any part failed.  If
anything failed in updating the build cache, the cache is cleaned up and left
in a consistent state.

=cut

# A string that cannot possibly prefix a build cache key:
our $incoming_subdir = 'incoming.dir';

# From "man 2 creat" on Linux 2.4.21:
# O_EXCL is broken on NFS file systems, programs which rely on it for
# performing lock-ing tasks will contain a race condition.  The solution for
# performing atomic file locking using a lockfile is to create a unique file
# on the same fs (e.g., incorporating hostname and pid), use link(2) to make
# a link to the lockfile.  If link() returns 0, the lock is successful.
# Otherwise, use stat(2) on the unique file to check if its link count has
# increased to 2, in which case the lock is also successful.
#
# $! will be set appropriately if it returns false; it may be altered even
# if it returns true.
sub link_over_nfs {
  # $old has to be a file that nobody else might be touching.
  #my ($old, $new) = @_;
  link $_[0], $_[1] or ((stat $_[0])[3] || 0) > 1;
}

my $unique_suffix;

# Because there is a race in aging between the time that the age of a file is
# sampled and when it is deleted, it is possible for a brand new file to get
# aged out if it replaces a file that is old enough to get aged.
# TBD: If this happens, we could probably recover seamlessly by retrying
# exactly once, but it's not clear whether it's worthwhile to uglify the code
# in order to do that.  The code is going to be hard enough to maintain as it
# is, because it's very hard to test the race conditions.
my $target_aged = 'temporary copy of target file was deleted, possibly by aging (OK)';
my $build_info_aged = 'temporary copy of build info was deleted, possibly by aging (OK)';

sub cache_file {
  my( $self, $input_finfo, $cache_fname, $reason ) = @_; # Name the arguments.
				# 4th arg atime, only for mppbcc, accessed below.
  $reason or die;

  my $input_filename = absolute_filename_nolink $input_finfo;
  my $orig_prot = (lstat_array $input_finfo)->[Mpp::File::STAT_MODE];
  return 1			# Succeed without doing anything
    unless S_ISREG $orig_prot;	# if not a regular file?

  # TBD: Perhaps we ought to succeed without doing anything if the entry
  # is already in the cache.  This reduces the likelihood of thrashing, but
  # perhaps strange things could happen if multiple targets of a rule weren't
  # actually built together.  Either way, you run the risk of leaving behind
  # a build info file without an MD5_SUM, which makes --md5-check-bc unhappy.

  if( $cache_fname !~ /^\// ) {	# Not called from Mpp::BuildCacheControl?
    substr $cache_fname, $_, 0, '/' for reverse @{$self->{SUBDIR_CHARS}};
    $cache_fname = $self->{DIRNAME} . '/' . $cache_fname;
				# Get the name of the file to create.
  }

# Build info is currently stored in a file whose name is the same as the main
# file, but with ".makepp" before the last directory and .mk as a suffix.
# E.g., if the filename is 01/234/56789abcdef, then the build info is
# stored in 01/234/.makepp/56789abcdef.mk.

  my $build_info_fname = $cache_fname;
  $build_info_fname =~ s@/([^/]+)$@/$Mpp::File::build_info_subdir@;
  unless( -d $build_info_fname or
    eval { Mpp::Cmds::c_mkdir $self->{MKDIR_OPT}, $build_info_fname } )
  {
    $$reason = ($! == ENOENT || $! == ESTALE) ? "$@ -- possibly due to aging (OK)" : $@;
    return;
  }				# Make sure .makepp directory and parents exists.

  $build_info_fname .= "/$1.mk";

# Before writing to the final location, we write to a temp location, so that
# the writes are atomic.  If we're linking, then we don't need to create a
# copy of it, because it gets linked in anyway, but we always create a temp
# file for the build info.  The temp paths are currently incoming.dir/$host.$pid
# and incoming.dir/$host.$pid.mk.

  # This is a string that it unique over all currently active processes that
  # might be able to write to the build cache, and it can't end in '.mk'.
  $unique_suffix ||= hostname . '_' . $$;
  my $temp_cache_fname = "$self->{DIRNAME}/$incoming_subdir/$unique_suffix";
  my $temp_build_info_fname = $temp_cache_fname . '.mk';

  my $build_info = $input_finfo->{BUILD_INFO}; # Get the build info hash.
  $build_info ||= Mpp::File::load_build_info_file($input_finfo);
				# Load it from disk if we didn't have it.
  $build_info or die "internal error: file in build cache (" . absolute_filename( $input_finfo ) .
    ") is missing build info\n";

  local $build_info->{SIGNATURE};
#
# Calculate the protections we want to be on the file.
# We make the world and group protections be the user protection anded
# with the build cache directory protections.
#

  my $file_prot = (0111 * int $orig_prot % 01000 / 0100) & $self->{ACCESS_PERMISSIONS};
				# Make the group & other protections the same
				# as the user protections.
				# Remove protections not granted by the
				# build cache directory.

#
# If the build cache is not on the same file system as the file, then
# copy the file.  If it is on the same file system, then make a hard link,
# since that is faster and uses almost no disk space.
#
  my $dev = (stat_array $input_finfo->{'..'})->[Mpp::File::STAT_DEV];
  my( $size, $mtime ) =
    @{Mpp::File::lstat_array $input_finfo}[Mpp::File::STAT_SIZE, Mpp::File::STAT_MTIME];
  # If it's on the same filesystem, then link; otherwise, copy.
  my $target_src;
  my @files_to_unlink;
  my $result = eval {
    my $linking;
    my $target_prot = $file_prot;
    if( $dev == $self->{DEV} && !$force_copy ) {
      $linking = 1;
      $target_src = $input_filename;
      $target_prot &= ~0222;	# Make it read only, so that no one can
				# accidentally corrupt the build cache copy.
      Mpp::File::set_build_info_string( $input_finfo, 'LINKED_TO_CACHE', 1 );
				# Remember that it's linked to the build
				# cache, so we need to delete it before
				# allowing it to be changed.
      Mpp::Signature::md5::signature $input_finfo # Make sure that $build_info->{MD5_SUM} is set.
	if defined $md5check;
    } else {			# Hard link not possible on different dev
      my $md5 = Digest::MD5->new
	if defined $md5check && !$build_info->{MD5_SUM};
      $target_src = $temp_cache_fname;
      push @files_to_unlink, $temp_cache_fname;
      # Need to unlink first, in case there are other links to it and/or
      # the current permissions don't allow writing.
      unless( unlink $temp_cache_fname or $! == ENOENT ) {
	$$reason = "unlink $temp_cache_fname: $!";
	return;
      }
      unless( ($size) = copy_check_md5($input_filename, $temp_cache_fname, $md5) ) {
	$$reason = ($! == ESTALE) ? $target_aged : "write $temp_cache_fname: $!";
	return;
      }
      unless( utime $_[4] || time, $mtime, $temp_cache_fname or # Try to copy over mtime.
	# NOTE: We can't get the mtime of $temp_cache_fname from the stat that
	# we do on the destination filehandle at the end of the copy, because
	# that mtime could be based on the local clock instead of the clock of
	# the machine on which the file is stored.
	$mtime = (stat $temp_cache_fname)[9] )
      {
	$$reason = ($! == ENOENT || $! == ESTALE) ? $target_aged : "stat $temp_cache_fname: $!";
	return;
      }
      $build_info->{MD5_SUM} = $md5->b64digest if $md5;
    }
    $build_info->{SIGNATURE} = $mtime . ',' . $size;
				  # Be sure we store a signature.

    push @files_to_unlink, $temp_build_info_fname;
    unless( unlink $temp_build_info_fname or $! == ENOENT ) {
      $$reason = "unlink $temp_build_info_fname: $!";
      return;
    }
    unless( Mpp::File::write_build_info_file $temp_build_info_fname, $build_info ) {
      $$reason = ($! == ESTALE) ? $build_info_aged : "write $temp_build_info_fname: $!";
      return;
    }
    unless( chmod $file_prot, $temp_build_info_fname ) {
      $$reason = ($! == ENOENT || $! == ESTALE) ? $build_info_aged : "chmod $temp_build_info_fname: $!";
      return;
    }

    # We can leave garbage in the incoming directory on an interrupt, but we
    # need to make sure that we don't corrupt to the cache entries if we can
    # possibly help it.
    my @files_to_unlink;
    $Mpp::critical_sections++;
    my $result = eval {
      # NOTE: We try to make the build info file live longer than the target
      # file, because we don't like to fail to import just because the build
      # info file isn't there yet.  However, this isn't guaranteed over NFS.
      for($cache_fname, $build_info_fname) {
	unless( unlink $_ or $! == ENOENT or $! == ESTALE ) {
	  $$reason = "unlink $_: $!";
	  return;
	}
      }

      unless( link_over_nfs $temp_build_info_fname, $build_info_fname ) {
	$$reason =
	  ($! == EEXIST) ? 'build info file was already there, possibly created by another party (OK)' :
	  ($! == ENOENT || $! == ESTALE) ? $build_info_aged :
	  # NOTE: This might instead mean that the parent directory of
	  # $build_info_fname was aged, so the message is a bit misleading.
	  "link $temp_build_info_fname to $build_info_fname: $!";
	return;
      }
      push @files_to_unlink, $build_info_fname;

      unless( chmod $target_prot, $target_src ) {
	$$reason = (!$linking && ($! == ENOENT || $! == ESTALE)) ? $target_aged : "chmod $target_src: $!";
	return;
      }
      unless( link_over_nfs $target_src, $cache_fname ) {
	$$reason =
	  ($! == EEXIST) ? "target file was already there, possibly created by another party after our build info was immediately aged (OK)" :
	  ($! == ENOENT || $! == ESTALE) ? $target_aged :
	  # NOTE: This might instead mean that the parent directory of
	  # $cache_fname was aged, so the message is a bit misleading.
	  "link $target_src to $cache_fname: $!";
	return;
      }
      #push @files_to_unlink, $cache_fname; # Currently redundant

      @files_to_unlink = ();	# Commit to leave the entry in the cache
      Mpp::log $linking ? 'BC_LINK' : 'BC_EXPORT' => $input_finfo, $cache_fname
	if $Mpp::log_level;
      1;
    };
    my $error = $@;
    eval { unlink @files_to_unlink }; # Ignore failure here
    --$Mpp::critical_sections;
    Mpp::propagate_pending_signals();
    die $error if $error;
    $result
  };
  my $error = $@;
  eval { unlink @files_to_unlink }; # Ignore failure here
  die $error if $error;
  $result;
}

=head2 lookup_file

  $bc_entry = $bc->lookup_file($file_key);

Lookup a file by its cache key.	 Returns undef if the file does not exist in
the cache.  Returns a Mpp::BuildCache::Entry structure if it does exist.  You can
query the Mpp::BuildCache::Entry structure to see what the build info is, or to
copy the file into the current directory.

=cut

sub lookup_file {
  my( $self, $cache_fname ) = @_;

  substr $cache_fname, $_, 0, '/' for reverse @{$self->{SUBDIR_CHARS}};
  $cache_fname = $self->{DIRNAME} . '/' . $cache_fname;
				# Get the file name we're looking for.

  return if exists $self->{SYMLINK} && !-e $cache_fname; # Stale link?

  my $dev = (lstat $cache_fname)[0]; # 0 == real STAT_DEV.  Does the file exist?

  defined $dev and		# Quit if file does not exist.
    bless { FILENAME => $cache_fname, DEV => $dev }, 'Mpp::BuildCache::Entry';
}

=head2 copy_check_md5

    my $md5;
    my $result = copy_check_md5("in", "out", \$md5, $setmode);

Assuming that the input file is atomically generated and removed,
copy_check_md5 will either copy the file as-is or return undef with $! set,
even if the input file is unlinked and/or re-created concurrently,
even over NFS.
Mode bits are copied as well if $mode is true.
Copy_check_md5 will instead die if it detects that the input file is not
being written atomically, or if it detects something that it can't explain.

If a Digest object is provided as a third argument, then the file's content
is added to it.  It may be modified even if the copy fails.
See L<Digest(3pm)>.

A successful copy will return a 2-element array consisting of the size and
modification time of the input file.

If the return value is an empty array, then $! is set as follows:

=over 2

=item ENOENT

The input file was removed while it was being read.

=item ESTALE

The output file was removed while it was being written,
or the directory containing the input file was removed.

=item Others

Many other errors are possible, such as EACCES, EINTR, EIO, EISDIR, ENFILE
EMFILE, EFBIG, ENOSPC, EROFS, EPIPE, ENAMETOOLONG, ENOSTR.
In most cases, these are non-transient conditions that require manual
intervention, and should therefore cause the program to terminate.

=back

=cut

our $Too_Big = 1024 * 1024 * 2;

sub copy_check_md5 {
  my ($in, $out, $md5, $setmode) = @_;

  open(my $fin, '<', $in) or return;

  # NOTE: This works only because we stat the filehandle instead of the
  # file.  The file could have been unlinked and re-created since we opened
  # it for read.
  my ($ino, $mode, $size, $mtime) = do { no warnings; (stat $fin)[1,2,7,9] };
  defined $size or return;

  open my $fout, '>', $out or return;

  # Adapted from File::Copy:
  my $bufsize = $size < 512 ? 1024 : $size > $Too_Big ? $Too_Big : $size;
  my $buf;
  for (;;) {
    my ($r, $w, $t);
    defined( $r = sysread $fin, $buf, $bufsize ) or return;
    last unless $r;
    $md5->add($buf) if $md5;
    for( $w = 0; $w < $r; $w += $t ) {
      $t = syswrite $fout, $buf, $r - $w, $w or return;
    }
  }


  my $size3;
  {
    no warnings 'unopened';
    $size3 = (stat $fout)[7];
  }
  close $fout or return;

  # Now, if the file is still there, report if it changed.  This is how
  # we'll know if somebody isn't following the rules.
  my( $ino2, $size2, $mtime2 ) = do { no warnings; (stat $fin)[1,7,9] };
  die "$in changed during copying (created non-atomically)"
    if $ino2 && ($ino2 != $ino || $size2 != $size || $mtime2 != $mtime);

  close $fin;

  # I don't know of any way that this could happen, but we'll check here
  # just so we know for sure that it didn't happen.
  die "Copying to $out: size $size3 doesn't match source size $size"
    unless defined($size3) && $size3 == $size;

  chmod($mode & 0777, $out) or die "chmod $out: $!" if $setmode;

  ($size, $mtime)
}

sub get {
  my( $rule, $targets ) = @_;
  my $rebuild_needed;
 import_loop:
  while( @$targets ) {
    my( $target_src, $target_dst ) = splice @$targets, 0, 2;
    unless( $target_src->copy_from_cache( $target_dst, $rule, \my $reason )) {
      my $msg = 'Copy of ' . Mpp::BuildCache::Entry::absolute_filename( $target_src ) . ' into ' .
	absolute_filename( $target_dst ) . " failed because $reason\n";
      &$error_hook( $msg ) if $error_hook;
      if( !$Mpp::stop_on_race && $msg =~ s/ \(OK\)$//m ) {
	warn "info: ${msg}This might just mean that the build cache file was in an inconsistent state due to concurrent access, so we'll rebuild instead.\n";
	$rebuild_needed = 1;
	last import_loop;
      } else {
	# If something happens that we can't explain as a transient phenomenon,
	# then we *don't* want to just fall back to rebuilding, because the user
	# probably wants to know that the build cache isn't operating normally.
	die $msg;
      }
    }

    Mpp::log BC_COPY => $target_dst, $target_src
      if $Mpp::log_level;
    ++$hits;
    print "$Mpp::progname: Imported `", absolute_filename( $target_dst ), "' from build cache\n";
  }
  $rebuild_needed;
}

# For Mpp::Rule

#
# Set the build cache for this rule.
#
sub set {
  $_[0]{BUILD_CACHE} = $_[1];
}

#
# Return a build cache associated with this rule, if any.
#
# A build cache may be specified for each rule, or for a whole makefile,
# or for all makefiles (on the command line).
#
sub Mpp::Rule::build_cache {
  exists $_[0]{BUILD_CACHE} ? $_[0]{BUILD_CACHE} :
  exists $_[0]{MAKEFILE}{BUILD_CACHE} ? $_[0]{MAKEFILE}{BUILD_CACHE} :
  $global;
}

###############################################################################
#
# Subroutines in the Mpp::BuildCache::Entry package:
#
package Mpp::BuildCache::Entry;

=head1 The Mpp::BuildCache::Entry package

A Mpp::BuildCache::Entry is an object returned by BuildCache::lookup_file.  You can
do the following with the object:

=head2 absolute_filename

   $bc_entry->absolute_filename

Returns the name of the file in the build cache.

=cut

sub absolute_filename { $_[0]->{FILENAME} }
*name = \&absolute_filename;

=head2 copy_from_cache

  $bc_entry->copy_from_cache($output_finfo, $rule, \$reason);

Replaces the file in $output_finfo with the file from the cache, and updates
all the Mpp::File data structures to reflect this change.
The build info signature is checked against the target file in the cache,
and if $md5check is set, then the MD5 checksum is also verified.

Returns true if the file was successfully restored from the cache, false if
not.  (I B<think> the only reason it wouldn't be successfully restored is that
someone deleted the file from cache between the time it was returned from
lookup_file and the time copy_from_cache is invoked.)
If it returns false, then $reason is set to a string that explains why.
If $reason ends with '(OK)', then the failure could have been due to legitimate
concurrent access of the build cache.
If it fails, then the output target is unlinked.

=cut

sub fix_ok {
# If we detect that a target and its build info don't go together,
# then we are empowered to nuke them even in --nopopulate_bc mode. We do this
# only if the target is at least 10 minutes old, because otherwise someone
# might always nuke files just as they get created.  It's still possible
# (although unlikely) for a file to be removed immediately after it replaces
# a file that had been in the cache for a long time, but that's OK.
  #my ($self) = @_;
  # Re-stat, because this is the last chance we have to notice an update.
  my $mtime = (stat $_[0]{FILENAME})[9]; # 9 == real STAT_MTIME
  $mtime && time - $mtime > 600
}

sub copy_from_cache {
  my( $self, $output_finfo, $rule, $reason ) = @_;
  $reason || die;

  Mpp::File::unlink $output_finfo;	    # Get rid of anything that's there currently.
  my $link_to_build_cache = 0;

#
# Read in the build info:
#
  my $build_info_fname =
    my $cache_fname = $self->{FILENAME};
  $build_info_fname =~ s@/([^/]+)$@/$Mpp::File::build_info_subdir/$1.mk@;
  open my $fh, '<:crlf', $build_info_fname;
  unless( $fh ) {
    if($! == POSIX::ENOENT || $! == Mpp::BuildCache::ESTALE) {
      $$reason = 'the build info file is missing (OK)';
      unlink $cache_fname if &fix_ok;
    } else {
      $$reason = "read $build_info_fname: $!";
    }
    return;
  }
  my $build_info = Mpp::File::grok_build_info_file $fh;

  unless( $build_info ) {
    $$reason = 'corrupt build info file, possibly deleted while reading (OK)';
    unlink $cache_fname, $build_info_fname if &fix_ok;
    return;
  } # Something's wrong with this file.

  # If the target directory doesn't already exist, then we assume that the
  # rule would have created it.
  Mpp::Cmds::c_mkdir '-p', Mpp::File::absolute_filename_nolink $output_finfo->{'..'};

# It's a real file.  If it's on the same file system, make it an extra hard
# link since that's faster and takes up almost no disk space.  Otherwise, copy the
# file.
# We have to be very careful not to import a target without its build info
# file, even if an interrupt arrives, because then it will look like a source
# file, and then --rm-stale might not work.
#
  $Mpp::critical_sections++;
  my $result = eval {
    my $output_fname = Mpp::File::absolute_filename_nolink $output_finfo;
    my $md5 = Digest::MD5->new if defined $md5check;
    my ($size, $mtime);
    # TBD: Maybe we shouldn't fall back to copying if link fails.  There
    # should be a warning at least.
    if( $self->{DEV} == ((Mpp::File::stat_array $output_finfo->{'..'})->[Mpp::File::STAT_DEV] || 0)
	&& !$force_copy && # Same file system?
	link($self->{FILENAME}, $output_fname)) {
      # Re-stat in case it changed since we looked it up.
      ($size, $mtime) = (stat $output_fname)[7, 9];
      unless( defined $size ) {
	$$reason = "cached file $self->{FILENAME} became a stale link after we looked it up (OK)";
	unlink $output_fname;
	unlink $cache_fname, $build_info_fname if &fix_ok;
	return;
      }
      if($md5 && open(my $fh, '<', $self->{FILENAME})) {
	$md5->addfile($fh);
      }
      $link_to_build_cache = 1;	# Remember that we did the link.
    } elsif( !( ($size, $mtime) = copy_check_md5( $self->{FILENAME}, $output_fname, $md5, 1) )) {
				  # Link failed for some reason:
      # NOTE: Several versions of the Linux NFS client can return EIO instead
      # of ESTALE or ENOENT on a read after the file has been unlinked.  If
      # this is a real hardware error, then we hope that it also shows up on
      # some other operation where it can't happen legitimately.
      $$reason = ($!==POSIX::ENOENT || $!==Mpp::BuildCache::ESTALE || $!==POSIX::EIO) ? 'file was just deleted (OK)' : "copy $self->{FILENAME} to $output_fname: $!";
      return;
    }
    my $signature = $mtime . ',' . $size;
                                    # Form the expected signature.
    my $build_info_sig = $build_info->{SIGNATURE} || '';
    if ($signature ne $build_info_sig) {
                                    # File was corrupted in the build cache.
                                    # Get rid of it, and don't import it.
      $$reason = "cached build info file $build_info_sig mismatches cached target file $signature (OK)";
      unlink $cache_fname, $build_info_fname if &fix_ok;
      return;
    }
    if($md5) {
      # Digest key and format needs to match Mpp::Signature::md5
      my $md5sum = $build_info->{MD5_SUM};
      unless( $md5sum ) {
        $$reason = 'no stored MD5 in cached build info file (OK)';
        return;
      }
      my $target_md5 = $md5->b64digest;
      if( $target_md5 ne $md5sum ) {
	$$reason = "cached target file $target_md5 mismatches build info MD5_SUM $md5sum (OK)";
        unlink $cache_fname, $build_info_fname if &fix_ok;
	return;
      }
    }

#
# Now restore the build info:
#
    Mpp::File::may_have_changed( $output_finfo );
    $output_finfo->{BUILD_INFO} = $build_info;
    Mpp::File::set_build_info_string( $output_finfo, 'LINKED_TO_CACHE', $link_to_build_cache);
				  # Remember if it's a link to something in
				  # the build cache.

    # Need to match build info signature to file signature, or else build info
    # will be ignored.  This has the drawback that targets that don't use an MD5
    # signature for this file as a dependency will think it has changed.
    Mpp::File::set_build_info_string( $output_finfo, 'SIGNATURE', Mpp::File::signature( $output_finfo ));

    # Update the DEP_SIGS that aren't MD5-based, so that the target will still
    # look up-to-date the next time we run makepp.
    $rule->build_check_method->update_dep_sigs($output_finfo, $rule);

    Mpp::File::mark_build_info_for_update( $output_finfo );
    &Mpp::File::update_build_infos; # Write out the build cache right now.
    1				# No error.
  };
  my $error = $@;
  $result or eval { Mpp::File::unlink( $output_finfo ) }; # Clean up on error
  $Mpp::critical_sections--;
  Mpp::propagate_pending_signals();
  die $error if $error;

  # TBD: Some filesystems don't update atime on file access, for performance
  # and/or power reasons.  If the build cache is on such a filesystem, then
  # files will get aged based on their creation time, which is bad because
  # frequently used files will be aged just as quickly as files that are never
  # used.  To fix that, I propose that the build_cache_options.pl file define
  # a new 'UTIME_ON_IMPORT' parameter, and if that is set, then we should
  # use utime(2) here to update the atime and set mtime to the same value
  # that we previously sampled.  (Gary Holt has tried this on such a
  # filesystem, and he reports that it works.)  This is likely to fail because
  # of permissions, in which case we can copy the target to a unique
  # filename that we own, then rename that file back to the target, and
  # finally call utime to update atime and reset the old mtime.  This isn't
  # implemented because nobody needs it yet (and therefore nobody would be
  # testing it).  When this is implemented, the check in copy_check_md5 for
  # constant mtime needs to be downgraded from a die to a failure, because
  # the utime operation introduces legitimate races.

  $result
}

*copy_check_md5 = \&Mpp::BuildCache::copy_check_md5;

1;
