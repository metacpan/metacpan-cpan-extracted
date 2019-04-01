use Mojo::Base -strict;
use Test::More;
use Mojo::Calendar;

# From first day of the month
my $date1 = Mojo::Calendar->new(from => '2019-04-01');

is($date1->yesterday->ymd, '2019-03-31');
is($date1->today->ymd, '2019-04-01');
is($date1->tomorrow->ymd, '2019-04-02');
is($date1->first_day_of_next_month->ymd, '2019-05-01');
is($date1->days_ago(6)->ymd, '2019-03-26');
is($date1->months_ago(6)->ymd, '2018-10-01');

# From a day in the middle of the month
my $date2 = Mojo::Calendar->new(from => '2019-03-20');

is($date2->yesterday->ymd, '2019-03-19');
is($date2->today->ymd, '2019-03-20');
is($date2->tomorrow->ymd, '2019-03-21');
is($date2->first_day_of_next_month->ymd, '2019-04-01');
is($date2->days_ago(6)->ymd, '2019-03-14');
is($date2->months_ago(6)->ymd, '2018-09-20');

# From last day of the month
my $date3 = Mojo::Calendar->new(from => '2019-03-31');

is($date3->yesterday->ymd, '2019-03-30');
is($date3->today->ymd, '2019-03-31');
is($date3->tomorrow->ymd, '2019-04-01');
is($date3->first_day_of_next_month->ymd, '2019-04-01');
is($date3->days_ago(6)->ymd, '2019-03-25');
is($date3->months_ago(6)->ymd, '2018-09-30');

done_testing;
