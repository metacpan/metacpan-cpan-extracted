package Local::Example::Joinable;

sub new {
	my $class = shift;
	bless [@_], $class;
}

*join = sub {
	my ( $self, $str ) = @_;
	$str = '' unless defined $str;
	return join $str, @$self;
};

1;