package Local::Example::Reversible;

sub new {
	my $class = shift;
	bless [@_], $class;
}

*reverse = sub {
	my ( $self ) = @_;
	return reverse @$self;
};

1;