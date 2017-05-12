# vim: set sw=2 sts=2 ts=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use Time::Local qw( timegm timelocal ); # core

# this script is testing exports/options (which means gmtime *and* localtime)
# so to avoid trouble with unknown time zones don't bother to mock time() just use regexps

# defaults
{ package # shh...
  Moe; use Time::Stamp qw(gmstamp localstamp),
    localstamp => { -as => 'localfrac', us => 1 };
}

like(Moe::gmstamp,    qr/^ \d{4} - \d{2} - \d{2} T \d{2} : \d{2} : \d{2} Z$/x, 'default gmstamp');
like(Moe::localstamp, qr/^ \d{4} - \d{2} - \d{2} T \d{2} : \d{2} : \d{2}  $/x,  'default localstamp');
like(Moe::localfrac,  qr/^ \d{4} - \d{2} - \d{2} T \d{2} : \d{2} : \d{2} \. \d{6}$/x,  'default with us');

# separators
{ package # shh...
  Larry; use Time::Stamp
    gmstamp    => {date_sep => '/', dt_sep => '_', tz_sep => '@'},
    gmstamp    => {date_sep => '/', dt_sep => '_', tz_sep => '@', frac => 2, -as => 'gmfrac2'},
    localstamp => {time_sep => '.', tz_sep => '@'};
}

like(Larry::gmfrac2,    qr#^ \d{4} / \d{2} / \d{2} _ \d{2}  : \d{2}  : \d{2} \. \d{2} @ Z$ #x, 'gmstamp with hundredths');
like(Larry::gmstamp,    qr#^ \d{4} / \d{2} / \d{2} _ \d{2}  : \d{2}  : \d{2} @ Z$ #x, 'gmstamp');
like(Larry::localstamp, qr#^ \d{4} - \d{2} - \d{2} T \d{2} \. \d{2} \. \d{2}    $ #x, 'localstamp');

# names
{ package # shh...
  Curly;
  BEGIN {
    my @imports;
    foreach my $name ( qw(easy numeric compact iso8601) ){
      push(@imports, $_.'stamp' => {format => $name, -as => $_.$name })
        for qw(gm local);
    }
    require Time::Stamp;
    Time::Stamp->import(@imports);
  }
}

like(Curly::gmeasy,    qr/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} Z$/, 'gmstamp easy');
like(Curly::localeasy, qr/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/,   'localstamp easy');

like(Curly::gmnumeric,    qr/^\d{4} \d{2} \d{2} \d{2} \d{2} \d{2}$/x, 'gmstamp numeric');
like(Curly::localnumeric, qr/^\d{4} \d{2} \d{2} \d{2} \d{2} \d{2}$/x, 'localstamp numeric');

like(Curly::gmcompact,    qr/^\d{4} \d{2} \d{2} _ \d{2} \d{2} \d{2} Z$/x, 'gmstamp compact');
like(Curly::localcompact, qr/^\d{4} \d{2} \d{2} _ \d{2} \d{2} \d{2}$/x, 'localstamp compact');

like(Curly::gmiso8601,    qr/^\d{4} - \d{2} - \d{2} T \d{2} : \d{2} : \d{2} Z$/x, 'gmstamp iso8601');
like(Curly::localiso8601, qr/^\d{4} - \d{2} - \d{2} T \d{2} : \d{2} : \d{2}$/x, 'localstamp iso8601');

# overwrite named format
{ package # shh...
  Shemp; use Time::Stamp
    gmstamp    => {format => 'compact', dt_sep => '||', tz_sep => '-'},
    gmstamp    => {format => 'compact', dt_sep => '||', tz_sep => '-', frac => 4, -as => 'gmfrac4'},
    localstamp => {tz => '0000', tz_sep => '.', format => 'numeric',   frac => 5, -as => 'localfrac5'},
    localstamp => {tz => '0000', tz_sep => '.', format => 'numeric'};
}

like(Shemp::gmfrac4,    qr/^\d{4} \d{2} \d{2} \|\| \d{2} \d{2} \d{2} \.\d{4} -Z$/x, 'gmstamp compact override with frac');
like(Shemp::gmstamp,    qr/^\d{4} \d{2} \d{2} \|\| \d{2} \d{2} \d{2} -Z$/x, 'gmstamp compact override');
like(Shemp::localstamp, qr/^\d{4} \d{2} \d{2}      \d{2} \d{2} \d{2} \. 0000$/x, 'localstamp numeric override');
like(Shemp::localfrac5, qr/^\d{4} \d{2} \d{2}      \d{2} \d{2} \d{2} \. \d{5} \. 0000$/x, 'localstamp numeric override with frac');

# group
{ package # shh...
  Joe; use Time::Stamp -stamps => {format => 'compact'};
}

like(Joe::gmstamp,    qr/^\d{4} \d{2} \d{2} _ \d{2} \d{2} \d{2} Z$/x, 'gmstamp compact');
like(Joe::localstamp, qr/^\d{4} \d{2} \d{2} _ \d{2} \d{2} \d{2}$/x, 'localstamp compact');

# group with fraction
{ package # shh...
  JoeFrac; use Time::Stamp -stamps => {format => 'compact', frac => 9};
}

like(JoeFrac::gmstamp,    qr/^\d{4} \d{2} \d{2} _ \d{2} \d{2} \d{2} \.\d{9} Z$/x,    'gmstamp compact with fraction');
like(JoeFrac::localstamp, qr/^\d{4} \d{2} \d{2} _ \d{2} \d{2} \d{2} \.\d{9}  $/x, 'localstamp compact with fraction');

# parsers
{ package # shh...
  CurlyJoe; use Time::Stamp
    'parsegm',
    parsegm    => { -as => 'parsegf', regexp => qr/(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d*)/ },
    parselocal => { -as => 'parself', regexp => qr/(\d+) (\d+) (\d+) (\d+) (\d+) (\d+) (0?\.\d+)?/ },
    # capture the fraction in the 6th group
    parsegm    => { -as => 'parseg6', regexp => qr/(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2}(?:\.\d+)?)/ },
    parselocal => { -as => 'parsel6', regexp => qr/(\d+) (\d+) (\d+) (\d+) (\d+) (\d+\.\d+)/ },
    # how's this for 'contrived':
    parsegm    => { -as => 'parsegs', regexp =>  q/^3(\d{4})99(\d{2})99(\d{2})\D+(\d{2})\D*(\d{2})\D*(\d{2})$/},
    parselocal => { -as => 'parselr',  regexp => qr/(\d+).(\d+).(\d+)=(\d+):(\d+):(\d+)/};
}

is(CurlyJoe::parsegm('20101230  171819'),     Time::Local::timegm(   19, 18, 17, 30, 11, 110), 'parsestamp to timegm');
is_deeply
  [CurlyJoe::parsegm('20101230  171819')],
  [         19, 18, 17, 30, 11, 110],
  'parsestamp to timegm (list)';

is(CurlyJoe::parsegs('3201099129930_171819'), Time::Local::timegm(   19, 18, 17, 30, 11, 110), 'parsestamp to timegm');
is_deeply
  [CurlyJoe::parsegs('3201099129930_171819')],
  [         19, 18, 17, 30, 11, 110],
  'parsestamp to timegm (list)';

is(CurlyJoe::parselr('1998/11/29=04:05:06' ), Time::Local::timelocal( 6,  5,  4, 29, 10,  98), 'parsestamp to timelocal');
is_deeply
  [CurlyJoe::parselr('1998/11/29=04:05:06' )],
  [          6,  5,  4, 29, 10,  98],
  'parsestamp to timelocal';

is CurlyJoe::parsegf('201012301718193456789'),
  timegm(   19,         18, 17, 30, 11, 110).'.3456789',
  'parsestamp to timegm with fraction';
is_deeply
  [CurlyJoe::parsegf('201012301718193456789')],
  [         19.3456789, 18, 17, 30, 11, 110],
  'parsestamp to timegm with fraction';

is CurlyJoe::parseg6('20101230171819.3456789'),
  timegm(   19,         18, 17, 30, 11, 110).'.3456789',
  'parsestamp to timegm with fraction';
is_deeply
  [CurlyJoe::parseg6('20101230171819.3456789')],
  [         19.3456789, 18, 17, 30, 11, 110],
  'parsestamp to timegm with fraction (list)';

is CurlyJoe::parself('1998 11 29 04 05 06 0.2345' ),
  timelocal( 6,       5,  4, 29, 10,  98).'.2345',
  'parsestamp to timelocal with fraction';
is_deeply
  [CurlyJoe::parself('1998 11 29 04 05 06 0.2345' )],
  [          6.2345,  5,  4, 29, 10,  98],
  'parsestamp to timelocal with fraction (list)';

is CurlyJoe::parsel6('1998 11 29 04 05 06.2345' ),
  timelocal( 6,       5,  4, 29, 10,  98).'.2345',
  'parsestamp to timelocal with fraction';
is_deeply
  [CurlyJoe::parsel6('1998 11 29 04 05 06.2345' )],
  [          6.2345,  5,  4, 29, 10,  98],
  'parsestamp to timelocal with fraction (list)';


# shortcuts
{ package # shh...
  RanOutOfStooges; use Time::Stamp qw( local-compact gm-easy );
}

like(RanOutOfStooges::gmstamp,    qr/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} Z$/,  'gm-easy shortcut');
like(RanOutOfStooges::localstamp, qr/^\d{4} \d{2} \d{2} _ \d{2} \d{2} \d{2}$/x, 'local-compact shortcut');

{ package # shh...
  NeedMoreStooges; use Time::Stamp qw( local-numeric-us gm-ms-compact );
}

like(NeedMoreStooges::gmstamp,    qr/^\d{4} \d{2} \d{2} _ \d{2} \d{2} \d{2} \.\d{3} Z$/x,  'gm-ms-compact shortcut');
like(NeedMoreStooges::localstamp, qr/^\d{4} \d{2} \d{2}   \d{2} \d{2} \d{2} \.\d{6}$/x, 'local-numeric-us shortcut');

{ package # shh...
  StillMoreStooges; use Time::Stamp qw( local-ms gm-us );
}

like(StillMoreStooges::gmstamp,    qr/^\d{4}-\d{2}-\d{2} T \d{2}:\d{2}:\d{2} \.\d{6} Z$/x,  'gm-us shortcut');
like(StillMoreStooges::localstamp, qr/^\d{4}-\d{2}-\d{2} T \d{2}:\d{2}:\d{2} \.\d{3}$/x, 'local-ms shortcut');

# collector
# TODO

done_testing;
