package Web::VWF::Display::states;

# Display the states page: every row of states.csv, as a table.
# The rows come from the states data handle, which the framework passes to
# every page under the last part of the data module's name.

use strict;
use warnings;

use version; our $VERSION = version->declare('0.004.1');

use Carp;
use Web::VWF::Display;

our @ISA = ('Web::VWF::Display');

sub html {
	my $self = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	my $states = $args{'states'};
	croak("Missing 'states' handle") unless($states);

	# Sorted by name, as people look states up by name; the CSV is in the
	# order of the codes.  An empty database gives an empty list rather than
	# undef so the template can always loop over it.
	my $rows = $states->selectall_arrayref(sort_by => 'name') || [];

	return $self->SUPER::html(states => $rows);
}

1;

=encoding utf8

=head1 NAME

Web::VWF::Display::states - The example site's page of U.S. states

=head1 VERSION

Version 0.004.1

=head1 DESCRIPTION

Shows every row of the C<states> database (see L<Web::VWF::Data::states>) as a
table, sorted by name, in F<states.tmpl>.  Reached as C<?page=states>.

=head1 METHODS

=head2 html

Needs the C<states> data handle, which L<Web::VWF> passes to every page, and
croaks without it.

=head3 API SPECIFICATION

=head4 INPUT

	{ states => { type => 'object' } }

=head4 OUTPUT

	{ type => 'string' }

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2010-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
