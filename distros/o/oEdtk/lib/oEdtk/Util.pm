package oEdtk::Util;

use strict;
use warnings;

our $VERSION   = 2.1129;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(_uc_hash_keys);

# Convert all hash keys to uppercase, useful
# because PostgreSQL returns column names in lowercase.
#
# XXX This function is no longer used now that we set
# the 'FetchHashKeyName' option to 'NAME_uc' in DBAdmin.pm.
sub _uc_hash_keys {
	my $hash = shift;

	$hash->{ uc $_ } = delete $hash->{$_} for keys %$hash;
	return $hash;
}

1;

=head1 NAME

oEdtk::Util - small one-off utility helpers

=head1 SYNOPSIS

    use oEdtk::Util qw(_uc_hash_keys);

    my $h = { name => 'x', len => 3 };
    _uc_hash_keys($h);   # { NAME => 'x', LEN => 3 }

=head1 DESCRIPTION

Holds small standalone helpers that do not belong to a larger module. The
current helper uppercases the keys of a column-name hash; it is kept for
compatibility.

=head1 FUNCTIONS

=head2 _uc_hash_keys

    my $hash = _uc_hash_keys($hash);

Uppercase every key of the hash reference C<$hash> in place and return it. It
was used to normalise the lowercase column names returned by PostgreSQL; it is
no longer needed now that C<oEdtk::DBAdmin> sets the C<FetchHashKeyName>
option to C<NAME_uc>.

=head1 AUTHOR

The oEdtk team.

=cut
