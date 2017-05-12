use strict;
use warnings;
use Test::More tests => 2;
use Test::MockTime qw();

use Time::Activated;

subtest 'Exact moments with after_moment and before' => sub {
	plan tests => 4;

	Test::MockTime::set_absolute_time('2000-01-01T00:00:00Z');

	time_activated
		after_moment '2000-01-01T00:00:00' => execute_logic { pass('After matches exact moment') },
		before_moment '2000-01-01T00:00:00' => execute_logic { fail('After matches exact moment') };

	time_activated
		after_moment '2000-01-01T00:00:00-00:00' => execute_logic { pass('After matches exact moment with TZ +0') },
		after_moment '2000-01-01T00:00:00+01:00' => execute_logic { pass('After matches exact moment with TZ +1') },
		after_moment '2000-01-01T00:00:00-01:00' => execute_logic { fail('After matches exact moment with TZ -1') },
		before_moment '2000-01-01T00:00:00-00:00' => execute_logic { fail('Before matches exact moment with TZ +0') },
		before_moment '2000-01-01T00:00:00+01:00' => execute_logic { fail('Before matches exact moment with TZ +1') },
		before_moment '2000-01-01T00:00:00-01:00' => execute_logic { pass('Before matches exact moment with TZ -1') },
};

subtest 'Exact moments with between' => sub {
	plan tests => 2;

	Test::MockTime::set_absolute_time('2000-01-01T00:00:00Z');
	time_activated
		between_moments '2000-01-01T00:00:00' => '2001-01-01T00:00:00' => execute_logic { pass('Between matches exact beggining') };

	Test::MockTime::set_absolute_time('2001-01-01T00:00:00Z');
	time_activated
		between_moments '2000-01-01T00:00:00' => '2001-01-01T00:00:00' => execute_logic { pass('Between matches exact endding') };
};

