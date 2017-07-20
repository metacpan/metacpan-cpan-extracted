use Test2::V0 -no_srand => 1;
use Test::Exec;

is(
  intercept { never_exec_ok { note 'here' } },
  array {
    event Note => sub {
      call message => 'here'
    };
    event Ok => sub {
      call name => 'does not call exec';
      call pass => T();
    };
    end;
  },
  'test passes',
);

my $line;

is(
  intercept { never_exec_ok { $line = __LINE__; note 'here1'; exec 'foo'; note 'not here' } },
  array {
    event Note => sub { call message => 'here1' };
    event Ok => sub {
      call name => 'does not call exec';
      call pass => F();
    };
    event Diag => sub {};
    event Diag => sub {
      call message => "exec at @{[ __FILE__ ]} line $line";
    };
    end;
  },
  'test fails',
);  

is(
  intercept { never_exec_ok { note 'here2' } 'test name' },
  array {
    event Note => sub { call message => 'here2' };
    event Ok => sub {
      call name => 'test name';
      call pass => T();
    };
    end;
  },
  'test with custom name',
);

done_testing;
