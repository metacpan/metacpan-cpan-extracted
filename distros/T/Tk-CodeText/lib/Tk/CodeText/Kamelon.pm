package Tk::CodeText::Kamelon;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.53';

use base qw(Syntax::Kamelon);

sub new {
	my $class = shift;
	my $widget = shift;
	my $self = $class->SUPER::new(@_);
	$self->{WIDGET} = $widget;
	return $self
}

sub ParseResultEndRegion {
	my $self = shift;
	my $region = pop @_;
	my $formatter = $self->Formatter;
	my $widget = $self->Widget;
	my $top = $formatter->FoldStackTop;
	if (defined $top) {
		my $begin = $formatter->FoldStackTop->{start};
		$formatter->FoldEnd($region);
		$widget->foldsCheck if (($begin >= $widget->visualBegin) and ($begin <= $widget->visualEnd));
	}
	my $parser = pop @_;
	return &$parser($self, @_);
}

sub Widget { return $_[0]->{WIDGET} }

1;

__END__


