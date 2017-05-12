############################################################
#
#   $Id: Dilbert.pm,v 1.19 2006/01/12 22:30:11 nicolaw Exp $
#   WWW::Dilbert - Retrieve Dilbert of the day comic strip images
#
#   Copyright 2004,2005,2006 Nicola Worthington
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
############################################################

package WWW::Dilbert;
# vim:ts=4:sw=4:tw=78

use strict;
use Exporter;
use LWP::UserAgent qw();
use HTTP::Request qw();
use Carp qw(carp croak);
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 1.19 || sprintf('%d.%02d', q$Revision$ =~ /(\d+)/g);
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(&get_strip &strip_url &mirror_strip);
%EXPORT_TAGS = ( all => \@EXPORT_OK );

sub mirror_strip {
	my $filename = shift;
	my $url = shift || strip_url();

	my $blob = get_strip($url);
	return undef if !defined($blob);

	if ((!defined($filename) || !length($filename)) && defined($url)) {
		($filename = $url) =~ s#.*/##;
	}
	my $ext = _image_format($blob);
	$filename =~ s/(\.(jpe?g|gif))?$/.$ext/i;

	open(FH,">$filename") ||
		croak "Unable to open file handle FH for file '$filename': $!";
	binmode FH;
	print FH $blob;
	close(FH) ||
		carp "Unable to close file handle FH for file '$filename': $!";
	return $filename;
}

sub get_strip {
	my $url = shift || strip_url() || '';

	if ($url =~ /^(?:dilbert)?(\d+(\.(jpg|gif))?)$/i) {
		$url = "http://www.dilbert.com/comics/dilbert/".
					"archive/images/dilbert$1";
		$url .= '.gif' unless $url =~ /\.(jpg|gif)$/i;
	}

	my $ua = _new_agent();
	my $req = HTTP::Request->new(GET => $url); 
	$req->referer('http://www.dilbert.com/');
	my $response = $ua->request($req);

	my $status;
	unless ($response->is_success) {
		$status = $response->status_line;
		unless ($url =~ s/\.gif$/.jpg/i) { $url =~ s/\.jpg$/.gif/i; }
		$req = HTTP::Request->new(GET => $url); 
		$req->referer('http://www.dilbert.com/');
		$response = $ua->request($req);
	}

	if ($response->is_success) {
		unless (_image_format($response->content)) {
			carp('Unrecognised image format') if $^W;
			return undef;
		}
		return $response->content;
	} elsif ($^W) {
		carp($status);
	}
	return undef;
}

sub strip_url {
	my $ua = _new_agent();

	my $response = $ua->get('http://www.dilbert.com');
	if ($response->is_success) {
		my $html = $response->content;
		if ($html =~ m#<img\s+src="((?:https?://[\w\.:\d\/]+)?
					/comics/dilbert/archive/images/dilbert.+?)"#imsx) {
			my $url = $1;
			$url = "http://www.dilbert.com$1" unless $url =~ /^https?:\/\//i;
			return $url;
		}

	} elsif ($^W) {
		carp($response->status_line);
	}

	return undef;
}

sub _image_format {
	local $_ = shift || '';
	return 'gif' if /^GIF8[79]a/;
	return 'jpg' if /^\xFF\xD8/;
	return 'png' if /^\x89PNG\x0d\x0a\x1a\x0a/;
	return undef;
}

sub _new_agent {
	my $ua = LWP::UserAgent->new(
			agent => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.8) '.
					'Gecko/20050718 Firefox/1.0.4 (Debian package 1.0.4-2sarge1)',
			timeout => 20
		);
	$ua->env_proxy;
	$ua->max_size(1024*250);
	return $ua;
}

1;

=pod

=head1 NAME

WWW::Dilbert - Retrieve Dilbert of the day comic strip images

=head1 SYNOPSIS

 use WWW::Dilbert qw(get_strip mirror_strip strip_url);
 
 # Get the URL for todays strip
 my $image_url = strip_url();
 
 # Get todays strip
 my $image_blob = get_strip();
 
 # Get a specific strip by specifying the ID
 my $ethical_garbage_man = get_strip("2666040051128");
 
 # Write todays strip to local_filename.gif on disk
 my $filename_written = mirror_strip("local_filename.gif");
 
 # Write a specific strip to mystrip.gif on disk
 my $filename_written = mirror_strip("mystrip.gif","2666040051128");

=head1 DESCRIPTION

This module will download the latest Dilbert of the Day cartoon strip
from the Dilbert website and return a binary blob of the image, or
write it to disk. 

=head1 EXPORTS

The following functions can be exported with the C<:all> export
tag, or individually as is show in the above example.

=head2 strip_url

 # Return todays strip URL
 my $url = strip_url();

 # Return the strip matching ID 200512287225
 $url = strip_url("200512287225");

Accepts an optional argument strip ID argument.

=head2 get_strip

 # Get todays comic strip image
 my $image_blob = get_strip();

Accepts an optional argument strip ID argument.

=head2 mirror_strip

 # Write todays comic strip to "mystrip.gif" on disk
 my $filename_written = mirror_strip("mystrip.gif");

Accepts two optional arguments. The first is the filename that
the comic strip should be written to on disk. The second specifies
the strip ID.

Returns the name of the file that was written to disk.

=head1 VERSION

$Id: Dilbert.pm,v 1.19 2006/01/12 22:30:11 nicolaw Exp $

=head1 AUTHOR

Nicola Worthington <nicolaw@cpan.org>

L<http://perlgirl.org.uk>

=head1 COPYRIGHT

Copyright 2004,2005,2006 Nicola Worthington.

This software is licensed under The Apache Software License, Version 2.0.

L<http://www.apache.org/licenses/LICENSE-2.0>

=cut



