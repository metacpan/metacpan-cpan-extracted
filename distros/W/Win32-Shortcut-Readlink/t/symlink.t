use strict;
use warnings;
use if $^O eq 'MSWin32', 'Test::More', skip_all => 'tests skipped on MSWin32';
use Test::More;
use Win32::Shortcut::Readlink;
use File::Temp qw( tempdir );
use File::Spec;

my $p58 = eval { require 5.008000 } && ! eval { require 5.010000 };

my $dir = tempdir( CLEANUP => 1 );

my $link_name        = File::Spec->catfile($dir, 'foo.txt');
my $target_name      = 'bar.txt';
my $full_target_name = File::Spec->catfile($dir, $target_name);

is do { no warnings; readlink undef }, undef, 'readlink undef = undef';
note "errno = $!";

if(!$p58)
{
  is do { no warnings; undef $_; readlink }, undef, 'readlink = undef (when $_ == undef)';
  note "errno = $!";
}

is readlink($link_name), undef, 'readlink $link_name = undef (where $link_name is a non existant file)';
note "errno = $!";

if(!$p58)
{
  is do { $_ = $link_name; readlink }, undef, 'readlink = undef (where $_ is a non existant file)';
  note "errno = $!";
}

do {
  my $fh;
  open($fh, '>', File::Spec->catfile($dir, $target_name)) || die "unable to create $target_name $!";
  close $fh;
  symlink($target_name, $link_name) || die "unable to symlink $link_name => $target_name $!";
};

is readlink($link_name), $target_name, "readlink \$link_name = $target_name";
note "errno = $!";

is do { no warnings; $_ = $link_name; readlink undef }, undef, "readlink undef = undef (with $_ defined)";
note "errno = $!";

is do { $_ = $link_name; readlink $link_name }, $target_name, "readlink = $target_name";
note "errno = $!";

is readlink($full_target_name), undef, 'readlink $full_target_name = undef';
note "errno = $!";

if(!$p58)
{
  is do { $_ = $full_target_name; readlink }, undef, 'readlink = undef';
  note "errno = $!";
}

is readlink($dir), undef, 'readlink $dir = undef';
note "errno = $!";

is do { $_ = $dir; readlink $dir }, undef, 'readlink = undef';
note "errno = $!";

done_testing;
