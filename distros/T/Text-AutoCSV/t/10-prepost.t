#!/usr/bin/perl

# t/10-prepost.t

#
# Written by Sébastien Millet
# June, September 2016
#

#
# Test script for Text::AutoCSV: pre and post subs
#

use strict;
use warnings;

use Test::More tests => 39;
#use Test::More qw(no_plan);

my $OS_IS_PLAIN_WINDOWS = !! ($^O =~ /mswin/i);
my $ww = ($OS_IS_PLAIN_WINDOWS ? 'ww' : '');

	# FIXME
	# If the below is zero, ignore this FIX ME entry
	# If the below is non zero, it'll use some hacks to ease development
my $DEVTIME = 0;

	# FIXME
	# Comment when not in dev
#use feature qw(say);
#use Data::Dumper;
#$Data::Dumper::Sortkeys = 1;

BEGIN {
	use_ok('Text::AutoCSV');
}

can_ok('Text::AutoCSV', ('new'));

use File::Temp qw(tmpnam);

if ($DEVTIME) {
	note("");
	note("***");
	note("***");
	note("***  !! WARNING !!");
	note("***");
	note("***  SET \$DEVTIME TO 0 BEFORE RELEASING THIS CODE TO PRODUCTION");
	note("***  RIGHT NOW, \$DEVTIME IS EQUAL TO $DEVTIME");
	note("***");
	note("***");
	note("");
}


# * ***************** *
# * read_update_after *
# * ***************** *

note("");
note("[RE]ad_update_after (a.k.a. in_map)");

my $tmpf = get_non_existent_temp_file_name();

my $csv = Text::AutoCSV->new(in_file => "t/${ww}pp1.csv", out_file => $tmpf)
	->read_update_after('NUM', \&in_updt)
	->write_update_before('NUM', \&out_updt)->write();

sub in_updt {
	return 0 if !defined($_) or $_ eq '';
	my $i;
	return -$i if ($i) = $_ =~ m/^\((.*)\)$/;
	$_;
}

sub out_updt {
	return '(' . (-$_) . ')' if $_ < 0;
	$_;
}

my $all = [ $csv->get_hr_all() ];
is_deeply($all,
	[{'NUM' => '18', 'RIEN' => '1'},
		{'NUM' => -15, 'RIEN' => '2'},
		{'NUM' => '0', 'RIEN' => '3'},
		{'NUM' => -1, 'RIEN' => ''}],
	"RE01 - t/pp1.csv: read_update_after"
);

my $csv2 = Text::AutoCSV->new(in_file => $tmpf);
my $all2 = [ $csv2->get_hr_all() ];
is_deeply($all2,
	[{ 'NUM' => '18', 'RIEN' => '1'},
		{'NUM' => '(15)', 'RIEN' => '2'},
		{'NUM' => '0', 'RIEN' => '3'},
		{'NUM' => '(1)', 'RIEN' => ''}],
	"RE02 - t/pp1.csv rewritten: check result of write_update_before"
);

$csv->write();
my $csv3 = Text::AutoCSV->new(in_file => $tmpf);
my $all3 = [ $csv3->get_hr_all() ];
is_deeply($all3,
	[{ 'NUM' => '18', 'RIEN' => '1'},
		{'NUM' => '(15)', 'RIEN' => '2'},
		{'NUM' => '0', 'RIEN' => '3'},
		{'NUM' => '(1)', 'RIEN' => ''}],
	"RE03 - t/pp1.csv rewritten: check result of write_update_before (in-memory)"
);

eval {
	local $SIG{__WARN__} = sub { };
	$csv->read()->read()->read()->write()->write()->write();
};
my $csv4 = Text::AutoCSV->new(in_file => $tmpf);
my $all4 = [ $csv4->get_hr_all() ];
is_deeply($all4,
	[{ 'NUM' => '18', 'RIEN' => '1'},
		{'NUM' => '(15)', 'RIEN' => '2'},
		{'NUM' => '0', 'RIEN' => '3'},
		{'NUM' => '(1)', 'RIEN' => ''}],
	"RE04 - t/pp1.csv rewritten: check result of write_update_before (multi)"
);


# * ******************* *
# * write_update_before *
# * ******************* *

note("");
note("[WR]rite_update_before (a.k.a. out_map)");

my $c = Text::AutoCSV->new(in_file => "t/${ww}pp1.csv", out_file => $tmpf)
	->in_map('RIEN', sub { "000$_" })
	->in_map('NUM', sub { s/1/7/g; $_; })
	->out_map('RIEN', \&c_updt);

sub c_updt {
	"__" . ($_ + 2);

}

my $aa = [ $c->get_hr_all() ];
is_deeply($aa,
	[{'NUM' => '78', 'RIEN' => '0001'},
		{'NUM' => '(75)', 'RIEN' => '0002'},
		{'NUM' => '0', 'RIEN' => '0003'},
		{'NUM' => '(7)', 'RIEN' => '000'}],
	"WR01 - t/pp1.csv: check content"
);

$c->write();
my $c2 = Text::AutoCSV->new(in_file => $tmpf);
my $a2 = [ $c2->get_hr_all() ];
is_deeply($a2,
	[{'NUM' => '78', 'RIEN' => '__3'},
		{'NUM' => '(75)', 'RIEN' => '__4'},
		{'NUM' => '0', 'RIEN' => '__5'},
		{'NUM' => '(7)', 'RIEN' => '__2'}],
	"WR02 - t/pp1.csv: check content"
);
$c->write();
my $c3 = Text::AutoCSV->new(in_file => $tmpf);
my $a3 = [ $c3->get_hr_all() ];
is_deeply($a3,
	[{'NUM' => '78', 'RIEN' => '__3'},
		{'NUM' => '(75)', 'RIEN' => '__4'},
		{'NUM' => '0', 'RIEN' => '__5'},
		{'NUM' => '(7)', 'RIEN' => '__2'}],
	"WR03 - t/pp1.csv: check content"
);

eval {
	local $SIG{__WARN__} = sub { };
	$c->read()->read()->read()->write()->write()->write();
};
my $c4 = Text::AutoCSV->new(in_file => $tmpf);
my $a4 = [ $c4->get_hr_all() ];
is_deeply($a4,
	[{'NUM' => '78', 'RIEN' => '__3'},
		{'NUM' => '(75)', 'RIEN' => '__4'},
		{'NUM' => '0', 'RIEN' => '__5'},
		{'NUM' => '(7)', 'RIEN' => '__2'}],
	"WR04 - t/pp1.csv: check content"
);


# * **************** *
# * DateTime objects *
# * **************** *

note("");
note("[DT] DateTime object management");

my $P_IN_THEORY =
	[{'ADMY' => 'DATETIME: 2016-12-14T00:00:00',
		'BMDY' => 'DATETIME: 2015-03-04T00:00:00',
		'CYMD' => 'DATETIME: 2014-02-28T00:00:00',
		'DANY' => 'bla',
		'EDMYT' => undef,
		'FMDYT' => 'DATETIME: 2015-03-04T23:45:16',
		'GYMDT' => 'DATETIME: 2014-02-28T15:45:00',
		'HBAD' => '2016-02-01',
		'IT' => 'DATETIME: 0001-01-01T20:15:00',
		'JUNDEF' => undef},
	{'ADMY' => 'DATETIME: 2016-12-31T00:00:00',
		'BMDY' => 'DATETIME: 2015-03-31T00:00:00',
		'CYMD' => 'DATETIME: 2014-02-01T00:00:00',
		'DANY' => 'foo',
		'EDMYT' => 'DATETIME: 2016-12-30T12:34:00',
		'FMDYT' => 'DATETIME: 2015-03-30T23:45:16',
		'GYMDT' => 'DATETIME: 2014-01-31T15:45:00',
		'HBAD' => '2016-02-01',
		'IT' => undef,
		'JUNDEF' => undef},
	{'ADMY' => undef,
		'BMDY' => 'DATETIME: 2015-01-02T00:00:00',
		'CYMD' => 'DATETIME: 2014-02-28T00:00:00',
		'DANY' => '',
		'EDMYT' => 'DATETIME: 2016-06-29T12:34:00',
		'FMDYT' => 'DATETIME: 2010-06-30T23:45:16',
		'GYMDT' => 'DATETIME: 2014-07-01T15:45:00',
		'HBAD' => '2016-02-01',
		'IT' => 'DATETIME: 0001-01-01T01:17:00',
		'JUNDEF' => undef},
	{'ADMY' => 'DATETIME: 1999-12-31T00:00:00',
		'BMDY' => 'DATETIME: 2015-03-04T00:00:00',
		'CYMD' => 'DATETIME: 9999-12-31T00:00:00',
		'DANY' => 'oh la',
		'EDMYT' => 'DATETIME: 2016-12-30T12:34:00',
		'FMDYT' => 'DATETIME: 2015-12-29T23:45:16',
		'GYMDT' => 'DATETIME: 8888-12-01T15:45:00',
		'HBAD' => '2016-02-30',
		'IT' => 'DATETIME: 0001-01-01T02:18:00',
		'JUNDEF' => undef}];

my $csvdt = Text::AutoCSV->new(in_file => "t/${ww}pp2.csv", out_file => $tmpf,
	fields_dates_auto => 1);
my $alldt = [ $csvdt->get_hr_all() ];
my $p = make_printable($alldt);
is_deeply($p, $P_IN_THEORY, "DT01 - t/pp2.csv: check DateTime objects are OK");

eval {
	local $SIG{__WARN__} = sub { };
	$csvdt->read();
};
my $alldt2 = [ $csvdt->get_hr_all() ];
my $p2 = make_printable($alldt2);
is_deeply($p2, $P_IN_THEORY, "DT02 - t/pp2.csv: check DateTime objects are OK after re-read");

eval {
	local $SIG{__WARN__} = sub { };
	$csvdt->read()->read()->write()->write()->write();
};
my $alldt3 = [ $csvdt->get_hr_all() ];
my $p3 = make_printable($alldt3);
is_deeply($p3, $P_IN_THEORY, "DT03 - t/pp2.csv: check DateTime objects are OK after multi r/w");

my $csvdt4 = Text::AutoCSV->new(in_file => $tmpf, fields_dates_auto => 1);
my $alldt4 = [ $csvdt4->get_hr_all() ];
my $p4 = make_printable($alldt4);
is_deeply($p4, $P_IN_THEORY, "DT04 - t/pp2.csv: check DateTime objects are write then read");

my $csvdt5 = Text::AutoCSV->new(in_file => $tmpf);
my $alldt5 = [ $csvdt5->get_hr_all() ];
is_deeply($alldt5,
	[{'ADMY' => '14/12/16',
		'BMDY' => '03/04/15',
		'CYMD' => '2014-02-28',
		'DANY' => 'bla',
		'EDMYT' => '',
		'FMDYT' => '03/04/15 23:45:16',
		'GYMDT' => '2014-02-28 03:45 PM',
		'HBAD' => '2016-02-01',
		'IT' => '20:15',
		'JUNDEF' => undef},
	{'ADMY' => '31/12/16',
		'BMDY' => '03/31/15',
		'CYMD' => '2014-02-01',
		'DANY' => 'foo',
		'EDMYT' => '30/12/16 12:34',
		'FMDYT' => '03/30/15 23:45:16',
		'GYMDT' => '2014-01-31 03:45 PM',
		'HBAD' => '2016-02-01',
		'IT' => '',
		'JUNDEF' => undef},
	{'ADMY' => '',
		'BMDY' => '01/02/15',
		'CYMD' => '2014-02-28',
		'DANY' => '',
		'EDMYT' => '29/06/16 12:34',
		'FMDYT' => '06/30/10 23:45:16',
		'GYMDT' => '2014-07-01 03:45 PM',
		'HBAD' => '2016-02-01',
		'IT' => '01:17',
		'JUNDEF' => undef},
	{'ADMY' => '31/12/99',
		'BMDY' => '03/04/15',
		'CYMD' => '9999-12-31',
		'DANY' => 'oh la',
		'EDMYT' => '30/12/16 12:34',
		'FMDYT' => '12/29/15 23:45:16',
		'GYMDT' => '8888-12-01 03:45 PM',
		'HBAD' => '2016-02-30',
		'IT' => '02:18',
		'JUNDEF' => undef}],
	"DT05 - t/pp2.csv: check DateTime objects are OK (check raw format on output)"
);

my $csvdt6 = Text::AutoCSV->new(in_file => "t/${ww}pp3.csv", fields_dates_auto => 1,
	dates_locales => "fr,en", out_file => $tmpf);
my $alldt6 = [ $csvdt6->get_hr_all() ];
my $p6 = make_printable($alldt6);
is_deeply($p6,
	[{ 'A' => 'DATETIME: 2015-04-19T00:00:00',
		'B' => 'DATETIME: 2015-04-19T01:02:03',
		'C' => 'DATETIME: 2015-12-31T00:00:00',
		'D' => ''},
	{'A' => 'DATETIME: 2000-05-01T00:01:02',
		'B' => 'DATETIME: 2000-05-01T18:40:59',
		'C' => 'DATETIME: 2016-01-01T00:00:00',
		'D' => ''}],
	"DT06 - t/pp3.csv: DateTime objects with locales");
$csvdt6->write();
my $csvdt6b = Text::AutoCSV->new(in_file => $tmpf);
my $alldt6b = [ $csvdt6b->get_hr_all() ];

	# On some OSes, there is no point at the end of month end, on some, there is...
	# Not a big issue, but enough to screw a test plan.
if (defined($alldt6b->[0]) and defined($alldt6b->[0]->{'B'})) {

	$alldt6b->[0]->{'B'} = '19 avr 2015 a 01:02:03'
		if $alldt6b->[0]->{'B'} eq '19 avr. 2015 a 01:02:03'

}

is_deeply($alldt6b,
	[{'A' => 'Apr 19, 2015, 12:00:00 AM',
		'B' => '19 avr 2015 a 01:02:03',
		'C' => '31/12/2015',
		'D' => '' },
	{'A' => 'May 01, 2000, 12:01:02 AM',
		'B' => '01 mai 2000 a 18:40:59',
		'C' => '01/01/2016',
		'D' => ''}],
	"DT07 - t/pp3.csv: DateTime objects with locales, rewritten");
my $csvdt6c = Text::AutoCSV->new(in_file => $tmpf, fields_dates_auto => 1,
	dates_locales => "fr,en");
my $alldt6c = [ $csvdt6c->get_hr_all() ];
my $p6c = make_printable($alldt6c);
is_deeply($p6c,
	[{ 'A' => 'DATETIME: 2015-04-19T00:00:00',
		'B' => 'DATETIME: 2015-04-19T01:02:03',
		'C' => 'DATETIME: 2015-12-31T00:00:00',
		'D' => ''},
	{'A' => 'DATETIME: 2000-05-01T00:01:02',
		'B' => 'DATETIME: 2000-05-01T18:40:59',
		'C' => 'DATETIME: 2016-01-01T00:00:00',
		'D' => ''}],
	"DT08 - t/pp3.csv: DateTime objects with locales, rewritten, re-analyzed");


# * *************************** *
# * All things done in parallel *
# * *************************** *

note("");
note("[AL]l things done in parallel");

sub inmapsub {
	return 0 if !defined($_) or $_ eq '';
	my $i;
	return -$i if ($i) = $_ =~ m/^\((.*)\)$/;
	$_;
}
$csv = Text::AutoCSV->new(in_file => "t/${ww}pp1.csv", out_file => $tmpf, quiet => 1)
	->in_map('NUM', \&inmapsub)
	->in_map('NUM', sub { return "<<$_>>"; });

$all = [ $csv->get_hr_all() ];
is_deeply($all,
	[{'NUM' => '<<18>>', 'RIEN' => '1'},
		{'NUM' => '<<-15>>', 'RIEN' => '2'},
		{'NUM' => '<<0>>', 'RIEN' => '3'},
		{'NUM' => '<<-1>>', 'RIEN' => ''}],
	"AL01 - t/pp1.csv: chain in_map"
);

$csv->in_map('NUM', sub { return "-$_-"; })
	->out_map('NUM', sub { s/^-<(.*)>-$/$1/; $_ })
	->out_map('NUM', sub { s/(\d)/$1$1/g; $_ })
	->out_map('RIEN', sub { $_ = 0 if !defined($_) or $_ eq ''; $_ + 1; })
	->out_map('RIEN', sub { $_ * 2; })
	->out_map('RIEN', sub { $_ + 100; })
	->read()->read()->write();
$all = [ $csv->get_hr_all() ];
is_deeply($all,
	[{'NUM' => '-<<18>>-', 'RIEN' => '1'},
		{'NUM' => '-<<-15>>-', 'RIEN' => '2'},
		{'NUM' => '-<<0>>-', 'RIEN' => '3'},
		{'NUM' => '-<<-1>>-', 'RIEN' => ''}],
	"AL02 - t/pp1.csv: chain out_map"
);

$csv = Text::AutoCSV->new(in_file => $tmpf);
$all = [ $csv->get_hr_all() ];
is_deeply($all,
	[{'NUM' => '<1188>', 'RIEN' => '104'},
		{'NUM' => '<-1155>', 'RIEN' => '106'},
		{'NUM' => '<00>', 'RIEN' => '108'},
		{'NUM' => '<-11>', 'RIEN' => '102'}],
	"AL03 - t/pp1.csv: check result of out_map"
);


my $z = Text::AutoCSV->new(in_file => "t/${ww}pp2.csv", out_file => $tmpf, fields_dates_auto => 1,
	quiet => 1);
my $pz = make_printable([ $z->get_hr_all() ]);
is_deeply($pz, $P_IN_THEORY, "AL04 - t/pp2.csv: (1) mix of in_map out_map with DateTime");

my $P_BIZARRE =
	[{'ADMY' => [2026, 12, 14],
		'BMDY' => 'DATETIME: 2015-03-04T00:00:00',
		'CYMD' => 'DATETIME: 2014-02-28T10:11:12',
		'DANY' => 'bla',
		'EDMYT' => undef,
		'FMDYT' => '2457086.489768',
		'GYMDT' => 'DATETIME: 2014-02-28T15:45:00',
		'HBAD' => '2016-02-01',
		'IT' => 'DATETIME: 0001-01-01T20:15:00',
		'JUNDEF' => undef},
	{'ADMY' => [2026, 12, 31],
		'BMDY' => 'DATETIME: 2015-03-31T00:00:00',
		'CYMD' => 'DATETIME: 2014-02-01T10:11:12',
		'DANY' => 'foo',
		'EDMYT' => 'DATETIME: 2016-12-30T12:34:00',
		'FMDYT' => '2457112.489768',
		'GYMDT' => 'DATETIME: 2014-01-31T15:45:00',
		'HBAD' => '2016-02-01',
		'IT' => undef,
		'JUNDEF' => undef},
	{'ADMY' => [11, 1, 1],
		'BMDY' => 'DATETIME: 2015-01-02T00:00:00',
		'CYMD' => 'DATETIME: 2014-02-28T10:11:12',
		'DANY' => '',
		'EDMYT' => 'DATETIME: 2016-06-29T12:34:00',
		'FMDYT' => '2455378.489768',
		'GYMDT' => 'DATETIME: 2014-07-01T15:45:00',
		'HBAD' => '2016-02-01',
		'IT' => 'DATETIME: 0001-01-01T01:17:00',
		'JUNDEF' => undef},
	{'ADMY' => [2009, 12, 31],
		'BMDY' => 'DATETIME: 2015-03-04T00:00:00',
		'CYMD' => 'DATETIME: 9999-12-31T10:11:12',
		'DANY' => 'oh la',
		'EDMYT' => 'DATETIME: 2016-12-30T12:34:00',
		'FMDYT' => '2457386.489768',
		'GYMDT' => 'DATETIME: 8888-12-01T15:45:00',
		'HBAD' => '2016-02-30',
		'IT' => 'DATETIME: 0001-01-01T02:18:00',
		'JUNDEF' => undef}];

SKIP: {
		# Found the trick below (to avoid evaluating a string) here:
		#   http://stackoverflow.com/questions/1917261/how-can-i-dynamically-include-perl-modules-without-using-eval
	my $skip_jd = 1;
	eval {
		require DateTime::Format::Epoch::JD;
		DateTime::Format::Epoch::JD->import();
		$skip_jd = 0;
	};

	skip("DateTime::Format::Epoch::JD not available, skipping tests AL05, AL06 and AL07", 3)
		if $skip_jd;

	$z->in_map('ADMY', sub { return [ $_->year(), $_->month(), $_->day() ] if $_; [1, 1, 1]; })
		->in_map('ADMY', sub { return [ $_->[0] + 10, $_->[1], $_->[2] ]; })
		->in_map('CYMD',
			sub { return unless $_; $_->set_hour(10); $_->set_minute(11); $_->set_second(12); $_; })
		->in_map('FMDYT', sub { return unless $_; $_->jd(); })
		->out_map('FMDYT',
			sub { return unless $_; return DateTime::Format::Epoch::JD->parse_datetime($_); })
		->out_map('FMDYT', sub { $_->set_year($_->year() + 1000); })
		->out_map('ADMY',
			sub { return DateTime->new(year => $_->[0], month => $_->[1], day => $_->[2]); });
	$pz = make_printable([ $z->get_hr_all() ]);
	is_deeply($pz, $P_BIZARRE, "AL05 - (JD) - t/pp2.csv: (2) mix of in_map out_map with DateTime");
	$z->read()->read()->write()->write()->write();
	$pz = make_printable([ $z->get_hr_all() ]);
	is_deeply($pz, $P_BIZARRE, "AL06 - (JD) - t/pp2.csv: (3) mix of in_map out_map with DateTime");

	my $z9 = Text::AutoCSV->new(in_file => $tmpf);
	my $a9 = [ $z9->get_hr_all() ];
	is_deeply($a9,
		[{'ADMY' => '14/12/26',
			'BMDY' => '03/04/15',
			'CYMD' => '2014-02-28',
			'DANY' => 'bla',
			'EDMYT' => '',
			'FMDYT' => '03/04/15 23:45:16',
			'GYMDT' => '2014-02-28 03:45 PM',
			'HBAD' => '2016-02-01',
			'IT' => '20:15',
			'JUNDEF' => undef},
		{'ADMY' => '31/12/26',
			'BMDY' => '03/31/15',
			'CYMD' => '2014-02-01',
			'DANY' => 'foo',
			'EDMYT' => '30/12/16 12:34',
			'FMDYT' => '03/30/15 23:45:16',
			'GYMDT' => '2014-01-31 03:45 PM',
			'HBAD' => '2016-02-01',
			'IT' => '',
			'JUNDEF' => undef},
		{'ADMY' => '01/01/11',
			'BMDY' => '01/02/15',
			'CYMD' => '2014-02-28',
			'DANY' => '',
			'EDMYT' => '29/06/16 12:34',
			'FMDYT' => '06/30/10 23:45:16',
			'GYMDT' => '2014-07-01 03:45 PM',
			'HBAD' => '2016-02-01',
			'IT' => '01:17',
			'JUNDEF' => undef},
		{'ADMY' => '31/12/09',
			'BMDY' => '03/04/15',
			'CYMD' => '9999-12-31',
			'DANY' => 'oh la',
			'EDMYT' => '30/12/16 12:34',
			'FMDYT' => '12/29/15 23:45:16',
			'GYMDT' => '8888-12-01 03:45 PM',
			'HBAD' => '2016-02-30',
			'IT' => '02:18',
			'JUNDEF' => undef}],
		"AL07 - (JD) - t/pp2.csv: check after read/write"
	);
}

my $y = Text::AutoCSV->new(in_file => "t/${ww}pp2.csv", fields_dates => ['ADMY', 'HBAD', 'JUNDEF']);

my $py0;
my $w = 0;
eval {
	local $SIG{__WARN__} = sub { $w++; };
	$py0 = [ $y->get_hr_all() ];
} or $w += 100;
is($w, 102, "AL08 - t/pp2.csv: (1) check warnings and errors displayed when date detection issue");
is($py0, undef, "AL09 - t/pp2.csv: check an error occured (croak_if_error => 1 (default))");

my $wrngs = '';
my $eval_failed = 0;
$py0 = undef;
eval {
	local $SIG{__WARN__} = sub { $wrngs .= "@_"; };
	$y = Text::AutoCSV->new(in_file => "t/${ww}pp4.csv", fields_dates => ['ADMY', 'HBAD'],
		croak_if_error => 0);
	$py0 = make_printable([ $y->get_hr_all() ]);
} or $eval_failed = 1;
if ($eval_failed) {
	print(__FILE__ . ': ' . __LINE__ . ": eval failed:\n----\n" . $@ . "\n----\n");
}
is($eval_failed, 0, "AL10 - t/pp4.csv: check eval succeeded");
like($wrngs, qr/unable to parse datetime/i,
	"AL11 - t/pp4.csv: (2) check error raised if date detection issue");

is_deeply($py0,
	[{'ADMY' => 'DATETIME: 2016-12-14T00:00:00',
		'BMDY' => '03/04/15',
		'CYMD' => '2014-02-28',
		'DANY' => 'bla',
		'EDMYT' => '',
		'FMDYT' => '03/04/15 23:45:17',
		'GYMDT' => '2014-02-28 3:45 PM',
		'HBAD' => 'DATETIME: 2016-02-01T00:00:00',
		'IT' => '20:15',
		'JUNDEF' => undef},
	{'ADMY' => 'DATETIME: 2016-12-31T00:00:00',
		'BMDY' => '03/31/15',
		'CYMD' => '2014-02-01',
		'DANY' => 'foo',
		'EDMYT' => '30/12/16 12:34',
		'FMDYT' => '03/30/15 23:45:17',
		'GYMDT' => '2014-01-31 3:45 PM',
		'HBAD' => 'DATETIME: 2016-02-01T00:00:00',
		'IT' => '',
		'JUNDEF' => undef},
	{'ADMY' => undef,
		'BMDY' => '1/2/15',
		'CYMD' => '2014-02-28',
		'DANY' => '',
		'EDMYT' => '29/06/16 12:34',
		'FMDYT' => '06/30/10 23:45:17',
		'GYMDT' => '2014-07-01 3:45 PM',
		'HBAD' => 'DATETIME: 2016-02-01T00:00:00',
		'IT' => '1:17',
		'JUNDEF' => undef},
	{'ADMY' => 'DATETIME: 1999-12-31T00:00:00',
		'BMDY' => '03/04/15',
		'CYMD' => '9999-12-31',
		'DANY' => 'oh la',
		'EDMYT' => '30/12/16 12:34',
		'FMDYT' => '12/29/15 23:45:17',
		'GYMDT' => '8888-12-01 3:45 PM',
		'HBAD' => undef,
		'IT' => '2:18',
		'JUNDEF' => undef},
	{'ADMY' => 'DATETIME: 1999-12-31T00:00:00',
		'BMDY' => '03/04/15',
		'CYMD' => '9999-12-31',
		'DANY' => 'oh la',
		'EDMYT' => '30/12/16 12:34',
		'FMDYT' => '12/29/15 23:45:17',
		'GYMDT' => '8888-12-01 3:45 PM',
		'HBAD' => 'DATETIME: 2016-02-29T00:00:00',
		'IT' => '2:18',
		'JUNDEF' => undef},
	{'ADMY' => 'DATETIME: 1999-12-31T00:00:00',
		'BMDY' => '03/04/15',
		'CYMD' => '9999-12-31',
		'DANY' => 'oh la',
		'EDMYT' => '30/12/16 12:34',
		'FMDYT' => '12/29/15 23:45:17',
		'GYMDT' => '8888-12-01 3:45 PM',
		'HBAD' => undef,
		'IT' => '2:18',
		'JUNDEF' => undef},
	{'ADMY' => 'DATETIME: 1999-12-31T00:00:00',
		'BMDY' => '03/04/15',
		'CYMD' => '9999-12-31',
		'DANY' => 'oh la',
		'EDMYT' => '30/12/16 12:34',
		'FMDYT' => '12/29/15 23:45:17',
		'GYMDT' => '8888-12-01 3:45 PM',
		'HBAD' => 'DATETIME: 2016-01-01T00:00:00',
		'IT' => '2:18',
		'JUNDEF' => undef}],
	"AL12 - t/pp4.csv: check processing recovers from a parse error (croak_if_error => 0)"
);

$wrngs = '';
$eval_failed = 0;
$py0 = undef;
eval {
	$y = Text::AutoCSV->new(in_file => "t/${ww}pp2.csv", fields_dates => ['ADMY', 'HBAD']);
	$py0 = $y->get_hr_all();
} or $eval_failed = 1;
if (!$eval_failed) {
	print(__FILE__ . ': ' . __LINE__ . ": eval did not fail (expected: failure)");
}
like($@, qr/unable to parse datetime/i,
	"AL13 - t/pp2.csv: check error raised when datetime detection issue");


# * ********************************************** *
# * in_map and out_map call chain error management *
# * ********************************************** *

note("");
note("[ER]ror management across in_map and out_map chained calls");

my $fail_num = -1;
sub myfail {
	my ($num, $self, $field) = @_;
	$field = '[?]' unless defined($field);

	if ($num == $fail_num) {
		my $in = $self->get_in_file_disp();
		my $recnum = $self->get_recnum();
		$self->_print_error("$in: record $recnum: field $field: ERROR #$num");
	}
}
sub myfail1 { return myfail(1, @_); }
sub myfail2 { return myfail(2, @_); }
sub myfail3 { return myfail(3, @_); }
sub myfail4 { return myfail(4, @_); }
sub myfail5 { return myfail(5, @_); }
sub myfail6 { return myfail(6, @_); }

my $ccc = Text::AutoCSV->new(in_file => "t/${ww}pp1.csv", out_file => $tmpf)
	->in_map('RIEN', \&myfail1)
	->in_map('RIEN', \&myfail2)
	->in_map('RIEN', \&myfail3)
	->out_map('RIEN', \&myfail4)
	->out_map('RIEN', \&myfail5)
	->out_map('RIEN', \&myfail6);
eval { $fail_num = 1; $ccc->write(); };
like($@, qr/Text::AutoCSV: error: .*: record 2: field RIEN: ERROR #1/i,
	"ER01 - t/pp1.csv: check error generation and display (1)");
eval { $fail_num = 2; $ccc->write(); };
like($@, qr/Text::AutoCSV: error: .*: record 2: field RIEN: ERROR #2/i,
	"ER02 - t/pp1.csv: check error generation and display (2)");
eval { $fail_num = 3; $ccc->write(); };
like($@, qr/Text::AutoCSV: error: .*: record 2: field RIEN: ERROR #3/i,
	"ER03 - t/pp1.csv: check error generation and display (3)");
eval { $fail_num = 4; $ccc->write(); };
like($@, qr/Text::AutoCSV: error: .*: record 2: field RIEN: ERROR #4/i,
	"ER04 - t/pp1.csv: check error generation and display (4)");
eval { $fail_num = 5; $ccc->write(); };
like($@, qr/Text::AutoCSV: error: .*: record 2: field RIEN: ERROR #5/i,
	"ER05 - t/pp1.csv: check error generation and display (5)");
eval { $fail_num = 6; $ccc->write(); };
like($@, qr/Text::AutoCSV: error: .*: record 2: field RIEN: ERROR #6/i,
	"ER06 - t/pp1.csv: check error generation and display (6)");

$ccc = Text::AutoCSV->new(in_file => "t/${ww}pp1.csv", out_file => $tmpf, one_pass => 1)
	->in_map('RIEN', \&myfail1)
	->in_map('RIEN', \&myfail2);
eval { $fail_num = 1; $ccc->write(); };
like($@, qr/Text::AutoCSV: error: .*: record 2: field RIEN: ERROR #1/i,
	"ER07 - t/pp1.csv: check error generation and display (7)");
eval { $fail_num = 2; $ccc->write(); };
like($@, qr/Text::AutoCSV: error: one_pass set, unable to read input again/i,
	"ER08 - t/pp1.csv: check error generation and display (8)");


unlink $tmpf unless $DEVTIME;


done_testing();


	#
	# Return the name of a temporary file name that is guaranteed NOT to exist.
	#
	# If ever it is not possible to return such a name (file exists and cannot be
	# deleted), then stop execution.
sub get_non_existent_temp_file_name {
	my $tmpf = tmpnam();
	$tmpf = 'tmp0.csv' if $DEVTIME;

	unlink $tmpf if -f $tmpf;
	die "File '$tmpf' already exists! Unable to delete it? Any way, tests aborted." if -f $tmpf;
	return $tmpf;
}

sub make_printable {
	my $ar = shift;

	for my $e (@$ar) {
		for (keys %$e) {
			my $v = $e->{$_};
			if (ref $v eq 'DateTime') {
				$e->{$_} = "DATETIME: $v"
			} elsif (defined($v) and ref $v eq '' and $v =~ m/^[[:digit:]]+\.[[:digit:]]+$/) {
				$v = int($v * 1000000) / 1000000;
				my ($main, $frac) = $v =~ m/^([[:digit:]]+)\.([[:digit:]]+)$/;
				$frac .= '0' x (6 - length($frac)) if length($frac) < 6;
				$e->{$_} = "$main.$frac";
			}
		}
	}
	return $ar;
}

