package Web::VWF::Data::states;

# The database associated with the states page: states.csv in the database
# directory, one row for each of the 50 U.S. states.
#
# The file is a standard comma-separated file with a header line, which is
# not what Database::Abstraction assumes (it defaults to "!" as the separator
# and to a key column called "entry"), so both are set here.  The key column
# is "state", the two letter code, so a single state can be fetched with
#	$states->fetchrow_hashref(state => 'NY')

use strict;
use warnings;

use Database::Abstraction;

use version; our $VERSION = version->declare('0.003.1');

our @ISA = ('Database::Abstraction');

sub new {
	my $class = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	# Caller's arguments come last so a site can still override either setting
	return $class->SUPER::new(id => 'state', sep_char => ',', %args);
}

1;

=encoding utf8

=head1 NAME

Web::VWF::Data::states - The example site's database of U.S. states

=head1 VERSION

Version 0.003.1

=head1 DESCRIPTION

A L<Database::Abstraction> over F<example/data/states.csv>, which has a header
line and one row for each of the 50 states: C<state> (the two letter code, which
is the key), C<abbreviation> and C<name>.  It is the example of a data module in
a site's own directory, which L<Web::VWF/CONFIGURATION> describes.  Unlike
L<Web::VWF::Data::index> the file is comma separated.

	my $row = $states->fetchrow_hashref(state => 'NY');	# { state => 'NY', ..., name => 'New York' }

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2010-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
