#!perl -T

use Test::More tests => 8;
use Tie::Syslog;
no warnings qw(once);

eval q( tie *DEF, "Tie::Syslog"; );
ok( ! $@, "Tying with defaults ($@)" );

eval q( print DEF "Built!"; );
ok ( ! $@, "Print test with defaults ($@)" );

eval q( close DEF; );
ok (! $@, "Close handle ($@)");

eval q( open DEF; );
ok (! $@, "Reopen handle ($@)");

eval q( untie *DEF; );
ok (! $@, "Untie handle ($@)");

# ------------------------------------------------------------------------------

eval q( tie *TEST, "Tie::Syslog", 'local0.debug'; );
ok ( ! $@, "Tying with old style syntax ($@)" );

eval q( print TEST "Built!"; );
ok ( ! $@, "Print test ($@)" );

eval q( untie *TEST; );
ok (! $@, "Untie handle ($@)");

