#!/usr/bin/perl -w
use warnings;
use strict;

use lib "t/lib";

BEGIN {
    # Ensure nothing else has loaded a $SIG{__DIE__}
    die if $SIG{__DIE__};
}

# Test::Builder might have a $SIG{__DIE__}, too so we
# make sure it is effected by any aliased bug, too.
use aliased "Test::More";
use aliased "HasSigDie";

use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

is ref $SIG{__DIE__}, "CODE",
  '$SIG{__DIE__} handlers should not be destroyed';

is $SIG{__DIE__}->(), 'whee!',
  '... and should behave as expected';

eval "use aliased 'BadSigDie'";
is ref $SIG{__DIE__}, "CODE",
  'A bad load should not break $SIG{__DIE__} handlers';

is $SIG{__DIE__}->(), 'whee!',
  '... and they should retain their value';

eval "use aliased 'NoSigDie'";
is ref $SIG{__DIE__}, "CODE",
  'Loading code without sigdie handlers should succeed';

is $SIG{__DIE__}->(), 'whee!',
  '... and the sigdie handlers should retain their value';

{
    local $SIG{__DIE__};
    delete $INC{'NoSigDie.pm'};
    eval "use aliased 'NoSigDie' => 'NoSigDie2'";
    ok ! ref $SIG{__DIE__},
      'Loading code without sigdie handlers should succeed';
    delete $INC{'HasSigDie.pm'};
    eval "use aliased 'HasSigDie' => 'HasSigDie2'";
    is ref $SIG{__DIE__}, "CODE",
      'New $SIG{__DIE__} handlers should be loaded';

    is $SIG{__DIE__}->(), 'whee!',
      '... and should behave as expected';
}

done_testing;
