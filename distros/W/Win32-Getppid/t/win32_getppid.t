use Test2::V0 -no_srand => 1;
use Win32::Getppid;

subtest 'all' => sub {
  my $ppid = Win32::Getppid::getppid;
  like $ppid, qr{^[0-9]+$}, "ppid = $ppid";
};

subtest 'cygwin' => sub {
  skip_all 'cygwin only' unless $^O =~ /^(cygwin|msys)$/;

  my $cygwin_ppid = getppid;
  my $win_ppid    = Win32::Getppid::getppid();

  like $cygwin_ppid, qr{^[0-9]+$}, "cygwin_ppid = $cygwin_ppid";
  like $win_ppid, qr{^[0-9]+$}, "win_ppid = $win_ppid";
  isnt $cygwin_ppid, $win_ppid, "they aren't the same";
};

subtest 'mswin32' => sub {
  skip_all 'MSWin32 only' unless $^O eq 'MSWin32';

  my $core_ppid = getppid();
  my $win_ppid    = Win32::Getppid::getppid();

  like $core_ppid, qr{^[0-9]+$}, "core_ppid = $core_ppid";
  like $win_ppid, qr{^[0-9]+$}, "win_ppid = $win_ppid";
  is $core_ppid, $win_ppid, "they are the same";
};

done_testing;
