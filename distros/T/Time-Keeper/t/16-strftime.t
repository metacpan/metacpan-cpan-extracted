#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
use POSIX ();

use Time::Keeper;

my $K = 'Time::Keeper';

# The conversions C has, against the C library's own strftime in the C
# locale, for random instants from 1970 to 2100 in UTC.
POSIX::setlocale(POSIX::LC_TIME(), 'C');
my @c = qw(a A b B C d D e F g G H I j m M p r R S T u U V w W y Y %);
my $pat = join '|', map { "%$_" } @c;
srand(16);
my ($n, $bad) = (0, 0);
for (1 .. 2000) {
    my $s = int(rand(4_102_444_800));
    my $t = $K->from_epoch($s);
    my $want = POSIX::strftime($pat, gmtime $s);
    my $got = $t->strftime($pat);
    $n++;
    next if $got eq $want;
    diag("$s: here '$got', C '$want'") if $bad < 3;
    $bad++;
}
is($bad, 0, "%a %A %b %B %C %d %D %e %F %g %G %H %I %j %m %M %p %r %R %S %T %u %U %V %w %W %y %Y %% agree with C on $n instants");

my $t = $K->new(year => 2026, month => 10, day => 15, hour => 9, minute => 5, second => 7,
                nanosecond => 123_456_789, zone => 'Asia/Tokyo');
is($t->strftime('%N'), '123456789', '%N is nine digits of nanoseconds');
is($t->strftime('%3N %6N %1N'), '123 123456 1', '%3N, %6N, %1N truncate');
is($t->strftime('%12N'), '123456789000', 'and %12N pads');
is($t->strftime('%s'), '1792022707', '%s is the epoch, whatever the zone');
is($t->strftime('%z %Z'), '+0900 JST', '%z and %Z');
is($t->strftime('%k|%l|%P'), ' 9| 9|am', '%k, %l and %P');
is($t->strftime('%n%t'), "\n\t", '%n and %t');
is($t->strftime('%h'), 'Oct', '%h is %b');
is($t->strftime('%q %E %'), '%q %E %', 'conversions it does not know are left as they were');

is($t->strftime('%-d %-m %-H'), '15 10 9', 'the - flag drops padding');
is($K->new(year => 2026, month => 3, day => 5)->strftime('%_d|%_m|%0e'), ' 5| 3|05', '_ pads with spaces, 0 with zeros');
is($t->strftime('%^a %^B %^p'), 'THU OCTOBER AM', '^ upper-cases');
is($K->new(year => 2026, month => 3, day => 5)->strftime('%10Y|%_10Y|%5d'), '0000002026|      2026|00005', 'a width pads numbers');

is($t->strftime('%{day_name} %{month_abbr}'), 'Thursday Oct', '%{method} calls the method');
is($t->strftime('%{no_such_method}'), '%{no_such_method}', 'and leaves one that is not there');
{
    package My::Keeper;
    our @ISA = ('Time::Keeper');
    sub mood { 'calm' }
}
is(My::Keeper->new(year => 2026)->strftime('%{mood}'), 'calm', 'a subclass\'s own method');

is($t->strftime('%c'), "Oct 15, 2026, 9:05:07\x{202F}AM", '%c is the locale\'s medium date and time');
is($t->strftime('%x'), 'Oct 15, 2026', '%x its medium date');
is($t->strftime('%X'), "9:05:07\x{202F}AM", '%X its medium time, with CLDR\'s narrow no-break space');
ok(utf8::is_utf8($t->strftime('%X')), 'which comes back as characters');
ok(!utf8::is_utf8($t->strftime('%F')), 'and plain ASCII does not');
is($t->strftime('%A, %d. %B'), 'Thursday, 15. October', 'literal text around the conversions');
is($t->strftime('é %Y ü'), 'é 2026 ü', 'a pattern with characters in it');

my @two = $t->strftime('%Y', '%m');
is_deeply(\@two, ['2026', '10'], 'several patterns, several results');
my $first = $t->strftime('%Y', '%m');
is($first, '2026', 'and in scalar context the first');

is($K->new(year => 2016, month => 12, day => 31, hour => 23, minute => 59, second => 60)->strftime('%S %T %s'),
   '60 23:59:60 1483228800', 'a leap second\'s %S is 60, and its %s the midnight after');
my $f = $K->new(year => 2026, zone => 'floating');
is($f->strftime('%z %Z'), '+0000 floating', 'floating time, as DateTime gives it');
is($K->new(year => 2026, zone => '+05:45:30')->strftime('%z'), '+054530', 'an offset with seconds keeps them');
is($K->new(year => -44, month => 3, day => 15)->strftime('%Y %y %C'), '-44 44 0', 'a year before Christ');
is($K->new(year => 5)->strftime('%Y %y %G %g'), '5 05 4 4', 'a one-digit year');

ok(!eval { $t->strftime; 1 }, 'strftime needs a pattern');

done_testing;
