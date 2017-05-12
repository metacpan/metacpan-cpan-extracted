############################################################
#
#   $Id: UserFriendly.pm,v 1.1 2006/01/09 23:31:45 nicolaw Exp $
#   WWW::Comic::Plugin::UserFriendly - UserFriendly plugin for WWW::Comic
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

package WWW::Comic::Plugin::UserFriendly;
# vim:ts=4:sw=4:tw=78

use strict;
use Carp qw(carp croak);

use vars qw($VERSION @ISA %COMICS);
$VERSION = sprintf('%d.%02d', q$Revision: 1.1 $ =~ /(\d+)/g);
@ISA = qw(WWW::Comic::Plugin);
%COMICS = ( userfriendly => 'User Friendly the Comic Strip' );

sub new {
	my $class = shift;
	my $self = { homepage => 'http://ars.userfriendly.org/cartoons/' };
	bless $self, $class;
	return $self;
}

sub strip_url {
	my $self = shift;
	my %param = @_;

	$self->{ua} ||= $self->_new_agent();
	my $url = $self->{homepage};
	if (exists $param{id} && $param{id} =~ /^[0-9]+$/) {
		$url .= "?id=$param{id}";
	}

	my $response = $self->{ua}->get($url);
	if ($response->is_success) {
		my $html = $response->content;
		if ($html =~ m#<img.+?src="((?:https?://[\w\.:\d\/]+)?
					/cartoons/archives/\S+/\w*uf\d+\.(gif|jpe?g|png))"#imsx) {
			my $url = $1;
			$url = "$self->{homepage}$1" unless $url =~ /^https?:\/\//i;
			return $url;
		}

	} elsif ($^W) {
		carp($response->status_line);
	}

	return undef;
}

1;

=pod

=head1 NAME

WWW::Comic::Plugin::UserFriendly - UserFriendly plugin for WWW::Comic

=head1 SYNOPSIS

See L<WWW::Comic>.

=head1 VERSION

$Id: UserFriendly.pm,v 1.1 2006/01/09 23:31:45 nicolaw Exp $

=head1 AUTHOR

Nicola Worthington <nicolaw@cpan.org>

L<http://perlgirl.org.uk>

=head1 COPYRIGHT

Copyright 2006 Nicola Worthington.

This software is licensed under The Apache Software License, Version 2.0.

L<http://www.apache.org/licenses/LICENSE-2.0>

=cut

