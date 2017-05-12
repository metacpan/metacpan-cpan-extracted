#! /usr/bin/perl
#---------------------------------------------------------------------
# t/50-ChangeNotify.t
#
# Test Win32::Semaphore
#---------------------------------------------------------------------

use strict;
use warnings;
use Test::More;
use File::Spec;

use Win32::ChangeNotify;

eval "use File::Temp 'tempdir';";
plan skip_all => "File::Temp required for testing Win32::ChangeNotify" if $@;

eval "use File::Path 'rmtree';";
plan skip_all => "File::Path required for testing Win32::ChangeNotify" if $@;

plan tests => 21;

diag(<<'END_WARNING');
This test should take no more than 10 seconds.
If it takes longer, please kill it with Ctrl-Break (Ctrl-C won't work right).
END_WARNING

#=====================================================================
my $dir = tempdir(CLEANUP => 1);

#---------------------------------------------------------------------
sub appendFile
{
  my $contents = pop @_;
  my $path = File::Spec->catfile($dir, @_);

  open(TMP, '>>', $path) or die "Unable to open $path";
  print TMP $contents;
  close TMP;

  ok(-s $path, "file $path is not empty");
} # end appendFile

#---------------------------------------------------------------------
sub createFile
{
  my $path = File::Spec->catfile($dir, @_);

  open(TMP, '>', $path) or die "Unable to create $path";
  close TMP;

  ok(-f $path, "created file $path");

  return $path;
} # end createFile

#---------------------------------------------------------------------
# Convert a path to Windows format (a no-op, except under Cygwin):

sub wPath
{
  my ($path) = @_;

  if ($^O eq 'cygwin') {
    $path =~ s/(['\\])/\\$1/g;  # quote metachars
    $path = `cygpath -w '$path'`;

    die "Failed to convert path $_[0]" if $?;

    chomp $path;
  } # end if running under Cygwin

  return $path;
} # end wPath

#=====================================================================

ok(FILE_NOTIFY_CHANGE_FILE_NAME != 0, 'FILE_NOTIFY_CHANGE_FILE_NAME');

is(FILE_NOTIFY_CHANGE_DIR_NAME,
   Win32::ChangeNotify::constant('FILE_NOTIFY_CHANGE_DIR_NAME'),
   'FILE_NOTIFY_CHANGE_DIR_NAME');

ok(INFINITE != 0, 'INFINITE');

#---------------------------------------------------------------------
ok(-d $dir, "$dir is a directory");

my $n = Win32::ChangeNotify->new(wPath($dir), undef, 'FILE_NAME|SIZE');
ok($n, 'created $n');

isa_ok($n, 'Win32::ChangeNotify');

is($n->wait(0), 0, 'wait(0) times out');

createFile('empty.txt');

is($n->wait(1), 1, 'wait(1) succeeds');

ok($n->reset, 'reset');

is($n->wait(2), 0, 'wait(2) times out');

createFile('empty2.txt');
createFile('file.txt');

is($n->wait(3), 1, 'wait(3) succeeds');

ok($n->FindNext, 'FindNext'); # Deprecated method name (now called reset)

is($n->wait(4), 1, 'wait(4) succeeds');

ok($n->reset, 'reset');

is($n->wait(5), 0, 'wait(5) times out');

appendFile('file.txt', "This is the file contents.\n");

is($n->wait(6), 1, 'wait(6) succeeds');

ok($n->close, 'closing $n');
