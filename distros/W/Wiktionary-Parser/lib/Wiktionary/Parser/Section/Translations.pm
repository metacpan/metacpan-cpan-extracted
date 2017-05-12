package Wiktionary::Parser::Section::Translations;

use Wiktionary::Parser::Section;
use Wiktionary::Parser::Section::Translations::WordSense;
use Wiktionary::Parser::Section::Translations::WordSense::Lexeme;

use base qw(Wiktionary::Parser::Section);

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless Wiktionary::Parser::Section->new(%args), $class;
	return $self;
}


sub get_templates {
	return [
		{
		 # e.g. {{trans-bottom}}
		 pattern => qr/{{trans-bottom}}/,
		 parser => sub { return { meta => 'end_word_sense' } }
		},
		{
		 # comma - separates different blocks of words+metadata
		 pattern => qr/[,;\.]/,
		 parser => sub { return {meta => 'end_segment' } },
		},
		{
		 # e.g. * Swedish: ...
		 pattern => qr/\*\:?\s([^\:]+)\:\s*/,
		 parser  => \&template_language,
		},
		{
		 # e.g. {{trans-top|colour}}
		 pattern => qr/{{trans-top\|([^}]+)/,
		 parser => sub { return { word_sense => $_[-1] } }
		},

		{
		 # e.g. {{trans-see|apples and pears (''Cockney rhyming slang'')|apples and pears}}
		 pattern => qr/{{trans-see\|([^}]+)}}/,
		 parser  =>\&template_trans_see,
		},

		{
		 # e.g. {{tø|arz|برتقان|tr=burtuʕaan|sc=Arab|xs=Egyptian Arabic}}
		 pattern => qr/{{t[^\|]*\|([^}]+)}}/,
		 parser => \&template_t,
		},
		{
		 # e.g. {{ku-Arab|[[پرته‌قاڵ]]
		 pattern => qr/{{(\w{2}\-Arab\|[^}]+)}/,
		 parser => \&template_t,
		},
		{
		 # e.g. {{qualifier|Dominican Republic|Puerto Rico}
		 pattern => qr/{{qualifier\|([^\}]+)}}/,
		 parser => \&template_qualifier,
		},
		{
		 # e.g. [[כלבא]] (kalbā’) {{m}}
		 pattern => qr/\[\[([^\]]+)\]\]\s+\(([^\)]+)\)\s+{{(\w)}}/,
		 parser => \&template_4,
		},
		{
		 # e.g. [[oranževec]] {{m}}
		 pattern => qr/\[\[([^\]]+)\]\]\s*{{(\w)}}/,
		 parser => \&template_2
		},
		{
		 # e.g.  (narangi) {{f}}
		 pattern => qr/\(([^\]]+)\)\s*{{(\w)}}/,
		 parser => \&template_2
		},
		{
		 # e.g. [[colore de aranzu]], [[ruggiu]], [[ruiu]], [[arrubiu]]
		 pattern => qr/\[\[([^\]]+)\]\]/,
		 parser => \&template_3
		},
		{
		 # e.g. ''(collective)''
		 pattern => qr/\'\'([^\']+)\'\'/,
		 parser => \&template_q,
		},

		# run this last - just chop a character off if nothing else matches;
		{
		 pattern => qr/./,
		 parser => sub { return {meta => 'unparsable'} }
		}

	];
}

sub template_q {
	my $self = shift;
	my $template = shift;
	$template =~ s/[\[\]\(\)]//g;
	return { qualifier => [$template] };
}

sub template_qualifier {
	my $self = shift;
	my $template = shift;
	my @parts = split(/\|/,$template);
	$self->clean_tokens(@parts);
	return {qualifier => \@parts}
}

sub template_language { 
	my $self = shift;
	my $language = shift;
	$self->clean_tokens($language);
	return { language => $language } 
}

# parse the trans-see template into its parts
# http://en.wiktionary.org/wiki/Template:trans-see
sub template_trans_see {
	my $self = shift;
	my ($title) = shift;
	
	my @params = split(/\|/,$title,2);

	# {{trans-see|that}}
	if ($params[0] && scalar @params == 1) {
		$self->clean_tokens(@params);
		return {
			word_sense => "wiktionary:$params[0]",
			meta       => 'wiktionary_link',
		}
	} 

	# {{trans-see|rally|[[rally#Etymology 2|rally]]}}
	if (my $link_meta = $params[1] =~ m/\[\[([^\]]+)\]\]/) {
		my @link_params = split(/\|/, $1);
		my $link;
		# grab the last value if there's more than one entry
		if (scalar @link_params > 1) {
			$link = $link_params[-1];
		} else {
			$link = shift @link_params;
		}

		$link =~ s/\#.+$//;

		return {
			word_sense => "wiktionary:$link",
			meta       => 'wiktionary_link',
		}
	}

	# {{trans-see|Nahuatl language|Nahuatl}}
	if ($params[1]) {
		my $link = $params[1];
		$link =~ s/\#.+$//;
		return {
			word_sense => "wiktionary:$link",
			meta       => 'wiktionary_link',
		}
	}

	return;
}

sub template_t {
	my $self = shift;
	my $template = shift;
	my @parts = split(/\|/,$template);
	my %meta;
	$meta{language_code} = shift @parts;
	my $translation = shift @parts;
	$translation ||= '';
	my @tokens = $translation =~ m/\[\[([^\]]+)\]\]/g;
	$translation =~ s/\[\[([^\]]+)\]\]//g;
	push @tokens, $translation; 
	
	$meta{translations} = [ grep { length($_) }@tokens ];
	for my $token (@parts) {
		if ($token =~ m/^[fmcn]$/) {
			# f: fem.
			# m: masc.
			# c: common
			# n: neut.
			$meta{gender} = $token;
		} elsif ($token =~ m/^[sp]$/) {
			# s: singular
			# p: plural
			$meta{number} = $token;
		} elsif ($token =~ m/^tr=(.+)/) {
			$meta{transliteration} = $1;
		} elsif ($token =~ m/^sc=(.+)/) {
			$meta{script_code_template} = $1;
		} elsif ($token =~ m/^alt=(.+)/) {
			$meta{alternate} = $1;
		} elsif ($token =~ m/^xs=(.+)/) {
			$meta{xs} = $1;
		}


	}

	return \%meta;
}

sub template_2 {
	my $self = shift;
	my @parts = @_;
	my %meta;
	my $translation = shift @parts;

	my @tokens = $translation =~ m/\[\[([^\]]+)\]\]/g;
	$translation =~ s/\[\[([^\]]+)\]\]//g;
	push @tokens, $translation; 
	$meta{translations} = \@tokens;

	$meta{gender} = shift @parts;
	return \%meta;
}

sub template_3 {
	my $self = shift;
	my @parts = @_;
	$self->clean_tokens(@parts);
	my %meta;
	$meta{translations} = \@parts;
	return \%meta;
}


sub template_4 {
	my $self = shift;
	my @parts = @_;
	$self->clean_tokens(@parts);
	my %meta;
	
	$meta{translations} = [shift @parts];
	$meta{transliteration} = shift @parts;
	my $gp = shift @parts;
	if ($gp =~ m/[mfcn]/) {
		$meta{gender} = $gp;
	} elsif ($gp =~ m/[ps]/) {
		$meta{number} = $gp;
	}

	return \%meta;
}

sub clean_tokens {
	my $self = shift;
	for (@_) {
		$_ =~ s/[\[\]\(\)]//g;
	}
}


# add a line of content to this section and parse it into its meaningful parts
sub add_content {
	my $self = shift;
	my $line = shift;

	# TODO:  template parsing issues
	#  {{qualifier|...}}
	# 

	my $line_copy = $line; # #$line is getting disembowled below
	push @{$self->{content}}, $line_copy;
	my $lexeme = Wiktionary::Parser::Section::Translations::WordSense::Lexeme->new();

	while (my $meta = $self->get_template_match($line)) {
		next unless defined $meta;

		if ($meta->{word_sense}) {
			# start new lexeme
			if ($self->get_current_word_sense()) {
				$self->get_current_word_sense()->add_lexeme($lexeme);
				$lexeme = Wiktionary::Parser::Section::Translations::WordSense::Lexeme->new();
			}
			my $word_sense = Wiktionary::Parser::Section::Translations::WordSense->new(
				word_sense => $meta->{word_sense},
			);
			$self->add_word_sense($word_sense);
			$self->set_current_word_sense($word_sense);
			next;
		}

		if ($meta->{meta} && $meta->{meta} eq 'end_word_sense') {
			$self->set_current_word_sense(undef);
		}

		if ($meta->{meta} && $meta->{meta} eq 'end_segment') {
			if ($self->get_current_word_sense()) {
				$self->get_current_word_sense()->add_lexeme($lexeme);
			}
			my $_lexeme = Wiktionary::Parser::Section::Translations::WordSense::Lexeme->new();
		}


		$lexeme->add_translations(@{$meta->{translations} || []}) if ($meta->{translations});
		$lexeme->set_gender($meta->{gender}) if ($meta->{gender});
		$lexeme->set_number($meta->{number}) if ($meta->{number});
		$lexeme->set_transliteration($meta->{transliteration}) if ($meta->{transliteration});
		$lexeme->set_alternate($meta->{alternate}) if ($meta->{alternate});

		$lexeme->add_qualifiers(@{$meta->{qualifier} || [] }) if $meta->{qualifier};

		$lexeme->set_language_name($meta->{language}) if $meta->{language};
		$lexeme->set_language_code($meta->{language_code}) if $meta->{language_code};

	}
	
	if ($self->get_current_word_sense() && $lexeme) {
		$self->get_current_word_sense()->add_lexeme($lexeme);
	}
}
# find the template pattern that matches the beginning of the given line
sub get_template_match {
	my $self = shift;

	my $templates = $self->get_templates();
	
	for my $template (@$templates) {

		my $pattern = $template->{pattern};
		my $parser  = $template->{parser};

		if (my @matches = $_[0] =~ m/^$pattern/) {
			# if there's a match parse extracted string into a hash of metadata
			my $meta = $parser->($self,@matches);
			
			# remove the matched piece from the line
			$_[0] =~ s/$pattern//;
			$_[0] =~ s/^\s*//;
			return $meta;
		}
	}
	return;
}

sub add_word_sense {
	my $self = shift;
	my $word_sense = shift;
	my $sense = $word_sense->get_word();
	$self->{word_senses}{$sense} = $word_sense;
}

sub get_word_sense {
	my $self = shift;
	my $sense = shift;
	return $self->{word_senses}{$sense};
}


sub get_word_senses {
	my $self = shift;
	return [values %{$self->{word_senses} || {}}];
}

sub set_current_word_sense {
	my $self = shift;
	$self->{current_word_sense} = shift;
}

sub get_current_word_sense {
	my $self = shift;
	return $self->{current_word_sense};
}
1;
