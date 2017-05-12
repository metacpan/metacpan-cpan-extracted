use IPC::Open3;
use Config;
use strict;
use warnings;

my @prove = ($Config{perlpath}, '-mApp::Prove', '-e', '$a=App::Prove->new();$a->process_args(@ARGV);$a->run()', '--', '-v');
sub run_spec {
  my ($filename) = @_;
  local $? = 0;
  my $pid = open3(\*IN, \*OUT, \*OUT, @prove, $filename);
  close(IN);
  my @lines = <OUT>;
  close(OUT);
  waitpid($pid, 0);
  return \@lines;
}

sub contains {
  my ($lines, $re, $name) = @_;
  scalar grep { $_ =~ $re } @$lines;
}

1;
