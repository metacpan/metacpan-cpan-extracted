package Test::Shared::Fixture::Wikibase::Datatype::MediainfoStatement::Commons::Depicts::Human;

use base qw(Wikibase::Datatype::MediainfoStatement);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::MediainfoSnak::Commons::Depicts::Human;

our $VERSION = 0.24;

sub new {
	my $class = shift;

	my @params = (
		'snak' => Test::Shared::Fixture::Wikibase::Datatype::MediainfoSnak::Commons::Depicts::Human->new,
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__
