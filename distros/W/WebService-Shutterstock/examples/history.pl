#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use WebService::Shutterstock;
use Data::Dumper;

my($api_user, $api_key, $username, $password, %subscription_filter, $help);
GetOptions(
	"api-user=s"     => \$api_user,
	"api-key=s"      => \$api_key,
	"username=s"     => \$username,
	"password=s"     => \$password,
	"help"           => \$help
);
usage(-1) if grep { !defined($_) } ($api_user, $api_key, $username, $password);

usage() if $help;

my $shutterstock = WebService::Shutterstock->new( api_username => $api_user, api_key => $api_key );
my $user = $shutterstock->auth( username => $username, password => $password );

my $history = $user->downloads();
print Dumper( $history );

# or
my $image_id = 2457122;
print "redownloadable state of image_id $image_id\n";
$history = $user->downloads( image_id => $image_id, field  => "redownloadable_state"  ); # these two must be used together
print Dumper( $history );

# or
print "page 1 of dl history\n";
$history = $user->downloads( page_number => 1 );    # that's page 2
print Dumper( $history );



sub usage {
	my $error = shift;
	print <<"_USAGE_";
usage: $0 --api-user justme --api-key abc123 --username my_user --password my_password 
_USAGE_
	exit $error || 0;
}

