use strict;
use warnings;

use Test::More 0.98;

BEGIN {
    if (defined $ENV{GBUDDY_USERNAME} && $ENV{GBUDDY_PASSWORD}) {
        plan tests => 7;
    }
    else {
        plan skip_all => 'GBUDDY_USERNAME and GBUDDY_PASSWORD environemnt vars not defined}';
    }

    use_ok 'WebService::GlucoseBuddy';
}

my $gb = new_ok('WebService::GlucoseBuddy' => [
    username    => $ENV{GBUDDY_USERNAME},
    password    => $ENV{GBUDDY_PASSWORD},
]);

my $logs_set = $gb->logs;

my $log = $logs_set->next;
isa_ok($log => 'WebService::GlucoseBuddy::Log');

my $reading = $log->reading;
isa_ok($reading => 'WebService::GlucoseBuddy::Log::Reading');

like($reading->value, qr/^[0-9\.]+$/, 'Reading value');
ok($log->event, 'Log event');
like(
    $log->time, 
    qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/,
    'Log time'
);

done_testing();

