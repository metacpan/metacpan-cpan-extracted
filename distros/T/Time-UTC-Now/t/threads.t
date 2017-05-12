use warnings;
use strict;

BEGIN {
	eval { require threads; };
	if($@ =~ /\AThis Perl not built to support threads/) {
		require Test::More;
		Test::More::plan(skip_all => "non-threading perl build");
	}
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "threads unavailable");
	}
	eval { require Thread::Semaphore; };
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "Thread::Semaphore unavailable");
	}
	eval { require threads::shared; };
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "threads::shared unavailable");
	}
}

use threads;

use Test::More tests => 6;
use Thread::Semaphore ();
use threads::shared;

my $done1 = Thread::Semaphore->new(0);
my $exit1 = Thread::Semaphore->new(0);
my $done2 = Thread::Semaphore->new(0);
my $exit2 = Thread::Semaphore->new(0);
my $done3 = Thread::Semaphore->new(0);
my $exit3 = Thread::Semaphore->new(0);
my $done4 = Thread::Semaphore->new(0);
my $exit4 = Thread::Semaphore->new(0);

my $ok1 :shared;
my $thread1 = threads->create(sub {
	my $ok = 1;
	eval(q{
		use Time::UTC::Now
			qw(now_utc_rat now_utc_sna now_utc_flt now_utc_dec);
		now_utc_rat();
		now_utc_sna();
		now_utc_flt();
		now_utc_dec();
		1;
	}) or $ok = 0;
	$ok1 = $ok;
	$done1->up;
	$exit1->down;
});
$done1->down;
ok $ok1;

my $ok2 :shared;
my $thread2 = threads->create(sub {
	my $ok = 1;
	eval(q{
		use Time::UTC::Now
			qw(now_utc_rat now_utc_sna now_utc_flt now_utc_dec);
		now_utc_rat();
		now_utc_sna();
		now_utc_flt();
		now_utc_dec();
		1;
	}) or $ok = 0;
	$ok2 = $ok;
	$done2->up;
	$exit2->down;
});
$done2->down;
ok $ok2;

ok eval(q{
	use Time::UTC::Now
		qw(now_utc_rat now_utc_sna now_utc_flt now_utc_dec);
1; });

my $ok3 :shared;
my $thread3 = threads->create(sub {
	my $ok = 1;
	"$]" < 5.007002 or eval(q{
		now_utc_rat();
		now_utc_sna();
		now_utc_flt();
		now_utc_dec();
		1;
	}) or $ok = 0;
	$ok3 = $ok;
	$done3->up;
	$exit3->down;
});
$done3->down;
ok $ok3;

my $ok4 :shared;
my $thread4 = threads->create(sub {
	my $ok = 1;
	"$]" < 5.007002 or eval(q{
		now_utc_rat();
		now_utc_sna();
		now_utc_flt();
		now_utc_dec();
		1;
	}) or $ok = 0;
	$ok4 = $ok;
	$done4->up;
	$exit4->down;
});
$done4->down;
ok $ok4;

$exit1->up;
$exit2->up;
$exit3->up;
$exit4->up;
$thread1->join;
$thread2->join;
$thread3->join;
$thread4->join;
ok 1;

1;
