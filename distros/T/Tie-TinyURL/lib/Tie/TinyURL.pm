############################################################
#
#   $Id: TinyURL.pm 566 2006-06-01 18:38:40Z nicolaw $
#   Tie::TinyURL - Tied interface to TinyURL.com
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

package Tie::TinyURL;
# vim:ts=4:sw=4:tw=78

use strict;
use LWP::UserAgent qw();
use Carp qw(croak carp);

use vars qw($VERSION $DEBUG);

$VERSION = '0.02' || sprintf('%d', q$Revision: 566 $ =~ /(\d+)/g);
$DEBUG = $ENV{DEBUG} ? 1 : 0;

sub UNTIE {}
sub DESTROY {}

sub TIEHASH {
	my $class = shift;

	my $self = {
			args => ( @_ % 2 ? [ @_ ] : { @_ } ),
			seen => {},
			ua => LWP::UserAgent->new(
					timeout => 20,
					agent => __PACKAGE__ . ' $Id: TinyURL.pm 566 2006-06-01 18:38:40Z nicolaw $',
					max_redirect => 0,
				),
		};

	$self->{ua}->env_proxy;
	$self->{ua}->max_size(1024*100);
	$self->{ua}->timeout($self->{args}->{timeout}) if
		ref($self->{args}) eq 'HASH' && defined($self->{args}->{timeout});

	bless $self, $class;
	DUMP('$self',$self);
	return $self;
}

sub FETCH {
	TRACE('FETCH()');
	my $self = shift;
	my $url = shift;

	TRACE("\$url = '$url'");
	return unless defined $url && length($url);
	return $self->{seen}->{$url} if exists $self->{seen}->{$url};
	return $self->_retrieve($url) if _isTinyURL($url);
	return $self->_store($url);
}

sub STORE {
	my $self = shift;
	DUMP('$self', $self);
	DUMP('@_',\@_);
}

sub DELETE {
	my $self = shift;
	my $url = shift;

	if (defined $url && exists $self->{seen}->{$url}) {
		delete $self->{seen}->{$self->{seen}->{$url}};
		delete $self->{seen}->{$url};
		return 1;
	}
	return 0;
}

sub EXISTS {
	my $self = shift;
	my $url = shift;

	return 0 if !defined($url) || !exists($self->{seen}->{$url});
	return 1;
}

sub FIRSTKEY {
}

sub NEXTKEY {
}

sub SCALAR {
}

sub _isTinyURL {
	return $_[0] =~ /^http:\/\/(?:www\.)?tinyurl\.com\/[a-zA-Z0-9]+$/i;
}

sub _retrieve {
	TRACE('_retrieve()');
	my $self = shift;
	my $tinyurl = shift;

	my $response = $self->{ua}->get($tinyurl);
	my $url = $response->header('location') || undef;
	if ($url) {
		$self->{seen}->{$tinyurl} = $url;
		$self->{seen}->{$url} = $tinyurl;
	}

	return $url;
}

sub _store {
	TRACE('_store()');
	my $self = shift;
	my $url = shift;

	my $tinyurl = undef;
	my $response = $self->{ua}->post(
						'http://tinyurl.com/create.php',
						[('url',$url)]
					);

	if ($response->is_success) {
		if ($response->content =~ m|<input\s+type=hidden\s+name=tinyurl\s+
						value="(http://tinyurl.com/[a-zA-Z0-9]+)">|x) {
			$tinyurl = $1;
			$self->{seen}->{$url} = $tinyurl;
			$self->{seen}->{$tinyurl} = $url;
		} else {
			TRACE("Couldn't extract tinyurl");
			DUMP("Content",$response->content);
		}
	}

	return $tinyurl;
}


sub TRACE {
	return unless $DEBUG;
	warn(shift());
}

sub DUMP {
	return unless $DEBUG;
	eval {
		require Data::Dumper;
		warn(shift().': '.Data::Dumper::Dumper(shift()));
	}
}


1;


=pod

=head1 NAME

Tie::TinyURL - Tied interface to TinyURL.com

=head1 SYNOPSIS

 use strict;
 use Tie::TinyURL;
 
 my %url;
 tie %url, "Tie::TinyURL";
 
 ## Explicitly set an HTTP timeout of 3 seconds
 # tie %url, "Tie::TinyURL", "timeout" => 3;
 
 my $tinyurl = $url{"http://www.bbc.co.uk"};
 my $url = $url{$tinyurl};
 print "$tinyurl => $url\n";
 
=head1 DESCRIPTION

This module provides a very basic tied interface to the TinyURL.com
web service.

=head1 SEE ALSO

L<WWW::Shorten::TinyURL>, L<http://www.tinyurl.com>

=head1 VERSION

$Id: TinyURL.pm 566 2006-06-01 18:38:40Z nicolaw $

=head1 AUTHOR

Nicola Worthington <nicolaw@cpan.org>

L<http://perlgirl.org.uk>

=head1 COPYRIGHT

Copyright 2006 Nicola Worthington.

This software is licensed under The Apache Software License, Version 2.0.

L<http://www.apache.org/licenses/LICENSE-2.0>

=cut


__END__

