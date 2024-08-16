package YATT::Lite::Util::File;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use YATT::Lite::Util ();
use File::Basename qw(dirname);
use File::Path qw(make_path);
use Time::HiRes qw/usleep/;
use File::stat;

sub mkfile {
  my ($pack) = shift;
  my @slept;
  while (my ($fn, $content) = splice @_, 0, 2) {
    ($fn, my @iolayer) = ref $fn ? @$fn : ($fn);
    unless (-d (my $dir = dirname($fn))) {
      make_path($dir) or die "Can't mkdir $dir: $!";
    }
    my $old_mtime;
    if (-e $fn) {
      if (my $slept = wait_for_time(($old_mtime = stat($fn)->mtime) + 1.05)) {
	push @slept, $slept;
      }
    }
    open my $fh, join('', '>', @iolayer), $fn or die "$fn: $!";
    print $fh $content;
    close $fh;
    unless (not defined $old_mtime or $old_mtime < stat($fn)->mtime) {
      croak "Failed to update mtime for $fn!";
    }
  }
  @slept;
}

# This works, but not so useful. Try wait_if_near_deadline instead.
sub wait_for_time {
  my ($time) = @_;
  my $now = Time::HiRes::time;
  my $diff = $time - $now;
  return if $diff <= 0;
  usleep(int($diff * 1000 * 1000));
  $diff;
}

# sleep if ($deadline - $hires_now) < $threshold
# Use like following:
#
#   if (my $slept = wait_if_near_deadline(time+1, 0.1)) {
#     diag "slept: $slept";
#   }
#
sub wait_if_near_deadline {
  my ($deadline, $threshold) = @_;
  $threshold //= 0.2;
  my $now = Time::HiRes::time;
  my $diff = $deadline - $now;
  return if $diff > $threshold;
  usleep(int($diff * 1000 * 1000));
  $diff;
}

# Auto Export.
my $symtab = YATT::Lite::Util::symtab(__PACKAGE__);
our @EXPORT_OK = grep {
  *{$symtab->{$_}}{CODE}
} keys %$symtab;

use Exporter qw(import);

1;
