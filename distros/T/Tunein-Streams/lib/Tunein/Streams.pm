=head1 NAME

Tunein::Streams - Fetch actual raw streamable URLs from radio-station websites on Tunein.com

=head1 AUTHOR

This module is Copyright (C) 2017 by

Jim Turner, C<< <turnerjw784 at yahoo.com> >>
		
Email: turnerjw784@yahoo.com

All rights reserved.

You may distribute this module under the terms of either the GNU General 
Public License or the Artistic License, as specified in the Perl README 
file.

=head1 SYNOPSIS

	use strict;

	use Tunein::Streams;

	my $station = new Tunein::Streams(<url>);

	die "Invalid URL or no streams found!\n"  unless ($station);

	my @streams = $station->get();

	my $first = $station->get();

	my $best = $station->getBest();

	print "Best stream URL=".$best->{'Url'}."\n";

	my $besturl = $station->getBest('Url');

	my $stationTitle = $station->getStationTitle();
	
	print "Best stream URL=$besturl, Title=$stationTitle\n";

	my @allfields = $station->validFields();

	for (my $i=0; $i<$station->count(); $i++) {

		foreach my $field (@allfields) {

			print "--$field: ".$streams[$i]->{$field}."\n";

		}

	}
	
=head1 DESCRIPTION

Tunein::Streams accepts a valid radio station URL on http://tunein.com and
returns the urls and other information properties for the actual stream URLs 
available for that station.  The purpose is that one needs one of these URLs 
in order to have the option to stream the station in one's own choice of 
audio player software rather than using their web browser and accepting any / 
all flash, ads, javascript, cookies, trackers, web-bugs, and other crapware 
that can come with that method of playing.  The author uses his own custom 
all-purpose audio player called "fauxdacious" (his custom hacked version of 
the open-source "audacious" media player.  "fauxdacious" incorporates this 
module to decode and play tunein.com streams.

One or more streams can be returned for each station.  The available 
properties for each stream returned are normally:  Bandwidth, 
HasPlaylist (1|0), MediaType (ie. MP3, AAC, etc.), Reliability (1-100), 
StreamId (numeric), Type (ie. Live) and Url.

=head1 EXAMPLES

use strict;

	use Tunein::Streams;

	my $kluv = new Tunein::Streams('http://tunein.com/radio/987-KLUV-s33892/');

	die "Invalid URL or no streams found!\n"  unless ($kluv);

	my $besturl = $kluv->getBest('Url');

	my $beststream = $kluv->getBest();

	my @allfields = $kluv->validFields();

	foreach my $field (@allfields) {

		print "--$field: ".$beststream->{$field}."\n";

	}

This would print:

--Bandwidth: 64

--HasPlaylist: 0

--MediaType: Windows

--Reliability: 100

--StreamId: 75549037

--Type: Live

--Url: http://19273.live.streamtheworld.com/KLUVFM_SC

=head1 SUBROUTINES/METHODS

=over 4

=item B<new>(I<url>)

Accepts a tunein.com URL and creates and returns a new station object, or 
I<undef> if the URL is not a valid tunein station or no streams are found.

=item $station->B<get>(I<[property]>)

Returns either a scalar or array of either values or hash references with 
an element for each stream url found.  If I<property> is specified, then 
the item(s) returned are scalars containing that property's value, 
otherwise, the item(s) returned are hash references, each to a hash who's 
elements represent the names and values for each I<property> of the given 
stream.  If a scalar target is used, the first stream is returned, if an 
array target is used, all streams are returned.

=item $station->B<getBest>(I<[property]>)

Similar to B<get>() except it only returns a single stream representing 
the "best" stream found.  "best" is determined as the one with the best 
I<Bandwidth> with the best I<Reliability>, if more than one with the 
same best I<Bandwidth> value.  If I<[property]> is specified, only that 
property value is returned as a scalar.  Otherwise, a hash reference 
to all the properties for that stream is returned.

=item $station->B<count>()

Returns the number of streams found for the station.

=item $station->B<validFields>()

Returns an array containing all the valid property names found.  This 
list is normally:  (B<Bandwidth>, B<HasPlaylist>, B<MediaType>, B<Reliability>, 
B<StreamId>, B<Type>, B<Url>).  These can be used in the I<get> functions and 
as the keys in the hash references returned to fetch the corresponding 
property values.

=item $station->B<getStationID>()

Returns the station's Tunein ID, for eample, the station: 
'http://tunein.com/radio/987-KLUV-s33892/' would return "s33892".

=item $station->B<getStationTitle>()

Returns the station's title (description).  for eample, the station:
'http://tunein.com/radio/987-KLUV-s33892/' would return:
"KLUV - Dallas, TX - Listen Online".

=item $station->B<getIconURL>()

Returns the url for the station's "cover art" icon image.

=item $station->B<getImageURL>()

Returns the url for the station's Tunein site's banner image.

=back

=head1 KEYWORDS

tunein

=head1 DEPENDENCIES

LWP::Simple

=head1 BUGS

Please report any bugs or feature requests to C<bug-tunein-streams at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tunein-Streams>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tunein::Streams

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tunein-Streams>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tunein-Streams>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tunein-Streams>

=item * Search CPAN

L<http://search.cpan.org/dist/Tunein-Streams/>

=back

=head1 ACKNOWLEDGEMENTS

The idea for this module came from a Python script that does this same task named 
"getstream", but I wanted a Perl module that could be called from within another 
program!  I do not know the author of getstream.py.

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jim Turner.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

package Tunein::Streams;

use strict;
use warnings;
#use Carp qw(croak);
use LWP::Simple qw();
use vars qw(@ISA @EXPORT $VERSION);

our $VERSION = '1.11';

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(get getBest count validFields);
$Carp::Internal{ (__PACKAGE__) }++;

sub new
{
	my $class = shift;
	my $url = shift;
	my $attrs;

	my $self = {};

	return undef  unless ($url);

	#THIS IS A TWO-STEP FETCH.  WE FIRST FETCH THE HTML FOR THE STATION'S tunein.com WEBSITE, 
	#PARSE IT FOR 'StreamUrl":"<//partial-url>"', THEN, (STEP 2) APPEND "http:" TO IT AND FETCH 
	#THAT.  THE 2ND FETCH RETURNS A FILE VERY SIMILAR TO A PERL "Data::Dumper" FILE CONTAINING 
	#A HASH TREE COMPOSED OF AN ARRAY OF ONE OR MORE STREAM URLS ALONG WITH THEIR OTHER PROPERTIES.
	#WE THEN USE A FEW REGICES TO CONVERT IT TO A TRUE PERL-EVALABLE "Data::Dumper" STRING THAT 
	#WE CAN THEN EVAL INTO A PERL HASH, FROM WHICH OUR get() FUNCTIONS CAN RETURN THE DESIRED 
	#DATA!

	my $html = '';
	my $wait = 1;
	for (my $i=0; $i<=2; $i++) {  #WE TRY THIS FETCH 3 TIMES SINCE FOR SOME REASON, DOESN'T ALWAYS RETURN RESULTS 1ST TIME?!:
		$html = LWP::Simple::get($url);
		last  if ($html);
		sleep $wait;
		++$wait;
	}
	return undef  unless ($html);  #STEP 1 FAILED, INVALID STATION URL, PUNT!

	my (@streams, @streamHash, $s, $html2);
	$self->{'cnt'} = 0;
	$self->{'total'} = '0';
	$self->{'id'} = ($url =~ m#([\w\d]+)\/?$#) ? $1 : $url;
	$self->{'title'} = ($html =~ m#\<title\>(.+?)\<\/title\>#) ? $1 : '';
	$self->{'iconurl'} = ($html =~ m#\<meta\s+property\s*\=\s*\"og\:image\"\s+content\s*\=\"([^\"]+)#) ? $1 : '';
	$self->{'imageurl'} = ($html =~ m#\"hero\"\s+id=\s*\"imgSrc\"\s+style\=\"background\-image\:\s+url\(([^\)]+)\)#) ? $1 : '';
	while ($html =~ s/StreamUrl\"\:\s*\"([^\"]+)\"(\,\s*\"DirectStreams\"\:\s*\[([^\]]+)\])?//o) {  #FIND ONE (OR MORE) STREAM URLS:
		$s = $1;
		if ($2) {   #WE HAVE A DIRECT STREAM (EMBEDDED TREE), USE THAT:
			$html2 = $2;
			$html2 =~ s/^\,\s*\"Direct//io;
			$html2 = '{ "' . $html2 . ' }';
		} else {    #WE HAVE A STREAM URL, FETCH TREE FROM THERE:
			$s = 'http:' . $s  if ($s && $s !~ m#^\w+\:\/\/#o);
			$wait = 1;
			for (my $i=0; $i<=2; $i++) {  #WE TRY THIS FETCH 3 TIMES SINCE FOR SOME REASON, DOESN'T ALWAYS RETURN RESULTS 1ST TIME?!:
				$html2 = LWP::Simple::get($s);
				last  if ($html);
				sleep $wait;
				++$wait;
			}
		}
		$html2 =~ s/\:\s*true\b/\:1/gio;   #CONVERT "true" AND "false" STRING VALUES INTO 1 & 0 RESPECTIVELY.
		$html2 =~ s/\:\s*false\b/\:0/gio;
		$html2 =~ s/\"\s*\:/\" =\> /go;    #FIXUP TO MAKE A VALID EVAL-ABLE HASH TREE OUT OF IT:
		$html2 = "\$streamHash[$self->{'cnt'}] = " . $html2;
		no strict;
		eval $html2;   #EVAL EACH STREAM URL'S CONTENT INTO A PERL HASH REF.
		use strict;
		$self->{'total'} += scalar @{$streamHash[$self->{'cnt'}]->{'Streams'}};
		++$self->{'cnt'};   #NUMBER OF StreamUrl's FOUND (NOT SAME AS # OF STREAMS!)
	}
	$self->{'streams'} = \@streamHash;
	return undef  unless ($self->{'cnt'});   #STEP 2 FAILED - NO PLAYABLE STREAMS FOUND, PUNT!

	#SAVE WHAT PROPERTY NAMES WE HAVE (FOR $station->validFields()):
	
	@{$self->{fields}} = ();
	foreach my $field (sort keys %{${$self->{'streams'}}[0]->{'Streams'}[0]}) {
		push @{$self->{fields}}, $field;
	}

	bless $self, $class;   #BLESS IT!

	return $self;
}

sub get
{
	my $self = shift;
	my $field = shift || 0;

	my @streams = ();
	my $subcnt;
	if ($field) {  #USER SUPPLIED A PROPERTY NAME, FETCH ONLY THAT PROPERTY, (ie. "Url"):
		return ${$self->{'streams'}}[0]->{'Streams'}[0]->{$field}  unless (wantarray);  #USER ONLY WANTS 1ST STREAM.
		for (my $i=0; $i<$self->{'cnt'}; $i++) {
			no strict;
			$subcnt = scalar @{${$self->{'streams'}}[$i]->{'Streams'}};
			for (my $j=0; $j<$subcnt; $j++) {
				push @streams, ${$self->{'streams'}}[$i]->{'Streams'}[$j]->{$field};
			}
		}
	} else {       #NO PROPERTY NAME, RETURN A HASH-REF TO ALL THE PROPERTIES:
		return ${$self->{'streams'}}[0]->{'Streams'}[0]  unless (wantarray);  #USER ONLY WANTS 1ST STREAM.
		for (my $i=0; $i<$self->{'cnt'}; $i++) {
			no strict;
			$subcnt = scalar @{${$self->{'streams'}}[$i]->{'Streams'}};
			for (my $j=0; $j<$subcnt; $j++) {
				push @streams, ${$self->{'streams'}}[$i]->{'Streams'}[$j];
			}
		}
	}
	return @streams;   #USER WANTS ALL OF 'EM.
}

sub getBest   #LIKE GET, BUT ONLY RETURN THE SINGLE ONE W/BEST BANDWIDTH AND RELIABILITY:
{
	my $self = shift;
	my $field = shift || 0;

	my $bestStream;
	my $subcnt;
	my $bestReliableBandwidth = 0;
	my $ReliableBandwidth;
	for (my $i=0; $i<$self->{'cnt'}; $i++) {
		no strict;
		$subcnt = scalar @{${$self->{'streams'}}[$i]->{'Streams'}};
		for (my $j=0; $j<$subcnt; $j++) {
			$ReliableBandwidth = (${$self->{'streams'}}[$i]->{'Streams'}[$j]->{'Bandwidth'} * 1000)
					+ ${$self->{'streams'}}[$i]->{'Streams'}[$j]->{'Reliability'};
			if ($ReliableBandwidth > $bestReliableBandwidth) {
				$bestStream = $field ? ${$self->{'streams'}}[$i]->{'Streams'}[$j]->{$field}
						: ${$self->{'streams'}}[$i]->{'Streams'}[$j];
				$bestReliableBandwidth = $ReliableBandwidth;
			}
		}
	}
	return $bestStream;
}

sub count
{
	my $self = shift;
	return $self->{'total'};  #TOTAL NUMBER OF PLAYABLE STREAM URLS FOUND.
}

sub validFields
{
	my $self = shift;
	return @{$self->{'fields'}};  #LIST OF ALL VALID PROPERTY NAME FIELDS.
}

sub getStationID
{
	my $self = shift;
	return $self->{'id'};  #URL TO THE STATION'S THUMBNAIL ICON, IF ANY.
}

sub getStationTitle
{
	my $self = shift;
	return $self->{'title'};  #URL TO THE STATION'S TITLE(DESCRIPTION), IF ANY.
}

sub getIconURL
{
	my $self = shift;
	return $self->{'iconurl'};  #URL TO THE STATION'S THUMBNAIL ICON, IF ANY.
}

sub getImageURL
{
	my $self = shift;
	return $self->{'imageurl'};  #URL TO THE STATION'S BANNER IMAGE, IF ANY.
}

1
