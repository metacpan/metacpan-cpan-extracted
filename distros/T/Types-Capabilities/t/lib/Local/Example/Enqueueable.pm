package Local::Example::Enqueueable;

sub new {
	my $class = shift;
	bless [@_], $class;
}

sub enqueue {
	my $self = shift;
	push @$self, @_;
}

1;