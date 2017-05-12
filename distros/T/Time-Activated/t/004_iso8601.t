use strict;
use warnings;
use Test::More tests => 1;
use Test::MockTime qw();

use Time::Activated;

subtest 'Support for full iso8601 format and expansions' => sub {
	plan tests => 6;

	Test::MockTime::set_absolute_time('2000-01-01T00:00:00Z');
	
	time_activated
		after_moment '2000' => execute_logic { pass('Expand from yyyy') },
		after_moment '2000-01' => execute_logic { pass('Expand from from yyyy-mm') },
		after_moment '2000-01-01' => execute_logic { pass('Expand from yyyy-mm-dd') },
		after_moment '2000-01-01T00:00' => execute_logic { pass('Expand from yyyy-mm-ddTHH:mm') },
		after_moment '2000-01-01T00:00:00' => execute_logic { pass('Expand from yyyy-mm-ddTHH:mm:ss') },
		after_moment '1999-12-31T23:00:00-01:00' => execute_logic { pass('Expand from yyyy-mm-ddTHH:mm:ss -1 with -1 TZ') },
		after_moment '2000-01-01T00:00:00-01:00' => execute_logic { fail('Expand from yyyy-mm-ddTHH:mm:ss with -1 TZ') };
};
