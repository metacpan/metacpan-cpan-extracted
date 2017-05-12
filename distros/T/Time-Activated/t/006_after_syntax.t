use strict;
use warnings;
use Test::More tests => 3;
use Test::MockTime qw();

use Time::Activated;

subtest 'After simple syntax' => sub {
	plan tests => 3;
	Test::MockTime::set_absolute_time('9999-01-01T01:00:00Z');

	time_activated
		after_moment '9999', execute_logic { pass('After simple syntax iso8601 year based') };

	time_activated
		after_moment '9999-01-01T00:00:00', execute_logic { pass('After simple syntax iso8601 full no timezone') };

	time_activated
		after_moment '9999-01-01T01:30:00', execute_logic { fail('After simple syntax iso8601 full no timezone future') };

	Test::MockTime::set_absolute_time('9999-01-01T02:00:00Z');

	time_activated
		after_moment '9999-01-01T01:30:00', execute_logic { pass('After simple syntax iso8601 full no timezone future FF +1 hour') };
};

subtest 'After complex syntax' => sub {
	plan tests => 5;
	Test::MockTime::set_absolute_time('9999-01-01T01:00:00Z');

	time_activated
		after_moment '9999', execute_logic { pass('After complex syntax iso8601 year based') },
		after_moment '9999-01-01T00:00:00', execute_logic { pass('After complex syntax iso8601 full no timezone') },
		after_moment '9999-01-01T01:30:00', execute_logic { fail('After complex syntax iso8601 full no timezone future FF +1 hour') };

	Test::MockTime::set_absolute_time('9999-01-01T02:00:00Z');

	time_activated
		after_moment '9999', execute_logic { pass('After complex syntax iso8601 year based FF +1 hour') },
		after_moment '9999-01-01T00:00:00', execute_logic { pass('After complex syntax iso8601 full no timezone FF +1 hour') },
		after_moment '9999-01-01T01:30:00', execute_logic { pass('After complex syntax iso8601 full no timezone future FF +1 hour') };
};

subtest 'After fancy syntax' => sub {
	plan tests => 5;
	Test::MockTime::set_absolute_time('9999-01-01T01:00:00Z');

	time_activated
		after_moment '9999' => execute_logic { pass('After fancy syntax iso8601 year based') },
		after_moment '9999-01-01T00:00:00' => execute_logic { pass('After fancy syntax iso8601 full no timezone') },
		after_moment '9999-01-01T01:30:00' => execute_logic { fail('After fancy syntax iso8601 full no timezone future FF +1 hour') };

	Test::MockTime::set_absolute_time('9999-01-01T02:00:00Z');

	time_activated
		after_moment '9999' => execute_logic { pass('After fancy syntax iso8601 year based FF +1 hour') },
		after_moment '9999-01-01T00:00:00' => execute_logic { pass('After fancy syntax iso8601 full no timezone FF +1 hour') },
		after_moment '9999-01-01T01:30:00' => execute_logic { pass('After fancy syntax iso8601 full no timezone future FF +1 hour') };
};
