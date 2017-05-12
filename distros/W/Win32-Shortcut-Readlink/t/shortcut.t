use strict;
use warnings;
use if $^O !~ /^(cygwin|MSWin32)$/, 'Test::More', skip_all => 'test only for MSWin32 or cygwin';
use if ! eval { require Win32::Shortcut; 1 }, 'Test::More', skip_all => 'test requires Win32::Shortcut';
use Test::More tests => 5;
use File::Temp qw( tempdir );
use Win32::Shortcut::Readlink;

my $dir = tempdir( CLEANUP => 1 );

do{
  my $lnk1 = Win32::Shortcut->new;
  $lnk1->{Path} = "C:\\Foo\\Bar.exe";
  $lnk1->Save(map { $^O eq 'cygwin' ? Cygwin::posix_to_win_path($_) : $_ } "$dir/link.lnk");
  $lnk1->Close;
};

is readlink "$dir/link.lnk", "C:\\Foo\\Bar.exe", "$dir/link.lnk => C:\\Foo\\Bar.exe";
is do { no warnings; readlink undef }, undef, "readlink undef = undef";
is do { $_ = "$dir/link.lnk"; no warnings; readlink undef }, undef, "readlink undef = undef";
is readlink "$dir/foo.txt", undef, "readlink $dir/foo.txt => undef";
note $!;
is readlink "$dir", undef, "readlink $dir => undef";
note $!;
