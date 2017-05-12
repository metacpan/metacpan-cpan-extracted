package Wiktionary::Parser::Language;
# 
# map language name to language code
#
use strict;
use warnings;
use Data::Dumper;

use Locale::Codes::Language qw();
use Locale::Codes::Constants;
use Text::Unidecode qw();


my $NAME_MAP;

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless \%args, $class;

	$self->_build_name_map();

	return $self;
}

sub _build_name_map {
	my $self = shift;
	return if $NAME_MAP;

	# other language name variations used on wiktionary.
	# mapped to language names used in Locale::Codes::Language
	my %name_map = (
		'min nan'  => 'Min Nan Chinese',
		'slovene'  => 'Slovenian',
		'rapa nui' => 'Rapanui',
		'acholi'   => 'Acoli',
		'west frisian' => 'Western Frisian',
		'romansch' => 'romansh',
		'romanche' => 'romansh',
		'mandarin' => 'Mandarin Chinese',
		'ojibwe'   => 'Ojibwa',
		'khmer'    => 'Central Khmer',
		'tuvan'    => 'Tuvinian',
		'sotho'    => 'Southern Sotho',
		'buryat'   => 'Buriat',
		'azeri'    => 'Azerbaijani',
		'taos'     => 'Northern Tiwa',
 	);

	my @all_names =  Locale::Codes::Language::all_language_names();
	my @all_names_3 = Locale::Codes::Language::all_language_names(Locale::Codes::Constants::LOCALE_LANG_ALPHA_3);

	for my $name (@all_names,@all_names_3) {
		next unless $name =~ m/\(/;
		my $sanitized_name = lc $name;
		$sanitized_name =~ s/\s*\(.+$//;
		$name_map{$sanitized_name} = $name;
	}
	
	$NAME_MAP = \%name_map;
}

# languages without ISO codes used on wiktionary.
# codes here either come from wiktionary itself, or linguist list
sub custom_codes {
	# http://en.wikipedia.org/wiki/Category:Languages_without_ISO_639-3_code_but_with_Linguist_List_code
	return {
		'jerriais'  => 'roa-jer', # roa-jer in wiktionary, fra-jer in linguist list...
		'tarantino' => 'roa-tar',
		'elfdalian' => 'qer',
		'cyrillic' => 'cyrl', # ISO 15924
		'translingual' => 'translingual',
	};
}

sub get_sanitized_language_name {
	my $self = shift;
	my $name = lc shift;
	my $unidecoded_name = Text::Unidecode::unidecode($name);
	return $unidecoded_name;
}

# return the code for the given language
sub language2code {
	my $self = shift;
	my $language_name = $self->get_sanitized_language_name(shift);

	my $code = Locale::Codes::Language::language2code(
		$language_name,
		Locale::Codes::Constants::LOCALE_LANG_ALPHA_2,
	);

	return $code if $code;

	$code = Locale::Codes::Language::language2code(
		$NAME_MAP->{$language_name},
		Locale::Codes::Constants::LOCALE_LANG_ALPHA_2,
	);



	return $code if $code;

	$code = Locale::Codes::Language::language2code(
		$language_name,
		Locale::Codes::Constants::LOCALE_LANG_ALPHA_3,
	);

	return $code if $code;

	$code = Locale::Codes::Language::language2code(
		$NAME_MAP->{$language_name},
		Locale::Codes::Constants::LOCALE_LANG_ALPHA_3,
	);

	return $code if $code;

	$code = $self->custom_codes()->{$language_name};

	return $code if $code;

	#print STDERR "$language_name has no code\n";

	return $language_name;
}

sub code2language {
	my $self = shift;
	my $code = shift;

	my $name;
	if (length($code) == 2) {
		$name = Locale::Codes::Language::code2language(
			$code,
			Locale::Codes::Constants::LOCALE_LANG_ALPHA_2,
		);
	} elsif (length($code) == 3) {
		$name = Locale::Codes::Language::code2language(
			$code,
			Locale::Codes::Constants::LOCALE_LANG_ALPHA_3,
		);
	}
	
	return $name if $name;

	my %custom_names = reverse %{$self->custom_codes()};
	return $custom_names{$code} || $name;
}

1;
