package oEdtk::Util;

use strict;
use warnings;

our $VERSION	= 2.1109;
our @ISA	= qw(Exporter);
our @EXPORT_OK	= qw(_uc_hash_keys);

# Convert all hash keys to uppercase, useful
# because PostgreSQL returns column names in lowercase.
#
# XXX This function is no longer used now that we set
# the 'FetchHashKeyName' option to 'NAME_uc' in DBAdmin.pm.
sub _uc_hash_keys {
	my $hash = shift;

	$hash->{uc $_} = delete $hash->{$_} for keys %$hash;
	return $hash;
}

1;
