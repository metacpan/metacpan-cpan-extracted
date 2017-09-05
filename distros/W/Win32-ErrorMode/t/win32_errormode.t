use Test2::V0 -no_srand => 1;
use Win32::ErrorMode qw( :all );

subtest 'basic' => sub {
  my $mode = GetErrorMode();
  note "mode = $mode\n";
  like $mode, qr{^[0-9]+$}, "mode looks like an integer";
  is $ErrorMode, $mode, "tie interface get ($mode)";
  SetErrorMode(0);
  is GetErrorMode(), 0, "SetErrorMode() updates ErrorMode";
  is $ErrorMode, 0, "tie interface get (0)";
  $ErrorMode = 0x3;
  is GetErrorMode(), 0x3, "tie interface set(3)";
};

subtest 'thread' => sub {
  skip_all 'test requires working GetThreadErrorMode and SetThreadErrorMode'
    unless Win32::ErrorMode::_has_thread();

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
