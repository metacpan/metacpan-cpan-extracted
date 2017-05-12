package Wiktionary::Parser::Section::PartofSpeech;

use Wiktionary::Parser::Section;

use base qw(Wiktionary::Parser::Section);

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless Wiktionary::Parser::Section->new(%args), $class;

	# in some poorly formatted sections, 
	# we can still get the part of speech and language from section headers
	# if they are not defined in markup
	$self->set_part_of_speech($self->get_header());
	$self->set_language_code($self->get_language());
	return $self;
}

# add a line of content to this section and parse it into its component parts
sub add_content {
	my $self = shift;
	my $line = shift;
	
	if ($line =~ m/^\{\{([^\}]+)\}\}/) {
		my $header_meta = $1;
		my @meta_parts = split(/\|/,$header_meta);
		
		# e.g. {{head|en|noun}}
		if ($meta_parts[0] eq 'head') {
			$self->set_language_code($meta_parts[1]);
			$self->set_part_of_speech($meta_parts[2])


		} elsif ($meta_parts[0] =~ m/^(\w+)\-(\w+)-(\w+)\|?/) {
			# {{roa-jer-noun|...
			$self->set_language_code($1);
			$self->set_part_of_speech($3);
			$self->set_inflection([@meta_parts[1..-1]]);

		} elsif ($meta_parts[0] =~ m/^(\w+)\-(\w+)/) {
			# e.g. {{en-noun|...}}
			$self->set_language_code($1);
			$self->set_part_of_speech($2);
			$self->set_inflection([@meta_parts[1..-1]]);
		}
	}
	
	push @{$self->{content}}, $line;
}

sub set_part_of_speech {
	my $self = shift;
	$self->{part_of_speech} = shift;
}

sub get_part_of_speech {
	my $self = shift;
	return $self->{part_of_speech};
}


sub set_language_code {
	my $self = shift;
	$self->{language_code} = shift;
}

sub get_language_code {
	my $self = shift;
	return $self->{language_code};
}

sub set_inflection {
	my $self = shift;
	$self->{inflection} = shift;
}

sub get_inflection {
	my $self = shift;
	return $self->{inflection};
}



1;
