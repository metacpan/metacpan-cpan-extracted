#!/usr/bin/perl
#use strict;
use WWW::BitTorrent;

my ($user, $pass) = ('username', 'password');

my $site = 'http://www.BitTorrentBoard.com';

my $client = WWW::BitTorrent->new( 'site' => $site, 'user' => $user, 'pass' => $pass);

if ($client->{STAT} == 0) {
 	print "ERROR: " . $client->{ERROR}."\n";
	exit;
}

my @page;

#@page = $client->browse(1);

@page = $client->search('keyword');

die("Error occured calling browse or page is empty\n") if ($#page == -1);

my $download;

foreach my $row (@page) {

	if ($row->{name} =~ /S01/) { 
		$download = $row; 
	}

	print "Rls: " . $row->{name} . "- id: " . $row->{id} ."\n";
}

$client->download_torrent($download, "~/file.torrent");

