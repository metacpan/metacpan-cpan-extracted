package
	forks::BerkeleyDB::ElemNotExists;	#hide from PAUSE

$VERSION = 0.060;
use strict;
use warnings;

my $instance = __PACKAGE__->_new();

sub _new {
	my $type = shift;
	return CORE::bless(\do { my $o }, ref($type) || $type);
}

sub instance {
	return $instance;
}

1;
