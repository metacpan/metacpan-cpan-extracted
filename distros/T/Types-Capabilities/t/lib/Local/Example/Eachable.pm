package Local::Example::Eachable;

sub new {
	my $class = shift;
	bless [@_], $class;
}

*each = sub {
	my ( $self, $code ) = @_;
	$code->($_) for @$self;
	return $self;
};

1;