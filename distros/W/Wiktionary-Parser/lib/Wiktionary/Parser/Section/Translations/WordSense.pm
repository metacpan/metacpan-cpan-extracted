package Wiktionary::Parser::Section::Translations::WordSense;

use Wiktionary::Parser::Section::Translations::WordSense::Lexeme;

sub new {
	my $class = shift;
	my %args = @_;

	die 'word_sense is not defined' unless defined $args{word_sense};

	my $self = bless \%args, $class;
	return $self;
}

sub get_word {
	my $self = shift;
	return $self->{word_sense};
}

sub add_translation {
	my $self = shift;
	my %args = @_;

	my $lexeme = Wiktionary::Parser::Section::Translations::WordSense::Lexeme->new(
		language_code => $args{language_code},
		language_name => $args{language_name},
		lexeme        => $args{translated_word},
		extra         => $args{extra},
	);
	$self->add_lexeme($lexeme);
	$self->{_last_lexeme} = $lexeme;
}

sub add_lexeme {
	my $self = shift;
	my $lexeme = shift;
	my $lang = $lexeme->get_language_name();
	return unless $lang;
	push @{$self->{languages}{$lang}}, $lexeme;
}

sub get_translations {
	my $self = shift;
	return $self->{languages};
}

1;
