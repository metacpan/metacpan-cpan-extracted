package Local::Example::Countable;

sub new {
	my $class = shift;
	bless [@_], $class;
}

sub count {
	my ( $self ) = @_;
	return scalar @$self;
}

1;