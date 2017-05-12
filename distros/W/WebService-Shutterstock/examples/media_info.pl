#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use WebService::Shutterstock;
use JSON;

my($api_user, $api_key, $image_id, $video_id, $help);
GetOptions(
	"api-user=s"     => \$api_user,
	"api-key=s"      => \$api_key,
	"image=i"        => \$image_id,
	"video=i"        => \$video_id,
	"help"           => \$help
);
usage(-1) if grep { !defined($_) } ($api_user, $api_key);
usage(-1) if !$video_id && !$image_id;

usage() if $help;

my $shutterstock = WebService::Shutterstock->new( api_username => $api_user, api_key => $api_key );
use Data::Dumper;
my $media;
my %data;
if($image_id){
	$media = $shutterstock->image($image_id);
} else {
	$media = $shutterstock->video($video_id);
}
if(!$media){
	print(($image_id ? "Image" : "Video") . " ID $image_id does not exist!\n");
	exit;
}
%data = %$media;

delete $data{client};
print JSON->new->utf8->canonical->pretty->encode(\%data);

sub usage {
	my $error = shift;
	print <<"_USAGE_";
usage: $0 --api-user justme --api-key abc123 --video <id>
 - or: $0 --api-user justme --api-key abc123 --image <id>
_USAGE_
	exit $error || 0;
}
