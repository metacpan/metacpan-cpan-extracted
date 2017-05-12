use warnings;
use strict;

use Test::More;
use XML::Simple;
use Win32::SqlServer::DTS::Application;

#use Win32::SqlServer::DTS::Assignment::Destination::Connection;

my $xml_file = 'test-config.xml';
my $xml      = XML::Simple->new();
my $config   = $xml->XMLin($xml_file);

my $app = Win32::SqlServer::DTS::Application->new( $config->{credential} );
my $package = $app->get_db_package( { name => $config->{package} } );

# test-all DTS package has only one Dynamic Properties Task
my $iterator  = $package->get_dynamic_props();
my $dyn_props = $iterator->();

plan tests => $dyn_props->count_assignments() * 2;

my $assign_iterator = $dyn_props->get_assignments();

while ( my $assignment = $assign_iterator->() ) {

    my $destination = $assignment->get_destination();

    isa_ok( $destination, 'Win32::SqlServer::DTS::Assignment::Destination',
        'destination is a subclass from Win32::SqlServer::DTS::Assignment::Destination superclass'
    );

    like(
        $destination->get_raw_string(),
        qr/^(\'[\w\s\(\)]+\'\;\'[\w\s\(\)]+\')(\'[\w\s\(\)]+\')*/,
        'get_raw_string returns a valid string'
    );

    #and test other methods

}

