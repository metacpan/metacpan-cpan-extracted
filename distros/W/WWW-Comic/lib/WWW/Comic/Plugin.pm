############################################################
#
#   $Id: Plugin.pm,v 1.7 2006/01/10 15:49:32 nicolaw Exp $
#   WWW::Comic::Plugin - Subclassable plugin module for WWW::Comic 
#
#   Copyright 2006 Nicola Worthington
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

package WWW::Comic::Plugin;
# vim:ts=4:sw=4:tw=78

use strict;
use LWP::UserAgent qw();
use HTTP::Request qw();
use Carp qw(carp croak confess);

use constant DEBUG => $ENV{DEBUG} ? 1 : 0;
use vars qw($VERSION);
$VERSION = sprintf('%d.%02d', q$Revision: 1.7 $ =~ /(\d+)/g);


#################################
# Public methods

sub comics {
	my $self = shift;

	# Look at instance specific first
	if (exists $self->{comics}) {
		if (ref($self->{comics}) eq 'ARRAY') {
			return @{$self->{comics}};
		} elsif (ref($self->{comics}) eq 'HASH') {
			return keys(%{$self->{comics}});
		}
	}

	# Then look package wide
	my @comics = ();
	eval {
		my %comics = eval('%'.ref($self).'::COMICS');
		push @comics, keys(%comics);
	};
	eval {
		push @comics, eval('@'.ref($self).'::COMICS');
	};

	return @comics;
}

sub strip_url {
	my $self = shift;
	confess "I do not know how to get the URL for this comic";
	return undef;
}

sub get_strip {
	my $self = shift;
	my %param = @_;

	$param{url} ||= $self->strip_url(%param);
	return undef unless $param{url} =~ /^https?:\/\/[a-z0-9\-\.]+.*/i;

	(my $referer = $param{url}) =~ s/[\?\&]//;
	$referer =~ s#/[^/]*$#/#;

	my $ua = $self->_new_agent();
	my $req = HTTP::Request->new(GET => $param{url});
	$req->referer($referer);
	my $response = $ua->request($req);

	if ($response->is_success) {
		unless ($self->_image_format($response->content)) {
			carp('Unrecognised image format') if $^W;
			return undef;
		}
		return $response->content;
	} elsif ($^W) {
		carp $response->status_line;
	}

	return undef;
}

sub mirror_strip {
	my $self = shift;
	my %param = @_;

	$param{url} ||= $self->strip_url(%param);
	my $blob = $self->get_strip(%param);
	return undef if !defined($blob);

	if ((!defined($param{filename}) || !length($param{filename}))
			&& defined($param{url})) {
		($param{filename} = $param{url}) =~ s#.*/##;
	}
	my $ext = $self->_image_format($blob);
	$param{filename} =~ s/(\.(jpe?g|gif|png))?$/.$ext/i;

	open(FH,">$param{filename}") ||
		croak "Unable to open file handle FH for file '$param{filename}': $!";
	binmode FH;
	print FH $blob;
	close(FH) ||
		carp "Unable to close file handle FH for file '$param{filename}': $!";

	return $param{filename};
}



#################################
# Private methods

sub _image_format {
	my $self = shift;
	local $_ = shift || '';
	return 'gif' if /^GIF8[79]a/;
	return 'jpg' if /^\xFF\xD8/;
	return 'png' if /^\x89PNG\x0d\x0a\x1a\x0a/;
	return undef;
}

sub _new_agent {
	my $self = shift;

	my @agents = (
			'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1).',
			'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.8) '.
			'Gecko/20050718 Firefox/1.0.4 (Debian package 1.0.4-2sarge1)',
			'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-GB; rv:1.7.5) '.
			'Gecko/20041110 Firefox/1.0',
			'Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) '.
			'AppleWebKit/125.5.5 (KHTML, like Gecko) Safari/125.12',
			'Mozilla/4.0 (compatible; MSIE 6.0; Windows 98)',
		);

	my $ua = LWP::UserAgent->new(
			agent => $agents[int(rand(@agents))],
			timeout => 20
		);
	$ua->env_proxy;
	$ua->max_size(1024*1024); # 1mb max limit

	return $ua;
}

sub TRACE {
	return unless DEBUG;
	carp(shift());
}

sub DUMP {
	return unless DEBUG;
	eval {
		require Data::Dumper;
		carp(shift().': '.Data::Dumper::Dumper(shift()));
	}
}


1;


=pod

=head1 NAME

WWW::Comic::Plugin - Plugin superclass for WWW::Comic

=head1 DESCRIPTION

This is a plugin superclass for WWW::Comic from which all plugin modules
are subclassed.

=head1 METHODS

Each plugin module should subclass WWW::Comic::Plugin, and support the
following methods explicitly or through inheritance:

=head2 new *MANDATORY*

This method is mandatory. Your plugin must allow instantiation through
this method.

=head2 comics

This method should return a list of comics which your plugin will
support.

The default superclassed C<comics()> method will try to determine
what comics your plugin supports by loogking for C<$self->{comics}>, which
can be an array of hash of comic names. If it cannot find a suitable
list of comics there, it will look for
C<@WWW::Comic::Plugin::YourPlugin::COMICS> or
C<%WWW::Comic::Plugin::YourPlugin::COMICS>.

=head2 strip_url *MANDATORY*

This method is mandatory. This method must return a valid comic strip
image URL. A predefined L<LWP::UserAgent> object can be obtained in order
to perform this functionality by calling the superclassed C<_new_agent()>
method.

This method should return an C<undef> value upon failure.

=head2 get_strip

The default superclassed C<get_strip()> method will try and download a URL
in to a scalar, and if it contains a valid GIF, JPEG or PNG image, it will
return. The URL of the comic strip image can be passed as a paramater. If
it is not passed, it will ask the C<strip_url()> method for a comic strip URL.

If you overload the default method, you should return C<undef> on failure,
or return the binary image data as a scalar if successful. You method should
validate the binary image data as a valid GIF, JPEG or PNG image file by
using the superclassed C<_image_format()> method.

=head2 mirror_strip

The default superclassed method will use the C<get_strip()> method to download
a comic image URL and then write it to disk. If no filename paramater is
passed, it will assume a sensible default filename to write to disk based upon
the comic strip URL that it is retrieving. It will return the name of the file
that it wrote to disk.

If you overload the default method, you should return C<undef> on failure,
or return the name of the file that was written to disk if successful.

=head1 PRIVATE METHODS

The following private methods existing withing the L<WWW::Comic::Plugin>
module as utility methods. These are not intended to be part of the
publically exposed and documented part of your plugin API.

=head2 _new_agent

This method returns an L<LWP::UserAgent> object, preconfigured with
sensible default paramaters.

=head2 _image_format

This method accepts a single scalar argument which should contain binary
image data. It will return a scalar value of C<gif>, C<jpg> or C<png> to
match the format of the image.

It will return an C<undef> value if it is not a valid GIF, JPEG or PNG
image.

=head1 EXAMPLES

See inside L<WWW::Comic::Plugin::UFS>, L<WWW::Comic::Plugin::uComics>,
L<WWW::Comic::Plugin::Dilbert>, L<WWW::Comic::Plugin::VenusEnvy>,
L<WWW::Comic::Plugin::UserFriendly>, L<WWW::Comic::Plugin::Goats>
and L<WWW::Comic::Plugin::MrWiggles>.

A good boiler plate example is L<WWW::Comic::Plugin::MrWiggles>.

=head1 VERSION

$Id: Plugin.pm,v 1.7 2006/01/10 15:49:32 nicolaw Exp $

=head1 AUTHOR

Nicola Worthington <nicolaw@cpan.org>

L<http://perlgirl.org.uk>

=head1 COPYRIGHT

Copyright 2006 Nicola Worthington.

This software is licensed under The Apache Software License, Version 2.0.

L<http://www.apache.org/licenses/LICENSE-2.0>

=cut


