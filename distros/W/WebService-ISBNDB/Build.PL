#!/usr/bin/perl

# $Id: Build.PL 51 2008-04-06 11:02:35Z  $

use Module::Build;

my $build = Module::Build->new(
    module_name    => 'WebService::ISBNDB',
    license        => 'perl',
    requires       => { perl => '5.006',
                        LWP => '5.801',
                        Business::ISBN => '2.0',
                        Class::Std => '0.0.8',
                        Error => '0.17',
                        XML::LibXML => '1.58' },
    build_requires => { Test::More => 0 },
    recommends     => { Date::Parse => '2.27',
		        Test::Pod => 0,
		        Test::Pod::Coverage => 0 },
    dist_author    => 'Randy J. Ray <rjray@blackperl.com>',
    dist_abstract  =>
    'Data and communication classes for talking to isbndb.com',
    sign           => 'here, please',
);

$build->add_to_cleanup(qw(META.yml WebService-ISBNDB-* *.html *.log t/*.log));
$build->create_build_script;
