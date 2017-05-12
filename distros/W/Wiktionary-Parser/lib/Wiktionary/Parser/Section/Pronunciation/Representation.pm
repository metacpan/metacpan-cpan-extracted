package Wiktionary::Parser::Section::Pronunciation::Representation;

# keys:
#  representation: IPA, SAMPA, prUS
#  pronunciation: string representing pronunciation in the given representation format
#  context: e.g. en(US), en(UK)
sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless \%args, $class;
	return $self;
}

sub get_representation {
	my $self = shift;
	return $self->{representation};
}

sub get_pronunciation {
	my $self = shift;
	return $self->{pronunciation};
}

sub get_context {
	my $self = shift;
	return $self->{context};
}

sub get_senses {
	my $self = shift;
	return $self->{senses};
}

1;
