package Local::Example::Sortable;

sub new {
	my $class = shift;
	bless [@_], $class;
}

*sort = sub {
	my ( $self, $code ) = @_;
	$code ||= sub { $a cmp $b };
	return sort { $code->($a, $b) } @$self;
};

1;