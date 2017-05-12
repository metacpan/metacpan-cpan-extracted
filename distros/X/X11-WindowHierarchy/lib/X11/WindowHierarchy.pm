package X11::WindowHierarchy;
# ABSTRACT: Retrieve information from X11 windows
use strict;
use warnings;
use parent qw(Exporter);

our $VERSION = '0.004';

=head1 NAME

X11::WindowHierarchy - wrapper around L<X11::Protocol> for retrieving the current window hierarchy

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 use X11::WindowHierarchy;

 # Returns a list of all windows with at least one 'word' character in the
 # window title, using the current $ENV{DISPLAY} to select the display and
 # screen
 my @windows = x11_filter_hierarchy(
    filter => qr/\w/
 );
 printf "Found window [%s] (id %d)%s\n", $_->{title}, $_->{id}, $_->{pid} ? ' pid ' . $_->{pid} : '' for @windows;

 # Dump all information we have about all windows on display :1
 use Data::TreeDumper;
 print DumpTree(x11_hierarchy(display => ':1'));

=head1 DESCRIPTION

Provides a couple of helper functions based on L<X11::Protocol> for
extracting the current window hierarchy.

=cut

use X11::Protocol;

our @EXPORT_OK = qw(x11_hierarchy x11_filter_hierarchy);
our @EXPORT    = qw(x11_hierarchy x11_filter_hierarchy);

=head1 FUNCTIONS

The following functions are exported by default, to avoid this:

 use X11::WindowHierarchy qw();

=cut

=head2 x11_hierarchy

Returns a hashref representing the current window hierarchy.

Takes the following named parameters, all of which are optional:

=over 4

=item * display - DISPLAY string, such as ':0'

=item * screen - the screen to use, such as 0 or 1

=back

Returns a hashref structure which contains the following keys:

=over 4

=item * id - the ID for this window

=item * parent - the ID for the parent window

=item * pid - the process ID for this window, if it has one

=item * title - the window name, with any vertical whitespace (such as \n) converted to a single space

=item * icon_name - the icon name

=item * children - an arrayref of any child windows under this

=back

=cut

sub x11_hierarchy {
	my %args = @_;

	# Only pass display if we have it
	my $x = X11::Protocol->new(exists $args{display} ? (delete $args{display}) : ());
	my $screen = delete $args{screen} || 0;

	# Tree walker
	my $code; $code = sub {
		# We get a window ID.
		my $win = shift;

		# Extract all the properties we can
		my %props = map {
			# not entirely sure of the correct parameters for the API here, but, uh... "seems to work"
			$_->[0] => ($x->GetProperty($win, $_->[1], 'AnyPropertyType', 0, 255))[0]
		} map [
			# pretty sure this only returns a scalar, and if it doesn't then we'll break in other ways,
			# but the tests will save us!
			$_ => scalar $x->atom($_, 1)
		], qw(
			_NET_WM_ICON_NAME
			_NET_WM_NAME
			_NET_WM_PID
		);

		# Get all the geometry info apart from the root, since we know that already
		my %geom = $x->GetGeometry($win);
		delete $geom{root};
		@props{keys %geom} = values %geom;

		# Apply our ID
		$props{id} = $win;

		# Grab the pid if we have it
		if(my $pid = delete $props{_NET_WM_PID}) {
			$props{pid} = unpack 'L1', $pid;
		}

		# Get rid of any \n or similar chars, which seem to be legal in window titles for example
		s/[\r\f\n\t\x0B]+/ /g for grep defined, values %props;

		# Remap to something more friendly
		$props{title} = delete $props{_NET_WM_NAME};
		$props{icon_name} = delete $props{_NET_WM_ICON_NAME};

		# Pull a list of all the child windows
		my (undef, $parent, @kids) = $x->QueryTree($win);

		# TODO seems to be consistent, but should check on l10n
		undef $parent if $parent eq 'None';
		$props{parent} = $parent if $parent;

		# ... and recurse for each child window.
		$props{children} = [ ];
		push @{$props{children}}, $code->($_, $win) for @kids;
		return \%props;
	};

	# Start at the root, work down.
	my $tree = $code->($x->{screens}[$screen]{root});

	# and we're done.
	return $tree;
}

=head2 x11_filter_hierarchy

Similar to L</x11_hierarchy> function, but instead of returning a tree hierarchy,
returns a list of windows which match the given criteria.

Takes the same parameters as L</x11_hierarchy>, with the addition of a C< filter >
parameter.

If given a coderef as the filter, this will be called for each window found,
including the window in the output list if the coderef returns a true value.
The hashref representing the window will be passed as the first parameter and
for convenience is also available in $_. The full hierarchy will be constructed
before filtering the list of windows, so you can perform matches based on
the child elements if required.

If given a regex as the filter, returns only the windows whose title matches
the given regex.

=cut

sub x11_filter_hierarchy {
	my %args = @_;
	my $code = delete $args{filter};

	if(ref($code) eq 'Regexp') {
		my $re = $code;
		$code = sub { return unless defined $_->{title}; $_->{title} =~ /$re/ };
	}

	my @out;
	my @pending = x11_hierarchy(%args);
	while(@pending) {
		my $item = shift @pending;
		push @pending, @{$item->{children}};

		# Pass in $_[0] and $_ for convenience.
		push @out, $item for grep $code->($item), $item;
	}
	@out
}

1;

__END__

=head1 EXAMPLES

Get all window IDs for a given PID:

 my @win = map $_->{id}, x11_filter_hierarchy(
    filter => sub { $_->{pid} && $_->{pid} == $pid },
 );

Find the window ID for the largest (as measured by width x height) window
for a given PID:

 use List::UtilsBy qw(max_by);
 my ($win) = max_by {
    $_->{width} * $_->{height}
 } map {
    $_->{id}
 } x11_filter_hierarchy(
    filter => sub {
       $_->{pid} && $_->{pid} == $pid
    },
 );

=head1 SEE ALSO

=over 4

=item * L<X11::Protocol> - provides all the real functionality this module uses

=back

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2012. Licensed under the same terms as Perl itself.
