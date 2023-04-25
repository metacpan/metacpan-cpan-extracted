package Wikibase::Datatype::Print::Mediainfo;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Print::MediainfoStatement;
use Wikibase::Datatype::Print::Utils qw(print_descriptions print_labels
	print_statements);
use Wikibase::Datatype::Print::Value::Monolingual;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.12;

sub print {
	my ($obj, $opts_hr) = @_;

	if (! defined $opts_hr) {
		$opts_hr = {};
	}

	if (! exists $opts_hr->{'lang'}) {
		$opts_hr->{'lang'} = 'en';
	}

	if (! $obj->isa('Wikibase::Datatype::Mediainfo')) {
		err "Object isn't 'Wikibase::Datatype::Mediainfo'.";
	}

	my @ret = (
		defined $obj->id ? 'Id: '.$obj->id : (),
		defined $obj->title ? 'Title: '.$obj->title : (),
		defined $obj->ns ? 'NS: '.$obj->ns : (),
		defined $obj->lastrevid ? 'Last revision id: '.$obj->lastrevid : (),
		defined $obj->modified ? 'Date of modification: '.$obj->modified : (),
		defined $obj->page_id ? 'Page ID: '.$obj->page_id : (),
	);

	# Label.
	push @ret, print_labels($obj, $opts_hr,
		\&Wikibase::Datatype::Print::Value::Monolingual::print);

	# Description.
	push @ret, print_descriptions($obj, $opts_hr,
		\&Wikibase::Datatype::Print::Value::Monolingual::print);

	# Statements.
	push @ret, print_statements($obj, $opts_hr,
		\&Wikibase::Datatype::Print::MediainfoStatement::print);

	return wantarray ? @ret : (join "\n", @ret);
}

1;

__END__
