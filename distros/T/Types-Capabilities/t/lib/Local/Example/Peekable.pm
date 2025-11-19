package Local::Example::Peekable;

our $INDEX = 0;

sub new {
	my $class = shift;
	bless [@_], $class;
}

sub peek {
	my ( $self ) = @_;
	return $self->[$INDEX];
}

1;