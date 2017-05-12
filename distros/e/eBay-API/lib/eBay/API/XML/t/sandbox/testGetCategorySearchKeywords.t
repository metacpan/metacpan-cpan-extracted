#! /usr/bin/perl -w
use strict;
use warnings;
use Test::More qw (no_plan);
use Data::Dumper;
use eBay::BaseApi;
print "Test GetCategorySearchKeywords call.\n";
$ENV{SITE_ID_AUSTRALIA}=15;
$ENV{SITE_ID_AUSTRIA}=16;
$ENV{SITE_ID_BELGIUMDUTCH}=123;
$ENV{SITE_ID_BELGIUMFRENCH}=23;
$ENV{SITE_ID_CANADA}=2;
$ENV{SITE_ID_CHINA}=223;
$ENV{SITE_ID_CORE}=0;
$ENV{SITE_ID_CZECHREPUBLIC}=197;
$ENV{SITE_ID_DENMARK}=198;
$ENV{SITE_ID_EBAYMOTORS}=100;
$ENV{SITE_ID_FINLAND}=199;
$ENV{SITE_ID_FRANCE}=71;
$ENV{SITE_ID_GERMANY}=77;
$ENV{SITE_ID_GREECE}=200;
$ENV{SITE_ID_HONGKONG}=201;
$ENV{SITE_ID_HUNGARY}=202;
$ENV{SITE_ID_INDIA}=203;
$ENV{SITE_ID_INDONESIA}=204;
$ENV{SITE_ID_IRELAND}=205;
$ENV{SITE_ID_ISRAEL}=206;
$ENV{SITE_ID_ITALY}=101;
$ENV{SITE_ID_JAPAN}=224;
$ENV{SITE_ID_JAPANEBAY}=104;
$ENV{SITE_ID_MALAYSIA}=207;
$ENV{SITE_ID_NETHERLANDS}=146;
$ENV{SITE_ID_NEWZEALAND}=208;
$ENV{SITE_ID_NORWAY}=209;
$ENV{SITE_ID_PHILIPPINES}=211;
$ENV{SITE_ID_POLAND}=212;
$ENV{SITE_ID_PORTUGAL}=213;
$ENV{SITE_ID_PUERTORICO}=214;
$ENV{SITE_ID_QUEBEC}=210;
$ENV{SITE_ID_ROWDEV01}=216;
$ENV{SITE_ID_ROWDEV02}=216;
$ENV{SITE_ID_RUSSIA}=215;
$ENV{SITE_ID_SINGAPORE}=216;
$ENV{SITE_ID_SOUTHAFRICA}=217;
$ENV{SITE_ID_SPAIN}=186;
$ENV{SITE_ID_SWEDEN}=218;
$ENV{SITE_ID_SWITZERLAND}=193;
$ENV{SITE_ID_TAIWAN}=196;
$ENV{SITE_ID_THAILAND}=219;
$ENV{SITE_ID_UK}=3;
$ENV{SITE_ID_UNKNOWN}=-1;
$ENV{SITE_ID_US}=1;
$ENV{SITE_ID_US1}=221;
$ENV{SITE_ID_US2}=222;
$ENV{SITE_ID_VIETNAM}=220;

use_ok('ROW::Constants');
use_ok('eBay::Data');
use_ok('ROW::EbayAPIRequestSOAP');
use_ok('ROW::ConvertNewToOld::ConvertGetCategorySearchKeywords');
use_ok('eBay::API::XML::Call::GetCategorySearchKeywords');
my $site_id = 201;
my $call = new eBay::API::XML::Call::GetCategorySearchKeywords({site_id => 201});
$call->setSiteID(eBay::Data::get_site_code_type($site_id));
$call->execute();
my $keywords = 
  ROW::ConvertNewToOld::ConvertGetCategorySearchKeywords::convert($call);

open LOG, ">new.dump";
$call->setLogFileHandle(\*LOG);
$call->dumpObject($keywords);
close(LOG);

# old style call

#$ENV{API_ANON_USER_NAME} = 'row_jstillwellanon';
#$ENV{API_ANON_PASSWD} = '3rd2twentyone';
#$ENV{EBAY_API_SOAP_TRANSPORT} = 'http://eazye.qa.ebay.com:80/wsapi';
#$ENV{EBAY_API_SOAP_URI}='urn:ebay:apis:eBLBaseComponents';

my $APIobj = ROW::EbayAPIRequestSOAP->new();

$APIobj->verb('GetCategorySearchKeywords');
$APIobj->siteID($site_id);
$APIobj->username($ENV{API_ANON_USER_NAME});
$APIobj->password($ENV{API_ANON_PASSWD});
$APIobj->addMethodArgs(
		       {
			SiteID => eBay::Data::get_site_code_type($site_id),
		       }
		      );
my $rv = $APIobj->execute();
my $api_response_root = $APIobj->get_results();

$keywords = undef();
$keywords = $api_response_root->{CategorySearchDetails}->{CategorySearchKeyword};

open LOG, ">old.dump";
$call->setLogFileHandle(\*LOG);
$call->dumpObject($keywords);
close(LOG);

my $diff = `diff new.dump old.dump`;
ok(!$diff, "No differences in old versus new raw response.");

print ("\nTHIS TEST MAY NOT WORK ON LOCAL PCs!\n");
#cleanup
sleep(5);
unlink('new.dump');
unlink('old.dump');
