package test_inc::anno_copy;

use warnings;
use strict;
use Carp;

use File::Copy ();

BEGIN { require Exporter; *import = \&Exporter::import; }

our @EXPORT = qw(
  anno_copy
);

use dtRdr::Annotation::IO;

sub anno_copy {
  my ($source, $dest_dir, $cond) = @_;

  my $in_io = dtRdr::Annotation::IO->new(uri => $source);
  foreach my $item ($in_io->items) {
    if($cond) {
      local $_ = $item;
      $cond->($item) or next;
    }
    File::Copy::copy($source . $item->{id} . '.yml', $dest_dir) or
      croak "copy anno '$item->{id}' from '$source' failed $!";
  }
}

1;
# vim:ts=2:sw=2:et:sta
