use strict;
use warnings;
use Test::More "no_plan";
# use Test::More tests => 12;
use WWW::WorldLingo;
use HTTP::Response;

ok( my $wl = WWW::WorldLingo->new, "WWW::WorldLingo->new");
ok( $wl->srclang("de"), "Setting srclang to 'de'");
ok( $wl->trglang("de"), "Setting trglang to 'de'");
ok( $wl->data("I will fail"), "Setting data to 'I will fail'");

is( $wl->api(), "http://www.worldlingo.com/S000.1/api",
    "API address is correct");

ok( my $request = $wl->request(), "Request returned" );
isa_ok( $request, "HTTP::Request", "Request isa HTTP::Request");

# Check if we have internet connection
require IO::Socket;
my $s = IO::Socket::INET->new(PeerAddr => "www.google.com:80",
                              Timeout  => 30,
                             );
if ($s) {
    close($s);
    if ( $ENV{WORLDLINGO_TEST} )
    {
        ok( ! ( my $result = $wl->translate ), "Translation fails" );
        ok( my $error_code = $wl->error_code, "Error code returned" );
        is( $error_code, 176, "Error code is correct");
        ok( my $error = $wl->error, "Error string returned" );
        is( $error, "Invalid language pair", "Error string is correct");
        ok( my $response = $wl->response, "Response returned" );
        isa_ok( $response, "HTTP::Response", "Response isa HTTP::Response");
        ok( my $str_response = $response->as_string,
            "Saving copy of response as a string");
        ok( my $remade = WWW::WorldLingo->parse( $response ),
            "New WWW::WorldLingo object made from a response object" );
        isa_ok( $remade, "WWW::WorldLingo", "isa WWW::WorldLingo");
        is( $remade->error_code, 176, "Remade WWW::WorldLingo has correct error");
        ok( my $remade2 = WWW::WorldLingo->parse( $str_response ),
            "Parsing string response");
        is( $remade2->error_code, $remade->error_code,
            "Remade WWW::WorldLingos have same error");

        ok( $wl = WWW::WorldLingo->new, "WWW::WorldLingo->new");
        ok( $wl->srclang("en"), "Setting srclang to 'en'");
        ok( $wl->trglang("kr"), "Setting trglang to 'kr'");
        ok( $wl->data("How are you?"),
            "Setting data to 'How are you?'");
        ok( my $result = $wl->translate, "Translate" );
        ok( ! $wl->error, "No error" );
        ok( my $response = $wl->response, "Response returned" );

        ok( my $remade3 = WWW::WorldLingo->parse( $response ),
            "New WWW::WorldLingo object made from a response object" );
        ok( ! $remade3->error, "No error for remade object" );
        is( $remade3->result, $wl->result,
            "Remade WWW::WorldLingo has same result as original");
        is( $remade3->api_mode, $wl->api_mode,
            "Remade WWW::WorldLingo has same api_mode as original");
    }
    else
    {
        diag <<EOT;
You appear to be directly connected to the Internet. If you would like
to run the live test calls to the WorldLingo API server set your
envirnoment variable WORLDLINGO_TEST to a true value and rerun this
test.
EOT
    }

}

