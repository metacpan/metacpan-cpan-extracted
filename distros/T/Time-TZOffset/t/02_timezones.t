use strict;
use warnings;
use Test::More;

use File::Basename;

my $inc = join ' ', map { "-I\"$_\"" } @INC;
my $dir = dirname(__FILE__);

my $found;
for my $tz (qw( Europe/Paris CET-1CEST )) {
    $ENV{TZ} = $tz;
    if (`$^X $inc $dir/02_timezones.pl string 0 0 0 1 1 112` =~ /^\+0[12]00$/) {
        $found = 1;
        last;
    };
};

if ($found) {
    plan tests => 4;
}
else {
    plan skip_all => 'Missing tzdata on this system';
};

my @t1 = (0, 0, 0, 1, 1, 112);
my @t2 = (0, 0, 0, 1, 7, 112);

is `$^X $inc $dir/02_timezones.pl string  @t1`, '+0100',     "tmzone1($ENV{TZ})";
is `$^X $inc $dir/02_timezones.pl string  @t2`, '+0200',     "tmzone2($ENV{TZ})";
is `$^X $inc $dir/02_timezones.pl seconds @t1`, 1 * 60 * 60, "tmzone1($ENV{TZ})";
is `$^X $inc $dir/02_timezones.pl seconds @t2`, 2 * 60 * 60, "tmzone2($ENV{TZ})";
