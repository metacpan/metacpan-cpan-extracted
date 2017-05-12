#!/usr/bin/perl

# basic test of VoiceXML::Client using the VXML at 
# http://voicexml.psychogenic.com/vocp.cgi
# Copyright (C) 2008, Pat Deegan Psychogenic.com
	
	use VoiceXML::Client;
	
	use strict;

	# debug defaults to 0 but it's here so you know and may easily change it... 1 is debug, > 1 is verbose
	$VoiceXML::Client::Debug = 0;

	# basic info for VoiceXML source
	my $sourceSite = 'voicexml.psychogenic.com';
	my $startURL = '/vocp.cgi';
	
	
	# using dummy device here, to get started
	my $telephonyDevice = VoiceXML::Client::Device::Dummy->new();
	$telephonyDevice->connect();
	
	# our workhorse: the user agent
	my $vxmlUserAgent = VoiceXML::Client::UserAgent->new($sourceSite);
	
	# go for it:
	$vxmlUserAgent->runApplication($startURL, $telephonyDevice);
	
	# done. Insert gleeful hand wringing here..
	
