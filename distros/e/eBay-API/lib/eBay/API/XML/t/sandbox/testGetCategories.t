#! /usr/bin/perl -w
use strict;
use warnings;
use Test::More qw (no_plan);
use Data::Dumper;

print "Test GetCategories call.\n";
use eBay::API::XML::Call::GetCategories;
use eBay::APIRequest;
use ROW::Constants;
use ROW::ConvertNewToOld::ConvertGetCategories;

my $categorycall = new eBay::API::XML::Call::GetCategories;
can_ok($categorycall, 'setCategoryParent');
can_ok($categorycall, 'setCategorySiteID');
can_ok($categorycall, 'setLevelLimit');
can_ok($categorycall, 'setDetailLevel');
$categorycall->setCategoryParent(36279);
$categorycall->setCategorySiteID(0);
$categorycall->setLevelLimit(3);
$categorycall->setDetailLevel('ReturnAll');
#print "request: " . $categorycall->getRequestRawXml() . "\n";
$categorycall->execute();

#print $categorycall->getApiCallName() . ":\n";
#print $categorycall->getResponseRawXml() . "\n";
is($categorycall->getResponseAck(), 'Success', 'Successful response received.');
ok($categorycall->getCategoryCount() > 0, 'Categories found.');
my $newresponseobject = ROW::ConvertNewToOld::ConvertGetCategories::convert($categorycall);

#open LOG, ">newresponse.dump";
#$categorycall->setLogFileHandle(\*LOG);
#$categorycall->dumpObject($newresponseobject);
#close(LOG);

# set up for old style call

$ENV{ROW_API_ENABLE} = 1;
$ENV{API_TRANSPORT} = $ENV{EBAY_API_XML_TRANSPORT};
$ENV{API_DEV_ID} = $ENV{EBAY_API_DEV_ID};
$ENV{API_APP_ID} = $ENV{EBAY_API_APP_ID};
$ENV{API_CERT_ID} = $ENV{EBAY_API_CERT_ID};

$eBay::APIRequest::DevName = $ENV{API_DEV_ID};
$eBay::APIRequest::AppName = $ENV{API_APP_ID};
$eBay::APIRequest::CertName = $ENV{API_CERT_ID};
$eBay::APIRequest::Transport = $ENV{API_TRANSPORT};

my $fh = eBay::APIRequest->new(
			       Verb => 'GetCategories',
			       RequestUserId => $ENV{EBAY_API_USER_NAME},
			       RequestPassword =>  $ENV{EBAY_API_USER_PASSWORD},
			       SiteId => 0,
			       LevelLimit => 3,
			       CategoryParent => '36279',
			       ErrorLevel => API_ERROR_LEVEL,
			       ErrorLanguage => 0,
			       DetailLevel => 1,
			      );

$fh->execute();

my $oldresponseobject = $fh->get_results();

#open LOG, ">oldresponse.dump";
#$categorycall->setLogFileHandle(\*LOG);
#$categorycall->dumpObject($oldresponseobject);
#close(LOG);

ok($newresponseobject->{Version} == $oldresponseobject->{Version}, "Compare Version.");
ok($newresponseobject->{CategoryCount} == $oldresponseobject->{CategoryCount}, "Compare CategoryCount.");
ok($newresponseobject->{Category}[0]->{CategoryId} == $oldresponseobject->{Category}[0]->{CategoryId},
   "Compare CategoryId.");
ok($newresponseobject->{Category}[0]->{CategoryName} eq $oldresponseobject->{Category}[0]->{CategoryName},
   "Compare CategoryName.");
