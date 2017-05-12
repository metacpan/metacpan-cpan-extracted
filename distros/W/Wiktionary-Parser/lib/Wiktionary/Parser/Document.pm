package Wiktionary::Parser::Document;

use strict;
use warnings;
use Data::Dumper;
use Wiktionary::Parser::Section;
use Wiktionary::Parser::Section::Translations;
use Wiktionary::Parser::Section::PartofSpeech;
use Wiktionary::Parser::Section::Etymology;
use Wiktionary::Parser::Section::Synonym;
use Wiktionary::Parser::Section::Hyponym;
use Wiktionary::Parser::Section::Hypernym;
use Wiktionary::Parser::Section::Antonym;
use Wiktionary::Parser::Section::Etymology;
use Wiktionary::Parser::Section::Pronunciation;
use Wiktionary::Parser::Section::DerivedTerms;
use Wiktionary::Parser::Section::AlternativeForms;
use Wiktionary::Parser::Section::WikisaurusSection;
use Wiktionary::Parser::Language;

sub new {
	my $class = shift;
	my %args = @_;
	
	my $sections = delete $args{sections};

	my $self = bless \%args, $class;

	$self->{verbose} ||= 0;

	# if a document is instantiated with existing section objects
	# add them one by one so that they get indexed
	if ($sections && @$sections) {
		for my $section (@$sections) {
			$self->add_section($section);
		}
	}

	return $self;
}

# return the title of this document
sub get_title {
	my $self = shift;
	return $self->{title};
}

# add a section object to the document
sub add_section {
	my $self = shift;
	my $section = shift;

	unless ($section->isa('Wiktionary::Parser::Section')) {
		die sprintf(
			'given value (%s) is not of type Wiktionary::Parser::Section',
			ref($section)
		);
	}

	# link section to document
	unless ($section->get_document()) {
		$section->set_document($self);
	}


	my $section_number = $section->get_section_number();
	$self->{sections}{$section_number} = $section;
}

# by default return a list of all sections
# if title is given, return all sections matching that title
# title may be a string or regex
sub get_sections {
	my $self = shift;
	my %args = @_;
	my $title = $args{title};

	if ($title) {
		my @sections;
		for my $number ($self->get_section_numbers()) {
			
			next unless $self->get_section(number => $number)->get_header() =~ m/$title/i;
			push @sections, $self->get_section(number => $number);
		}
		return \@sections;
	}

	return $self->{sections};
}

# given some criteria to select a set of sections
# return a document object encompassing only those sections
sub get_sub_document {
	my $self = shift;
	my %args = @_;
	my $title = $args{title};

	# if no section name pattern was passed in, just return the whole document
	return $self unless $title;

	my $sections = $self->get_sections(title => $title);
	
	return unless $sections && @$sections;
	
	my @children;
	for my $section (@$sections) {
		push @children, @{$section->get_child_sections() || []};
	}

	push @$sections, @children;
	my $sub_document = $self->create_sub_document(
		sections => $sections,
	);

	return $sub_document;
}


# return a document object consisting of just the given language section and its children
sub get_language_section {
	my $self = shift;
	my %args = @_;
	my $language = $args{language} or die 'language needs to be specified';

	# go through the document top to bottom and return the first matching section
	my $section;
	for my $number ($self->get_section_numbers()) {
		next unless $self->get_section(number => $number)->get_header() =~ m/^$language$/i;
		$section = $self->get_section(number => $number);
		last;
	}
	if ($section) {
		return $section->get_child_document();
	}

	return;
}

sub get_section {
	my $self = shift;
	my %args = @_;
	my $number = $args{number}; # lookup section by number

	if ($number) {
		return $self->{sections}{$number};
	}
	return;
}

# act as a section factory
sub create_section {
	my $self = shift;
	my %args = @_;
	my $section_number = $args{section_number};
	my $header = $args{header};

	my $section;
	my $class;
	if ($self->get_title() =~ m/^Wikisaurus\:/) {
		$class = 'Wiktionary::Parser::Section::WikisaurusSection';
	} elsif ($header =~ m/translation/i) {
		$class = 'Wiktionary::Parser::Section::Translations';
	} elsif ($header =~ m/etymology/i) {
		$class = 'Wiktionary::Parser::Section::Etymology';
	} elsif ($header =~ m/synonym/i) {
		$class = 'Wiktionary::Parser::Section::Synonym';
	} elsif ($header =~ m/hypernym/i) {
		$class = 'Wiktionary::Parser::Section::Hypernym';
	} elsif ($header =~ m/hyponym/i) {
		$class = 'Wiktionary::Parser::Section::Hyponym';
	} elsif ($header =~ m/antonym/i) {
		$class = 'Wiktionary::Parser::Section::Antonym';
	} elsif ($header =~ m/pronunciation/i) {
		$class = 'Wiktionary::Parser::Section::Pronunciation';
	} elsif ($header =~ m/alternat\w+ form/i) {
		$class = 'Wiktionary::Parser::Section::AlternativeForms';
	} elsif ($header =~ m/derived\sterm/i) {
		$class = 'Wiktionary::Parser::Section::DerivedTerms';
	} elsif ($self->is_part_of_speech($header)) {
		$class = 'Wiktionary::Parser::Section::PartofSpeech'
	} else {
		$class = 'Wiktionary::Parser::Section';
	}

	$section = $class->new(
		section_number => $section_number,
		header         => $header,
		document       => $self,
	);

	$self->add_section($section);

	return $section;
}

sub get_table_of_contents {
	my $self = shift;
	my @contents;
	for my $number ($self->get_section_numbers()) {
		push @contents, sprintf("%s,%s",$number,$self->get_section(number => $number)->get_header());
	}
	return \@contents;
}


# grab all translation sections
sub get_translation_sections {
	my $self = shift;
	return $self->get_sections_of_type('Wiktionary::Parser::Section::Translations');
}

# grab all part of speech sections
sub get_part_of_speech_sections {
	my $self = shift;
	return $self->get_sections_of_type('Wiktionary::Parser::Section::PartofSpeech');
}

sub get_synonym_sections {
	my $self = shift;
	return $self->get_sections_of_type('Wiktionary::Parser::Section::Synonym');
}

sub get_hypernym_sections {
	my $self = shift;
	return $self->get_sections_of_type('Wiktionary::Parser::Section::Hypernym');
}

sub get_hyponym_sections {
	my $self = shift;
	return $self->get_sections_of_type('Wiktionary::Parser::Section::Hyponym');
}

sub get_pronunciation_sections {
	my $self = shift;
	return $self->get_sections_of_type('Wiktionary::Parser::Section::Pronunciation');
}


sub get_sections_of_type {
	my $self = shift;
	my $type = shift;
	my @sections;
	for my $number ($self->get_section_numbers()) {
		next unless $self->get_section(number => $number)->isa($type);
		push @sections, $self->get_section(number => $number);
	}
	return \@sections;
}


sub get_section_numbers {
	my $self = shift;
	return (sort {$a cmp $b} grep {$_} keys %{$self->{sections} || {}});
}


sub get_word_senses {
	my $self = shift;
	my %args = @_;

	# follow links to other wiktionary pages
	my $_meta_follow_links = defined($args{_meta_follow_links}) ? $args{_meta_follow_links} : 1;


	my $sections = $self->get_translation_sections();
	my @word_senses;
	for my $section (@{$sections || []}) {
		my $word_senses = $section->get_word_senses();

		for my $word_sense (@{$word_senses || []}) {

			if (my ($title) = $word_sense->get_word() =~ m/^wiktionary\:(.+)$/i) {
				if ($_meta_follow_links) {
					# get titles to linked pages
					# get translations from the linked document 
					my $linked_document = $self->get_parser()->get_document(title => $title);
					# set _meta_follow_links to 0, to ensure we don't end up in 
					# an endless loop if pages link back to each other
					my $linked_word_senses = $linked_document->get_word_senses(_meta_follow_links => 0);
					push @word_senses, @{$linked_word_senses};
				}

				next;
			}


			push @word_senses, $word_sense->get_word();
		}
	}

	return \@word_senses;
}

sub get_synonyms {
	my $self = shift;
	my %args = @_;
	return $self->get_classifications(
		class => 'Wiktionary::Parser::Section::Synonym',
	);
}

sub get_hyponyms {
	my $self = shift;
	my %args = @_;
	return $self->get_classifications(
		class => 'Wiktionary::Parser::Section::Hyponym',
	);
}

sub get_hypernyms {
	my $self = shift;
	my %args = @_;
	return $self->get_classifications(
		class => 'Wiktionary::Parser::Section::Hypernym',
	);
}

sub get_antonyms {
	my $self = shift;
	my %args = @_;
	return $self->get_classifications(
		class => 'Wiktionary::Parser::Section::Antonym',
	);
}


sub get_classifications {
	my $self = shift;
	my %args = @_;
	my $class = $args{class};

	if ($self->{"__get_${class}__"}) {
		return $self->{"__get_${class}__"};
	}

	my $sections = $self->get_sections_of_type($class);
	my %x_nyms;

	for my $section (@{$sections || []}) {
		my $x_nyms = $section->get_groups();
		for my $x_nym (@{$x_nyms || []}) {

			my $lang = $x_nym->{language};
			my $sense = $x_nym->{sense};

			my @lexemes = @{$x_nym->{lexemes} || []};


			my @full_word_list;
			while (my $lexeme = shift @lexemes) {


				# look for links to wikisaurus entries
				# and include content from those documents
				
				if ($lexeme =~ m/^Wikisaurus:/) {
					my $wikisaurus_document = $self->get_linked_document(title => $lexeme);
					my $ws_sections = $wikisaurus_document->get_sections(title => $section->get_header());

					for my $ws_section (@{$ws_sections || []}) {
						my $word_list = $ws_section->get_words();
						for my $word (@{$word_list || []}) {
							push @full_word_list, $word->{word};
						}
					}
				} else {
					push @full_word_list, $lexeme;
				}
			}

			push @{$x_nyms{$lang}{sense}{$sense}}, @full_word_list;
			$x_nyms{$lang}{language} ||= $self->get_language_mapper()->code2language($lang);

		}
	}

	$self->{"__get_${class}__"} = \%x_nyms;

	return \%x_nyms;
}

# return lists of words from the Derived Terms sections broken down by language
sub get_derived_terms {
	my $self = shift;
	my $class = 'Wiktionary::Parser::Section::DerivedTerms';
	my $sections = $self->get_sections_of_type($class);
	my %terms;
	for my $section (@{$sections || []}) {
		my $hr = $section->get_derived_terms();
		for my $language (keys %{$hr}) {
			push @{$terms{$language}}, @{$hr->{$language} || []}
		}
	}
	return \%terms;
}

# return all pronunciation metadata broken down by language
sub get_pronunciations {
	my $self = shift;
	my %args = @_;
	my $class = 'Wiktionary::Parser::Section::Pronunciation';

	my $sections = $self->get_sections_of_type($class);
	my %meta;
	my %seen;

	for my $section (@{$sections || []}) {

		{
			my $hr = $section->get_pronunciations();
			for my $lang (keys %{$hr}) {
				push @{$meta{$lang}{pronunciation}}, @{$hr->{$lang}};
				$meta{$lang}{language} ||= $self->get_language_mapper()->code2language($lang);
			}
		}

		{
			my $hr = $section->get_audio();
			for my $lang (keys %{$hr}) {
				# remove duplicates
				push @{$meta{$lang}{audio}}, grep {!$seen{audio}{$lang}{ $_->{file} }++} @{$hr->{$lang}};
				$meta{$lang}{language} ||= $self->get_language_mapper()->code2language($lang);
			}
		}

		{
			my $hr = $section->get_rhymes();
			for my $lang (keys %{$hr}) {
				push @{$meta{$lang}{rhyme}}, @{$hr->{$lang}};
				$meta{$lang}{language} ||= $self->get_language_mapper()->code2language($lang);
			}
		}

		{
			my $hr = $section->get_homophones();
			for my $lang (keys %{$hr}) {
				push @{$meta{$lang}{homophone}}, @{$hr->{$lang}};
				$meta{$lang}{language} ||= $self->get_language_mapper()->code2language($lang);
			}
		}

		{
			my $hr = $section->get_hyphenations();
			for my $lang (keys %{$hr}) {
				push @{$meta{$lang}{hyphenation}}, @{$hr->{$lang}};
				$meta{$lang}{language} ||= $self->get_language_mapper()->code2language($lang);
			}
		}


	}

	return \%meta;
}



sub get_parts_of_speech {
	my $self = shift;
	my %args = @_;

	if ($self->{__get_parts_of_speech__}) {
		return $self->{__get_parts_of_speech__};
	}

	my $sections = $self->get_part_of_speech_sections();

	my %parts_of_speech;
	for my $section (@{$sections || []}) {
		my $pos = $section->get_part_of_speech();
		my $lang_code = $section->get_language_code();
		next unless $pos && $lang_code;
		push @{$parts_of_speech{$lang_code}{part_of_speech}}, $pos;
		$parts_of_speech{$lang_code}{language} ||= get_language_mapper()->code2language($lang_code);

	}

	$self->{__get_parts_of_speech__} = \%parts_of_speech;
	return \%parts_of_speech;
}


sub get_translations {
	my $self = shift;
	my %args = @_;
	my $include_transliterations = defined($args{include_transliterations}) ? $args{include_transliterations} : 1;
	my $include_alternate_translations = defined($args{include_alternate_translations}) ? $args{include_alternate_translations} : 1;

	# follow links to other wiktionary pages
	my $_meta_follow_links = defined($args{_meta_follow_links}) ? $args{_meta_follow_links} : 1;

	my $sections = $self->get_translation_sections();
	my @word_senses;
	my %translations;

	for my $section (@{$sections || []}) {
		my $word_senses = $section->get_word_senses();

		for my $word_sense (@{$word_senses || []}) {
			my $word_sense_lexeme = $word_sense->get_word();
			my $translations = $word_sense->get_translations();

			# if we have a link to another page, download that page and merge its translation data
			if (my ($title) = $word_sense->get_word() =~ m/^wiktionary\:(.+)$/i) {
				
				if ($_meta_follow_links) {
					# get titles to linked pages
					# get translations from the linked document 

					my $linked_document = $self->get_parser()->get_document(title => $title);
					# set _meta_follow_links to 0, to ensure we don't end up in 
					# an endless loop if pages link back to each other

					my $linked_translations = {};
					if ($linked_document) {
						$linked_translations = $linked_document->get_translations(_meta_follow_links => 0);
					}

					for my $linked_word_sense (keys %$linked_translations) {
						for my $linked_lang_code (keys %{ $linked_translations->{$linked_word_sense} || {} }) {
							$translations{$linked_word_sense}{$linked_lang_code}{language} = $linked_translations->{$linked_word_sense}{$linked_lang_code}{language};
							push @{ $translations{$linked_word_sense}{$linked_lang_code}{translations} }, @{ $linked_translations->{$linked_word_sense}{$linked_lang_code}{translations} || []};
						}
					}
				}

				next;
			}



			for my $language (keys %{$translations || {}}) {

				my $language_code = $self->get_language_mapper()->language2code($language);
				my $normalized_language = $self->get_language_mapper()->code2language($language_code);

				my $lexemes = $translations->{$language};
				my %seen;
				for my $lexeme (@{$lexemes}) {
					my @translations = $lexeme->get_translations();

					# if the lexeme has a language code, use that to determine language
					my $tagged_language_code = $lexeme->get_language_code();
					if ($tagged_language_code) {
						$normalized_language = $self->get_language_mapper()->code2language($tagged_language_code) || $normalized_language;
						$language_code = $self->get_language_mapper()->language2code($normalized_language) || $tagged_language_code;
					}


					my $part_of_speech = $section->get_part_of_speech();
					

					if ($include_transliterations && $lexeme->get_transliteration()) {
						push @translations, $lexeme->get_transliteration();
					}
					if ($include_alternate_translations && $lexeme->get_alternate()) {
						push @translations, $lexeme->get_alternate();
					}

					for my $lex (sort @translations) {

						next unless defined $lex;
						unless (grep {$_ eq $lex} @{$translations{$word_sense_lexeme}{$language_code}{translations} || []}) {
							push @{$translations{$word_sense_lexeme}{$language_code}{translations}},$lex;
							$translations{$word_sense_lexeme}{$language_code}{language} ||= $normalized_language;
							$translations{$word_sense_lexeme}{$language_code}{part_of_speech} ||= $part_of_speech;

						}
					}
				}
			}
		}
	}

	return \%translations;
}

sub is_part_of_speech {
	my $self = shift;
	my $header = shift;
	return 1 if grep { $header =~ m/^$_$/i } qw(
		noun
		verb
		adjective
		adverb
		pronoun
		preposition
		article
		conjunction
		determiner
		interjection
		symbol
	);

	return 0;
}


# call the parser to download a page for a term in this document
sub get_linked_document {
	my $self = shift;
	my %args = @_;
	my $title = $args{title};

	$self->{linked_documents} ||= {};
	if ($self->{linked_documents}{$title}) {
		return $self->{linked_documents}{$title};
	}

	$self->debug("Getting Linked Page: $title");

	my $parser = $self->get_parser();
	return unless $parser;

	$self->{linked_documents}{$title} = $parser->get_document(title => $title);
	return $self->{linked_documents}{$title};
}

sub get_parser {
	my $self = shift;
	return $self->{parser};
}

sub get_language_mapper {
	my $self = shift;
	return $self->{language_map} ||= Wiktionary::Parser::Language->new();
}


# create a document object with a subset of sections
sub create_sub_document {
	my $self = shift;
	my %args = @_;
	my $sections = $args{sections} or die 'sections must be defined';
	return __PACKAGE__->new( sections => $sections, title => $self->get_title() );

}

sub debug {
	my $self = shift;
	return unless $self->{verbose};
	local $\ = "\n";
	local $, = ' ';
	print 'DEBUG:',@_;
}


sub add_category {
	my $self = shift;
	my %args = @_;
	my $category = $args{category};
	push @{$self->{categories}},$category;
}

sub add_language_link {
	my $self = shift;
	my %args = @_;
	my $tag = $args{tag};
	push @{$self->{language_links}},$tag;
}

sub get_language_links {
	my $self = shift;
	return $self->{language_links};
}

sub get_categories {
	my $self = shift;
	return $self->{categories};
}

# get the languages represented by sections in this document
sub get_section_languages {
	my $self = shift;
	my @languages;
	# get top level sections
	for my $number ($self->get_section_numbers()) {
		next if $number =~ m/\./;
		push @languages, $self->get_section(number => $number)->get_header();
	}	
	return \@languages;
}

1;
