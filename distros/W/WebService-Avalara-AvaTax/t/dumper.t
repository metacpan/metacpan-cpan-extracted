#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;    # skip_all => 'bugs in Data::Dump::Streamer';
use Test::File::ShareDir::Module 1.000000 {
    'WebService::Avalara::AvaTax::Service::Tax' => 'shares/ServiceTax/'
};
use Test::RequiresInternet ( 'development.avalara.net' => 443 );
use Const::Fast;
use List::Util 1.33;
use WebService::Avalara::AvaTax::Service::Tax;

const my @AVALARA_ENV => qw(username password);

plan skip_all => 'set environment variables ' . join q{ } =>
    map {"AVALARA_\U$_"} @AVALARA_ENV
    if not List::Util::all { $ENV{"AVALARA_\U$_"} } @AVALARA_ENV;

my $tax_service = new_ok( 'WebService::Avalara::AvaTax::Service::Tax' =>
        [ map { ( $_ => $ENV{"AVALARA_\U$_"} ) } @AVALARA_ENV ] );

my $package  = 'Local::' . $tax_service->_package_name;
my $tempfile = Path::Tiny->tempfile('dumperXXXXX');

lives_ok(
    sub {
        $tax_service->_write_dump_file( "$tempfile", $package,
            %{ $tax_service->clients } );
    } => "write dump file as $package to $tempfile",
);
require_ok($tempfile);
lives_ok( sub { $package->import }, "import $package" );

done_testing;
