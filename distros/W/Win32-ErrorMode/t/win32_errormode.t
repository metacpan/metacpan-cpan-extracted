use Test2::V0 -no_srand => 1;
use Win32::ErrorMode qw( :all );

subtest 'basic' => sub {
  my $mode = GetErrorMode();
  note "mode = $mode\n";
  like $mode, qr{^[0-9]+$}, "mode looks like an integer";
  is $ErrorMode, $mode, "tie interface get ($mode)";
  SetErrorMode(0x5);
  is GetErrorMode(), 0x5, "SetErrorMode() updates ErrorMode";
  is $ErrorMode, 0x5, "tie interface get (0)";
  $ErrorMode = 0x7;
  is GetErrorMode(), 0x7, "tie interface set(3)";
};

subtest 'thread' => sub {
  my $mode = GetThreadErrorMode();
  note "mode = $mode\n";
  like $mode, qr{^[0-9]+$}, "mode looks like an integer";
  is $ThreadErrorMode, $mode, "tie interface get ($mode)";
  SetThreadErrorMode(0);
  is GetThreadErrorMode(), 0, "SetThreadErrorMode() updates ThreadErrorMode";
  is $ThreadErrorMode, 0, "tie interface get (0)";
  $ThreadErrorMode = 0x3;
  is GetThreadErrorMode(), 0x3, "tie interface set(3)";
};

done_testing;
