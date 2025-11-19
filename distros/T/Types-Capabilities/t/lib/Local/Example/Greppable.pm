package Local::Example::Greppable;

sub new {
	my $class = shift;
	bless [@_], $class;
}

*grep = sub {
	my ( $self, $code ) = @_;
	return grep { $code->($_) } @$self;
};

1;