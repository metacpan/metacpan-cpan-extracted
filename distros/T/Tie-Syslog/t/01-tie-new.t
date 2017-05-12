#!perl -T

use Test::More tests => 7;
use Tie::Syslog;
no warnings qw(once);

$Tie::Syslog::ident  = 'Tie::Syslog newstyle test';
$Tie::Syslog::logopt = 'pid,ndelay';

eval q( tie *FAIL, "Tie::Syslog", {}; );
ok( $@, "Parameters check" );

eval q(
    tie *TEST, "Tie::Syslog", {
        'priority' => 'LOG_DEBUG',
        'facility' => 'LOG_LOCAL0',
    };
);
ok ( ! $@, "Tying test ($@)" );

eval q(
    print  TEST "Built!";
    printf TEST "%d", 1;

    my $str = "testprint";
    syswrite (TEST, $str, 4, 0);
);
ok ( ! $@, "Print test ($@)" );

eval q( close TEST; );
ok ( ! $@, "Close test ($@)" );

eval q( open TEST, "ignored-param"; );
ok ( ! $@, "Reopen handle test ($@)" );

eval q( print TEST "A new beginning"; );
ok (! $@, "Print after close-and-open ($@)");

eval q( untie *TEST; );
ok (! $@, "Untie test");

