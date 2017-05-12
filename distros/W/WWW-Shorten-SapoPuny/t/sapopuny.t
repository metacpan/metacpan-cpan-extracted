use Test::More tests => 6;

BEGIN { use_ok WWW::Shorten::SapoPuny }

my $url    = 'https://metacpan.org/release/WWW-Shorten';
my $return = makeashorterlink($url);

ok( $return, 'not a error' )
  or diag "\$_error_message = $WWW::Shorten::SapoPuny::_error_message";

like $return, qr!http://[a-z0-9]+\.[a-z0-9]+\.xsl\.pt!,
  "looks like a SapoPuny!";

is( makealongerlink($return), $url, 'make it longer' )
  or diag "\$_error_message = $WWW::Shorten::SapoPuny::_error_message";

eval { makeashorterlink() };
ok( $@, 'makeashorterlink fails with no args' );
eval { makealongerlink() };
ok( $@, 'makealongerlink fails with no args' );
