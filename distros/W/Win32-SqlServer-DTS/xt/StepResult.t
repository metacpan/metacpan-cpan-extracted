use XML::Simple;
# there are 5 steps in the sample DTS Package
use Test::More tests => 5 * 4;
use Win32::SqlServer::DTS::Application;

my $xml_file = 'test-config.xml';
my $xml      = XML::Simple->new();
my $config   = $xml->XMLin($xml_file);

my $app = Win32::SqlServer::DTS::Application->new( $config->{credential} );
my $package = $app->get_db_package( { name => $config->{package} } );

my $results = $package->execute();

foreach my $result ( @{$results} ) {

    isa_ok( $result, 'Win32::SqlServer::DTS::Package::Step::Result' );
    ok( $result->to_string(),       'to_string returns a true value' );
    ok( $result->to_xml(),          'to_xml returns a true value' );
    ok( not( $result->is_success ), 'all steps fail' );

}

