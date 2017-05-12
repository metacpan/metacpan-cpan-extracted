package Text::Trac::Heading;
use strict;
use warnings;
use base qw(Text::Trac::BlockNode);

our $VERSION = '0.18';

sub init {
	my $self = shift;
	$self->pattern(qr/^(=+) \s (.*) \s (=+)$/xms);
}

sub parse {
	my ( $self, $l ) = @_;
	my $c = $self->context;

	$l =~ $self->pattern or return;
	my $level = length($1) + $c->min_heading_level - 1;

	my $id = $self->_strip($2);
	$l = qq(<h$level id="$id">) . $self->replace($2) . qq(</h$level>);

	$c->htmllines($l);
}

sub _strip {
	my ( $self, $word ) = @_;
	$word =~ s/[\s,_`'{}!]//g;
	return $word;
}

1;
