package Test::FitNesse::Slim::RunnerPath;

use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw(validate_runner_file);

sub validate_runner_file {
  my ($path) = @_;
  my $label = defined($path) ? $path : '(undefined)';
  die "the runner is not a regular file: $label" unless defined($path) && -f $path;
  die "the runner is not readable: $label" unless -r $path;
  return $path;
}

1;
