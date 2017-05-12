use Mojo::Base -strict;

use Test::More;

use Webservice::Shipment;

my $ship = Webservice::Shipment->new(defaults => {date_format => '%m/%d/%y'});
$ship->add_carrier('UPS');
my $ups = $ship->carriers->[0];
isa_ok $ups, 'Webservice::Shipment::Carrier::UPS';
is $ups->date_format, '%m/%d/%y', 'defaults used correctly';

$ship->add_carrier('USPS', {date_format => '%d/%m/%y'});
my $usps = $ship->carriers->[1];
isa_ok $usps, 'Webservice::Shipment::Carrier::USPS';
is $usps->date_format, '%d/%m/%y', 'default overridden by passed in arguments';

isa_ok $ship->detect('9400115901396094290000'), 'Webservice::Shipment::Carrier::USPS';
like $ship->human_url('9400115901396094290000'), qr/usps/i, 'correct delegation';

isa_ok $ship->detect('1Z584856NT65700000'), 'Webservice::Shipment::Carrier::UPS';
like $ship->human_url('1Z584856NT65700000'), qr/ups/i, 'correct delegation';

done_testing;


