use Test::More;

use_ok('Tiny::OpenSSL::Subject');

my $san = Tiny::OpenSSL::Subject->new;

can_ok( $san, 'commonname' );
can_ok( $san, 'locality' );
can_ok( $san, 'state' );
can_ok( $san, 'country' );
can_ok( $san, 'organization' );
can_ok( $san, 'organizational_unit' );

$san->commonname('test certificate');
$san->locality('Austin');
$san->state('TX');
$san->country('US');
$san->organization('Example Department');
$san->organizational_unit('Example Company');

is($san->dn, '/C=US/ST=TX/L=Austin/O=Example Department/OU=Example Company/CN=test certificate');

done_testing;
