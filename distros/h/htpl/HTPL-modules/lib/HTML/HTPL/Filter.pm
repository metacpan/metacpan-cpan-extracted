package HTML::HTPL::Filter;
use strict qw(vars subs);

sub TIEHANDLE {
	my ($class, $out, $filter, @p) = @_;
	bless {'f' => $filter, 'o' => $out, 'p' => \@p}, $class;
}

sub WRITE {
	my ($self, $scalar, $length, $offset) = @_;
	$self->PRINT(substr($scalar, $offset, $length));
}

sub PRINT {
	my ($self, @list) = @_;
	my $code = $self->{'f'};
	my $out = $self->{'o'};
	my $p = $self->{'p'};
	foreach (@list) {
		print $out (&$code($_, @$p));
	}
}

sub PRINTF {
	my ($self, $format, @list) = @_;
	$self->PRINT(sprintf($format, @list));
}

1;
