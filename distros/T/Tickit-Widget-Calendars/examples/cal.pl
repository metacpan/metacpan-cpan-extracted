#!/usr/bin/env perl 
use strict;
use warnings;
use Tickit::DSL;
use Tickit::Widget::Calendar::MonthView;
use Tickit::Style;

Tickit::Style->load_style(<<'EOF');
Calendar::MonthView {
 month-fg: 248;
 weekday-fg: 243;
 today-bg: 'blue';
}
EOF

vbox {
	customwidget {
		my ($day, $month, $year) = (localtime)[3..5];
		$year += 1900;
		++$month;
		my $w = Tickit::Widget::Calendar::MonthView->new(
			day   => $day,
			month => $month,
			year  => $year,
		);
		$w->day($day);
		$w->month($month);
		$w->year($year);
	} expand => 1;
};
tickit->run

