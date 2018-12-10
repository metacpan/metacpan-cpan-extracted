package Text::Trac::P;
use strict;
use warnings;
use base qw(Text::Trac::BlockNode);
use Text::Trac::Text;

our $VERSION = '0.24';

sub parse {
	my ( $self, $l ) = @_;
	my $c = $self->{context};

	if ( !@{ $c->in_block_of } or $c->in_block_of->[-1] ne 'p' ) {
		$c->htmllines('<p>');
		push @{ $c->in_block_of }, 'p';
	}

	# define block parsers called.
	$self->block_nodes( [qw( blockquote hr )] );
	$self->block_parsers( $self->_get_parsers('block') );

	my $cite_depth = 0;
	$c->unshiftline;
	while ( $c->hasnext ) {
		last if $c->nextline =~ /^$/;
		$l = $c->shiftline;
		last if $l =~ /^\s+$/;

		my $blockquote_depth = 0;
		for ( @{ $c->in_block_of } ) {
			$blockquote_depth++ if $_ eq 'blockquote';
		}

		if ( $l =~ /^(>+)/ ) {
			$cite_depth = length $1;
			if ( $blockquote_depth != $cite_depth ) {
				$c->unshiftline;
				last;
			}
			else {
				$l =~ s/^>+//;
			}
		}
		elsif ( $l !~ /^(?:>|\s+)/ and $blockquote_depth ) {
			$c->htmllines('</p>');
			pop @{ $c->in_block_of };
			for ( 1 .. $blockquote_depth ) {
				$c->htmllines('</blockquote>');
				pop @{ $c->in_block_of };
			}

			$c->unshiftline;
			last;
		}

		# parse other block nodes
		my $parsers = $self->_get_matched_parsers( 'block', $l );
		if ( grep { ref($_) ne 'Text::Trac::P' } @{$parsers} ) {
			$c->htmllines('</p>');
			pop @{ $c->in_block_of };
			$c->unshiftline;
			last;
		}

		# parse inline nodes
		$l = $self->replace($l);
		$c->htmllines($l);
	}

	if ( @{ $c->in_block_of } and $c->in_block_of->[-1] eq 'p' ) {
		$c->htmllines('</p>');
		pop @{ $c->in_block_of };

		my $blockquote_depth = 0;
		for ( @{ $c->in_block_of } ) {
			$blockquote_depth++ if $_ eq 'blockquote';
		}

		if ($cite_depth) {
			for ( $blockquote_depth .. length $1 ) {
				$c->htmllines('</blockquote>');
				pop @{ $c->in_block_of };
			}
		}
	}

	return;
}

1;
