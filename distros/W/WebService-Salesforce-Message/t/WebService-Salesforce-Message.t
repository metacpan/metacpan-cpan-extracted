#/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 20;

BEGIN {
    use_ok( 'WebService::Salesforce::Message' );
    can_ok( 'WebService::Salesforce::Message',
        ( qw( ack new organization_id action_id session_id enterprise_url partner_url notifications ) ) );

    use_ok( 'WebService::Salesforce::Message::Notification' );
    can_ok(
        'WebService::Salesforce::Message::Notification',
        ( qw( new get attrs object_type sobject id ) )
    );
}

my $xml = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
 <soapenv:Body>
  <notifications xmlns="http://soap.sforce.com/2005/09/outbound">
   <OrganizationId>00De0000000pmu1EAA</OrganizationId>
   <ActionId>04ke0000000Cb2DAAS</ActionId>
   <SessionId>00De0000000pmu1!AQsAQJ6TzpySaKROMNTwKzcOluY5SsZ0rFz9nhA3ktEIly2om86AQtWIbEaakQ9x1lTKNohBaUhDaz2ZD3RSUDCWAGuvJbS0</SessionId>
   <EnterpriseUrl>https://cs15.salesforce.com/services/Soap/c/29.0/00De0000000pmu1</EnterpriseUrl>
   <PartnerUrl>https://cs15.salesforce.com/services/Soap/u/29.0/00De0000000pmu1</PartnerUrl>
   <Notification>
    <Id>04le0000004lnFFAAY</Id>
    <sObject xsi:type="sf:State_Province__c" xmlns:sf="urn:sobject.enterprise.soap.sforce.com">
     <sf:Id>a29e0000000K4P0AAK</sf:Id>
     <sf:Abbrev__c>AR</sf:Abbrev__c>
     <sf:Country__c>a28e00000002hMtAAI</sf:Country__c>
     <sf:Name>Arkansas</sf:Name>
    </sObject>
   </Notification>
   <Notification>
    <Id>04le0000004lnFFAAZ</Id>
    <sObject xsi:type="sf:State_Province__c" xmlns:sf="urn:sobject.enterprise.soap.sforce.com">
     <sf:Id>a29e0000000Jz3m</sf:Id>
     <sf:Abbrev__c>CA</sf:Abbrev__c>
     <sf:Country__c>a28e00000002hMtAAI</sf:Country__c>
     <sf:Name>California</sf:Name>
    </sObject>
   </Notification>
  </notifications>
 </soapenv:Body>
</soapenv:Envelope>
XML

my $msg = WebService::Salesforce::Message->new( xml => $xml );

isa_ok( $msg, 'WebService::Salesforce::Message' );
cmp_ok( $msg->organization_id, 'eq', '00De0000000pmu1EAA' );
cmp_ok( $msg->action_id,       'eq', '04ke0000000Cb2DAAS' );
cmp_ok( $msg->session_id, 'eq',
    '00De0000000pmu1!AQsAQJ6TzpySaKROMNTwKzcOluY5SsZ0rFz9nhA3ktEIly2om86AQtWIbEaakQ9x1lTKNohBaUhDaz2ZD3RSUDCWAGuvJbS0'
);
cmp_ok( $msg->enterprise_url, 'eq',
    'https://cs15.salesforce.com/services/Soap/c/29.0/00De0000000pmu1' );

cmp_ok( $msg->partner_url, 'eq',
    'https://cs15.salesforce.com/services/Soap/u/29.0/00De0000000pmu1' );

like( $msg->ack, qr/xml/, 'check xml ack' );

my $notifications = $msg->notifications;
cmp_ok( scalar( @{$notifications} ), '==', 2 );

my $notification = $notifications->[0];
isa_ok( $notification, 'WebService::Salesforce::Message::Notification' );

cmp_ok( $notification->id,          'eq', '04le0000004lnFFAAY' );
cmp_ok( $notification->object_type, 'eq', 'State_Province__c' );
is_deeply( $notification->attrs, [qw( Id Abbrev__c Country__c Name )] );
cmp_ok( $notification->get( 'Id' ),         'eq', 'a29e0000000K4P0AAK' );
cmp_ok( $notification->get( 'Abbrev__c' ),  'eq', 'AR' );
cmp_ok( $notification->get( 'Country__c' ), 'eq', 'a28e00000002hMtAAI' );
cmp_ok( $notification->get( 'Name' ),       'eq', 'Arkansas' );

