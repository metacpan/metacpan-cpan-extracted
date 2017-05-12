#!perl

use strict;
use warnings;

use LWP::Online ':skip_all';
use Test::More 0.88 tests => 8;
use WebService::BambooHR;
my $domain             = 'testperl';
my $api_key            = 'bfb359256c9d9e26b37309420f478f03ec74599b';
my $INVALID_FIELD_NAME = 'superheroName';
my $bamboo;
my $employee;

SKIP: {

    my $bamboo = WebService::BambooHR->new(
                        company => $domain,
                        api_key => $api_key);
    ok(defined($bamboo), "create BambooHR class");

    eval {
        $employee = $bamboo->employee(40345);
    };
    ok(!$@ && defined($employee), 'load employee');

    ok($employee->firstName eq 'Shelly', 'first name');
    ok($employee->lastName eq 'Konold',  'last name');
    ok($employee->status eq 'Active',    'status');
    ok($employee->location eq 'Chicago', 'location');
    ok($employee->selfServiceAccess eq 'No', 'self-service access');

    eval {
        $employee = $bamboo->employee(40345, $INVALID_FIELD_NAME);
    };
    ok($@ && $@->code == 400 && $@->message =~ /unknown field name/,
       "trying to get an unknown field on an employee");
};

