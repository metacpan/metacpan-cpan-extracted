use warnings;
use strict;
use XML::Simple;
use Win32::SqlServer::DTS::Application;

my $xml_file = 'modify.xml';
my $xml      = XML::Simple->new();
my $config   = $xml->XMLin($xml_file);

my $app = Win32::SqlServer::DTS::Application->new( $config->{credential} );
my $package = $app->get_db_package( { name => $config->{package} } );

my $iterator = $package->get_dynamic_props();

while ( my $dyn_prop = $iterator->() ) {

    my $assign_iterator = $dyn_prop->get_assignments();

    while ( my $assignment = $assign_iterator->() ) {

        my $dest = $assignment->get_destination();

        print 'old: ', $destination->get_raw_string(), "\n";

        if ( $dest->changes('GlobalVar') ) {

            if ( $dest->get_destination() eq 'computer_name' ) {

                $dest->set_string(
'\'Global Variables\';\'v_computer_name\';\'Properties\';\'Value\''
                );

            }

        }

        print 'new: ', $destination->get_raw_string(), "\n";
        print 'new, from original DTS object: ', $assignment->get_sibling()->{DestinationPropertyID},
          "\n";

    }

}

$package->save_to_server( $app->get_credential()->to_list() );
