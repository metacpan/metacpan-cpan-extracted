use strict;
use warnings;
use Test::More "no_plan";
# use Test::More tests => 12;
use WWW::WorldLingo;

ok( my $wl = WWW::WorldLingo->new, "WWW::WorldLingo->new");

ok( $wl->srclang("en"), "Setting srclang to 'en'");

ok( $wl->trglang("it"), "Setting trglang to 'it'");

ok( $wl->data("Hello world"), "Setting data to 'Hello world'");

is( $wl->api(), "http://www.worldlingo.com/S000.1/api",
    "API address is correct");

ok( $wl->scheme("https"), "Setting for secure request");

is( $wl->api(), "https://www.worldlingo.com/S000.1/api",
    "Secure API address is correct");

isa_ok( $wl->request(), "HTTP::Request", "HTTP::Request was formed");

is( $wl->request->method, "POST", "HTTP::Request is a POST request");

is( $wl->request->uri, $wl->api, "HTTP::Request->uri matches \$wl->api");

# Check if we have internet connection
require IO::Socket;
my $s = IO::Socket::INET->new(PeerAddr => "www.google.com:80",
                              Timeout  => 30,
                             );
if ($s) {
    close($s);
    if ( $ENV{WORLDLINGO_TEST} )
    {
        ok( $wl->scheme("http"), "Putting scheme back to http");
        is( $wl->api(), "http://www.worldlingo.com/S000.1/api",
            "API address correctly reset");
        ok( my $result = $wl->translate(), "Translate" );
        is( $wl->api_mode, "TEST MODE ONLY - Random Target Languages",
            "API mode is correct");
        is( $result, $wl->result,
            "Result is equal to return value for translation");
        diag( $wl->result );
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

=pod

Bonjour monde
Hallo Welt
Hello wereld
Hello mundo
Hola mundo
Ciao mondo

=cut

