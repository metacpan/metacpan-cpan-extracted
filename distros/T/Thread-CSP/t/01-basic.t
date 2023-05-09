#! perl

use strict;
use warnings;

use Test::More;
use Thread::CSP;

use lib 't/lib';

subtest 'First', sub {
	my $q = Thread::CSP::Channel->new;
	my $r = Thread::CSP->spawn('Basic', 'Basic::basic', $q, 7);

	ok(!$r->is_finished, 'is not finished');
	$q->send(6);
	is($q->receive, 42, 'product is correct');

	is($r->get, 13, 'returns 13');
	is($r->get, 13, 'returns 13 again');
	ok($r->is_finished, 'is finished');
};

subtest 'Second', sub {
	my $r = Thread::CSP->spawn('Basic', 'Basic::non_existent');
	my $val = eval { $r->get };
	like($@, qr/Undefined subroutine &Basic::non_existent called./);
};

subtest 'Third', sub {
	my $r = Thread::CSP->spawn('NonExistent', 'Basic::one');
	my $val = eval { $r->get };
	like($@, qr/Can't locate NonExistent.pm in \@INC/);
};

subtest 'Fourth', sub {
	my $q = Thread::CSP::Channel->new;
	my $r = Thread::CSP->spawn('Basic', 'Basic::basic', $q, 7);

	my $in = $r->finished_fh;
	ok(!$r->is_finished, 'is not finished');
	$q->send(1);
	$q->receive;
	read $in, my $buffer, 1 or die;
	is($buffer, "\377", 'Event as expected');
};

subtest 'Fifth', sub {
	my $q = Thread::CSP::Channel->new;
	my $r = Thread::CSP->spawn('Basic', 'Basic::closed', $q);

	$q->send(6);
	$q->send(7);
	$q->close;
	is($r->get(), 13);
};

subtest 'Thread', sub {
	use threads::shared;

	my @value :shared = 42;
	my $q = Thread::CSP::Channel->new;
	my $r = Thread::CSP->spawn('Basic', 'Basic::two', \@value);
	is($r->get, 12);
	is($value[0], 24);
};

done_testing();
