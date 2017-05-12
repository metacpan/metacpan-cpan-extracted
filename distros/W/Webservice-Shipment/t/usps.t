use Mojo::Base -strict;
use Test::More;

use Webservice::Shipment::Carrier::USPS;
use Webservice::Shipment::MockUserAgent;

my $mock = Webservice::Shipment::MockUserAgent->new;

my $usps = Webservice::Shipment::Carrier::USPS->new(
  date_format => '%m/%d/%y',
  ua => $mock,
  username => 'johnq',
  password => 'p@ssword',
);

subtest 'delivered 1' => sub {
  $mock->mock_response({text => <<'  XML', format => 'xml'});
<?xml version="1.0" encoding="UTF-8"?>
<TrackResponse><TrackInfo ID="9400115901396094290000"><Class>First-Class Package Service</Class><ClassOfMailCode>FC</ClassOfMailCode><DestinationCity>BLOOMFIELD HILLS</DestinationCity><DestinationState>MI</DestinationState><DestinationZip>48304</DestinationZip><EmailEnabled>true</EmailEnabled><ExpectedDeliveryDate>March 9, 2015</ExpectedDeliveryDate><KahalaIndicator>false</KahalaIndicator><MailTypeCode>DM</MailTypeCode><MPDATE>2015-03-06 15:08:20.000000</MPDATE><MPSUFFIX>293362061</MPSUFFIX><OriginCity>MADISON</OriginCity><OriginState>WI</OriginState><OriginZip>53717</OriginZip><PodEnabled>false</PodEnabled><PredictedDeliveryDate>March 9, 2015</PredictedDeliveryDate><RestoreEnabled>false</RestoreEnabled><RramEnabled>false</RramEnabled><RreEnabled>false</RreEnabled><Service>USPS Tracking&lt;SUP&gt;&amp;#153;&lt;/SUP&gt;</Service><ServiceTypeCode>001</ServiceTypeCode><Status>Delivered</Status><StatusCategory>Delivered</StatusCategory><StatusSummary>Your item was delivered at 9:24 am on March 9, 2015 in BLOOMFIELD HILLS, MI 48304.</StatusSummary><TABLECODE>T</TABLECODE><TrackSummary><EventTime>9:24 am</EventTime><EventDate>March 9, 2015</EventDate><Event>Delivered</Event><EventCity>BLOOMFIELD HILLS</EventCity><EventState>MI</EventState><EventZIPCode>48304</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>01</EventCode></TrackSummary><TrackDetail><EventTime>9:16 am</EventTime><EventDate>March 9, 2015</EventDate><Event>Sorting Complete</Event><EventCity>BLOOMFIELD HILLS</EventCity><EventState>MI</EventState><EventZIPCode>48304</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>PC</EventCode></TrackDetail><TrackDetail><EventTime>8:37 am</EventTime><EventDate>March 9, 2015</EventDate><Event>Arrived at Post Office</Event><EventCity>BLOOMFIELD HILLS</EventCity><EventState>MI</EventState><EventZIPCode>48304</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>07</EventCode></TrackDetail><TrackDetail><EventTime>9:48 am</EventTime><EventDate>March 8, 2015</EventDate><Event>Departed USPS Facility</Event><EventCity>ALLEN PARK</EventCity><EventState>MI</EventState><EventZIPCode>48101</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>EF</EventCode></TrackDetail><TrackDetail><EventTime>7:38 pm</EventTime><EventDate>March 7, 2015</EventDate><Event>Arrived at USPS Facility</Event><EventCity>ALLEN PARK</EventCity><EventState>MI</EventState><EventZIPCode>48101</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>10</EventCode></TrackDetail><TrackDetail><EventTime>9:45 pm</EventTime><EventDate>March 6, 2015</EventDate><Event>Departed USPS Facility</Event><EventCity>OAK CREEK</EventCity><EventState>WI</EventState><EventZIPCode>53154</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>EF</EventCode></TrackDetail><TrackDetail><EventTime>9:14 pm</EventTime><EventDate>March 6, 2015</EventDate><Event>Arrived at USPS Origin Facility</Event><EventCity>OAK CREEK</EventCity><EventState>WI</EventState><EventZIPCode>53154</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>10</EventCode></TrackDetail><TrackDetail><EventTime>3:22 pm</EventTime><EventDate>March 6, 2015</EventDate><Event>Picked up by Request</Event><EventCity>MADISON</EventCity><EventState>WI</EventState><EventZIPCode>53717</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>03</EventCode></TrackDetail><TrackDetail><EventTime>2:52 pm</EventTime><EventDate>March 6, 2015</EventDate><Event>Shipping Label Created</Event><EventCity>MADISON</EventCity><EventState>WI</EventState><EventZIPCode>53717</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>GX</EventCode></TrackDetail></TrackInfo></TrackResponse>
  XML
  my $data = $usps->track('9400115901396094290000');
  my $expect = {
    service => 'USPS First-Class Package Service',
    destination => {
      city => 'BLOOMFIELD HILLS',
      state => 'MI',
      postal_code => '48304',
      country => '',
      address1 => '',
      address2 => '',
    },
    status => {
      description => 'Your item was delivered at 9:24 am on March 9, 2015 in BLOOMFIELD HILLS, MI 48304.',
      delivered => 1,
      date => '03/09/15',
    },
    weight => '',
    human_url => 'https://tools.usps.com/go/TrackConfirmAction?tLabels=9400115901396094290000',
  };
  is_deeply $data, $expect, 'correct parsed response';
};

subtest 'delivered 2' => sub {
  $mock->mock_response({text => <<'  XML', format => 'xml'});
<?xml version="1.0" encoding="UTF-8"?>
<TrackResponse><TrackInfo ID="9400115901396094290000"><Class>First-Class Package Service</Class><ClassOfMailCode>FC</ClassOfMailCode><DestinationCity>NEW YORK</DestinationCity><DestinationState>NY</DestinationState><DestinationZip>10128</DestinationZip><EmailEnabled>true</EmailEnabled><ExpectedDeliveryDate>March 9, 2015</ExpectedDeliveryDate><KahalaIndicator>false</KahalaIndicator><MailTypeCode>DM</MailTypeCode><MPDATE>2015-03-06 15:08:20.000000</MPDATE><MPSUFFIX>293424476</MPSUFFIX><OriginCity>MADISON</OriginCity><OriginState>WI</OriginState><OriginZip>53717</OriginZip><PodEnabled>false</PodEnabled><PredictedDeliveryDate>March 9, 2015</PredictedDeliveryDate><RestoreEnabled>false</RestoreEnabled><RramEnabled>false</RramEnabled><RreEnabled>false</RreEnabled><Service>USPS Tracking&lt;SUP&gt;&amp;#153;&lt;/SUP&gt;</Service><ServiceTypeCode>001</ServiceTypeCode><Status>Delivered, Front Desk/Reception</Status><StatusCategory>Delivered</StatusCategory><StatusSummary>Your item was delivered to the front desk or reception area at 11:46 am on March 9, 2015 in NEW YORK, NY 10128.</StatusSummary><TABLECODE>T</TABLECODE><TrackSummary><EventTime>11:46 am</EventTime><EventDate>March 9, 2015</EventDate><Event>Delivered, Front Desk/Reception</Event><EventCity>NEW YORK</EventCity><EventState>NY</EventState><EventZIPCode>10128</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>01</EventCode><DeliveryAttributeCode>05</DeliveryAttributeCode></TrackSummary><TrackDetail><EventTime>11:14 am</EventTime><EventDate>March 9, 2015</EventDate><Event>Out for Delivery</Event><EventCity>NEW YORK</EventCity><EventState>NY</EventState><EventZIPCode>10028</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>OF</EventCode></TrackDetail><TrackDetail><EventTime>11:04 am</EventTime><EventDate>March 9, 2015</EventDate><Event>Sorting Complete</Event><EventCity>NEW YORK</EventCity><EventState>NY</EventState><EventZIPCode>10028</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>PC</EventCode></TrackDetail><TrackDetail><EventTime>6:42 am</EventTime><EventDate>March 9, 2015</EventDate><Event>Arrived at Post Office</Event><EventCity>NEW YORK</EventCity><EventState>NY</EventState><EventZIPCode>10028</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>07</EventCode></TrackDetail><TrackDetail><EventTime>3:15 am</EventTime><EventDate>March 9, 2015</EventDate><Event>Departed USPS Facility</Event><EventCity>BETHPAGE</EventCity><EventState>NY</EventState><EventZIPCode>11714</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>EF</EventCode></TrackDetail><TrackDetail><EventTime>9:24 am</EventTime><EventDate>March 8, 2015</EventDate><Event>Arrived at USPS Facility</Event><EventCity>BETHPAGE</EventCity><EventState>NY</EventState><EventZIPCode>11714</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>10</EventCode></TrackDetail><TrackDetail><EventTime>9:45 pm</EventTime><EventDate>March 6, 2015</EventDate><Event>Departed USPS Facility</Event><EventCity>OAK CREEK</EventCity><EventState>WI</EventState><EventZIPCode>53154</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>EF</EventCode></TrackDetail><TrackDetail><EventTime>9:14 pm</EventTime><EventDate>March 6, 2015</EventDate><Event>Arrived at USPS Origin Facility</Event><EventCity>OAK CREEK</EventCity><EventState>WI</EventState><EventZIPCode>53154</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>10</EventCode></TrackDetail><TrackDetail><EventTime>3:22 pm</EventTime><EventDate>March 6, 2015</EventDate><Event>Picked up by Request</Event><EventCity>MADISON</EventCity><EventState>WI</EventState><EventZIPCode>53717</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>03</EventCode></TrackDetail><TrackDetail><EventTime>2:50 pm</EventTime><EventDate>March 6, 2015</EventDate><Event>Shipping Label Created</Event><EventCity>MADISON</EventCity><EventState>WI</EventState><EventZIPCode>53717</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>GX</EventCode></TrackDetail></TrackInfo></TrackResponse>
  XML
  my $data = $usps->track('9400115901396094290000');
  my $expect = {
    service => 'USPS First-Class Package Service',
    destination => {
      city => 'NEW YORK',
      state => 'NY',
      postal_code => '10128',
      country => '',
      address1 => '',
      address2 => '',
    },
    status => {
      description => 'Your item was delivered to the front desk or reception area at 11:46 am on March 9, 2015 in NEW YORK, NY 10128.',
      delivered => 1,
      date => '03/09/15',
    },
    weight => '',
    human_url => 'https://tools.usps.com/go/TrackConfirmAction?tLabels=9400115901396094290000',
  };
  is_deeply $data, $expect, 'correct parsed response';
};

subtest 'delivered 3 (non-blocking)' => sub {
  $mock->mock_blocking(0);
  $mock->mock_response({text => <<'  XML', format => 'xml'});
<?xml version="1.0" encoding="UTF-8"?>
<TrackResponse><TrackInfo ID="9400115901396094290000"><Class>First-Class Package Service</Class><ClassOfMailCode>FC</ClassOfMailCode><DestinationCity>YORKTOWN</DestinationCity><DestinationState>VA</DestinationState><DestinationZip>23693</DestinationZip><EmailEnabled>true</EmailEnabled><ExpectedDeliveryDate>March 9, 2015</ExpectedDeliveryDate><KahalaIndicator>false</KahalaIndicator><MailTypeCode>DM</MailTypeCode><MPDATE>2015-03-06 15:08:20.000000</MPDATE><MPSUFFIX>293426351</MPSUFFIX><OriginCity>MADISON</OriginCity><OriginState>WI</OriginState><OriginZip>53717</OriginZip><PodEnabled>false</PodEnabled><PredictedDeliveryDate>March 9, 2015</PredictedDeliveryDate><RestoreEnabled>false</RestoreEnabled><RramEnabled>false</RramEnabled><RreEnabled>false</RreEnabled><Service>USPS Tracking&lt;SUP&gt;&amp;#153;&lt;/SUP&gt;</Service><ServiceTypeCode>001</ServiceTypeCode><Status>Delivered, In/At Mailbox</Status><StatusCategory>Delivered</StatusCategory><StatusSummary>Your item was delivered in or at the mailbox at 1:44 pm on March 9, 2015 in YORKTOWN, VA 23693.</StatusSummary><TABLECODE>T</TABLECODE><TrackSummary><EventTime>1:44 pm</EventTime><EventDate>March 9, 2015</EventDate><Event>Delivered, In/At Mailbox</Event><EventCity>YORKTOWN</EventCity><EventState>VA</EventState><EventZIPCode>23693</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>01</EventCode><DeliveryAttributeCode>01</DeliveryAttributeCode></TrackSummary><TrackDetail><EventTime>9:27 am</EventTime><EventDate>March 9, 2015</EventDate><Event>Out for Delivery</Event><EventCity>YORKTOWN</EventCity><EventState>VA</EventState><EventZIPCode>23692</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>OF</EventCode></TrackDetail><TrackDetail><EventTime>9:17 am</EventTime><EventDate>March 9, 2015</EventDate><Event>Sorting Complete</Event><EventCity>YORKTOWN</EventCity><EventState>VA</EventState><EventZIPCode>23692</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>PC</EventCode></TrackDetail><TrackDetail><EventTime>6:05 am</EventTime><EventDate>March 9, 2015</EventDate><Event>Arrived at Post Office</Event><EventCity>YORKTOWN</EventCity><EventState>VA</EventState><EventZIPCode>23692</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>07</EventCode></TrackDetail><TrackDetail><EventTime>5:00 am</EventTime><EventDate>March 9, 2015</EventDate><Event>Departed USPS Facility</Event><EventCity>NORFOLK</EventCity><EventState>VA</EventState><EventZIPCode>23501</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>EF</EventCode></TrackDetail><TrackDetail><EventTime>1:53 pm</EventTime><EventDate>March 8, 2015</EventDate><Event>Arrived at USPS Facility</Event><EventCity>NORFOLK</EventCity><EventState>VA</EventState><EventZIPCode>23501</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>10</EventCode></TrackDetail><TrackDetail><EventTime>9:45 pm</EventTime><EventDate>March 6, 2015</EventDate><Event>Departed USPS Facility</Event><EventCity>OAK CREEK</EventCity><EventState>WI</EventState><EventZIPCode>53154</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>EF</EventCode></TrackDetail><TrackDetail><EventTime>9:15 pm</EventTime><EventDate>March 6, 2015</EventDate><Event>Arrived at USPS Origin Facility</Event><EventCity>OAK CREEK</EventCity><EventState>WI</EventState><EventZIPCode>53154</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>10</EventCode></TrackDetail><TrackDetail><EventTime>3:22 pm</EventTime><EventDate>March 6, 2015</EventDate><Event>Picked up by Request</Event><EventCity>MADISON</EventCity><EventState>WI</EventState><EventZIPCode>53717</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>03</EventCode></TrackDetail><TrackDetail><EventTime>2:45 pm</EventTime><EventDate>March 6, 2015</EventDate><Event>Shipping Label Created</Event><EventCity>MADISON</EventCity><EventState>WI</EventState><EventZIPCode>53717</EventZIPCode><EventCountry /><FirmName /><Name /><AuthorizedAgent>false</AuthorizedAgent><EventCode>GX</EventCode></TrackDetail></TrackInfo></TrackResponse>
  XML
  my ($err, $data);
  $usps->track('9400115901396094290000', sub { (undef, $err, $data) = @_ });
  ok ! $err, 'no error';
  my $expect = {
    service => 'USPS First-Class Package Service',
    destination => {
      city => 'YORKTOWN',
      state => 'VA',
      postal_code => '23693',
      country => '',
      address1 => '',
      address2 => '',
    },
    status => {
      description => 'Your item was delivered in or at the mailbox at 1:44 pm on March 9, 2015 in YORKTOWN, VA 23693.',
      delivered => 1,
      date => '03/09/15',
    },
    weight => '',
    human_url => 'https://tools.usps.com/go/TrackConfirmAction?tLabels=9400115901396094290000',
  };
  is_deeply $data, $expect, 'correct parsed response';
};

done_testing;

