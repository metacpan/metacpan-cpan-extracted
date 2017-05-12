use warnings;
use strict;
use Test::More tests => 5;
use XML::Simple;
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

    next unless ( $assignment->get_type_name() eq 'DataFile' );

    # test the new method new
    isa_ok( $assignment, 'Win32::SqlServer::DTS::Assignment::DataFile' );

    is( $assignment->get_type, 5, 'get_type returns 5' );

    is(
        $assignment->get_source(),
        'E:\dts\perl_dts\DTS\test-all.txt',
        'get_source returns E:\dts\perl_dts\DTS\test-all.txt'
    );

    is_deeply(
        $assignment->get_properties(),
        {
            type        => 5,
            source      => 'E:\dts\perl_dts\DTS\test-all.txt',
            destination => Win32::SqlServer::DTS::Assignment::Destination::Connection->new(
                q{'Connections';'Text File (Source)';'Properties';'DataSource'}
            )
        },
        'get_properties returns a well defined hash reference'
    );

    like( $assignment->to_string(),
        qr/[\w\n]+/, 'to_string returns a string with new line characters' );

}

