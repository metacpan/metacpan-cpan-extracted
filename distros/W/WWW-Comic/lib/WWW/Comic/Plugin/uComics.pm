############################################################
#
#   $Id: uComics.pm,v 1.3 2006/01/10 15:45:58 nicolaw Exp $
#   WWW::Comic::Plugin::uComics - uComics plugin for WWW::Comic
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

package WWW::Comic::Plugin::uComics;
# vim:ts=4:sw=4:tw=78

use strict;
use Carp qw(carp croak);

use vars qw($VERSION @ISA %COMICS $HAVE_PROBED);
$VERSION = sprintf('%d.%02d', q$Revision: 1.3 $ =~ /(\d+)/g);
@ISA = qw(WWW::Comic::Plugin);
$HAVE_PROBED = 0;
%COMICS = (
		garfield => 'Garfield',
	);

sub new {
	my $class = shift;
	my $self = { homepage => 'http://www.ucomics.com' };
	bless $self, $class;
	return $self;
}

sub strip_url {
	my $self = shift;
	my %param = @_;

	# If we don't know about this comic and we've not probed before,
	# then go and probe for the first time
	if (!exists($COMICS{$param{comic}}) && !$HAVE_PROBED) {
		$self->comics(probe => 1);
	}

	# If we've probed and we still do not know about this comic then
	# return undef and complain if perl warnings are turned on
	if ($HAVE_PROBED && !exists($COMICS{$param{comic}})) {
		carp "I do not know how to handle comic '$param{comic}'" if $^W;
		return undef;
	}

	my $url = "$self->{homepage}/$param{comic}/";
	if (exists $param{id}) {
		if (my ($yy,$mm,$dd) = $param{id} =~ m/^(\d\d)(\d\d)(\d\d)$/) {
			if ($yy =~ /^9/) { $yy = "19$yy"; }
			else { $yy = "20$yy"; }
			$url .= "$yy/$mm/$dd/";
		} elsif ($param{id} =~ m/^\d{4}\/\d{2}\/\d{2}$/) {
			$url .= "$param{id}";
		}
	}

	$self->{ua} ||= $self->_new_agent();
	my $response = $self->{ua}->get($url);
	if ($response->is_success) {
		my $html = $response->content;
		if ($html =~ m#<img\s+src="((?:https?://[\w\.:\d\/]+)?
					/comics/[a-z0-9\_\-/]+?/[a-z0-9]+\.(gif|jpg|png))"#imsx) {
			my $url = $1;
			$url = "$self->{homepage}$1" unless $url =~ /^https?:\/\//i;
			return $url;
		}

	} elsif ($^W) {
		carp($response->status_line);
	}

	return undef;
}

sub comics {
	my $self = shift;
	my %param = @_ % 2 ? (@_,1) : @_;

	# If we have comic information then return it
	if (keys(%COMICS)) {
		# Unless we've never probed before and we're being asked to probe
		unless (!$HAVE_PROBED && exists $param{probe} && $param{probe}) {
			return (keys(%COMICS));
		}
	}

	# Only continue if we've never probed before and we're
	# being asked to probe
	unless (!$HAVE_PROBED && exists $param{probe} && $param{probe}) {
		return (keys(%COMICS));
	}

	$HAVE_PROBED = 1;
	$self->{ua} ||= $self->_new_agent;
	my $response = $self->{ua}->get($self->{homepage});
	if ($response->is_success) {
		my $html = $response->content;
		while (my ($str,$comic,$title) = $html =~
				m#(<option\s+value="http://www\.ucomics\.com/([a-z0-9]+?)/">(.+?)</option>)#ims) {
			$COMICS{$comic} = $title;
			$html =~ s#/$comic/##ig;
		}

	} elsif ($^W) {
		carp "Failed to retrieve $self->{homepage}: ".$response->status_line;
	}

	return (keys(%COMICS));
}

sub title {
	my $self = shift;
	my %param = @_;
	if (exists $COMICS{$param{comic}}) {
		return $COMICS{$param{comic}};
	}
	return undef;
}

sub homepage {
	my $self = shift;
	my %param = @_;
	if (exists $COMICS{$param{comic}}) {
		return "$self->{homepage}/$param{comic}}/";
	}
	return undef;
}

1;

=pod

=head1 NAME

WWW::Comic::Plugin::uComics - uComics plugin for WWW::Comic

=head1 SYNOPSIS

 # Actively probe www.comics.com to return (and cache)
 # a list of supported comics
 my @comics = $plugin->comics(probe => 1);
 
 # Return a list of supported comics that has already
 # been cached in memory
 @comics = $plugin->comics;
 
 # Return the comic homepage URL
 my $url = $plugin->homepage(comic => "peanuts");

See L<WWW::Comic>.

=head1 METHODS

See L<WWW::Comic> and L<WWW::Comic::Plugin> for a list of standard
methods that this module supports.

Additional methods are:

=over 4

=item title

Returns the full title of comic strip.

=item homepage

Returns the comic homepage URL.

=back

=head1 VERSION

$Id: uComics.pm,v 1.3 2006/01/10 15:45:58 nicolaw Exp $

=head1 AUTHOR

Nicola Worthington <nicolaw@cpan.org>

L<http://perlgirl.org.uk>

=head1 COPYRIGHT

Copyright 2006 Nicola Worthington.

This software is licensed under The Apache Software License, Version 2.0.

L<http://www.apache.org/licenses/LICENSE-2.0>

=cut

