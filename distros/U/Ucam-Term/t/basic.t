#!/usr/bin/perl -w

use strict;

use Test::More tests => 92;
#use Test::More 'no_plan';
use Test::Exception;

my $term;

# Basic 'can we use it' test
BEGIN { use_ok('Ucam::Term') };

# Constructors with term expressed various ways
ok(Ucam::Term->new('m',2009));
ok(Ucam::Term->new('mICh',2009));
ok(Ucam::Term->new('michaELmas',2009));
ok(Ucam::Term->new('L',2009));
ok(Ucam::Term->new('LenT',2009));
ok(Ucam::Term->new('e',2009));
ok(Ucam::Term->new('eASTERr',2009));

dies_ok { Ucam::Term->new('zzz',2009) };

# term and year getters
$term = Ucam::Term->new('m',2009);
ok($term);

is($term->name, 'Michaelmas');
is($term->year, '2009');

# available_years
my @years = Ucam::Term->available_years;
ok(scalar(@years) >= 14,"Expecting at least 14 years, got " . scalar(@years));
my $current = 2007;
foreach my $year (@years) {
    is($year, $current, "Year data in ascending order");
    ++$current;
}

# term

$term =  Ucam::Term->new('m',1066);
is($term->dates, undef());
is($term->fullterm_dates, undef());
is($term->division, undef());

$term =  Ucam::Term->new('m',2007);
is ($term->dates->start->iso8601,             '2007-10-01T00:00:00');
is ($term->dates->end->iso8601,               '2007-12-20T00:00:00');
ok ($term->dates->start_is_closed);
ok ($term->dates->end_is_open);

is ($term->fullterm_dates->start->iso8601,    '2007-10-02T00:00:00');
is ($term->fullterm_dates->end->iso8601,      '2007-12-01T00:00:00');

is ($term->division->iso8601,                 '2007-11-09T00:00:00');

dies_ok { $term->general_admission };
dies_ok { $term->long_vac };

$term =  Ucam::Term->new('l',2008);
is ($term->dates->start->iso8601,             '2008-01-05T00:00:00');
is ($term->dates->end->iso8601,               '2008-03-25T00:00:00');
ok ($term->dates->start_is_closed);
ok ($term->dates->end_is_open);

is ($term->fullterm_dates->start->iso8601,    '2008-01-15T00:00:00');
is ($term->fullterm_dates->end->iso8601,      '2008-03-15T00:00:00');

is ($term->division->iso8601,                 '2008-02-13T00:00:00');

dies_ok { $term->general_admission };
dies_ok { $term->long_vac };

# In 2008, Full Easter term starts 'on or after' 22nd April so term begins
#  on 17th and General Admission is in the week after the 4th Sunday
$term =  Ucam::Term->new('e',2008);
is ($term->dates->start->iso8601,             '2008-04-17T00:00:00');
is ($term->dates->end->iso8601,               '2008-06-26T00:00:00');
ok ($term->dates->start_is_closed);
ok ($term->dates->end_is_open);

is ($term->fullterm_dates->start->iso8601,    '2008-04-22T00:00:00');
is ($term->fullterm_dates->end->iso8601,      '2008-06-14T00:00:00');

is ($term->division->iso8601,                 '2008-05-21T00:00:00');

is ($term->general_admission->start->iso8601, '2008-06-26T00:00:00');
is ($term->general_admission->end->iso8601,   '2008-06-29T00:00:00');

is ($term->long_vac->start->iso8601,          '2008-07-07T00:00:00');
is ($term->long_vac->end->iso8601,            '2008-08-10T00:00:00');

# In 2009, Full Easter term starts before 22nd April so term begins
# on 10th and General Admission is in the week after the 3rd Sunday
$term =  Ucam::Term->new('e',2009);
is ($term->dates->start->iso8601,             '2009-04-10T00:00:00');
is ($term->dates->end->iso8601,               '2009-06-19T00:00:00');
ok ($term->dates->start_is_closed);
ok ($term->dates->end_is_open);

is ($term->fullterm_dates->start->iso8601,    '2009-04-21T00:00:00');
is ($term->fullterm_dates->end->iso8601,      '2009-06-13T00:00:00');

is ($term->division->iso8601,                 '2009-05-14T00:00:00');

is ($term->general_admission->start->iso8601, '2009-06-25T00:00:00');
is ($term->general_admission->end->iso8601,   '2009-06-28T00:00:00');
ok ($term->general_admission->start_is_closed);
ok ($term->general_admission->end_is_open);

is ($term->long_vac->start->iso8601,          '2009-07-06T00:00:00');
is ($term->long_vac->end->iso8601,            '2009-08-09T00:00:00');
ok ($term->long_vac->start_is_closed);
ok ($term->long_vac->end_is_open);

# 2013 was the last year with a 3 day General Admission - from 2014
# it's a 4-day affair. This has implications for calculating the
# dates of the Long Vacation

$term =  Ucam::Term->new('e',2013);
is ($term->general_admission->start->iso8601, '2013-06-27T00:00:00');
is ($term->general_admission->end->iso8601,   '2013-06-30T00:00:00');
is ($term->long_vac->start->iso8601,          '2013-07-08T00:00:00');
is ($term->long_vac->end->iso8601,            '2013-08-11T00:00:00');

$term =  Ucam::Term->new('e',2014);
is ($term->general_admission->start->iso8601, '2014-06-25T00:00:00');
is ($term->general_admission->end->iso8601,   '2014-06-29T00:00:00');
is ($term->long_vac->start->iso8601,          '2014-07-07T00:00:00');
is ($term->long_vac->end->iso8601,            '2014-08-10T00:00:00');
