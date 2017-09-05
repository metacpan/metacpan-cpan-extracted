use lib 't/lib';
use Test2::Require::Win;
use Test2::Require::Module 'Win32::Shortcut';
use Test2::V0 -no_srand => 1;
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
is do { local $SIG{__WARN__} = sub {}; readlink undef }, undef, "readlink undef = undef";
is do { $_ = "$dir/link.lnk"; local $SIG{__WARN__} = sub {}; readlink undef }, undef, "readlink undef = undef";
is readlink "$dir/foo.txt", undef, "readlink $dir/foo.txt => undef";
note $!;
is readlink "$dir", undef, "readlink $dir => undef";
note $!;

done_testing;
