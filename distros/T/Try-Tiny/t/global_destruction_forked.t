use strict;
use warnings;

use Test::More tests => 3;
use Try::Tiny;

{
  package WithCatch;
  use Try::Tiny;

  sub DESTROY {
    try {}
    catch {};
    return;
  }
}

{
  package WithFinally;
  use Try::Tiny;

  our $_in_destroy;
  sub DESTROY {
    local $_in_destroy = 1;
    try {}
    finally {};
    return;
  }
}

try {
  my $pid = fork;
  unless ($pid) {
    my $o = bless {}, 'WithCatch';
    $SIG{__DIE__} = sub {
      exit 1
        if $_[0] =~ /A try\(\) may not be followed by multiple catch\(\) blocks/;
      exit 2;
    };
    exit 0;
  }
  waitpid $pid, 0;
  is $?, 0, 'nested try in cleanup after fork does not maintain outer catch block';
}
catch {};

try {
  my $pid = fork;
  unless ($pid) {
    my $o = bless {}, 'WithFinally';
    exit 0;
  }
  waitpid $pid, 0;
  is $?, 0, 'nested try in cleanup after fork does not maintain outer finally block';
}
finally { exit 1 if $WithFinally::_in_destroy };

pass("Didn't just exit");
