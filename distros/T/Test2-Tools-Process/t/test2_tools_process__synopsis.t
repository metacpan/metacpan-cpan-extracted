use Test2::V0 -no_srand => 1;
use Test2::Tools::Process;

process {
  system 'foo', 'bar';
} [
  # check tht the first system call is to
  # a command foo with any arguments
  proc_event(system => array {
    item 'foo';
    etc;
  }, sub {
    # simulate the foo command
    my($proc, @args) = @_;
    note "faux bar command: @args";
    # simulate a notmsl exit
    $proc->exit(0);
  }),
];

process {
  exit 2;
  note 'not executed';
} [
  # can use any Test2 checks on the exit status
  proc_event(exit => match qr/^[2-3]$/),
];

process {
  exit 4;
} [
  # or you can just check that the exit status matches numerically
  proc_event(exit => 4),
];

process {
  exit 5;
} [
  # or just check that we called exit.
  proc_event('exit'),
];

process {
  exec 'foo bar';
  exec 'baz';
  note 'not executed';
} [
  # emulate first exec as failed
  proc_event(exec => match qr/^foo\b/, sub {
    my($return, @command) = @_;
    $! = 2;
    return 0;
  }),
  # the second exec will be emulated as successful
  proc_event('exec'),
];

# just intercept `exit`
is intercept_exit { exit 10 }, 10;

# just intercept `exec`
is intercept_exec { exec 'foo', 'bar', 'baz' }, ['foo','bar','baz'];

done_testing;
