package App::Rgit::TestUtils;

use strict;
use warnings;

use Cwd        qw/abs_path/;
use File::Temp qw/tempfile/;
use File::Spec (); # curdir, catfile
use POSIX      qw/WIFEXITED WEXITSTATUS WIFSIGNALED WTERMSIG/;

BEGIN {
 no warnings 'redefine';
 *WIFEXITED   = sub { 1 }             unless eval { WIFEXITED(0);   1 };
 *WEXITSTATUS = sub { shift() >> 8 }  unless eval { WEXITSTATUS(0); 1 };
 *WIFSIGNALED = sub { shift() & 127 } unless eval { WIFSIGNALED(0); 1 };
 *WTERMSIG    = sub { shift() & 127 } unless eval { WTERMSIG(0);    1 };
}

use base qw/Exporter/;

our @EXPORT_OK = (qw/can_run_git/);

sub can_run_git {
 my ($fh, $filename) = tempfile(UNLINK => 1);

 my @ret = (1, '');

TRY:
 {
  my @args = (
   abs_path($filename),
   'version',
  );

  my $git = File::Spec->catfile(File::Spec->curdir, qw/t bin git/);
  if ($^O eq 'MSWin32') {
   unless (-x $git) {
    $git .= '.bat';
    unless (-x $git) {
     @ret = (0, "no $git executable");
     last TRY;
    }
   }
  } else {
   unless (-x $git) {
    @ret = (0, "no $git executable");
    last TRY;
   }
  }

  system { $git } $git, @args;

  if ($? == -1) {
   @ret = (0, $! || "unknown");
   last TRY;
  }

  my $status;
  $status = WEXITSTATUS($?) if WIFEXITED($?);

  if (WIFSIGNALED($?)) {
   @ret = (0, 'process recieved signal ' . WTERMSIG($?));
  } elsif ($status) {
   @ret = (0, "process exited with code $status");
  }
 }

 return wantarray ? @ret : $ret[0];
}

1;
