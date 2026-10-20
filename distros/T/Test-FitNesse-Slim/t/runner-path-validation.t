use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use IPC::Run qw(run timeout);
use lib "$Bin/lib";
use Test::More;
use Test::FitNesse::Slim::RunnerPath qw(validate_runner_file);

my $directory = tempdir(CLEANUP => 1);
my $script = File::Spec->catfile($directory, 'perl-slim');
open my $script_fh, '>', $script or die "create temporary Perl runner: $!";
print {$script_fh} "print qq(runner executed through Perl\\n);\n";
close $script_fh or die "close temporary Perl runner: $!";

SKIP: {
  skip 'Unix executable permission bits are not available on Windows', 4
    if $^O eq 'MSWin32';
  chmod 0444, $script or skip "cannot set readable non-executable mode: $!", 4;
  ok(!-x $script, 'temporary runner has no executable permission');
  is(validate_runner_file($script), $script,
    'readable Perl runner is accepted without executable permission');

  my $output = '';
  my $ran = eval {
    run([$^X, $script], '>', \$output, timeout(5));
    1;
  };
  ok($ran, 'Perl executes the non-executable runner file') or diag($@);
  is($output, "runner executed through Perl\n", 'temporary runner produced its output');
}

my $missing = File::Spec->catfile($directory, 'missing-runner');
my $ok = eval { validate_runner_file($missing); 1 };
ok(!$ok, 'nonexistent runner is rejected');
like($@, qr/not a regular file/, 'missing-runner diagnostic identifies file requirement');

my $dir_runner = File::Spec->catdir($directory, 'runner-directory');
make_path($dir_runner);
$ok = eval { validate_runner_file($dir_runner); 1 };
ok(!$ok, 'directory supplied as runner is rejected');
like($@, qr/not a regular file/, 'directory diagnostic identifies file requirement');

SKIP: {
  skip 'Unix read permission bits are not available on Windows', 2
    if $^O eq 'MSWin32';
  my $unreadable = File::Spec->catfile($directory, 'unreadable-runner');
  open my $fh, '>', $unreadable or die "create unreadable runner: $!";
  print {$fh} "print qq(unreachable);\n";
  close $fh or die "close unreadable runner: $!";
  chmod 0000, $unreadable or skip "cannot remove read permissions: $!", 2;
  skip 'current user can still read mode-000 file', 2 if -r $unreadable;
  $ok = eval { validate_runner_file($unreadable); 1 };
  ok(!$ok, 'unreadable runner is rejected');
  like($@, qr/not readable/, 'unreadable-runner diagnostic identifies permissions');
}

done_testing;
