use strict;
use warnings;

use Test::More tests => 5;
use Win32;

BEGIN {
  use_ok 'Win32API::Console', qw(
    SetConsoleCtrlHandler
    GenerateConsoleCtrlEvent
    CTRL_C_EVENT
    CTRL_BREAK_EVENT
  );
}

# Use the current process ID, which is the same as $$. But not on cygwin, 
# where $$ is the cygwin-internal PID and not the windows PID. 
my $pid = Win32::GetCurrentProcessId();

my $called = 0;
my $event_type = undef;

my $handler = sub {
  my ($event) = @_;
  $called++;
  $event_type = $event;
  return 1;    # indicate event was handled
};

subtest 'Register handler' => sub {
  ok(SetConsoleCtrlHandler($handler, 1), 'Handler registered');
};

subtest 'Send CTRL_C_EVENT' => sub {
  $called = 0;
  $event_type = undef;
  ok(GenerateConsoleCtrlEvent(CTRL_C_EVENT, $pid), 'CTRL_C_EVENT sent');
  select(undef, undef, undef, 0.5);

  ok($called > 0, 'Handler was called');
  is($event_type, CTRL_C_EVENT, 'Correct event type received');
};

subtest 'Send CTRL_BREAK_EVENT' => sub {
  $called = 0;
  $event_type = undef;
  ok(GenerateConsoleCtrlEvent(CTRL_BREAK_EVENT, $pid), 'CTRL_BREAK_EVENT sent');
  select(undef, undef, undef, 0.5);

  ok($called > 0, 'Handler was called');
  is($event_type, CTRL_BREAK_EVENT, 'Correct event type received');
};

subtest 'Unregister handler' => sub {
  ok(SetConsoleCtrlHandler($handler, 0), 'Handler unregistered');
};

done_testing();
