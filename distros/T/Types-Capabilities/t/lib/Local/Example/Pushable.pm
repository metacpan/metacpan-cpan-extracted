package Local::Example::Pushable;

sub new {
	my $class = shift;
	bless [@_], $class;
}

*push = sub {
	my $self = shift;
	push @$self, @_;
};

1;