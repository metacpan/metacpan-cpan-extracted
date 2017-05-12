#!/usr/bin/perl

use Class::Easy;

use Test::More qw(no_plan);

use_ok 'Web::App';

use_ok 'Web::App::Lib::EntityRecord';

use_ok 'Web::App::Lib::EntityCollection';

my $statement = Web::App::Lib::EntityCollection->statement_from_params (undef, {
	'sort.order' => 'asc',
	'sort.field' => 'id',
	'filter.is_active' => 1,
	'filter.display_mode' => " != 'mega' "
});

ok $statement->{sort_order} eq 'asc';
ok $statement->{sort_field} eq 'id';

ok scalar keys %{$statement->{where}} == 2;

ok $statement->{where}->{is_active} = 1;
ok $statement->{where}->{_display_mode} = " != 'mega' ";