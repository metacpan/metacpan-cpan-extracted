package Text::Trac::Dl;

use strict;
use warnings;
use base qw(Text::Trac::BlockNode);

our $VERSION = '0.18';

sub init {
	my $self = shift;
	$self->pattern(qr/^\s+(.*)::$/xms);
}

sub parse {
	my ( $self, $l ) = @_;
	my $c       = $self->{context};
	my $pattern = $self->pattern;

	if ( !@{ $c->in_block_of } or $c->in_block_of->[-1] ne 'dl' ) {
		$c->htmllines('<dl>');
		push @{ $c->in_block_of }, 'dl';
	}

	$c->unshiftline;
	while ( $c->hasnext ) {
		last if ( $c->nextline =~ /^$/ );
		my $l = $c->shiftline;

		if ( $l =~ /$pattern/ ) {
			if ( $c->in_block_of->[-1] eq 'dd' ) {
				$l = "</dd>\n<dt>$1</dt>";
				pop @{ $c->in_block_of };
			}
			else {
				$l = "<dt>$1</dt>";
			}
		}
		else {
			$l =~ s/^\s+//g;
			if ( $c->in_block_of->[-1] ne 'dd' ) {
				$l = "<dd>\n$l";
				push @{ $c->in_block_of }, 'dd';
			}
		}
		$c->htmllines($l);
	}

	if ( $c->in_block_of->[-1] eq 'dd' ) {
		$c->htmllines('</dd>');
		pop @{ $c->in_block_of };
	}

	pop @{ $c->in_block_of };
	$c->htmllines('</dl>');

	return;
}

1;
