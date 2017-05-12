# vim: set sw=2 sts=2 ts=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;

use Time::Stamp ();

sub f { goto &Time::Stamp::_format; }

my %z = qw(tz Z);
my %f = (frac => 6);
my %zf = (%z, %f);

# names
is(f({format => 'default'}),    '%04d-%02d-%02dT%02d:%02d:%02d',   'default format spec');
is(f({format => 'default',%z}), '%04d-%02d-%02dT%02d:%02d:%02dZ',  'default format spec with tz');
is(f({format => 'default',%f}), '%04d-%02d-%02dT%02d:%02d:%02d%s', 'default format spec with us');
is(f({format => 'default',%zf}),'%04d-%02d-%02dT%02d:%02d:%02d%sZ','default format spec with us and tz');

is(f({format => 'easy'   }),    '%04d-%02d-%02d %02d:%02d:%02d',   'easy to read');
is(f({format => 'easy',   %z}), '%04d-%02d-%02d %02d:%02d:%02d Z', 'easy to read with tz');
is(f({format => 'easy',   %f}), '%04d-%02d-%02d %02d:%02d:%02d%s',   'easy to read with us');
is(f({format => 'easy',   %zf}),'%04d-%02d-%02d %02d:%02d:%02d%s Z', 'easy to read with us and tz');

is(f({format => 'numeric'}),    '%04d%02d%02d%02d%02d%02d',        'numeric');
is(f({format => 'numeric',%z}), '%04d%02d%02d%02d%02d%02dZ',       'numeric');
is(f({format => 'numeric',%f}), '%04d%02d%02d%02d%02d%02d%s',      'numeric');
is(f({format => 'numeric',%zf}),'%04d%02d%02d%02d%02d%02d%sZ',     'numeric');

is(f({format => 'compact'}),    '%04d%02d%02d_%02d%02d%02d',       'compact');
is(f({format => 'compact',%z}), '%04d%02d%02d_%02d%02d%02dZ',      'compact');
is(f({format => 'compact',%f}), '%04d%02d%02d_%02d%02d%02d%s',     'compact with us');
is(f({format => 'compact',%zf}),'%04d%02d%02d_%02d%02d%02d%sZ',    'compact with us and tz');

# aliases for default
is(f({format => 'iso8601'}),    '%04d-%02d-%02dT%02d:%02d:%02d',   'the famous iso8601');
is(f({format => 'iso8601',%z}), '%04d-%02d-%02dT%02d:%02d:%02dZ',  'the famous iso8601 with tz');
is(f({format => 'rfc3339'}),    '%04d-%02d-%02dT%02d:%02d:%02d',   'rfc3339 profile of iso8601');
is(f({format => 'rfc3339',%z}), '%04d-%02d-%02dT%02d:%02d:%02dZ',  'rfc3339 with tz');
is(f({format => 'w3cdtf' }),    '%04d-%02d-%02dT%02d:%02d:%02d',   'w3cdtf  profile of iso8601');
is(f({format => 'w3cdtf', %z}), '%04d-%02d-%02dT%02d:%02d:%02dZ',  'w3cdtf  with tz');

is(f({format => 'goober' }),    '%04d-%02d-%02dT%02d:%02d:%02d',   'unknown becomes default');
is(f({format => 'goober', %z}), '%04d-%02d-%02dT%02d:%02d:%02dZ',  'unknown with tz');
is(f({format => 'goober', %f}), '%04d-%02d-%02dT%02d:%02d:%02d%s', 'default with us');
is(f({format => 'goober', %zf}),'%04d-%02d-%02dT%02d:%02d:%02d%sZ','default with us and tz');

# pieces
is(f({date_sep => '+'}),        '%04d+%02d+%02dT%02d:%02d:%02d',   'date_sep');
is(f({dt_sep   => '+'}),        '%04d-%02d-%02d+%02d:%02d:%02d',   'dt_sep');
is(f({time_sep => '+'}),        '%04d-%02d-%02dT%02d+%02d+%02d',   'time_sep');
is(f({tz_sep   => '+'}),        '%04d-%02d-%02dT%02d:%02d:%02d',   'tz_sep (no tz)');
is(f({tz_sep   => '+',%z}),     '%04d-%02d-%02dT%02d:%02d:%02d+Z', 'tz_sep (with tz)');
is(f({tz       => 'Z'}),        '%04d-%02d-%02dT%02d:%02d:%02dZ',  'tz');
is(f({frac     =>   8}),        '%04d-%02d-%02dT%02d:%02d:%02d%s', 'frac => 8');

done_testing;
