package WebService::Jamendo;

################################################
# Jamendo
################################################

use strict;
use warnings;
use diagnostics;
use HTTP::Request;
require LWP::UserAgent;
our $VERSION = qw('0.01');

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# public
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# constructor
sub new{
	my $class = shift;

	my $oUserAgent = LWP::UserAgent->new;
 	$oUserAgent->timeout(10);
 	$oUserAgent->env_proxy;
	$oUserAgent->agent(qq(jamendo.pm));

	my $oHTTPRequest = HTTP::Request->new;
	$oHTTPRequest->method(qq(GET));

	my $sBaseUrl = 	qq(http://api.jamendo.com/get2/);
	my $sURLEncode =

	my $self = {'oUserAgent' => $oUserAgent,
		    'oHTTPRequest' => $oHTTPRequest,
		    'sBaseUrl' => $sBaseUrl
	};

	bless $self, $class;
	return $self;
}

### getSomeInfos ###

# getArtistInfos
sub getArtistInfos{

	my $self = (defined $_[0] ? $_[0] : warn "jamendo not constructed?");
	my %hArgs = ((defined $_[1] && keys%{$_[1]}) ? %{$_[1]} : warn "no arguments hash for jamendo::getArtistInfos() given");

	my %hParams = ();
	$hParams{'sFields'} = "artist_id+artist_name+artist_url+artist_image+artist_mbgid+location_country+location_state+location_city";
	$hParams{'sUnit'} = "artist";
	$hParams{'sFormat'} = (defined $hArgs{'format'} ? $hArgs{'format'} : "json");
	$hParams{'hArgs'} = __getParams(\%hArgs);

	return __getDataSet($self, \%hParams);
}

# getUserInfos
sub getUserInfos{

	my $self = (defined $_[0] ? $_[0] : warn "jamendo not constructed?");
	my %hArgs = ((defined $_[1] && keys%{$_[1]}) ? %{$_[1]} : warn "no arguments hash for jamendo::getUserInfos() given");

	my %hParams = ();
	$hParams{'sFields'} = "user_id+user_name+user_idstr+user_url+user_image+user_mbgid+location_country+location_state+location_city";
	$hParams{'sUnit'} = "user";
	$hParams{'sFormat'} = (defined $hArgs{'format'} ? $hArgs{'format'} : "json");
	$hParams{'hArgs'} = __getParams(\%hArgs);

	return __getDataSet($self, \%hParams);
}

# getAlbumInfos
sub getAlbumInfos{

	my $self = (defined $_[0] ? $_[0] : warn "jamendo not constructed?");
	my %hArgs = ((defined $_[1] && keys%{$_[1]}) ? %{$_[1]} : warn "no arguments hash for jamendo::getAlbumInfos() given");

	my %hParams = ();
	$hParams{'sFields'} = "artist_id+album_id+album_name+album_url+album_genre+album_mbgid+album_image+album_duration";
	$hParams{'sUnit'} = "album";
	$hParams{'sFormat'} = (defined $hArgs{'format'} ? $hArgs{'format'} : "json");
	$hParams{'hArgs'} = __getParams(\%hArgs);

	return __getDataSet($self, \%hParams);
}

# getTrackInfos
sub getTrackInfos{

	my $self = (defined $_[0] ? $_[0] : warn "jamendo not constructed?");
	my %hArgs = ((defined $_[1] && keys%{$_[1]}) ? %{$_[1]} : warn "no arguments hash for jamendo::getAlbumInfos() given");

	my %hParams = ();
	$hParams{'sFields'} = "album_id+track_id+track_name+track_filename+track_numalbum+track_duration";
	$hParams{'sUnit'} = "track";
	$hParams{'sFormat'} = (defined $hArgs{'format'} ? $hArgs{'format'} : "json");
	$hParams{'hArgs'} = __getParams(\%hArgs);

	return __getDataSet($self, \%hParams);
}

### getSomethingFrom ###

# getAlbumTracks
sub getAlbumTracks{

	my $self = (defined $_[0] ? $_[0] : warn "jamendo not constructed?");
	my %hArgs = ((defined $_[1] && keys%{$_[1]}) ? %{$_[1]} : warn "no arguments hash for jamendo::getAlbumTracks() given");

	my %hParams = ();
	$hParams{'sFields'} = "artist_id+album_id+album_name+album_url+album_genre+album_mbgid+album_image+album_duration+track_id+track_name+track_filename+track_numalbum+track_duration";
	$hParams{'sUnit'} = "album";
	$hParams{'sFormat'} = (defined $hArgs{'format'} ? $hArgs{'format'} : "json");
	$hParams{'hArgs'} = __getParams(\%hArgs);

	return __getDataSet($self, \%hParams);
}

# getUserFriends
sub getUserFriends{

	my $self = (defined $_[0] ? $_[0] : warn "jamendo not constructed?");
	my %hArgs = ((defined $_[1] && keys%{$_[1]}) ? %{$_[1]} : warn "no arguments hash for jamendo::getUserFriends() given");

	my %hParams = ();
	$hParams{'sFields'} = "user_id+user_name+user_idstr+user_url+user_image+user_mbgid+location_country+location_state+location_city";
	$hParams{'sUnit'} = "user";
	$hParams{'sFormat'} = (defined $hArgs{'format'} ? $hArgs{'format'} : "json");
	$hParams{'hArgs'} = __getParams(\%hArgs);
	$hParams{'sFunction'} = "user_user2_friend";

	return __getDataSet($self, \%hParams);
}

# getUserAlbums
sub getUserAlbums{

	my $self = (defined $_[0] ? $_[0] : warn "jamendo not constructed?");
	my %hArgs = ((defined $_[1] && keys%{$_[1]}) ? %{$_[1]} : warn "no arguments hash for jamendo::getUserFriends() given");

	my %hParams = ();
	$hParams{'sFields'} = "user_id+user_idstr+artist_id+album_id+album_name+album_url+album_genre+album_mbgid+album_image+album_duration";
	$hParams{'sUnit'} = "album";
	$hParams{'sFormat'} = (defined $hArgs{'format'} ? $hArgs{'format'} : "json");
	$hParams{'hArgs'} = __getParams(\%hArgs);
	$hParams{'sFunction'} = "album_user_starred";

	return __getDataSet($self, \%hParams);
}

# getUserTracks
sub getUserTracks{

	my $self = (defined $_[0] ? $_[0] : warn "jamendo not constructed?");
	my %hArgs = ((defined $_[1] && keys%{$_[1]}) ? %{$_[1]} : warn "no arguments hash for jamendo::getUserFriends() given");

	my %hParams = ();
	$hParams{'sFields'} = "user_id+user_idstr+album_id+track_id+track_name+track_filename+track_numalbum+track_duration";
	$hParams{'sUnit'} = "track";
	$hParams{'sFormat'} = (defined $hArgs{'format'} ? $hArgs{'format'} : "json");
	$hParams{'hArgs'} = __getParams(\%hArgs);
	$hParams{'sFunction'} = "tracks_user_starred";

	return __getDataSet($self, \%hParams);
}

# getTrackStreamingFile
sub getTrackStreamingFile{

	my $self = (defined $_[0] ? $_[0] : warn "jamendo not constructed?");
	my %hArgs = ((defined $_[1] && keys%{$_[1]}) ? %{$_[1]} : warn "no arguments hash for jamendo::getTrackStreamingFile() given");

	my %hParams = ();
	$hParams{'sFields'} = "stream";
	$hParams{'sUnit'} = "track";
	$hParams{'sFormat'} = (defined $hArgs{'format'} ? $hArgs{'format'} : "plain");
	$hParams{'hArgs'} = __getParams(\%hArgs);
	$hParams{'hArgs'}{'streamencoding'} = (defined $hParams{'hArgs'}{'streamencoding'} ? $hParams{'hArgs'}{'streamencoding'} : "ogg2");
	$hParams{'sFunction'} = "redirect";

	return __getDataSet($self, \%hParams);
}

### getSomeSearch ###

# getArtistSearch
sub getArtistSearch{

	my $self = (defined $_[0] ? $_[0] : warn "jamendo not constructed?");
	my %hArgs = ((defined $_[1] && keys%{$_[1]}) ? %{$_[1]} : warn "no arguments hash for jamendo::getArtistSearch() given");

	my $sReturn = getUserInfos($self, \%hArgs);
	return $sReturn;
}

# getAlbumSearch
sub getAlbumSearch{

	my $self = (defined $_[0] ? $_[0] : warn "jamendo not constructed?");
	my %hArgs = ((defined $_[1] && keys%{$_[1]}) ? %{$_[1]} : warn "no arguments hash for jamendo::getAlbumSearch() given");

	my $sReturn = getAlbumInfos($self, \%hArgs);
	return $sReturn;
}

# getTrackSearch
sub getTrackSearch{

	my $self = (defined $_[0] ? $_[0] : warn "jamendo not constructed?");
	my %hArgs = ((defined $_[1] && keys%{$_[1]}) ? %{$_[1]} : warn "no arguments hash for jamendo::getTrackSearch() given");

	my $sReturn = getTrackInfos($self, \%hArgs);
	return $sReturn;
}

# getUserSearch
sub getUserSearch{

	my $self = (defined $_[0] ? $_[0] : warn "jamendo not constructed?");
	my %hArgs = ((defined $_[1] && keys%{$_[1]}) ? %{$_[1]} : warn "no arguments hash for jamendo::getUserSearch() given");

	my $sReturn = getUserInfos($self, \%hArgs);
	return $sReturn;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# private
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# __getParams
sub __getParams{

	my %hArgs = ((defined $_[0] && keys%{$_[0]}) ? %{$_[0]} : warn "no arguments hash for jamendo::__getParams() given");

	my %hParams = ();
	foreach my $sArg(keys%hArgs){
		if(defined $hArgs{$sArg} && $sArg ne "format"){
			$hParams{$sArg} = $hArgs{$sArg};
		}
	}

	return \%hParams;
}

# __getDataSet
sub __getDataSet{

	my $self = (defined $_[0] ? $_[0] : warn "jamendo not constructed?");
	my %hArgs = ((defined $_[1] && keys%{$_[1]}) ? %{$_[1]} : warn "no arguments hash for jamendo::__getDataSet() given");

	my $sFields = (defined $hArgs{'sFields'} ? $hArgs{'sFields'} : warn "no URL fields for jamendo::__getDataSet() given");
	my $sUnit = (defined $hArgs{'sUnit'} ? $hArgs{'sUnit'} : warn "no URL unit for jamenod::__getDataSet() given");
	my $sFormat = (defined $hArgs{'sFormat'} ? $hArgs{'sFormat'} : warn "no URL format for jamenod::__getDataSet() given");
	my $sFunction = (defined $hArgs{'sFunction'} ? "/".$hArgs{'sFunction'}."/" : "");

	my $sArgs;
	if(defined $hArgs{'hArgs'}){

		foreach my $sArg(keys%{$hArgs{'hArgs'}}){

			my $sParam = $sArg;
			$sParam =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;

			my $sArgument = $hArgs{'hArgs'}{$sArg};
			$sArgument =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;

			$sArgs .= "$sParam=".$sArgument."&";
		}
	}

	my $sRequestUrl = "$self->{'sBaseUrl'}$sFields/$sUnit/$sFormat$sFunction?$sArgs";
	my $oRequest = $self->{'oHTTPRequest'};
	$oRequest->uri($sRequestUrl);
	my $oResponse = $self->{'oUserAgent'}->request($oRequest);
	return $oResponse->content;
}

1;

__END__

=head1 NAME

WebService::Jamendo - Perl API for jamendo.get2

=head1 VERSION

This document refers to jamendo version 0.01

=head1 DESCRIPTION

WebService::Jamendo provides some methods for getting informations about Jamendo artist, albums, tracks etc.
It will return the data in the formats plain, JSON or JSON pretty.

=head1 NOTICE

I tried to get the best out of the jamendo.get2 API but some of the results just makes me wonder ;-)
Please visit the the offical documentation of the jamendo.get2 API for more informations.

=head1 QUICK START

To get the JSON formatted data of a jamendo artist by his artist_id just follow these simply steps:

	# Step 0
	use WebService::Jamendo;

	# Step 1
	my $jamendo = WebService::Jamendo->new;

	# Step 2										
	my %hParams = ('artist_id' => '22');

	# Step 3							
	my $sArtistString = $jamendo->getArtistInfos(\%hParams);

	# Step 4		
	print "$sArtistString\n";											

=head1 JAMENDO METHODS

In version 0.01 jamendo provides the following public methods

	new()
	getAlbumInfos()
	getAlbumSearch()
	getAlbumTracks()
	getArtistInfos()
	getArtistSearch()
	getTrackInfos()
	getTrackSearch()
	getTrackStreamingFile()
	getUserAlbums()
	getUserFriends()
	getUserInfos()
	getUserSearch()
	getUserTracks()

In version 0.01 jamendo provides the following private methods

	__getDataSet()
	__getParams()

=head2 new()

Create a new jamendo object

	use WebService::Jamendo;
	my $jamendo = WebService::Jamendo->new;

=head2 getAlbumInfos()

Get informations for an album

This method returns:

	artist_id
	album_id
	album_name
	album_url
	album_genre
	album_mbgid
	album_image
	album_duration

foreach matching album.
Default return format is json.

This method expects at least one of these parameters:

	artist_id
	album_id
	album_name
	album_url
	album_genre
	album_mbgid
	album_image
	album_duration

Optional parameters may be:

	format
	n
	order

Example:

	# Return informations about the album with id = 50 in plain text (default is json)
	my %hParams = ('album_id' => '50', 'format' => 'plain');
	my $sAlbumString = $jamendo->getAlbumInfos(\%hParams);
	print "$sAlbumString\n";

=head2 getAlbumSearch()

Search for Albums

This method returns:

	artist_id
	album_id
	album_name
	album_url
	album_genre
	album_mbgid
	album_image
	album_duration

foreach found album.
Default return format is json.

This method expects at least one of these parameters:

	searchquery

Optional parameters may be:

	artist_id
	album_id
	album_name
	album_url
	album_genre
	album_mbgid
	album_image
	album_duration
	format
	n
	order

Example:

	# Return informations about 5 albums with love inside in jsonpretty format (default is json), order descending
	my %hParams = ('searchquery' => 'love', 'n' => '5', 'order' => 'desc', 'format' => 'jsonpretty');
	my $sAlbumString = $jamendo->getAlbumSearch(\%hParams);
	print "$sAlbumSting\n";

=head2 getAlbumTracks()

Get the tracks of an album

This method returns:

	artist_id
	album_id
	album_name
	album_url
	album_genre
	album_mbgid
	album_image
	album_duration
	track_id
	track_name
	track_filename
	track_numalbum
	track_duration

foreach track on the albums.
Default return format is json.

This method expects at least one of these parameters:

	artist_id
	album_id
	album_name
	album_url
	album_genre
	album_mbgid
	album_image
	album_duration
	track_id
	track_name
	track_filename
	track_numalbum
	track_duration

Optional parameters may be:

	format
	n
	order

Example:

	# Get informations about the tracks from the album with image url http://imgjam.com/albums/1114/covers/1.100.jpg in json pretty format (default is json)
	my %hParams = ('album_image' => 'http://imgjam.com/albums/1114/covers/1.100.jpg', 'format' => 'jsonpretty');
	my $sTrackString = jamendo->getAlbumTracks(\%hParams);
	print "$sTrackString\n";

=head2 getArtistInfos()

Get informations about artists

This method returns:

	artist_id
	artist_name
	artist_url
	artist_image
	artist_mbgid
	location_country
	location_state
	location_city

foreach matching artist.
Default return format is json.

This method expects at least one of these parameters:

	artist_id
	artist_name
	artist_url
	artist_image
	artist_mbgid
	location_country
	location_state
	location_city

Optional parameters may be:

	format
	n
	order

Example:

	# Get infos about artists living in Hamburg, Germany in JSON format
	my %hParams = ('location_city' => 'hamburg', 'location_country' => 'DEU');
	my $sArtistString = $jamendo->getArtistInfos(\%hParams);
	print "$sArtistString\n";

=head2 getArtistSearch()

Search for artists

This method returns:

	artist_id
	artist_name
	artist_url
	artist_image
	artist_mbgid
	location_country
	location_state
	location_city

foreach found artist.
Default return format is json.

This method expects at least one of these parameters:

	searchquery

Optional parameters may be:

	artist_id
	artist_id
	artist_name
	artist_url
	artist_image
	artist_mbgid
	location_country
	location_state
	location_city
	format
	n
	order

Example:

	# Search for artists named felixaltona living in Hamburg
	my %hParams = ('searchquery' => 'felixaltona', 'location_state' => 'HH');
	my $sArtistString = $jamendo->getArtistSearch(\%hParams);
	print "$sArtistString\n";

=head2 getTrackInfos()

Get information about tracks

This method returns:

	album_id
	track_id
	track_name
	track_filename
	track_numalbum
	track_duration

foreach matching track.
Default return format is json.

This method expects at least one of these parameters:

	album_id
	track_id
	track_name
	track_filename
	track_numalbum
	track_duration

Optional parameters may be:

	format
	n
	order

Example:

	# Get informations about all tracks from the album with id = 50
	my %hParams = ('album_id' => '50');
	my $sTrackString = $jamendo->getTrackInfos(\%hParams);
	print "$sTrackString\n";

=head2 getTrackSearch()

Search for tracks

This method returns:

	album_id
	track_id
	track_name
	track_filename
	track_numalbum
	track_duration

foreach found track.
Default return format is json.

This method expects at least one of these parameters:

	searchquery

Optional parameters may be:

	album_id
	track_id
	track_name
	track_filename
	track_numalbum
	track_duration
	format
	n
	order

Example:

	# Search for tracks with love inside
	my %hParams = ('searchquery' => 'love');
	my $sTrackString = $jamendo->getTrackSearch(\%hParams);
	print "$sTrackString\n";

=head2 getTrackStreamingFile()

This method returns the URL to the streaming media of tracks.

This method returns:

	stream

Default return format is plain.
Default return streamencoding is ogg2.

This method expects at least one of these parameters:

	track_id
	track_name
	track_filename

Optional parameters may be:

	streamencoding
	format
	n
	order

Example:

	# get the the streaming url for the track "Broken Hearts & Credit Cards" in 128k mp3 (default is ogg2)
	my %hParams = ('track_name' => 'Broken Hearts & Credit Cards', 'streamencoding' => 'mp31');
	my $sTrackURL = $jamendo->getTrackStreamingFile(\%hParams);
	print "$sTrackURL\n";

=head2 getUserAlbums()

Get the albums a user has starred

This method returns:

	user_id
	user_idstr
	artist_id
	album_id
	album_name
	album_url
	album_genre
	album_mbgid
	album_image
	album_duration

Default return format is json.

This method expects at least one of these parameters:

	user_id
	user_idstr

Optional parameters may be:

	artist_id
	album_id
	album_name
	album_url
	album_genre
	album_mbgid
	album_image
	album_duration
	format
	n
	order

Example:

	# get the albums user sylvinus has starred
	my %hParams = ('user_idstr' => 'sylvinus');
	my $sAlbumString = $jamendo->getUserAlbums(\%hParams);
	print "$sAlbumString\n";

=head2 getUserFriends()

Get the friends of a user (hopefully he got some)
Please notice that the user we search for here uses the user2_* fields, the user_* fields returning belong to his friends

This method returns:

	user_id
	user_name
	user_idstr
	user_url
	user_image
	user_mbgid
	location_country
	location_state
	location_city

Default return format is json.

This method expects at least one of these parameters:

	user2_id
	user2_idstr

Optional parameters may be:

	user_name
	user_idstr
	user_url
	user_image
	user_mbgid
	location_country
	location_state
	location_city
	format
	n
	order

Example:

	# get all the friends of user sylvinus
	my %hParams = ('user2_idstr' => 'sylvinus');
	my $sFriendsString = $jamendo->getUserFriends(\%hParams);
	print "$sFriendsString\n";

=head2 getUserInfo()

Get informations about users

This method returns:

	user_id
	user_name
	user_idstr
	user_url
	user_image
	user_mbgid
	location_country
	location_state
	location_city

foreach matching user.
Default return format is json.

This method expects at least one of these parameters:

	user_id
	user_name
	user_idstr
	user_url
	user_image
	user_mbgid
	location_country
	location_state
	location_city

Optional parameters may be:

	format
	n
	order

Example:

	# get informations about user in Hamburg, Germany in json pretty format (default is json)
	my %hParams = ('location_city' => 'hamburg', 'location_country' => 'DEU', 'format' => 'jsonpretty');
	my $sUserString = $jamendo->getUserInfos(\%hParams);
	print "$sUserString\n";

=head2 getUserSearch()

Search for user

This method returns:

	user_id
	user_name
	user_idstr
	user_url
	user_image
	user_mbgid
	location_country
	location_state
	location_city

foreach found user.
Default return format is json.

This method expects at least one of these parameters:

	searchquery

Optional parameters may be:

	user_id
	user_name
	user_idstr
	user_url
	user_image
	user_mbgid
	location_country
	location_state
	location_city
	format
	n
	order

Example:

	# search for the user sylvinus
	my %hParams = ('searchquery' => 'sylvinus');
	my $sUserString = $jamendo->getUserSearch(\%hParams);
	print "$sUserString\n";

=head2 getUserTracks()

Get the tracks a user has starred.
I dont know if this works, I didnt find a user who has starred tracks.
At least it doesnt return any error messages but this method may be useless.

This method should return:

	user_id
	user_idstr
	album_id
	track_id
	track_name
	track_filename
	track_numalbum
	track_duration

foreach track.
Default return format is json.

This method should expect at least one of these parameters:

	user_id
	user_idstr

Optional parameters may be:

	album_id
	track_id
	track_name
	track_filename
	track_numalbum
	track_duration
	format
	n
	order

Example:

	# get the starred tracks of user sylvinus
	my %hParams = ('user_idstr' => 'sylvinus');
	my $sTrackString = $jamendo->getUserTracks(\%hParams);
	print "$sTrackString\n";

=head1 BUGS

If you find bugs please report me via email.

=head1 TODO

Tags, most rated etc.
If you have suggestions please tell me via email.

=head1 SEE ALSO

HTTP::Request http://search.cpan.org/~gaas/libwww-perl-5.828/lib/HTTP/Request.pm

LWP::UserAgent http://search.cpan.org/~gaas/libwww-perl-5.828/lib/LWP/UserAgent.pm

Jamendo web2API documentation http://developer.jamendo.com/de/wiki/Musiclist2Api


=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty for the software, to the extent permitted by applicable law. Except when otherwise stated in writing the copyright holders and/or other parties provide the software "as is" without warranty of any kind, either expressed or implied, including, but not limited to, the implied warranties of merchantability and fitness for a particular purpose. The entire risk as to the quality and performance of the software is with you. Should the software prove defective, you assume the cost of all necessary servicing, repair, or correction.
In no event unless required by applicable law or agreed to in writing will any copyright holder, or any other party who may modify and/or redistribute the software as permitted by the above licence, be liable to you for damages, including any general, special, incidental, or consequential damages arising out of the use or inability to use the software (including but not limited to loss of data or data being rendered inaccurate or losses sustained by you or third parties or a failure of the software to operate with any other software), even if such holder or other party has been advised of the possibility of such damages.

=head1 AUTHOR

Christoph Glaß christoph.glass@gmail.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Christoph Glaß
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
