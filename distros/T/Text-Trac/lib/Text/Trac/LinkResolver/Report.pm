package Text::Trac::LinkResolver::Report;

use strict;
use warnings;
use base qw( Text::Trac::LinkResolver );

our $VERSION = '0.19';

sub init {
	my $self = shift;
	$self->{pattern} = '!?\{\d+\}';
}

sub format_link {
	my ( $self, $match, $target, $label ) = @_;
	return $match if $self->_is_disabled;

	my $c = $self->{context};
	$label ||= $match;
	my ($rev) = ( $match =~ m/(\d+)/ );

	my $url = $c->{trac_report_url} || $c->trac_url . 'report/';
	$url .= $rev;
	return sprintf '<a %s href="%s">%s</a>', ( $c->{class} ? q{class="report"} : '' ), $url, $label;
}

1;
