package Wikibase::Datatype::Print::Sense;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Print::Statement;
use Wikibase::Datatype::Print::Utils qw(print_glosses print_statements);
use Wikibase::Datatype::Print::Value::Monolingual;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.07;

sub print {
	my ($obj, $opts_hr) = @_;

	if (! $obj->isa('Wikibase::Datatype::Sense')) {
		err "Object isn't 'Wikibase::Datatype::Sense'.";
	}

	# Id.
	my @ret = (
		'Id: '.$obj->id,
	);

	# Glosses.
	push @ret, print_glosses($obj, $opts_hr,
		\&Wikibase::Datatype::Print::Value::Monolingual::print);

	# Statements.
	push @ret, print_statements($obj, $opts_hr,
		\&Wikibase::Datatype::Print::Statement::print);

	return wantarray ? @ret : (join "\n", @ret);
}

1;

__END__
