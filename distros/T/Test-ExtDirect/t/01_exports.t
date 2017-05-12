use strict;
no  strict 'refs';
use warnings;

use Test::More tests => 4;

use_ok 'Test::ExtDirect';

my @default_exports = qw(
    start_server stop_server call_extdirect call_extdirect_ok
    submit_extdirect submit_extdirect_ok poll_extdirect poll_extdirect_ok
    get_extdirect_api
);

my @all_exports = qw(
    start_server stop_server call_extdirect call_extdirect_ok
    submit_extdirect submit_extdirect_ok poll_extdirect poll_extdirect_ok
    call submit poll call_ok submit_ok poll_ok get_extdirect_api
);

my %shortcuts = (
    call      => 'call_extdirect',
    call_ok   => 'call_extdirect_ok',
    submit    => 'submit_extdirect',
    submit_ok => 'submit_extdirect_ok',
    poll      => 'poll_extdirect',
    poll_ok   => 'poll_extdirect_ok',
);

my $exported = 1;
my $failed;

for my $export ( @default_exports ) {
    $exported = !!*{"main::$export"}{CODE};

    if ( not $exported ) {
        $failed = $export;
        last;
    };
};

ok $exported, sprintf "Default exports%s", $failed ? ": $failed" : '';

Test::ExtDirect->import(':all');

$exported = 1;

for my $export ( @all_exports ) {
    $exported = !!*{"main::$export"}{CODE};

    if ( not $exported ) {
        $failed = $export;
        last;
    };
};

ok $exported, sprintf "All exports%s", $failed ? ": $failed" : '';

my $got_shortcuts = 1;

while ( my ($k, $v) = each %shortcuts ) {
    $got_shortcuts = !!(*{"main::$k"}{CODE} eq *{"main::$v"}{CODE});

    if ( not $got_shortcuts ) {
        $failed = $k;
        last;
    };
};

ok $got_shortcuts, sprintf "All shortcuts%s", $failed ? ": $failed" : '';

