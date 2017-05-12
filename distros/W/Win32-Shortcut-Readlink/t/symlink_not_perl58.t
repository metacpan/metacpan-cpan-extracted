use strict;
use warnings;
use if $^O eq 'MSWin32', 'Test::More', skip_all => 'tests skipped on MSWin32';
use if eval { require 5.008000 } && !eval {require 5.010000 }, 'Test::More', skip_all => 'test does not work on Perl 5.8';
use Test::More tests => 4;
use Win32::Shortcut::Readlink;
use File::Temp qw( tempdir );
use File::Spec;

my $dir = tempdir( CLEANUP => 1 );

my $link_name        = File::Spec->catfile($dir, 'foo.txt');
my $target_name      = 'bar.txt';
my $full_target_name = File::Spec->catfile($dir, $target_name);

is readlink $link_name, undef, 'readlink $link_name = undef (where $link_name is a non existant file)';
note "errno = $!";

do {
  my $fh;
  open($fh, '>', File::Spec->catfile($dir, $target_name)) || die "unable to create $target_name $!";
  close $fh;
  symlink $target_name, $link_name;
};

is readlink $link_name, $target_name, "readlink \$link_name = $target_name";
note "errno = $!";

is readlink $full_target_name, undef, 'readlink $full_target_name = undef';
note "errno = $!";

is readlink $dir, undef, 'readlink $dir = undef';
note "errno = $!";

