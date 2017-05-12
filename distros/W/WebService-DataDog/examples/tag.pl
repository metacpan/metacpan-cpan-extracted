#!/usr/bin/perl

use strict;
use warnings;

use WebService::DataDog;
use Try::Tiny;
use Data::Dumper;

my $datadog = WebService::DataDog->new(
	api_key         => 'YOUR_API_KEY',
	application_key => 'YOUR_APP_KEY',
#	verbose         => 1,
);

my $tag = $datadog->build('Tag');
my $tag_list;

try
{
	# Get mapping of tags to hosts
	$tag_list = $tag->retrieve_all();
}
catch
{
	print "FAILED - Couldn't retrieve tags because: @_ \n";
};

print "Tag list:\n", Dumper($tag_list);


my $one_host = 'host.example.com';

# Tag list for single host
my $host_tags = $tag->retrieve( id => $one_host );
print "Tags for host >$one_host<: ", Dumper($host_tags);

# Add new tags to existing tags, for specified host
$tag->add(
	host => $one_host,
	tags => [ 'additional_tag', 'yet_another_tag' ],
);

# Update tags for specified host, replacing existing tags
$tag->update(
	host => $one_host,
	tags => [ 'only_one_tag_now' ],
);

# Remove any tags from the specified host
$tag->delete(
	host => $one_host,
);
