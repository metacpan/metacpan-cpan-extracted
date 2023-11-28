#<<<
use strict; use warnings;
#>>>

# Load Time::Out before Test::More: Recent version of Test::More load
# Time::HiRes. This should be avoided.
use Time::Out qw( timeout );

use Test::More import => [ qw( is is_deeply plan skip subtest ) ], tests => 6;
use POSIX qw( );

subtest 'timeout: void context; keep the CPU busy' => sub {
  plan tests => 1;

  timeout 2 => sub {
    while ( 1 ) { }
  };
  is $@, 'timeout', 'eval error was set to "timeout"';
};

SKIP: {
  skip 'POSIX module does not provide pause() implementation', 1 unless POSIX->can( 'pause' );

  subtest 'timeout: void context; pause the current process' => sub {
    plan tests => 1;

    timeout 2 => sub {
      POSIX::pause();
    };
    is $@, 'timeout', 'eval error was set to "timeout"';
  };
}

SKIP: {
  skip "alarm(2) doesn't interrupt blocking I/O on $^O", 1 if $^O eq 'MSWin32';

  subtest 'timeout: void context; blocking I/O' => sub {
    plan tests => 1;
    require IO::Handle;
    my $rh = IO::Handle->new;
    my $wh = IO::Handle->new;
    pipe( $rh, $wh );
    $wh->autoflush( 1 );
    print $wh "\n";
    my $line = <$rh>;
    timeout 2 => sub {
      $line = <$rh>;
    };
    is $@, 'timeout', 'eval error was set to "timeout"';
  };
}

subtest 'no timeout: void context' => sub {
  plan tests => 1;

  timeout 3 => sub {
    select( undef, undef, undef, 1 );
  };
  is $@, '', 'empty eval error';
};

subtest 'no timeout: scalar context; echo argument passed to code' => sub {
  plan tests => 2;

  my $expected_result = 42;
  my $got_result      = timeout 3, $expected_result => sub {
    select( undef, undef, undef, 1 );
    $_[ 0 ];
  };
  is $@,          '',               'empty eval error';
  is $got_result, $expected_result, 'expected result';
};

subtest 'no timeout: list context; echo arguments passed to code' => sub {
  plan tests => 2;

  my $expected_result = [ 42, 'Hello, World!' ];
  my $got_result      = [
    timeout 3,
    @$expected_result => sub {
      select( undef, undef, undef, 1 );
      @_;
    }
  ];
  is $@, '', 'empty eval error';
  is_deeply $got_result, $expected_result, 'expected result';
};
