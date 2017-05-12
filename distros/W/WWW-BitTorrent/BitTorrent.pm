package WWW::BitTorrent;

=pod

=head1 NAME

WWW::BitTorrent - Search and Download .torrent(s) files from BitTorrents boards.

=head1 SYNOPSIS
		
	# Creates WWW::BitTorrent Object.
	my $client = WWW::BitTorrent->new( 'site' => $site, 'user' => $user, 'pass' => $pass);

	# Check for errors.
	if ($client->{STAT} == 0) {
		print "ERROR: " . $client->{ERROR}."\n";
		exit;
	}

	# return all rows (from page 1) and prints it
	my @page = $client->browse(1);
		die("Error occured calling browse or page is empty\n") if ($#page == -1);
	
	foreach my $row (@page) {
		print "Row: " . $row->{name} . "- id: " . $row->{id} ."\n";
	}
	
	# Search for a row
	@page = $client->search('DiAMOND');
		die("No Results.\n") if ($#page == -1);

	my $download_row;

	foreach my $row (@page) {
		print "Row: " . $row->{name} . "- id: " . $row->{id} ."\n";
		$download_row = $row if ($row->{name} =~ /my.favorite.movie/);
	}

	# download .torrent file
	$client->download_torrent($download_row, '/tmp/' . $download_row->{id} . '.torrent');


=head1 DESCRIPTION

"WWW::BitTorrent" provides an object interface to using two
BitTorrent based boards: "TBSource", "BrokenStone" (tell me about more).
This boards are being update every day with files.
This module allows you to search for files in a couple of ways.

NOTE: any use of this module that is illegal is out of my responsibilty.

This module requires B<LWP::UserAgent> and B<LWP::Simple>.

=head1 INTERFACE

=cut

use strict;

use vars qw/$VERSION/;
$VERSION = "0.01";

use LWP::UserAgent;
use LWP::Simple;

# fast create for the user agent object with the ident cookie
sub _agent {
	my $self = shift;

	# creates LWP::UserAgent object
	my $agent = LWP::UserAgent->new;
	$agent->timeout(10);
	
	if ($self->{COOKIE}) {
		  $agent->default_header('Cookie' => $self->{COOKIE});
	}
	
	$agent->agent('Mozilla/5.0'); # fake agent
	$agent->default_header('Keep-Alive' => 300);
	$agent->default_header('Connection' => 'keep-alive');

	$self->{AGENT} = $agent;

return $self;
}

sub _parse {
	my $self = shift;
	my $content = shift;

	my @page;
	# parse the current page and create a hash with the information
	while ($content =~  /<td align=left><a href=\"details\.php\?id=(\d+)&amp;hit=1\"><b>([a-zA-Z0-9-_.]+)<\/b><\/a>/g) {
	my $row;
		$row->{name} = $2;
		$row->{id} = $1;
		$row->{torrent} = $self->{SITE} . "/download.php/" . $1 ."/" . $2 . ".torrent";

		push(@page, $row);
	}

	return @page;
}

=pod

	new( [ARGS] )

		Used to login the Board with the username and password
		of the board (all arguments are required) and create a new Object of 
		the WWW::BitTorrent module. 

		Arguments:

		site- The BitTorrents board URL address.
		user- the username for login the board. 
		pass- the password for login the board. 

		NOTES: 	Returns a blessed object anyways.
			object->{STAT}: 0 - for error (object->{ERROR} - http code)
					1 - for success

=cut

sub new {
my $class = shift;
my %args = @_;
my $self;

	# inserts args into class
	foreach (keys %args) {
		$self->{uc($_)} = $args{$_};
	}

	my $agent = LWP::UserAgent->new;
	$agent->timeout(10);

	$agent->agent('Mozilla/5.0'); # fake agent
	$agent->default_header('Keep-Alive' => 300);
	$agent->default_header('Connection' => 'keep-alive');

	# Create and send the request
	my $req = HTTP::Request->new( POST => $self->{SITE}."/".'takelogin.php');
	$req->content_type('application/x-www-form-urlencoded');
	$req->content('username='.$self->{USER}.'&password='.$self->{PASS});
	my $res = $agent->request($req);

	if ($res->status_line =~ RC_FOUND || $res->status_line =~ RC_OK) {

	my $cookies = $res->header("Set-Cookie");
	
	# parse cookies
	$self->{uid} = $1 if ($cookies =~ /uid=(\d+);/g);
	$self->{pass} = $1 if ($cookies =~ /pass=(\w+);/g);
	$self->{punbb_cookie} = $1 if ($cookies =~ /punbb_cookie=([a-zA-Z0-9%]+);/g);

	
	# cookie for ident
	$self->{COOKIE} = 	'punbb_cookie=' . $self->{punbb_cookie} .'; ' .
				'uid=' . $self->{uid} . '; ' . 
				'pass=' . $self->{pass};

	delete $self->{PUNBB_COOKIE};
	delete $self->{uid};
	delete $self->{pass};

	$self->{STAT} = 1;
	} 
	else {
	$self->{STAT} = 0; # error occured
	$self->{ERROR} = $res->status_line; # the error: status number and text
	}

	return bless $self, $class;
		
}

=pod

	browse( $page_number ) 

		Returns a list(array) of all rows(ref) from the the '$page_number' page.
		C<page_number>: number between 0 (first page) and max number of pages.

		Arguments:
	
		page_number- the number of the page you want the rows from.

=cut

sub browse {
	my $self = shift;
	my $num = shift;
	
	my $url = $self->{SITE};

	if ($num == 0) { $url .= "/browse.php"; } else { $url .= "/browse.php?page=" . $num; }

	# create new agent with cookie into $self
	$self->_agent();

	# create the request
	my $req = HTTP::Request->new(GET => $url);
	my $res = $self->{AGENT}->request($req);

	# status ok (200)
	if ($res->status_line =~ RC_OK) {
		return $self->_parse($res->content);
	}
	
	return 0;
}

=pod

	search( $keyword )

		This method do the same as browse just by the search option at the board.

=cut

sub search {
	my $self = shift;
	my $keyword = shift;

	$keyword =~ s/ /+/;

	my $url = $self->{SITE} . "/browse.php?search=".$keyword;

	$self->_agent;
	my $req = HTTP::Request->new(GET => $url);
	my $res = $self->{AGENT}->request($req);

	if ($res->status_line =~ RC_OK) {
		return $self->_parse($res->content);
	}
	
	return 0;
}

=pod

	download_torrent($row, $path)

		Download the .torrent file using the LWP::Simple module.

=cut

sub download_torrent {
	my $self = shift;
	my $row = shift;
	my $path = shift;

	# using the LWP::Simple function to download the .torrent file
	mirror($row->{torrent}, $path);

	return $self;
}

=pod

=head1 AUTHOR

This module was written by
Amit Sides C<< <amit.sides@gmail.com> >>

=head1 Copyright

Copyright (c) 2006 Amit Sides. All rights reserved. 

=head1 LICENSE

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
