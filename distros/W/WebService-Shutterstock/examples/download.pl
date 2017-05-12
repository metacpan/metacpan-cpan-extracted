#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use WebService::Shutterstock;

my($api_user, $api_key, $username, $password, %subscription_filter, $image_id, $video_id, $size, $file, $directory, %metadata, $help);
GetOptions(
	"api-user=s"     => \$api_user,
	"api-key=s"      => \$api_key,
	"username=s"     => \$username,
	"password=s"     => \$password,
	"subscription=s" => \%subscription_filter,
	"image=i"        => \$image_id,
	"video=i"        => \$video_id,
	"size=s"         => \$size,
	"metadata=s"     => \%metadata,
	"file=s"         => \$file,
	"directory=s"    => \$directory,
	"help"           => \$help
);
usage(-1) if grep { !defined($_) } ($api_user, $api_key, $username, $password, $size);
usage(-1) if !$image_id && !$video_id;
usage(-1, 'Please specify either an image or a video to download (not both)') if $image_id && $video_id;
usage(-1) if !$file && !$directory;

my $type = $image_id ? 'image' : 'video';

usage() if $help;

my $shutterstock = WebService::Shutterstock->new( api_username => $api_user, api_key => $api_key );
my $user = $shutterstock->auth( username => $username, password => $password );

my $license_method = "license_$type";

my %license_args = ( size => $size );

if($type eq 'image'){
	$license_args{image_id} = $image_id;
} else {
	$license_args{video_id} = $video_id;
}

$license_args{metadata} = \%metadata                if keys %metadata;
$license_args{subscription} = \%subscription_filter if keys %subscription_filter;

my $licensed_media = $user->$license_method( %license_args );

my $saved;
if ($directory) {
	$saved = $licensed_media->download( directory => $directory );
} elsif ( $file eq '-' ) {
	binmode(STDOUT);
	print $licensed_media->download;
} elsif ($file) {
	$saved = $licensed_media->download( file => $file );
}

if($saved){
	print "Saved $type to $saved\n";
}

sub usage {
	my $exit_code = shift;
	my $error = shift;
	print "$error\n" if $error;
	print <<"_USAGE_";
usage (for images): $0 --api-user justme --api-key abc123 --username my_user --password my_password --image 59915404 --size medium --directory .
   or (for videos): $0 --api-user justme --api-key abc123 --username my_user --password my_password --video 11234 --size lowres --directory .
_USAGE_
	exit $exit_code || 0;
}
