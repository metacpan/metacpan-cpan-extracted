package Text::Trac::Table;

use strict;
use warnings;
use base qw(Text::Trac::BlockNode);

our $VERSION = '0.18';

sub init {
	my $self = shift;
	$self->pattern(qr/^\|\|([^\|]*\|\|(?:[^\|]*\|\|)+)$/xms);
	return $self;
}

sub parse {
	my ( $self, $l ) = @_;
	my $c       = $self->{context};
	my $pattern = $self->pattern;
	$l =~ $pattern or return $l;

	$c->htmllines('<table>');

	$c->unshiftline;
	while ( $c->hasnext and ( $c->nextline =~ $pattern ) ) {
		my $l = $c->shiftline;
		$l =~ s{ $self->{pattern} }{$1}xmsg;
		$l = '<tr><td>' . join(
			'</td><td>',
			map {
				$self->replace($_)    # parse inline nodes
			} split( /\|\|/, $l )
		) . '</td></tr>';

		$c->htmllines($l);
	}

	$c->htmllines('</table>');

	return;
}

1;
