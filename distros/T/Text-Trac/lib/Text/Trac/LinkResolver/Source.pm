package Text::Trac::LinkResolver::Source;

use strict;
use warnings;
use base qw( Text::Trac::LinkResolver );

our $VERSION = '0.22';

sub init {
	my $self = shift;
}

sub format_link {
	my ( $self, $match, $target, $label ) = @_;
	return $match if $self->_is_disabled;

	my $c = $self->{context};
	$label ||= $match;
	my ( $file, $rev ) = ( $target =~ m/([^#]+)(?:#(\d+))?/ );

	my $url = $c->{trac_source_url} || $c->trac_url . 'browser/';
	$url .= $file;
	$url .= "?rev=$rev" if $rev;

	return sprintf '<a %s href="%s">%s</a>', ( $c->{class} ? q{class="source"} : '' ), $url, $label;
}

1;
