package Wiktionary::Parser::Section::Translations::WordSense::Lexeme;

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless \%args, $class;
	return $self;
}


sub add_translations {
	my $self = shift;
	my @words = @_;
	push @{$self->{translations}}, @words;
}

sub add_qualifiers {
	my $self = shift;
	my @words = @_;
	push @{$self->{qualifiers}}, @words;
}

sub set_gender {
	my $self = shift;
	my $gender = shift;
	$self->{gender} = $gender;
}

sub set_number {
	my $self = shift;
	my $number = shift;
	$self->{number} = $number;
}

sub set_transliteration {
	my $self = shift;
	my $transliteration = shift;
	$self->{transliteration} = $transliteration;
}

sub set_alternate {
	my $self = shift;
	my $alternate = shift;
	$self->{alternate} = $alternate;
}

sub set_language_code {
	my $self = shift;
	my $language_code = shift;
	$self->{language_code} = $language_code;
}
sub set_language_name {
	my $self = shift;
	my $language_name = shift;
	$self->{language_name} = $language_name;
}


sub get_translations {
	my $self = shift;
	return @{$self->{translations} || []};
}

sub get_language_code {
	my $self = shift;
	return $self->{language_code};
}

sub get_language_name {
	my $self = shift;
	return $self->{language_name};
}


sub get_gender {
	my $self = shift;
	return $self->{gender};
}

sub get_number {
	my $self = shift;
	return $self->{number};
}

sub get_transliteration {
	my $self = shift;
	return $self->{transliteration};
}

sub get_alternate {
	my $self = shift;
	return $self->{alternate};
}

sub get_qualifiers {
	my $self = shift;
	return $self->{qualifiers};
}



1;
