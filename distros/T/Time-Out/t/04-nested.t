use strict;
use warnings;

# Load Time::Out before Test::More: Recent version of Test::More load
# Time::HiRes. This should be avoided.
use Time::Out qw( timeout );

use Test::More import => [ qw( fail is plan subtest ) ], tests => 2;

subtest 'inner timer fires before outer timer' => sub {
  plan tests => 2;

  timeout 5 => sub {
    timeout 2 => sub {
      while ( 1 ) { }
    };
    is $@, 'timeout', 'inner timeout: eval error was set to "timeout"';
    while ( 1 ) { }
  };
  is $@, 'timeout', 'outer timeout: eval error was set to "timeout"';
};

subtest 'outer timer interrupts inner timer' => sub {
  plan tests => 1;

  timeout 2 => sub {
    timeout 5 => sub {
      while ( 1 ) { }
    };
    fail 'we should never get here';
  };
  is $@, 'timeout', 'outer timeout: eval error was set to "timeout"';
};
