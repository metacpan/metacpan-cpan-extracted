#!/usr/bin/perl

use strict;
use warnings;

use WebService::DataDog;
use Try::Tiny;

my $datadog = WebService::DataDog->new(
	api_key         => 'YOUR_API_KEY',
	application_key => 'YOUR_APPLICATION_KEY',
	verbose         => 1,
);


my $search = $datadog->build('Search');

try
{
	$search->retrieve(
		term => 'test',
	);
}
catch
{
	print "FAILED - Couldn't search because: @_ \n";
};


try                                                                             
{                                                                               
  $search->retrieve(                                                            
    term  => 'test',                                                             
		facet => 'hosts',
  );                                                                            
}                                                                               
catch                                                                           
{                                                                               
  print "FAILED - Couldn't search because: @_ \n";                              
};
