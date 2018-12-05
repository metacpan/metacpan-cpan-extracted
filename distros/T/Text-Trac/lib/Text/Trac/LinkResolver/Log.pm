package Text::Trac::LinkResolver::Log;

use strict;
use warnings;
use base qw( Text::Trac::LinkResolver );

our $VERSION = '0.20';

sub init {
	my $self = shift;
	$self->{pattern} = '!?\[\d+:\d+\]|(?:\b|!)r\d+:\d+\b';
}

sub format_link {
	my ( $self, $match, $target, $label ) = @_;
	return $match if $self->_is_disabled;

	my $c = $self->{context};
	$label ||= $match;
	my ( $from, $to ) = ( $match =~ m/(\d+):(\d+)/ );

	my $url = $c->{trac_log_url} || $c->trac_url . 'log/';
	return sprintf '<a %s href="%s?rev=%s&amp;stop_rev=%s">%s</a>', ( $c->{class} ? q{class="source"} : '' ), $url,
		$to, $from, $label;
}

1;
