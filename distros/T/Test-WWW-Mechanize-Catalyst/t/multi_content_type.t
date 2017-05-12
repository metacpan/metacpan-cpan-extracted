#!perl
use strict;
use warnings;
use lib qw(lib t/lib);

my $PORT;

BEGIN {
    $PORT = $ENV{TWMC_TEST_PORT} || 7357;
}

use Test::More;
use Test::Exception;

BEGIN {
    diag(
        "\n###################################################################\n",
        "Starting an external Catalyst HTTP server on port $PORT\n",
        "To change the port, please set the TWMC_TEST_PORT env variable.\n",
        "(The server will be automatically shut-down right after the tests).\n",
        "###################################################################\n"
    );
}

# Let's catch interrupts to force the END block execution.
$SIG{INT} = sub { warn "INT:$$"; exit };

use_ok 'ExternalCatty';
my $pid;
($pid, $PORT) = ExternalCatty->background($PORT);
$ENV{CATALYST_SERVER} ||= "http://localhost:$PORT";

use Test::WWW::Mechanize::Catalyst;
my $m = Test::WWW::Mechanize::Catalyst->new;

# Yeah, sorry - wait for the forked process to spin up...
sleep 10;

my $skip = 0;
TRY_CONNECT: {
  eval { $m->get('/') };

  if ($@ || $m->content =~ /Can't connect to \w+:$PORT/) {
    $skip = $@ || $m->content;
    diag $m;
  }
}

SKIP: {
  skip $skip, 9 if $skip;
  lives_ok { $m->get_ok( '/', 'Get a multi Content-Type response' ) }
  'Survive to a multi Content-Type sting';

  is( $m->ct, 'text/html', 'Multi Content-Type Content-Type' );
  $m->title_is( 'Root', 'Multi Content-Type title' );
  $m->content_contains( "Hello, test \x{263A}!", 'Multi Content-Type body' );

  # Test a redirect with a remote server now too.
  $m->get_ok( '/hello' );
  is($m->uri, "$ENV{CATALYST_SERVER}/");

  $m->get_ok( '/host' );
  $m->content_contains("Host: localhost:$PORT") or diag $m->content;

}

END {
    if ( $pid && $pid != 0 ) {
        kill 9, $pid;
    }
}

done_testing;

1;

