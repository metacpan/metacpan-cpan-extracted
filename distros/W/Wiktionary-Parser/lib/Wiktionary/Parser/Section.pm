package Wiktionary::Parser::Section;

use strict;
use warnings;
use Data::Dumper;

use Wiktionary::Parser::TemplateParser;
use Wiktionary::Parser::Language;

sub new {
	my $class = shift;
	my %args = @_;

	die 'section_number not defined' unless defined $args{section_number};
	$args{header} = lc($args{header}) if $args{header};

	my $self = bless \%args, $class;

	$self->{template_parser} = Wiktionary::Parser::TemplateParser->new();

	return $self;
}

sub get_section_number {
	my $self = shift;
	return $self->{section_number};
}

sub get_header {
	my $self = shift;
	return lc $self->{header};
}

sub set_header {
	my $self = shift;
	$self->{header} = lc shift;
}

# add a line of content to this section
sub add_content {
	my $self = shift;
	my $line = shift;
	
	push @{$self->{content}}, $line;
}

# return an arrayref of lines of text from this section
sub get_content {
	my $self = shift;
	return $self->{content};
}

sub get_document {
	my $self = shift;
	return $self->{document};
}

sub set_document {
       my $self = shift;
       my $doc = shift;
       return $self->{document} = $doc;
}


# return the parent section
# e.g. if this is section 1.2.1
# return section 1.2
sub get_parent_section {
	my $self = shift;
	my $num = $self->get_section_number();
	if ($num =~ m/\./) {
		$num =~ s/\.\d+$//;
		$num =~ s/\.0*$//; # remove trailing zero's - if sections were added too deep e.g. section ===== under ===

		return $self->get_document()->get_section(number => $num);
	}
	return;
}


# return a list of sections below this one
sub get_child_sections {
	my $self = shift;
	my $section_number = $self->get_section_number();
	my @section_numbers = $self->get_document()->get_section_numbers();

	my @children = ($self);
	for my $num (@section_numbers) {
		next unless $num =~ m/^$section_number\.\d+/;
		next if $num eq $section_number;
		push @children, $self->get_document()->get_section(number => $num);
	}
	return \@children;
}

# return a document object containing only the child sections of this section
sub get_child_document {
	my $self = shift;
	my $children = $self->get_child_sections();

	return unless $children && @$children;
	return $self->get_document()->create_sub_document(
		sections => $children,
	);
}


# returns the topmost section in the hierarchy
sub _get_parent_language_section {
	my $self = shift;
	my $sections = $self->get_ancestor_sections();
	if ($sections && @$sections) {
		return $sections->[-1];
	}
	return $self;
}

sub _get_parent_part_of_speech_section {
	my $self = shift;

	# if the current section is a part of speech section, return self
	if ($self->get_document()->is_part_of_speech( $self->get_header() )) {
		return $self;
	}

	# otherwise look through parent sections for a match
	my $sections = $self->get_ancestor_sections();
	if ($sections && @$sections) {
		for my $section (@$sections) {
			next unless 
			    $self->get_document()->is_part_of_speech(
					$section->get_header()
				);
			return $section;
		}
	}
	return;

}

# get all parent sections up to the top level
sub get_ancestor_sections {
	my $self = shift;
	my @ancestors;
	my $section = $self;
	while (my $parent = $section->get_parent_section()) {
		push @ancestors, $parent;
		$section = $parent;
	}

	return \@ancestors;
}

# get the language from the parent section at the top of the section hierarchy
sub get_language {
	my $self = shift;
	my $parent = $self->_get_parent_language_section();
	return unless $parent;
	my $language_name = $parent->get_header();
	my $lang = Wiktionary::Parser::Language->new();
	my $code = $lang->language2code($language_name);
	return $code;
}

# get the part of speech of the current section based on the part of speech section above this in the hierarchy
sub get_part_of_speech {
	my $self = shift;
	if ($self->{__part_of_speech__}) {
		return $self->{__part_of_speech__};
	}
	my $parent = $self->_get_parent_part_of_speech_section();
	return unless $parent;

	$self->{__part_of_speech__} = $parent->get_header();
	return $self->{__part_of_speech__};
}

sub get_template_parser {
	my $self = shift;
	return $self->{template_parser};
}


1;

