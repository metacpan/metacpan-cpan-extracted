use XML::Simple;
use Test::More;
use Test::Exception;
use Win32::SqlServer::DTS::Application;
use Win32::SqlServer::DTS::Assignment;
use Win32::OLE qw(in);

my $xml_file = 'test-config.xml';
my $xml      = XML::Simple->new();
my $config   = $xml->XMLin($xml_file);

my $app = Win32::SqlServer::DTS::Application->new( $config->{credential} );
my $package = $app->get_db_package( { name => $config->{package} } );

# test-all DTS package has only one Dynamic Properties Task
my $iterator  = $package->get_dynamic_props();
my $dyn_props = $iterator->();

plan tests => 6 * $dyn_props->count_assignments();

# using direct methods from sibling to be able to instantiate Win32::SqlServer::DTS::Assignment objects directly
# without using the subclasses from it
my $assignments = $dyn_props->get_sibling()->Assignments();

foreach my $assignment ( in($assignments) ) {

    my $new_assign = Win32::SqlServer::DTS::Assignment->new($assignment);

    # test the new method new
    isa_ok( $new_assign, 'Win32::SqlServer::DTS::Assignment' );
    like( $new_assign->get_type, qr/^\d$/, 'get_type returns an integer' );

    dies_ok( sub { $new_assign->get_source() }, 'get_source should die' );
    dies_ok( sub { $new_assign->get_properties() },
        'get_properties should die due get_source method not be overrided' );
    dies_ok( sub { $new_assign->to_string() },
        'to_string should die due get_source method not be overrided' );

    isa_ok( $new_assign->get_destination(), 'Win32::SqlServer::DTS::Assignment::Destination' );
}

