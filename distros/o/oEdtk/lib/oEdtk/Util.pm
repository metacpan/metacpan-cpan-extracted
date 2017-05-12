package oEdtk::Util;

use strict;
use warnings;

our $VERSION	= 0.01;
our @ISA	= qw(Exporter);
our @EXPORT_OK	= qw(_uc_hash_keys);

# Conversion de toutes les clefs d'un hash en majuscule, utile
# car PostgreSQL retourne les noms de colonnes en minuscule.
#
# XXX Cette fonction n'est plus utilisée maintenant qu'on set
# l'option 'FetchHashKeyName' à 'NAME_uc' dans DBAdmin.pm.
sub _uc_hash_keys {
	my $hash = shift;

	$hash->{uc $_} = delete $hash->{$_} for keys %$hash;
	return $hash;
}

1;
