package Text::Trac::LinkResolver::Attachment;

use strict;
use warnings;
use base qw( Text::Trac::LinkResolver );

our $VERSION = '0.24';

sub init {
	my $self = shift;
}

sub format_link {
	my ( $self, $match, $target, $label ) = @_;
	return $match if $self->_is_disabled;

	my $c = $self->{context};
	$label ||= $match;

	my ( $type, $name, $file ) = ( $match =~ m/attachment:([^:]+):([^:]+):([^:\]\s]+)/ );
	my $url = $c->{trac_attachment_url} || $c->trac_url . 'attachment/';
	$url .= "$type/$name/$file";

	return sprintf '<a %s href="%s">%s</a>', ( $c->{class} ? q{class="attachment"} : '' ), $url, $label;
}

1;
