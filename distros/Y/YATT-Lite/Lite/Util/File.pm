package YATT::Lite::Util::File;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use YATT::Lite::Util ();
use File::Basename qw(dirname);
use File::Path qw(make_path);
use Time::HiRes qw/usleep/;
use File::stat;

use constant DEBUG => $ENV{DEBUG_YATT_UTIL_FILE};

# 書き換え時に mtime の厳密な前進を保証するため、旧 mtime + 1.05 秒まで
# 実時間で眠ることがある(通常は最大 ~1 秒)。mtime 前進はこの関数自身が
# 保証するので、utime で mtime を進める運用と併用してはならない。
# mtime が MAX_MTIME_WAIT 秒を超えて未来のファイル(utime 済み)には
# 黙って眠らず croak する。

use constant MAX_MTIME_WAIT => 5;

sub mkfile_may_wait {
  my ($pack) = shift;
  my @slept;
  while (my ($fn, $content) = splice @_, 0, 2) {
    ($fn, my @iolayer) = ref $fn ? @$fn : ($fn);
    unless (-d (my $dir = dirname($fn))) {
      make_path($dir) or die "Can't mkdir $dir: $!";
    }
    my $old_mtime;
    if (-e $fn) {
      my $deadline = ($old_mtime = stat($fn)->mtime) + 1.05;
      if ((my $diff = $deadline - Time::HiRes::time) > MAX_MTIME_WAIT) {
	croak sprintf("mkfile_may_wait: mtime of %s is %.1f secs in the future!"
		      ." (do not combine mkfile_may_wait with utime-forwarded mtimes)"
		      , $fn, $diff);
      }
      if (my $slept = wait_for_time($deadline)) {
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

# 旧名 (互換のための alias)。二重代入は "used only once" warning の抑制。
*mkfile = *mkfile = \&mkfile_may_wait;

# This works, but not so useful. Try wait_if_near_deadline instead.
sub wait_for_time {
  my ($time) = @_;
  my $now = Time::HiRes::time;
  my $diff = $time - $now;
  return if $diff <= 0;
  print STDERR "# wait_for_time: $diff secs\n"
    if DEBUG;
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
  return if $diff <= 0;
  usleep(int($diff * 1000 * 1000));
  $diff;
}

# Auto Export.
my $symtab = YATT::Lite::Util::symtab(__PACKAGE__);
our @EXPORT_OK = grep {
  my $entry = $symtab->{$_};
  # To remove constant;
  !ref $entry && *{$entry}{CODE}
} keys %$symtab;

use Exporter qw(import);

1;
