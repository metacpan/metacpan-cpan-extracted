package Wiktionary::Parser::Section::Pronunciation;

use Wiktionary::Parser::Section;
use Wiktionary::Parser::Section::Pronunciation::Audio;
use Wiktionary::Parser::Section::Pronunciation::Representation;

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

	push @{$self->{content}}, $line;

	return unless $line;
	$line =~ s/^[\*\s]+//i;
	my @meta = $line =~ m/\{\{([^\}]+)\}\}/g;
	if (@meta) {
		my @context;
		my @senses;
		for my $meta (@meta) {
			my @parts = split(/\|/,$meta);

			if ($parts[0] eq 'sense') {
				if (@parts > 1) {
					push @senses, grep {$_ && $_ ne 'sense'} @parts
				}
			} elsif ($parts[0] eq 'a') {
				if (@parts > 1) {
					push @context, grep {$_ && $_ ne 'a'} @parts
				}
			} elsif ($parts[0] eq 'audio') {
				my $lang = $self->get_language();
				
				$self->add_audio(
					language => $lang,
					file => $parts[1],
					text => $parts[2],
					context => \@context,
					senses  => \@senses,			
				);
			} elsif ($parts[0] =~ m/(rhyme|homophone|hyphenation)/) {
				
				my $meta = $self->parse_template(@parts);
				$meta->{lang} ||= $self->get_language();

				$self->add_category(
					category => $1,
					language => $meta->{lang},
					representation => $meta->{representation},
					pronunciation => $meta->{pronunciation},
					context => \@context,
					senses  => \@senses,			
				);

			} else {
				my $meta = $self->parse_template(@parts);
				$meta->{lang} ||= $self->get_language();

				$self->add_pronunciation(
					language => $meta->{lang},
					representation => $meta->{representation},
					pronunciation => $meta->{pronunciation},
					context => \@context,
					senses  => \@senses,			
				);
			}
		}
	}
}

sub parse_template {
	my $self = shift;
	my @parts = @_;

	my %meta;
	my $representation;
	my $lang;
	my @pronunciation = [];
	for my $i (0..$#parts) {
		if ($parts[$i] =~ m/rhyme|homophone|hyphenation/) {
			
		} elsif ($parts[$i] =~ m/(IPA|enPR|AHD|SAMPA)/) {
			$meta{representation} = $parts[$i];
		} elsif ($parts[$i] =~ m/lang=(.+)/) {
			$meta{lang} = $1;
		} else {
			push @{$meta{pronunciation}}, $parts[$i];
		}
	}
	return \%meta;
}

sub add_pronunciation {
	my $self = shift;
	my %args = @_;

	my $meta = {};
	my $lang = $args{language} || '__language_undefined__';

	my $pronunciation = Wiktionary::Parser::Section::Pronunciation::Representation->new( 
		representation => $args{representation},
		pronunciation  => $args{pronunciation},
		context => $args{context},
	);
	push @{$self->{pronunciation}{$lang}},$pronunciation;
}


# rhyme, homophone, hyphenation entries
sub add_category {
	my $self = shift;
	my %args = @_;
	my $category = $args{category} or die 'category not defined';

	my $lang = $args{language} || '__language_undefined__';
	my $meta = {};
	my $item = Wiktionary::Parser::Section::Pronunciation::Representation->new( 
		representation => $args{representation},
		pronunciation  => $args{pronunciation},
		context => $args{context},
		senses => $args{senses},
	);
	push @{$self->{$category}{$lang}},$item;
}


sub add_audio {
	my $self = shift;
	my %args = @_;
	my $lang = $args{language} || '__language_undefined__';

	my $audio = Wiktionary::Parser::Section::Pronunciation::Audio->new(
		file    => $args{file},
		text    => $args{text},
		context => $args{context},
	);

	push @{$self->{audio}{$lang}}, $audio;
}

sub get_pronunciations {
	my $self = shift;
	return $self->{pronunciation};
}

sub get_audio {
	my $self = shift;
	return $self->{audio};
}

sub get_rhymes {
	my $self = shift;
	return $self->{rhyme}
}

sub get_homophones{
	my $self = shift;
	return $self->{homophone}
}

sub get_hyphenations{
	my $self = shift;
	return $self->{hyphenation}
}

1;
