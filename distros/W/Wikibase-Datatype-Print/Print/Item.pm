package Wikibase::Datatype::Print::Item;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Print::Sitelink;
use Wikibase::Datatype::Print::Statement;
use Wikibase::Datatype::Print::Utils qw(print_aliases print_descriptions
	print_labels print_sitelinks print_statements);
use Wikibase::Datatype::Print::Value::Monolingual;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.09;

sub print {
	my ($obj, $opts_hr) = @_;

	if (! defined $opts_hr) {
		$opts_hr = {};
	}

	if (! exists $opts_hr->{'lang'}) {
		$opts_hr->{'lang'} = 'en';
	}

	if (! $obj->isa('Wikibase::Datatype::Item')) {
		err "Object isn't 'Wikibase::Datatype::Item'.";
	}

	my @ret;

	# Label.
	push @ret, print_labels($obj, $opts_hr,
		\&Wikibase::Datatype::Print::Value::Monolingual::print);

	# Description.
	push @ret, print_descriptions($obj, $opts_hr,
		\&Wikibase::Datatype::Print::Value::Monolingual::print);

	# Aliases.
	push @ret, print_aliases($obj, $opts_hr,
		\&Wikibase::Datatype::Print::Value::Monolingual::print);

	# Sitelinks.
	push @ret, print_sitelinks($obj, $opts_hr,
		\&Wikibase::Datatype::Print::Sitelink::print);

	# Statements.
	push @ret, print_statements($obj, $opts_hr,
		\&Wikibase::Datatype::Print::Statement::print);

	return wantarray ? @ret : (join "\n", @ret);
}

1;

__END__
