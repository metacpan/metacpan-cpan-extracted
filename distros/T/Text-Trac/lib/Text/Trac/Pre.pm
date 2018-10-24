package Text::Trac::Pre;

use strict;
use warnings;
use base qw(Text::Trac::BlockNode);

our $VERSION = '0.19';

sub init {
	my $self = shift;
	$self->pattern(qr/^\{\{\{$/xms);
	return $self;
}

sub parse {
	my ( $self, $l ) = @_;
	my $c       = $self->{context};
	my $pattern = $self->pattern;
	$l =~ /$pattern/ or return $l;
	my $match = $1;
	my $class = $c->{class} ? q{ class="wiki"} : '';

	if ( $l =~ /^\{\{\{$/ ) {
		$c->htmllines(qq{<pre$class>});
	}

	while ( $c->hasnext ) {
		my $l = $c->shiftline;
		if ( $l =~ /^\}\}\}$/ ) {
			$c->htmllines('</pre>');
			last;
		}
		else {
			$c->htmllines( $self->escape($l) );
		}
	}

	return;
}

1;
