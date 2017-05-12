package HTML::HTPL::Stream;
use strict;

sub TIEHANDLE {
	my $class = shift;
	my $txt;
	bless \$txt, $class;
}

sub WRITE {
	my ($self, $scalar, $length, $offset) = @_;
	$self->PRINT(substr($scalar, $offset, $length));
}

sub PRINT {
	my ($self, @list) = @_;
	$$self .= join("", @list);
}

sub PRINTF {
	my ($self, $format, @list) = @_;
	$self->PRINT(sprintf($format, @list));
}

1;
