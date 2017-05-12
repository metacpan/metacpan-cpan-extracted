use XML::Simple;
use Test::More tests => 4;
use Win32::SqlServer::DTS::Application;

my $xml_file = 'test-config.xml';
my $xml      = XML::Simple->new();
my $config   = $xml->XMLin($xml_file);
my $regex    = '^t.*l$';

my $app = Win32::SqlServer::DTS::Application->new( $config->{credential} );

isa_ok( $app->get_db_package( { name => $config->{package} } ),
    'Win32::SqlServer::DTS::Package' );
isa_ok( $app->get_db_package_regex($regex), 'Win32::SqlServer::DTS::Package' );
ok(
    test_list( $app->list_pkgs_names() ),
    'Listing packages names on database server'
);
ok( test_list( $app->regex_pkgs_names($regex) ),
    'Listing packages names on database server by using a regular expression' );

sub test_list {

    my $array_ref = shift;
    my $founded;

    foreach ( @{$array_ref} ) {

        if ( $_ eq $config->{package} ) {

            $founded++;
            last;

        }

    }

    return $founded;

}

