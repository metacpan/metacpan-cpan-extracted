package Local::Example::Dequeueable;

sub new {
	my $class = shift;
	bless [@_], $class;
}

sub dequeue {
	my $self = shift;
	shift @$self;
}

1;