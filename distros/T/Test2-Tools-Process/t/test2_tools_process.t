use Test2::V0 -no_srand => 1;
use Test2::Tools::Process;
use Config;

subtest 'export' => sub {
  imported_ok 'process';
  imported_ok 'proc_event';
  imported_ok 'named_signal';
};

subtest 'basic' => sub {

  process {
    note 'nothing';
  } [];

  process {
    note 'nothing';
  };

  process {
    note 'nothing';
  } [], 'custom test name 1';

  process {
    note 'nothing';
  } 'custom test name 2';

};

subtest 'exit' => sub {

  process {
    exit;
  } [
    proc_event exit => number(0),
  ];

  my $ret1;
  my $ret2;
  my $ret3;

  process {
    $ret1  = exit 2;
    $ret2  = exit 3;
    $ret3  = exit;
  } [
    proc_event( exit => 2, sub { return -42 }),
    proc_event( exit => sub { return -43 }),
    proc_event( exit => 0),
  ];

  is $ret1, -42;
  is $ret2, -43;
  is $ret3, U();

  is
    intercept { process { exit 2 } [ proc_event exit => 3 ] },
    array {
      event 'Fail';
      end;
    },
    'fail 1',
  ;

  is
    intercept { process { note 'nothing' } [ proc_event 'exit' ] },
    array {
      event 'Note';
      event 'Fail';
      etc;
    },
    'fail 1',
  ;

};

subtest 'exec' => sub {

  process { exec; } [ proc_event( exec => U() ) ];

  process { exec 'hi'; } [
    proc_event(exec => 'hi'),
  ];

  process { exec 'bye'; } [
    proc_event(exec => match qr/^b/),
  ];

  process { exec 'hi', 'bye' } [
    proc_event(exec => array {
      item 'hi';
      item match qr/^b/;
      end;
    }),
  ];

  process { exec 'hi', 'bye' } [
    proc_event(exec => ['hi','bye']),
  ];

  is
    intercept { process { note 'nothing' } [ proc_event 'exec' ] },
    array {
      event 'Note';
      event 'Fail';
    },
    'fail 1',
  ;

  is
    intercept { process { exec; } [ proc_event 'exec' => D() ] },
    array {
      event 'Fail';
    },
    'fail 2',
  ;

  is
    intercept { process { exec 'hi'; } [ proc_event 'exec' => 'bye' ] },
    array {
      event 'Fail';
    },
    'fail 3',
  ;

  is
    intercept { process { exec 'bye'; } [ proc_event 'exec' => match qr/^h/ ] },
    array {
      event 'Fail';
    },
    'fail 4',
  ;

  is
    intercept {
      process { exec 'hi', 'bye' } [
        proc_event(exec => array {
          item 'hi';
          item match qr/^x/;
          end;
        }),
      ];
    },
    array {
      event 'Fail';
    },
    'fail 5',
  ;

  is
    intercept {
      process { exec 'hi', 'bye' } [
        proc_event(exec => ['bye','hi']),
      ];
    },
    array {
      event 'Fail';
    },
    'fail 6',
  ;

};

subtest 'system' => sub {

  my $n = sub {};

  process {
    system;
    system 'hi';
    system 'hi', 'bye';
    system 'hi', 'bye';
  } [
    proc_event(system => U(), $n),
    proc_event(system => 'hi', $n),
    proc_event(system => array {
      item 'hi';
      item match qr/^b/;
    }, $n),
    proc_event(system => ['hi','bye'], $n),
  ];

  is
    intercept { process { note 'nothing' } [ proc_event 'system', $n ] },
    array {
      event 'Note';
      event 'Fail';
    },
    'fail 1',
  ;

  is
    intercept { process { system; } [ proc_event 'system' => D(), $n ] },
    array {
      event 'Fail';
    },
    'fail 2',
  ;

  is
    intercept { process { system 'hi'; } [ proc_event 'system' => 'bye', $n ] },
    array {
      event 'Fail';
    },
    'fail 3',
  ;

  is
    intercept { process { system 'bye'; } [ proc_event 'system' => match qr/^h/, $n ] },
    array {
      event 'Fail';
    },
    'fail 4',
  ;

  is
    intercept {
      process { system 'hi', 'bye' } [
        proc_event(system => array {
          item 'hi';
          item match qr/^x/;
          end;
        }, $n),
      ];
    },
    array {
      event 'Fail';
    },
    'fail 5',
  ;

  is
    intercept {
      process { system 'hi', 'bye' } [
        proc_event(system => ['bye','hi'], $n),
      ];
    },
    array {
      event 'Fail';
    },
    'fail 6',
  ;

  subtest 'emulation' => sub {

    process {
      is system('hi'), 0;
      is $?, 0;
      is `hi`, 'hello';
      is $?, 0;
      is system('false','two','three'), 2560;
      is $?, 2560;
      is `false two three`, "haha";
      is $?, 2560;
      is system('signal'), 9;
      is $?, 9;
      is system('signal'), 9;
      is $?, 9;
      is system('bogus'), -1;
      note "errno = $!";
      is $!, number(2);
    } [
      proc_event(system => sub {
        my($proc, @args) = @_;
        isa_ok $proc, 'Test2::Tools::Process::SystemProc';
        is $proc->type, 'system';
        is \@args, ['hi'];
        $proc->exit;
      }),
      proc_event(system => sub {
        my($proc, @args) = @_;
        isa_ok $proc, 'Test2::Tools::Process::SystemProc';
        is $proc->type, 'readpipe';
        is \@args, ['hi'];
        print "hello";
        $proc->exit;
      }),
      proc_event(system => { status => 10 }, sub {
        my($proc, @args) = @_;
        is \@args, ['false','two','three'];
        $proc->exit(10);
      }),
      proc_event(system => { status => 10 }, sub {
        my($proc, @args) = @_;
        print "haha";
        $proc->exit(10);
      }),
      proc_event(system => { signal => 9 }, sub {
        my($proc, @args) = @_;
        $proc->signal(9);
      }),
      proc_event(system => { signal => 9 }, sub {
        my($proc, @args) = @_;
        eval { $proc->signal('bogus') };
        note "exception = $@";
        $proc->signal('KILL');
      }),
      proc_event(system => { errno => number(2) }, sub {
        my($proc, @args) = @_;
        $proc->errno(2);
      }),
    ];


  };

};

subtest 'named signal' => sub {

  foreach my $name (split /\s+/, $Config{sig_name})
  {
    my $value = named_signal($name);
    is $value, match qr/^[0-9]+$/, "named_signal($name) = $value";
  }

};

subtest 'intercept exit and exec' => sub {


  is intercept_exit { note 'nothing to intercept (exit)' }, U();
  is intercept_exec { note 'nothing to intercept (exec)' }, U();

  is intercept_exit { exit }, 0;
  is intercept_exit { exit 2 }, 2;
  is intercept_exec { exec 'foo','bar','baz' }, ['foo','bar','baz'];

};

done_testing;
