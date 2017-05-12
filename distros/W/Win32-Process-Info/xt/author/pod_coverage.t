package main;

use strict;
use warnings;

use Test::More 0.88;

BEGIN {
    eval {
	require Test::Pod::Coverage;
	Test::Pod::Coverage->VERSION(1.00);
	Test::Pod::Coverage->import();
	1;
    } or do {
	plan skip_all => 'Test::Pod::Coverage 1.00 or greater required.';
	exit;
    };
}

pod_coverage_ok (
    'Win32::Process::Info',
    {
	also_private => [ qr{^[[:upper:]\d_]+$}, ],
	coverage_class => 'Pod::Coverage::CountParents'
    }
);

SKIP: {

    eval {
	require Win32::Process::Info::NT;
	1;
    } or skip 'Can not load Win32::Process::Info::NT', 1;

    pod_coverage_ok(
	'Win32::Process::Info::NT',
	{
	    coverage_class => 'Pod::Coverage::CountParents',
	},
    );

}

SKIP: {

    eval {
	require Win32::Process::Info::PT;
	1;
    } or skip 'Can not load Win32::Process::Info::PT', 1;

    pod_coverage_ok(
	'Win32::Process::Info::PT',
	{
	    coverage_class => 'Pod::Coverage::CountParents',
	},
    );

}

SKIP: {

    eval {
	require Win32::Process::Info::WMI;
	1;
    } or skip 'Can not load Win32::Process::Info::WMI', 1;

    pod_coverage_ok(
	'Win32::Process::Info::WMI',
	{
	    coverage_class => 'Pod::Coverage::CountParents',
	},
    );

}

done_testing;

1;
