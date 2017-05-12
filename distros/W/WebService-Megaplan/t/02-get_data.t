#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use open ':encoding(utf8)', ':std';
use Test::More tests => 11;

BEGIN {
    use_ok( 'WebService::Megaplan' ) || print "Bail out!\n";
}

SKIP: {
    skip 'No env MEGAPLAN_LOGIN',    10 if(! $ENV{MEGAPLAN_LOGIN});
    skip 'No env MEGAPLAN_PASSWORD', 10 if(! $ENV{MEGAPLAN_PASSWORD});
    skip 'No env MEGAPLAN_HOST',     10 if(! $ENV{MEGAPLAN_HOST});

    my $api = WebService::Megaplan->new(
                    login => $ENV{MEGAPLAN_LOGIN},
                    password => $ENV{MEGAPLAN_PASSWORD},
                    hostname => $ENV{MEGAPLAN_HOST},
                    use_ssl  => 1,
                );
    ok($api, 'object created');

    ok($api->authorize(), 'login successful');

    ok($api->secret_key, 'got SecretKey');
    ok($api->access_id, 'got AccessID');

    my $p_data = $api->get_data('/BumsProjectApiV01/Project/list.api');
    ok($p_data, 'got project list');
    ok($p_data->{data}->{projects}, 'Found projects: '. scalar( @{ $p_data->{data}->{projects} } ));

    my $e_data = $api->get_data('/BumsStaffApiV01/Employee/list.api', { OrderBy => 'department'});
    ok($e_data, 'got users list');
    ok($e_data->{data}->{employees}, 'Found employees: '. scalar( @{ $e_data->{data}->{employees} }));

    my $employee = $e_data->{data}->{employees}->[0];
    my $em_data = $api->get_data('/BumsStaffApiV01/Employee/card.api', { Id => $employee->{Id} });
    ok($em_data, 'Get one employee info');
    ok($em_data->{data}->{employee}->{Name}, 'Employee name: ' . $em_data->{data}->{employee}->{Name});
}

diag( "Testing WebService::Megaplan $WebService::Megaplan::VERSION, Perl $], $^X" );
