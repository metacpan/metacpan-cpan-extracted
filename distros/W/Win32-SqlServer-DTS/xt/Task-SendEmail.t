use XML::Simple;
use Test::More;
use Win32::SqlServer::DTS::Application;

my $xml_file = 'test-config.xml';
my $xml      = XML::Simple->new();
my $config   = $xml->XMLin($xml_file);

my $app = Win32::SqlServer::DTS::Application->new( $config->{credential} );
my $package = $app->get_db_package( { name => $config->{package} } );

my $iterator = $package->get_send_emails();

plan tests => 8 * $package->count_send_emails();

while ( my $send = $iterator->() ) {

    $send->kill_sibling();

    ok( not( $send->is_nt_service() ), 'is_nt_service method returns false' );
    ok( $send->save_sent(), 'save_sent method returns true' );
    is(
        $send->get_message_text(),
        'Did you POD your code today?',
        'get_message_text returns correct content'
    );
    is( $send->get_cc_line(),     '', 'get_cc_line returns no content' );
    is( $send->get_attachments(), '', 'get_attachments returns no content' );
    is( $send->get_profile_password(),
        '', 'get_profile_password method returns no content' );
    is( $send->get_subject(), 'Hello World!',
        'get_subject returns correct content' );
    is( $send->get_to_line(), 'somebody@somewhere.com',
        'get_to_line returns correct content' );

}

