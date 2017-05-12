package test_inc::tempdir;

use warnings;
use strict;

BEGIN {
  require Exporter;
  *import = \&Exporter::import;
}

our @EXPORT = qw(
  wants
);

use File::Path ();

my @to_cleanup;
sub wants ($) {
  my ($storage_dir) = @_;

  $storage_dir =~ s#/+$##;

  # also cleanup leftovers from runs where DBG_STORAGE was unset
  File::Path::rmtree($storage_dir);

  # TODO no auto-naming on windows?
  # (Parallelized tests probably won't work there anyway.)
  $storage_dir .= $$ unless($ENV{DBG_STORAGE});
  $storage_dir .= '/';

  File::Path::rmtree($storage_dir);
  (-d $storage_dir) and die "oops -- cannot cleanup $storage_dir";
  File::Path::mkpath($storage_dir);
  (-d $storage_dir) or die "oops -- cannot create $storage_dir";
  push(@to_cleanup, $storage_dir);
  return($storage_dir);
}
END {
  foreach my $dir (@to_cleanup) {
    File::Path::rmtree($dir) unless($ENV{DBG_STORAGE} or
      ($^O eq 'MSWin32') # uh? Why is windows so broken!
    );
  }
}

# vim:ts=2:sw=2:et:sta
1;
