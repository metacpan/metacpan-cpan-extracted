use Mojo::Base -strict;
use Test::More;

use Webservice::Shipment::Carrier::UPS;
use Webservice::Shipment::MockUserAgent;

my $mock = Webservice::Shipment::MockUserAgent->new;

my $ups = Webservice::Shipment::Carrier::UPS->new(
  date_format => '%m/%d/%y',
  ua => $mock,
  username => 'johnq',
  password => 'p@ssword',
  api_key => 'COOLBEANS',
);

subtest 'delivered 1' => sub {
  $mock->mock_response({text => <<'  XML', format => 'xml'});
<?xml version="1.0"?>
<TrackResponse><Response><TransactionReference><CustomerContext>1Z584856NT65700000</CustomerContext></TransactionReference><ResponseStatusCode>1</ResponseStatusCode><ResponseStatusDescription>Success</ResponseStatusDescription></Response><Shipment><Shipper><ShipperNumber>584856</ShipperNumber><Address><AddressLine1>1234 MAIN STREET</AddressLine1><City>MADISON</City><StateProvinceCode>WI</StateProvinceCode><PostalCode>53717   2007</PostalCode><CountryCode>US</CountryCode></Address></Shipper><ShipmentWeight><UnitOfMeasurement><Code>LBS</Code></UnitOfMeasurement><Weight>0.00</Weight></ShipmentWeight><Service><Code>NT</Code><Description>UPS NEXT DAY AIR</Description></Service><ShipmentIdentificationNumber>1Z584856NT65700000</ShipmentIdentificationNumber><DeliveryDateUnavailable><Type>Scheduled Delivery</Type><Description>Scheduled Delivery Date is not currently available, please try back later</Description></DeliveryDateUnavailable><Package><TrackingNumber>1Z584856NT65700000</TrackingNumber><Activity><ActivityLocation><Address><City>YATAHEY</City><StateProvinceCode>NM</StateProvinceCode><PostalCode>87375</PostalCode><CountryCode>US</CountryCode></Address><Code>ML</Code><Description>FRONT DOOR</Description></ActivityLocation><Status><StatusType><Code>D</Code><Description>DELIVERED</Description></StatusType><StatusCode><Code>FS</Code></StatusCode></Status><Date>20140820</Date><Time>105900</Time></Activity><PackageWeight><UnitOfMeasurement><Code>LBS</Code></UnitOfMeasurement><Weight>0.00</Weight></PackageWeight></Package></Shipment></TrackResponse>
  XML
  my $data = $ups->track('1Z584856NT65700000');
  my $expect = {
    'status' => {
      'description' => 'DELIVERED',
      'date' => '08/20/14',
      'delivered' => 1,
    },
    'destination' => {
      'country' => '',
      'postal_code' => '',
      'state' => '',
      'city' => '',
      'address2' => '',
      'address1' => '',
    },
    'weight' => '0.00 LBS',
    'service' => 'UPS NEXT DAY AIR',
    human_url => 'http://wwwapps.ups.com/WebTracking/track?trackNums=1Z584856NT65700000&track.x=Track',
  };
  is_deeply $data, $expect, 'parsed data correctly';
};

subtest 'delivered 2' => sub {
  $mock->mock_response({text => <<'  XML', format => 'xml'});
<?xml version="1.0"?>
<TrackResponse><Response><TransactionReference><CustomerContext>1Z584856NW66600000</CustomerContext></TransactionReference><ResponseStatusCode>1</ResponseStatusCode><ResponseStatusDescription>Success</ResponseStatusDescription></Response><Shipment><Shipper><ShipperNumber>584856</ShipperNumber><Address><AddressLine1>1234 MAIN STREET</AddressLine1><City>MADISON</City><StateProvinceCode>WI</StateProvinceCode><PostalCode>53717   2007</PostalCode><CountryCode>US</CountryCode></Address></Shipper><ShipTo><Address><City>CARROLLTON</City><StateProvinceCode>TX</StateProvinceCode><PostalCode>750062755</PostalCode><CountryCode>US</CountryCode></Address></ShipTo><ShipmentWeight><UnitOfMeasurement><Code>LBS</Code></UnitOfMeasurement><Weight>0.60</Weight></ShipmentWeight><Service><Code>013</Code><Description>NEXT DAY AIR SAVER</Description></Service><ReferenceNumber><Code>01</Code><Value>88135290008</Value></ReferenceNumber><ShipmentIdentificationNumber>1Z584856NW66600000</ShipmentIdentificationNumber><PickupDate>20150305</PickupDate><DeliveryDateUnavailable><Type>Scheduled Delivery</Type><Description>Scheduled Delivery Date is not currently available, please try back later</Description></DeliveryDateUnavailable><Package><TrackingNumber>1Z584856NW66600000</TrackingNumber><Activity><ActivityLocation><Address><City>CARROLLTON</City><StateProvinceCode>TX</StateProvinceCode><PostalCode>75006</PostalCode><CountryCode>US</CountryCode></Address><Code>ML</Code><Description>FRONT DOOR</Description></ActivityLocation><Status><StatusType><Code>D</Code><Description>DELIVERED</Description></StatusType><StatusCode><Code>FS</Code></StatusCode></Status><Date>20150306</Date><Time>185200</Time></Activity><PackageWeight><UnitOfMeasurement><Code>LBS</Code></UnitOfMeasurement><Weight>0.60</Weight></PackageWeight><ReferenceNumber><Code>01</Code><Value>88135290008</Value></ReferenceNumber></Package></Shipment></TrackResponse>
  XML
  my $data = $ups->track('1Z584856NW66600000');
  my $expect = {
    'status' => {
      'delivered' => 1,
      'date' => '03/06/15',
      'description' => 'DELIVERED'
    },
    'destination' => {
      'address2' => '',
      'postal_code' => '750062755',
      'city' => 'CARROLLTON',
      'country' => 'US',
      'state' => 'TX',
      'address1' => ''
    },
    'service' => 'UPS NEXT DAY AIR SAVER',
    'weight' => '0.60 LBS',
    human_url => 'http://wwwapps.ups.com/WebTracking/track?trackNums=1Z584856NW66600000&track.x=Track',
  };
  is_deeply $data, $expect, 'parsed data correctly';
};

subtest 'delivered 3' => sub {
  $mock->mock_response({text => <<'  XML', format => 'xml'});
<?xml version="1.0"?>
<TrackResponse><Response><TransactionReference><CustomerContext>1Z584856NT64470000</CustomerContext></TransactionReference><ResponseStatusCode>1</ResponseStatusCode><ResponseStatusDescription>Success</ResponseStatusDescription></Response><Shipment><Shipper><ShipperNumber>584856</ShipperNumber><Address><AddressLine1>1234 MAIN STREET</AddressLine1><City>MADISON</City><StateProvinceCode>WI</StateProvinceCode><PostalCode>53717   2007</PostalCode><CountryCode>US</CountryCode></Address></Shipper><ShipTo><Address><City>NEW YORK</City><StateProvinceCode>NY</StateProvinceCode><PostalCode>100655924</PostalCode><CountryCode>US</CountryCode></Address></ShipTo><ShipmentWeight><UnitOfMeasurement><Code>LBS</Code></UnitOfMeasurement><Weight>1.10</Weight></ShipmentWeight><Service><Code>001</Code><Description>NEXT DAY AIR</Description></Service><ReferenceNumber><Code>01</Code><Value>88148560006</Value></ReferenceNumber><ShipmentIdentificationNumber>1Z584856NT64470000</ShipmentIdentificationNumber><PickupDate>20150305</PickupDate><DeliveryDateUnavailable><Type>Scheduled Delivery</Type><Description>Scheduled Delivery Date is not currently available, please try back later</Description></DeliveryDateUnavailable><Package><TrackingNumber>1Z584856NT64470000</TrackingNumber><Activity><ActivityLocation><Address><City>NEW YORK</City><StateProvinceCode>NY</StateProvinceCode><PostalCode>10065</PostalCode><CountryCode>US</CountryCode></Address><Code>ML</Code><Description>FRONT DOOR</Description></ActivityLocation><Status><StatusType><Code>D</Code><Description>DELIVERED</Description></StatusType><StatusCode><Code>FS</Code></StatusCode></Status><Date>20150309</Date><Time>090300</Time></Activity><PackageWeight><UnitOfMeasurement><Code>LBS</Code></UnitOfMeasurement><Weight>1.10</Weight></PackageWeight><ReferenceNumber><Code>01</Code><Value>88148560006</Value></ReferenceNumber></Package></Shipment></TrackResponse>
  XML
  my $data = $ups->track('1Z584856NT64470000');
  my $expect = {
    'destination' => {
      'city' => 'NEW YORK',
      'address2' => '',
      'country' => 'US',
      'state' => 'NY',
      'postal_code' => '100655924',
      'address1' => ''
    },
    'weight' => '1.10 LBS',
    'status' => {
      'date' => '03/09/15',
      'delivered' => 1,
      'description' => 'DELIVERED'
    },
    'service' => 'UPS NEXT DAY AIR',
    human_url => 'http://wwwapps.ups.com/WebTracking/track?trackNums=1Z584856NT64470000&track.x=Track',
  };
  is_deeply $data, $expect, 'parsed data correctly';
};

subtest 'delivered 4 (non-blocking)' => sub {
  $mock->mock_blocking(0);
  $mock->mock_response({text => <<'  XML', format => 'xml'});
<?xml version="1.0"?>
<TrackResponse><Response><TransactionReference><CustomerContext>1Z5848562966510000</CustomerContext></TransactionReference><ResponseStatusCode>1</ResponseStatusCode><ResponseStatusDescription>Success</ResponseStatusDescription></Response><Shipment><Shipper><ShipperNumber>584856</ShipperNumber><Address><AddressLine1>1234 MAIN STREET</AddressLine1><City>MADISON</City><StateProvinceCode>WI</StateProvinceCode><PostalCode>53717   2007</PostalCode><CountryCode>US</CountryCode></Address></Shipper><ShipTo><Address><City>W HARRISON</City><StateProvinceCode>NY</StateProvinceCode><PostalCode>106042137</PostalCode><CountryCode>US</CountryCode></Address></ShipTo><ShipmentWeight><UnitOfMeasurement><Code>LBS</Code></UnitOfMeasurement><Weight>0.50</Weight></ShipmentWeight><Service><Code>013</Code><Description>NEXT DAY AIR SAVER</Description></Service><ReferenceNumber><Code>01</Code><Value>87972050004</Value></ReferenceNumber><ShipmentIdentificationNumber>1Z5848562966510000</ShipmentIdentificationNumber><PickupDate>20150305</PickupDate><DeliveryDateUnavailable><Type>Scheduled Delivery</Type><Description>Scheduled Delivery Date is not currently available, please try back later</Description></DeliveryDateUnavailable><Package><TrackingNumber>1Z5848562966510000</TrackingNumber><PackageServiceOptions><SignatureRequired><Code>S</Code></SignatureRequired></PackageServiceOptions><Activity><ActivityLocation><Address><City>WEST HARRISON</City><StateProvinceCode>NY</StateProvinceCode><PostalCode>10604</PostalCode><CountryCode>US</CountryCode></Address><Code>M1</Code><Description>RESIDENTIAL</Description><SignedForByName>JOHN Q. PUBLIC</SignedForByName></ActivityLocation><Status><StatusType><Code>D</Code><Description>DELIVERED</Description></StatusType><StatusCode><Code>KB</Code></StatusCode></Status><Date>20150309</Date><Time>113400</Time></Activity><PackageWeight><UnitOfMeasurement><Code>LBS</Code></UnitOfMeasurement><Weight>0.50</Weight></PackageWeight><ReferenceNumber><Code>01</Code><Value>87972050004</Value></ReferenceNumber><Accessorial><Code>043</Code><Description>CUSTOMIZED DELIVERY CONFIRM.</Description></Accessorial></Package></Shipment></TrackResponse>
  XML
  my ($err, $data);
  $ups->track('1Z5848562966510000', sub { (undef, $err, $data) = @_ });
  ok ! $err, 'no error';
  my $expect = {
    'weight' => '0.50 LBS',
    'status' => {
      'description' => 'DELIVERED',
      'date' => '03/09/15',
      'delivered' => 1,
    },
    'destination' => {
      'city' => 'W HARRISON',
      'address2' => '',
      'postal_code' => '106042137',
      'state' => 'NY',
      'country' => 'US',
      'address1' => '',
    },
    'service' => 'UPS NEXT DAY AIR SAVER',
    human_url => 'http://wwwapps.ups.com/WebTracking/track?trackNums=1Z5848562966510000&track.x=Track',
  };
  is_deeply $data, $expect, 'parsed data correctly';
};

done_testing;

