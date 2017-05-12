use strict;
use warnings;
use Test::More tests => 3;
use Test::MockTime qw();

use Time::Activated;
use DateTime;

subtest 'Basic syntax iso8601' => sub {
	plan tests => 3;

	Test::MockTime::set_absolute_time('1986-05-27T00:00:00Z');

	time_activated after_moment '1985-01-01T00:00:00-03:00', execute_logic { pass('Basic after') };
    time_activated before_moment '1986-12-31T00:00:00-03:00', execute_logic { pass('Basic before') };
    time_activated between_moments '1985-01-01T00:00:00Z', '1986-12-31T00:00:00Z', execute_logic { pass('Basic between') };
};

subtest 'Basic inline documentation syntax iso8601' => sub {
	plan tests => 3;

	Test::MockTime::set_absolute_time('2018-05-27T00:00:00Z');
	time_activated after_moment '2018', execute_logic { pass('Basic documented after 2018') };

	Test::MockTime::set_absolute_time('2017-05-27T00:00:00Z');
	time_activated before_moment '2018', execute_logic { pass('Basic documented before 2018') };

	Test::MockTime::set_absolute_time('2018-05-27T00:00:00Z');
	time_activated between_moments '2018','2018-12-31T23:59:59', execute_logic { pass('Basic documented between 2018') };
};

subtest 'Basic syntax DateTime' => sub {
	plan tests => 1;

    my $past = DateTime::Infinite::Past->new();
    time_activated after_moment $past, execute_logic { pass('After simple syntax DT past') };

    my $future = DateTime::Infinite::Future->new();
    time_activated after_moment $future, execute_logic { fail('After simple syntax DT future should never be in the past') };
};
