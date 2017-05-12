#!/usr/bin/perl

###################################################
##                                               ##
## VKontakte serverside manager                  ##
##                                               ##
## Marat Shaymardanov,   LeonMedia LLC, 2013     ##
## info@leonmedia.ru     http://leonmedia.ru     ##
##                                               ##
## http://vk.com/do.more                         ##
##                                               ##
###################################################

use VK;

my $security_code = 1234; # last 4 digits of your phone registered to account

# login to post to our own wall
my $vk = VK->new('vkaccount@email.com', 'mypassword', undef, $security_code);

# next init sample is for group's wall posting (uncomment)
# my $vk = VK->new('vkaccount@email.com', 'mypassword', "/mygroupaddress", $security_code);

print $vk->wallPost(
	message         => "Hello World!", # post message
	#to_id           => 1234456, # userid/wallid where we are going to post, or void to post to own wall/group-wall

	link            => "http://code.google.com/p/vkontakte-non-api-manager",	# link
	link_title      => "This is the title of the link popup", # link popup description
	link_desc       => "This is the content of link popup", # link popup description
	
	signed          => '', # 1/0 - signs post if 
	note_title      => '',

	photo           => "sample.jpg",	
	album           => "This is the new album",
	album_desc      => "This is description of a new album",
	album_view      => 0, # 0-all, 1-friends, 2-friends&friends, 3-me
	album_comments  => 0,	# 0-all, 1-friends, 2-friends&friends, 3-me
)?'Succeeded':'Failed';
