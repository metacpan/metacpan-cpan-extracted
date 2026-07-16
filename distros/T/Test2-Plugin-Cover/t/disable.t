use Test2::Plugin::Cover ();
use Test2::V0 -target => 'Test2::Plugin::Cover';
use Path::Tiny qw/path/;
use Fcntl qw/O_RDONLY/;

BEGIN { unshift @INC => 't/lib' }

require Fake1;

$CLASS->enable;
$CLASS->reset_coverage;
$CLASS->disable;

ok(!$CLASS->enabled, "disabled");

Fake1->fake;
open(my $fh, '<', 'zzz_disabled.json');
sysopen(my $fh2, 'yyy_disabled.json', O_RDONLY);
$CLASS->touch_source_file('manual_disabled.pl');
$CLASS->touch_data_file('manual_disabled.json');

is(
    [grep { m/disabled|Fake/ } keys %Test2::Plugin::Cover::REPORT],
    [],
    "nothing recorded while disabled, not even manual touches"
);

like(dies { $CLASS->touch_source_file() }, qr/A file is required/, "still validates args while disabled");

$CLASS->enable;
ok($CLASS->enabled, "re-enabled");

Fake1->fake;
open(my $fh3, '<', 'zzz_enabled.json');
sysopen(my $fh4, 'yyy_enabled.json', O_RDONLY);
$CLASS->touch_source_file('manual_enabled.pl');
$CLASS->touch_data_file('manual_enabled.json');

like(
    $CLASS->files(root => path('.')),
    bag {
        item 'zzz_enabled.json';
        item 'yyy_enabled.json';
        item 'manual_enabled.pl';
        item 'manual_enabled.json';
        item 't/lib/Fake1.pm';
        etc;
    },
    "sub calls, opens, sysopens, and manual touches all recorded when enabled"
);

$CLASS->reset_coverage;

done_testing;
