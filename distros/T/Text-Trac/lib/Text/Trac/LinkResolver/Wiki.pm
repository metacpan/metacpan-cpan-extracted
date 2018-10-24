package Text::Trac::LinkResolver::Wiki;

use strict;
use warnings;
use base qw( Text::Trac::LinkResolver );

our $VERSION = '0.19';

sub init {
	my $self = shift;
	$self->{pattern}
		= '!?(?<!/)\b[A-Z][a-z]+(?:[A-Z][a-z]*[a-z/])+' . '(?:\#[A-Za-z_:][A-Za-z0-9_:.-]*)?(?=\Z|[\s.,;:!?\)\}\]])';
}

sub format_link {
	my ( $self, $match, $target, $label ) = @_;
	return $match if $self->_is_disabled;

	my $c = $self->{context};
	$label  ||= $match;
	$target ||= $match;

	if ( $label =~ /\[wiki:(\S+)\s+(.+)\]/ ) {
		$target = $1;
		$label  = $2;
	}

	my $url = $c->{trac_wiki_url} || $c->trac_url . 'wiki/';
	$url .= $target;
	return sprintf '<a %s href="%s">%s</a>', ( $c->{class} ? q{class="wiki"} : '' ), $url, $label;
}

1;
