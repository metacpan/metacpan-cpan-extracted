package Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Human;

use base qw(Wikibase::Datatype::Item);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::Human;
use Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::SexOrGender::Male;

sub new {
	my $class = shift;

	my @params = (
		'statements' => [
			Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::InstanceOf::Human->new,
			Test::Shared::Fixture::Wikibase::Datatype::Statement::Wikidata::SexOrGender::Male->new,
		],
#		'lastrevid' => 1428556087,
#		'title' => 'Q42',
		# TODO
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
