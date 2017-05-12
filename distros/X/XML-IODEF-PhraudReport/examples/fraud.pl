#!/usr/bin/perl -w

use lib './lib';
use XML::IODEF::PhraudReport;
my $root = 'IncidentIncidentDataEventDataAdditionalDataPhraudReport';

my $r = XML::IODEF::PhraudReport->new();
$r->add($root.'FraudType','phishemail');
$r->add($root.'OriginatingSensorOriginatingSensorType','Human');

$r->add('IncidentIncidentDataEventDataSystemNodeAddresscategory','e-mail');
$r->add('IncidentIncidentDataEventDataSystemNodeAddressaddress','phishingaddress@rockndomain.org');
$r->add($root.'EmailRecordEmailCount',1);
$r->add($root.'EmailRecordMessage','Pretend this is a really long email with headers and all');
warn $r->out();