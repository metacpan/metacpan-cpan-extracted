use strict;
use warnings;
use Test::More tests => 4;
use Test::MockTime qw();

use Time::Activated;
use DateTime;

subtest 'Fancy multiline syntax iso8601' => sub {
    Test::MockTime::set_absolute_time('1986-05-27T00:00:00Z');

	time_activated
		after_moment '1985-01-01T00:00:00+00:00', execute_logic { pass('Basic after') },
	    before_moment '1986-12-31T00:00:00+00:00', execute_logic { pass('Basic before') },
		between_moments '1985-01-01T00:00:00+00:00', '1986-12-31T00:00:00+00:00', execute_logic { pass('Basic between') };
};

subtest 'Fancy DateTime syntax' => sub {
    my $past = DateTime::Infinite::Past->new();
    my $future = DateTime::Infinite::Future->new();

    time_activated after_moment $past, execute_logic { pass('After simple syntax DT past') };
    time_activated after_moment $future, execute_logic { fail('After simple syntax DT future should never be in the past') };
};

subtest 'Fancy multiline abusing hash iso8601' => sub {
    Test::MockTime::set_absolute_time('1986-05-27T00:00:00Z');

	time_activated
		after_moment '1985-01-01T00:00:00+00:00' => execute_logic { pass('Basic after') },
	    before_moment '1986-12-31T00:00:00+00:00' => execute_logic { pass('Basic before') },
		between_moments '1985-01-01T00:00:00+00:00' => '1986-12-31T00:00:00+00:00' => execute_logic { pass('Basic between') };
};

subtest 'Fancy conditions with external subs' => sub {
	plan tests => 4;

	Test::MockTime::set_absolute_time('2001-01-01T00:00:00Z');

	time_activated
		after_moment '2001' => execute_logic \&external_condition_pass;

	time_activated
		after_moment '2001' => execute_logic {&external_condition_pass('External conditions')};

	time_activated
		after_moment '2001' => execute_logic (\&external_condition_pass),
		after_moment '2000' => execute_logic (\&external_condition_pass),
		after_moment '2002' => execute_logic \&external_condition_fail;
};

sub external_condition_pass {
	pass($_[0]);
}

sub external_condition_fail {
	fail($_[0]);
}
