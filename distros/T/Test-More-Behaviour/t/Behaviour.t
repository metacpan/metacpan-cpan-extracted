use strict;
use warnings;

use Test::More;
use IO::Capture::Stdout;

BEGIN {
  use_ok('Test::More::Behaviour')
};

subtest 'describe takes a description and executes a block' => sub {
  my $var = 0;
  describe 'test' => sub { $var = 1 };
  is($var, 1);

  done_testing();
};

subtest 'it takes a description and executes a block and requires at least one expectation' => sub {
  my $var = 0;
  it 'test' => sub { ok(1); $var = 1; };
  is($var, 1);

  done_testing();
};

subtest 'describe can take multiple its' => sub {
  my $var1 = 0;
  my $var2 = 0;
  describe 'test' => sub {
    it 'multiple it number 1' => sub {
      ok(1);
      $var1 = 1;
    };
    it 'multiple it number 2' => sub {
      ok(1);
      $var2 = 2;
    };
  };

  is($var1, 1);
  is($var2, 2);

  done_testing();
};

subtest 'context takes a description and executes a block' => sub {
  my $var = 0;
  context 'test' => sub { $var = 1 };
  is($var, 1);

  done_testing();
};

subtest 'context can take multiple its' => sub {
  my $var1 = 0;
  my $var2 = 0;
  my $var3 = 0;
  context 'test' => sub {
    $var1 = 1;
    it 'test it 1 inside context' => sub {
      ok(1);
      $var2 = 2;
    };
    it 'test it 2 inside context' => sub {
      ok(1);
      $var3 = 3;
    };
  };

  is($var1, 1);
  is($var2, 2);
  is($var3, 3);

  done_testing();
};

subtest 'describe can take multiple contexts' => sub {
  my $var1 = 0;
  my $var2 = 0;
  my $var3 = 0;
  my $var4 = 0;
  describe 'test describe' => sub {
    context 'test context 1' => sub {
      $var1 = 1;
      it 'test it inside context 1' => sub {
        ok(1);
        $var2 = 2;
      };
    };
    context 'test context 2' => sub {
      $var3 = 3;
      it 'test it inside context 2' => sub {
        ok(1);
        $var4 = 4;
      };
    };
  };

  is($var1, 1);
  is($var2, 2);
  is($var3, 3);
  is($var4, 4);

  done_testing();
};

my $before_all_var = 0;
sub before_all { $before_all_var += 1; }
subtest 'before_all executes for each describe' => sub {
  describe 'test describe 1' => sub {
    it 'test it 1' => sub { ok(1); };
  };

  is($before_all_var, 1);

  describe 'test describe 2' => sub {
    it 'test it 2' => sub { ok(1); };
  };

  is($before_all_var, 2);

  done_testing();
};

my $before_each_var = 0;
sub before_each { $before_each_var += 1; }
subtest 'before_each executes for each it' => sub {
  describe 'test describe 1' => sub {
    it 'test it 1' => sub { ok(1); };
    it 'test it 2' => sub { ok(1); };
  };

  is($before_each_var, 2);

  describe 'test describe 2' => sub {
    it 'test it 3' => sub { ok(1); };
  };

  is($before_each_var, 3);

  done_testing();
};

my $after_all_var = 0;
sub after_all { $after_all_var += 1; }
subtest 'after_all executes for each describe' => sub {
  describe 'test describe 1' => sub {
    it 'test it 1' => sub { ok(1); };
  };

  is($after_all_var, 1);

  describe 'test describe 2' => sub {
    it 'test it 2' => sub { ok(1); };
  };

  is($after_all_var, 2);

  done_testing();
};

my $after_each_var = 0;
sub after_each { $after_each_var += 1; }
subtest 'after_each executes for each it' => sub {
  describe 'test describe 1' => sub {
    it 'test it 1' => sub { ok(1); };
    it 'test it 2' => sub { ok(1); };
  };

  is($after_each_var, 2);

  describe 'test describe 2' => sub {
    it 'test it 3' => sub { ok(1); };
  };

  is($after_each_var, 3);

  done_testing();
};

subtest 'passing test prints green' => sub {
  my $capture = IO::Capture::Stdout->new;
  $capture->start;
  describe 'test describe' => sub {
    it 'passes' => sub {
      ok(1);
    };
  };
  $capture->stop;

  my $line = $capture->read;

  is(substr($line, 1, 4), '[32m');

  done_testing();
};

TODO: {
  local $TODO = 'this is a passing test but fails because the test needs the inner test to fail.';
  subtest 'failing test prints red' => sub {
    my $capture = IO::Capture::Stdout->new;
    $capture->start;
    describe 'test describe' => sub {
      it 'fails' => sub {
        fail;
      };
    };
    $capture->stop;

    my $line = $capture->read;

    is(substr($line, 1, 4), '[31m');

    done_testing();
  };
};

done_testing();
