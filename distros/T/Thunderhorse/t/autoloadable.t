use v5.40;
use Test2::V1 -ipP;

################################################################################
# This tests whether autoloading works correctly
################################################################################

package TestApp {
	use Mooish::Base -standard;
	extends 'Thunderhorse::App';

	sub testone ($self, $arg)
	{
		return "one $arg " . ref $self;
	}
}

package TestAutoloader {
	use Mooish::Base -standard;
	extends 'Thunderhorse::AppController';

	sub testone ($self, @args)
	{
		return 'altered ' . $self->SUPER::testone(@args);
	}

	sub testtwo ($self, @args)
	{
		return $self->SUPER::testtwo(@args);
	}
}

my $app = TestApp->new;
my $c = TestAutoloader->new(app => $app);

subtest '"can" from app controller should work' => sub {
	can_ok $c, ['testone', 'run'], 'can on app methods ok';
	can_ok $c, ['does', 'meta'], 'can on Moo methods ok';
	can_ok $c, ['isa', 'DOES'], 'can on universal methods ok';
};

subtest 'autoloading from app controller should work' => sub {
	is $c->testone('two'), 'altered one two TestApp', 'running app methods ok';
	ok $c->does('Thunderhorse::Autoloadable'), 'running Moo methods ok';
	ok $c->isa('Thunderhorse::Controller'), 'running universal methods ok';
};

subtest 'autoloading bad symbols should not work' => sub {
	ok !$c->can('testthree'), 'can on bad methods ok';
	like dies { $c->testtwo }, qr{no such method testtwo},
		'method with bad SUPER ok';
	like dies { $c->testthree }, qr{no such method testthree}, 'bad method ok';
};

done_testing;

