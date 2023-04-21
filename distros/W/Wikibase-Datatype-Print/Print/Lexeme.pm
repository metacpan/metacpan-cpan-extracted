package Wikibase::Datatype::Print::Lexeme;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Print::Form;
use Wikibase::Datatype::Print::Sense;
use Wikibase::Datatype::Print::Statement;
use Wikibase::Datatype::Print::Utils qw(print_forms print_senses print_statements);
use Wikibase::Datatype::Print::Value::Monolingual;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.09;

sub print {
	my ($obj, $opts_hr) = @_;

	if (! defined $opts_hr) {
		$opts_hr = {};
	}

	if (! $obj->isa('Wikibase::Datatype::Lexeme')) {
		err "Object isn't 'Wikibase::Datatype::Lexeme'.";
	}

	my @ret = (
		'Title: '.$obj->title,
	);

	# Lemmas.
	my ($lemma) = @{$obj->lemmas};
	if (defined $lemma) {
		push @ret, 'Lemmas: '.
			Wikibase::Datatype::Print::Value::Monolingual::print($lemma, $opts_hr);
	}

	# Language.
	if ($obj->language) {
		push @ret, (
			'Language: '.$obj->language,
		);
	}

	# Lexical category.
	if ($obj->lexical_category) {
		push @ret, (
			'Lexical category: '.$obj->lexical_category,
		);
	}

	# Statements.
	push @ret, print_statements($obj, $opts_hr,
		\&Wikibase::Datatype::Print::Statement::print);

	# Senses.
	push @ret, print_senses($obj, $opts_hr,
		\&Wikibase::Datatype::Print::Sense::print);

	# Forms.
	push @ret, print_forms($obj, $opts_hr,
		\&Wikibase::Datatype::Print::Form::print);

	return wantarray ? @ret : (join "\n", @ret);
}

1;

__END__
