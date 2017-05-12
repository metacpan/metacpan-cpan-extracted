#!perl -w

use lib 't';

use WWW'Scripter;

{ package ScriptHandler;
  sub new { shift; bless [@_] }
  sub eval { my $self = shift; $self->[0](@_) }
  sub event2sub { my $self = shift; $self->[1](@_) }
}

my @__;
(my $m = new WWW::Scripter)->script_handler(
 qr/javascript/i => new ScriptHandler sub { push @__, $_[1] }
);

use tests 4; # basic timeout tests
diag('This script (timers.t) pauses a few times.');
{
 package fake_code_ref;
 use overload fallback=>1,'&{}' =>sub{${$_[0]}}
}
$m->get('data:text/html,');
$m->setTimeout("42",2000);
$m->setTimeout(sub { push @__, 'scrext' }, 2000);
$m->setTimeout(
 bless(\sub { push @__, 'sked' }, fake_code_ref::),
 2000
);
$m->clearTimeout($m->setTimeout("43",2100));
$m->check_timers;
is "@__", '', 'before timeout';
$_ = 'crit';
is $m->count_timers, 3, 'count_timers';
is $_, 'crit', 'count_timers does not clobber $_'; # fixed in 0.008
sleep 3;
$m->check_timers;
is "@__", '42 scrext sked', 'timeout';

use tests 5; # frames
@__ = ();
$m->get('data:text/html,<iframe>');
$m->setTimeout('cile',500);
$m->frames->[0]->setTimeout('frew',501);
is $m->count_timers, 2, 'count_timers with frames';
sleep 1;
$m->check_timers;
is "@__", 'cile frew', 'check_timers with frames';
$m->frames->[0]->setTimeout('dat',500);
is $m->count_timers, 1, 'count_timers with timers only in frames';
sleep 1;
$m->check_timers;
is "@__", 'cile frew dat', 'check_timers with timers only in frames';
{
 my $w = new WWW::Scripter;
 $m->get('data:text/html,<iframe>');
 $m->frames->[0]->setTimeout('dat',500);
 is $m->count_timers, 1,
  'count_timers w/timers in frame when the main window has never had any';
  # Yes, this actually failed.
}


use tests 2; # errors
{
 my $w;
 local $SIG{__WARN__} = sub { $w = shift };
 $m->setTimeout(sub{die 'cror'}, 500);
 sleep 1;
 ok eval { $m->check_timers; 1 },
  'script errors do not cause check_timers to die';
 like $w, qr/^cror/, 'check_timers turns errors into warnings';
}

use tests 5; # basic interval tests
$m->get('data:text/html,');
@__ = ();
$id = $m->setInterval("42",500);
$id2 = $m->setInterval(sub { push @___, 'scrext' }, 1000);
$id3 = $m->setInterval(
 bless(\sub { push @____, 'sked' }, fake_code_ref::),
 1100
);
$m->clearInterval($m->setInterval("43",1000));
is $m->count_timers, 3, 'count_timers with setInterval';
for(1..2500/100) { # 2.5 seconds; 100 ms intervals
 $m->check_timers;
 select(undef,undef,undef,.1);
}
like "@__", qr/^42 42 42 42 42/, "setInterval with string";
like "@___", qr/^scrext scrext/, "setInterval with code ref";
like "@____", qr/^sked sked/, "setInterval with &{}-overloaded object";
$m->clearInterval($_) for $id, $id2, $id3;
is $m->count_timers, 0, 'clearInterval';

use tests 5; # wait_for_timers
$id = $m->setInterval(sub{}, 100);
$m->setTimeout(sub{}, 100);
my $start_time = time;
$m->wait_for_timers(max_wait => 2);
cmp_ok time-$start_time, '>=', 2, 'wait_for_timers with max_wait';
is $m->count_timers, 1, 'wait_for_timers left a timer running';

$start_time = time;
$m->setTimeout(sub{}, 100);
$m->wait_for_timers(min_timers => 1);
cmp_ok time-$start_time, '<=', 1, 'wait_for_timers with min_timers';
is $m->count_timers, 1,
 'wait_for_timers with min_timers left a timer running';
$m->clearInterval($id);

$start_time = time;
$m->setTimeout(sub{}, 200);
$m->wait_for_timers(interval => 1);
# We allow for 2 sec in this regexp, because of overhead; e.g., if the
# timer starts at 5.999 sec. past midnight, the overhead may cause the cur-
# rent time to be 7.001.
like time-$start_time, qr/^[12]\z/, 'wait_for_timers with interval';


use tests 1; # A bug in 0.015 and earlier: If the JavaScript plugin is not
             # loaded, check_timers will simply return on finding a string
             # of code,  instead of continuing to see whether there is  a   
{            # code ref. This has only been a problem since 0.008, which
 my $called;  # introduced code ref timers.
 (my $w = new WWW::Scripter)->setTimeout("prin",0);
 $w->setTimeout(sub{++$called},0);
 $w->check_timers; 
 is $called, 1,
  'string timeouts do not inhibit code ref timeouts without JS plugin';
}

use tests 1; # script errors
{
	my $w;
	(my $m = new WWW::Scripter onwarn => sub { $w = shift })
	 ->script_handler(
			default => new ScriptHandler sub {
				$@ = "tew"
			}, sub {} 
	);
	$m->setTimeout("tror",0);
	$m->check_timers;
	is $w, 'tew', 'script errors turn into warnings';
}
