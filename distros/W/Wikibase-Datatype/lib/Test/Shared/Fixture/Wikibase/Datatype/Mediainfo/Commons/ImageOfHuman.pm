package Test::Shared::Fixture::Wikibase::Datatype::Mediainfo::Commons::ImageOfHuman;

use base qw(Wikibase::Datatype::Mediainfo);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::MediainfoStatement::Commons::Depicts::Human;
use Wikibase::Datatype::Value::Monolingual;

our $VERSION = 0.21;

sub new {
	my $class = shift;

	my @params = (
		'descriptions' => [
		],
		'id' => 'M10031710',
		'labels' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'Portrait of Douglas Adams',
			),
		],
		'lastrevid' => 617544224,
		'modified' => '2021-12-30T08:38:29Z',
		'ns' => 6,
		'pageid' => 10031710,
		'statements' => [
			Test::Shared::Fixture::Wikibase::Datatype::MediainfoStatement::Commons::Depicts::Human->new,
		],
		'title' => 'File:Douglas adams portrait cropped.jpg',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
