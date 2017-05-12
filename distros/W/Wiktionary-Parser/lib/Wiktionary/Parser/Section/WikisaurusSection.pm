package Wiktionary::Parser::Section::WikisaurusSection;

use Wiktionary::Parser::Section;
use Wiktionary::Parser::TemplateParser;

use base qw(Wiktionary::Parser::Section);

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless Wiktionary::Parser::Section->new(%args), $class;
	return $self;
}

# add a line of content to this section and parse it into its component parts
sub add_content {
	my $self = shift;
	my $line = shift;

	# * {{sense|swindler}} [[swindler]], [[cheat]]	
	# * {{l|en|blee}}
	# * {{l|pt|para|gloss=[[to]], [[for]]}}

	if (my @templates = $self->get_template_parser()->extract_templates(line => $line)) {

		for my $template (@templates) {
			my $meta = $self->get_template_parser()->parse_template(template => $template);
			my $template_type = delete $meta->{template_type};

			next unless $meta && keys %$meta;
			if ($meta->{word}) {
				$self->add_word(%$meta);
			}
		}
	}
}

sub add_word {
	my $self = shift;
	my %args = @_;
	
	push @{$self->{words}}, \%args;
}

sub get_words {
	my $self = shift;
	return $self->{words};
}

1;
