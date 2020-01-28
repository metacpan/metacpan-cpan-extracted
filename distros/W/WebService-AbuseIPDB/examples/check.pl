#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: check.pl
#
#        USAGE: ./check.pl IPADDR [ IPADDR ... ]
#
#  DESCRIPTION: Check one or more ip addresses and print results
#
# REQUIREMENTS: WebService::AbuseIPDB
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      CREATED: 12/08/19 11:40:00
#===============================================================================

use strict;
use warnings;
use WebService::AbuseIPDB;

my $ipdb = WebService::AbuseIPDB->new (key => $ENV{AIPDB_KEY});
my @fields = (
	{method => 'ip',               name => 'IP Address'},
	{method => 'ipv',              name => 'IP Version'},
	{method => 'public',           name => 'Public Address?'},
	{method => 'whitelisted',      name => 'Whitelisted?'},
	{method => 'score',            name => 'Abuse Score (%)'},
	{method => 'cc',               name => 'Country'},
	{method => 'domain',           name => 'Domain'},
	{method => 'isp',              name => 'ISP'},
	{method => 'usage_type',       name => 'Used For'},
	{method => 'report_count',     name => 'Total Reports'},
	{method => 'reporter_count',   name => 'Total Reporters'},
	{method => 'last_report_time', name => 'Most Recently At'},
);

for my $ip (@ARGV) {
	my $res = $ipdb->check (ip => $ip, max_age => 180);    #, verbose => 999);
	print "\n";
	for my $f (@fields) {
		my $meth = $f->{method};
		printf "%18s: %s\n", $f->{name}, $res->$meth // '-';
	}
}
