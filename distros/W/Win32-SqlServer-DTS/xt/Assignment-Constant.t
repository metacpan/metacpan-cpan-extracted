use strict;
use warnings;
use XML::Simple;
use Test::More tests => 5;
use Win32::SqlServer::DTS::Application;

my $xml_file = 'test-config.xml';
my $xml      = XML::Simple->new();
my $config   = $xml->XMLin($xml_file);

my $app = Win32::SqlServer::DTS::Application->new( $config->{credential} );
my $package = $app->get_db_package( { name => $config->{package} } );

# test-all DTS package has only one Dynamic Properties Task
my $iterator  = $package->get_dynamic_props();
my $dyn_props = $iterator->();

my $assign_iterator = $dyn_props->get_assignments();

while ( my $assignment = $assign_iterator->() ) {

    next unless ( $assignment->get_type_name() eq 'Constant' );

    # test the new method new
    isa_ok( $assignment, 'Win32::SqlServer::DTS::Assignment::Constant' );
    is( $assignment->get_type, 4, 'get_type returns 4' );

    is( $assignment->get_source, 'dts-testing',
        'get_source returns "dts-testing"' );

    is_deeply(
        $assignment->get_properties,
        {
            type        => 4,
            source      => 'dts-testing',
            destination => Win32::SqlServer::DTS::Assignment::Destination::Task->new(
                q{'Tasks';'DTSTask_DTSSendMailTask_1';'Properties';'Profile'})
        },
        'get_properties returns a hash reference'
    );

    like( $assignment->to_string, qr/[\w\n]+/,
        'to_string returns a string with new line characters' );

}

