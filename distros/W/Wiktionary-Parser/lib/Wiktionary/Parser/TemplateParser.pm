package Wiktionary::Parser::TemplateParser;

use strict;
use warnings;
use Data::Dumper;

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless \%args, $class;
	return $self;
}

# given a line of text, extract the content of each template
sub extract_templates {
	my $self = shift;
	my %args = @_;
	my $line = $args{line};

	my @templates = $line =~ m/\{\{([^\}]+)\}\}/g;

	return @templates;
}

sub extract_tokens {
	my $self = shift;
	my %args = @_;
	my $line = $args{line};

	my @tokens = $line =~ m/\[\[([^\]]+)\]\]/g;

	return @tokens;
}


sub parse_template {
	my $self = shift;
	my %args = @_;
	my $template = $args{template};

	my @parts = split(/\|/,$template);

	my $template_type = shift @parts;
	$template_type =~ s/\s+/_/g;
	my $template_parsing_method = "template_$template_type";

	my $meta = {};
	if ($self->can($template_parsing_method)) {
		$meta = $self->$template_parsing_method(@parts);
	} elsif (@parts) {
		$meta = { content => \@parts };
	}

	$meta->{template_type} = $template_type;

	return $meta;
}

sub template_ws_beginlist {
	my $self = shift;
	return {meta => 'begin'};
}

sub template_ws_endlist {
	my $self = shift;
	return {meta => 'end'};
}


sub template_ws_sense {
	my ($self, @parts) = @_;
	my %meta;
	for my $part (@parts) {
		push @{$meta{sense}}, $part;
	}
	return \%meta;
}

sub template_ws {
	my ($self, @parts) = @_;
	my %meta;
	$meta{word} = $parts[0];
	$meta{gloss} = $parts[-1] if scalar @parts > 1;
	return \%meta;
}

sub template_l {
	my ($self, @parts) = @_;
	my %meta;
	$meta{lang} = $parts[0];
	$meta{word} = $parts[1];
}


1;
