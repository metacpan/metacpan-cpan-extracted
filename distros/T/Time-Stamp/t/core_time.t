# vim: set sw=2 sts=2 ts=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';
use ControlTime;
use TestHelpers -all;

# declare different 'time' sub in local namespace
# to test that Time::Stamp's time() isn't affected
use subs 'time';
sub time { 'silly' }

BEGIN {
  # tell TS that hires is *not* available (so that it just calls time())
  ControlTime->fake_have_hires(0);
}

use Time::Stamp gmstamp => { format => 'compact', us => 1, -as => 'stamp', tz => '' };

trap_warnings {
  is time(), 'silly', 'time() defined in local namespace';

  {
    package # no_index
      _Any_Other_Package;
    ::isnt time(), 'silly', 'time() is pure in another package';
  }

  my $time = 1357714248;
  my $ts = '20130109_065048.000000';

  my $re = qr/^\d{8}_\d{6}\.0{6}$/;

  {
    my $stamp = eval { stamp() };
    like $stamp, $re, 'stamp works before override';
    isnt $stamp, $ts, 'stamp got "real" time';
  }

  ControlTime->set($time);

  {
    is eval { stamp() }, $ts, 'stamp works with overridden time()';
    no_error_ok;
    no_warnings_ok;
  }

  {
    my $bad = eval { stamp('stinky') };

    like $bad, $re, 'stamp works when passed a non-number';
    is $bad, stamp(0), 'stamp returned epoch after numifying string';

    no_error_ok;
    warnings_like(
      qr/Argument "stinky" isn't numeric in gmtime/,
        'got warnings for getting bad value from time()'
    );
  }

  is time(), 'silly', 'time() still defined in local namespace';
};

done_testing;
