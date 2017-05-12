package inc::MBwishlist::trees;

# Copyright (C) 2007, by Eric Wilhelm
# License: perl

# filetree wishlist items

use warnings;
use strict;
use Carp;

=head1 Methods


=head2 want_path

  $self->want_path($dirname, clean => 1);

=cut

sub want_path {
  my $self = shift;
  my ($path, %opts) = @_;

  if((ref($path)||'') eq 'ARRAY') {
    $path = File::Spec->catdir(@$path);
  }

  require File::Path;

  if((-e $path) and $opts{clean}) {
    my $dir = $path;
    $dir =~ s#/+$##; # Win32 nit
    # ugh, mkpath dies, but rmtree returns zero?
    File::Path::rmtree($dir) or die "cannot rmtree('$dir')";
  }

  (-e $path) and return;

  File::Path::mkpath($path);
} # end subroutine want_path definition
########################################################################


=head2 copy_files

  $self->copy_files($file, $destfile, %opts);

  $self->copy_files([@files], $destdir, %opts);

=over

=item verbose

log_info() about which files are being copied.

=item flatten

=back

=cut

sub copy_files {
  my $self = shift;
  my @files = (shift(@_));
  my $dest = shift(@_);
  my %opts = @_;
  # copy files to directory
  my $dest_dir;
  if((ref($files[0]) ||'') eq 'ARRAY') {
    @files = @{$files[0]};
    $dest_dir = $dest;
  }

  $opts{verbose} = !$self->quiet unless exists $opts{verbose};
  
  my @copied;
  foreach my $file (@files) {
    if(defined $dest_dir) {
      $dest = File::Spec->catfile(
        $dest_dir,
        ($opts{flatten} ? File::Basename::basename($file) : $file )
      );
    }
  
    if($self->up_to_date($file, $dest)) { # Already fresh
      $self->log_info("Skip (up-to-date) $dest\n") if($opts{verbose});
      next;
    }

    # hmm, some way to make the log wrap more neatly?
    $self->log_info("Copy $file\n  -> $dest\n") if($opts{verbose});
    $self->_copy_file($file, $dest, %opts);
    push(@copied, $dest);
  
  }
  return(@copied);
} # end subroutine copy_files definition
########################################################################

=head2 _copy_file

  $self->_copy_file($file, $destfile, %opts);

=cut

sub _copy_file {
  my $self = shift;
  my ($file, $dest, %opts) = @_;

  if(-e $dest) { # delete destination if exists
    unlink($dest) or die "cannot remove '$dest' $!";
  }

  # Create parent directories
  File::Path::mkpath(File::Basename::dirname($dest), 0, oct(777));
  
  # would we need the os2 syscopy overwrite if we already did unlink?
  File::Copy::copy($file, $dest) or
    die "Can't copy('$file', '$dest'): $!";

  # TODO mode as an option?
  # mode is read-only + (executable if source is executable)
  #my $mode = oct(444) | ( $self->is_executable($file) ? oct(111) : 0 );
  #chmod( $mode, $dest );
} # end subroutine _copy_file definition
########################################################################

1;
# vim:ts=2:sw=2:et:sta
