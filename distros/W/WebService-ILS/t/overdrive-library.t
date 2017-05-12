#!/usr/bin/perl

use Modern::Perl;

use Test::More tests => 4;
use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/lib";
use T::OverDrive;

use_ok('WebService::ILS::OverDrive::Library');

SKIP: {
    skip "Not testing OverDrive::Library API, WEBSERVICE_ILS_TEST_OVERDRIVE_LIBRARY not set", 3
      unless $ENV{WEBSERVICE_ILS_TEST_OVERDRIVE_LIBRARY};

    my $od_id     = $ENV{OVERDRIVE_TEST_CLIENT_ID}
        or BAIL_OUT("Env OVERDRIVE_TEST_CLIENT_ID not set");
    my $od_secret = $ENV{OVERDRIVE_TEST_CLIENT_SECRET}
        or BAIL_OUT("Env OVERDRIVE_TEST_CLIENT_SECRET not set");
    my $od_library_id = $ENV{OVERDRIVE_TEST_LIBRARY_ID}
        or BAIL_OUT("Env OVERDRIVE_TEST_LIBRARY_ID not set");

    my $od = WebService::ILS::OverDrive::Library->new({
        test => 1,
        client_id => $od_id,
        client_secret => $od_secret,
        library_id => $od_library_id,
    });

    # Standard interface
    #
    subtest "Standard search" => sub { T::OverDrive::search( $od ) };

    # Native interface
    #
    my $library = $od->native_library_account;
    ok( $library && $library->{name}, "Native library")
        or diag(Dumper($library));

    subtest "Native search"   => sub { T::OverDrive::native_search( $od ) };
}
