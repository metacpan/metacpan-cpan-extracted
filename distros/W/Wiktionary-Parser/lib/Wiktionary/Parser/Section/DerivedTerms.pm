package Wiktionary::Parser::Section::DerivedTerms;

use Wiktionary::Parser::Section;

use base qw(Wiktionary::Parser::Section);

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless Wiktionary::Parser::Section->new(%args), $class;
	return $self;
}

sub add_content {
	my $self = shift;
	my $line = shift;

	my $language = $self->get_language();

	if (my @templates = $self->get_template_parser()->extract_templates(line => $line)) {
		
	}

	if (my @tokens = $self->get_template_parser()->extract_tokens(line => $line)) {
		for my $term (@tokens) {
			$self->add_derived_term(term => $term, language => $language);
		}
	}
	


}

sub add_derived_term {
	my $self = shift;
	my %args = @_;
	my $term = $args{term};
	my $language = $args{language};
	push @{$self->{derived_terms}{$language}}, $term;
}

sub get_derived_terms {
	my $self = shift;
	return $self->{derived_terms};
}


1;
