package Local::Example::Poppable;

sub new {
	my $class = shift;
	bless [@_], $class;
}

*pop = sub {
	my $self = shift;
	pop @$self;
};

1;