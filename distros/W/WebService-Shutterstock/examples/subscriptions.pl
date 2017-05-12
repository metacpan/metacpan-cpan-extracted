#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use WebService::Shutterstock;

my($api_user, $api_key, $username, $password, %subscription_filter, $help);
GetOptions(
	"api-user=s"     => \$api_user,
	"api-key=s"      => \$api_key,
	"username=s"     => \$username,
	"password=s"     => \$password,
	"subscription=s" => \%subscription_filter,
	"help"           => \$help
);
usage(-1) if grep { !defined($_) } ($api_user, $api_key, $username, $password);

usage() if $help;

my $shutterstock = WebService::Shutterstock->new( api_username => $api_user, api_key => $api_key );
my $user = $shutterstock->auth( username => $username, password => $password );

my @active = $user->find_subscriptions(%subscription_filter, is_active => 1);
if (@active) {
	print "ACTIVE SUBSCRIPTIONS\n";
	print "====================\n";
	foreach my $subscription (@active) {
		print_subscription_details($subscription);
	}
}

my @expired = $user->find_subscriptions(%subscription_filter, is_expired => 1);
if (@expired) {
	print "EXPIRED SUBSCRIPTIONS\n";
	print "=====================\n";
	foreach my $subscription (@expired) {
		print_subscription_details($subscription);
	}
}

if(!@expired && !@active){
	print "No subscriptions found!\n";
	exit -1;
}

sub usage {
	my $error = shift;
	print <<"_USAGE_";
usage: $0 --api-user justme --api-key abc123 --username my_user --password my_password
_USAGE_
	exit $error || 0;
}

sub print_subscription_details {
	my $subscription = shift;
	printf "%s (ID: %d)\n", $subscription->description, $subscription->id;
	my $allotment = $subscription->current_allotment;
	if ( $allotment->{downloads_limit} ) {
		printf(
			" - Downloads Remaining: %d out of %d (expiring %s)\n",
			$allotment->{downloads_left},
			$allotment->{downloads_limit},
			$allotment->{end_datetime}
		);
	} else {
		printf( " - Access expires: %s\n", $subscription->expiration_time );
	}
	printf " - Sizes available: %s\n", join ', ', map { "$_->{short_name} ($_->{text_id})" } values %{ $subscription->sizes };
	print "\n";
}
