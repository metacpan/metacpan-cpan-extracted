#!/usr/bin/perl

# vmd - download user's tracks from vk.com
# (c) Genaev Misha 2012-2015 | http://genaev.com/vmd
# Please visit my home page for geting full version of the script

use strict;
use warnings;
use VK::App 0.06;
use MP3::Tag;
use File::Copy;

my $login = 'email or mobile phone';
my $password = 'password';

my $api_id = '2998239'; # The api_id of my app. You can create your own. See 'perldoc VK::App' for details.

# Authorizing by cookie file
my $vk = VK::App->new(
#	login      => $login,
#	password   => $password,
	api_id     => $api_id,
	cookie_file => "/home/user/.vmd.cookie", # Name of the file to restore cookies from and save cookies to
	format => 'Perl', # JSON, XML or Perl. Perl by default
	scope => 'friends,photos,audio,video,wall,groups,messages,offline', # Set application access rights
);

print $vk->uid,"\n"; # print UID of the current user

my $user = $vk->request('getProfiles',{uid=>'genaev',fields=>'uid'}); # Get user id by name
my $uid = $user->{response}->[0]->{uid};
my $tracks = $vk->request('audio.get',{uid=>$uid}); # Get a list of tracks by uid
my $ua = $vk->ua; # Get LWP::UserAgent object
$|=1;
my $i = 1;
my $n = scalar @{$tracks->{response}}; # number of tracks
foreach my $track (@{$tracks->{response}}) {
	my $url = $track->{url}; # track url
	my $mp3_filename = $track->{aid}.'.mp3';
	print "$i/$n Download $url";
	my $req = HTTP::Request->new(GET => $url);
	my $res = $ua->request($req, $mp3_filename);
	if ($res->is_success) {
		my $mp3 = MP3::Tag->new($mp3_filename);
		my $new_mp3_filename = $mp3->artist.'-'.$mp3->title.'-'.$mp3_filename;
		move($mp3_filename, $new_mp3_filename);
		print " - saved as '$new_mp3_filename'\n";
	}
	else {
		print " - ", $res->status_line, "\n";
	}
	$i++;
}
