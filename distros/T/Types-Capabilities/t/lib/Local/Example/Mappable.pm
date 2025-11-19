package Local::Example::Mappable;

sub new {
	my $class = shift;
	bless [@_], $class;
}

*map = sub {
	my ( $self, $code ) = @_;
	return map { $code->($_) } @$self;
};

1;