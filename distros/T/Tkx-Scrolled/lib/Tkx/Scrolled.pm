#===============================================================================
# Tkx/Scrolled.pm
# Copyright 2009-2010 Michael J. Carman. All rights reserved.
#===============================================================================
package Tkx::Scrolled;
use 5.006;
use strict;
use warnings;

use Carp qw(croak);
use Tkx;
use base qw(Tkx::widget Tkx::MegaConfig);

our $VERSION = '0.06';

__PACKAGE__->_Mega('tkx_Scrolled');

__PACKAGE__->_Config(
	DEFAULT => ['.scrolled'],
);

my $initialized;
my $tile_available;

# regular expression for validation of -scrollbars argument
my $valid_scrollbar_position = qr/
	(?:^o?[ns]?o?[ew]?$)  # normal directions: n, s, e, w, ne, nw, se, sw
	|(?:^o?[ew]o?[ns]$)   # unusual variants: en, es, wn, ws
/xi;

#-------------------------------------------------------------------------------
# Subroutine : _ClassInit
# Purpose    : Perform class initialization.
# Notes      : 
#-------------------------------------------------------------------------------
sub _ClassInit {
	# determine availability of themed widgets
	$tile_available = eval { Tkx::package_require('tile') };
	$initialized++;
}


#-------------------------------------------------------------------------------
# Method  : _Populate
# Purpose : Create a new Tkx::Scrolled widget
# Notes   : 
#-------------------------------------------------------------------------------
sub _Populate {
	my $class  = shift;
	my $widget = shift;
	my $path   = shift;
	my $type   = shift;
	my %opt    = (
		-tile       => 1,
		-scrollbars => 'se',
		@_,
	);

	_ClassInit() unless $initialized;

	# Create the megawidget.
	my $self = ($tile_available && $opt{-tile})
		? $class->new($path)->_parent->new_ttk__frame(-name => $path, -class => 'Tkx_Scrolled')
		: $class->new($path)->_parent->new_frame(-name => $path, -class => 'Tkx_Scrolled');
	$self->_class($class);
	
	my $data = $self->_data();

	# Delete megawidget options so that we can safely pass the remaining
	# ones through to the scrolled subwidget.
	$data->{-tile}       = delete $opt{-tile} && $tile_available;
	$data->{-scrollbars} = delete $opt{-scrollbars};

	# Validate requested scrollbar positions.
	if ($data->{-scrollbars} =~ $valid_scrollbar_position) {
		$data->{xscrollbar}{optional} = ($data->{-scrollbars} =~ /o[ns]/);
		$data->{yscrollbar}{optional} = ($data->{-scrollbars} =~ /o[ew]/);
	}
	else {
		croak("Invalid value for option '-scrollbars', must be n, s, e, w or a combination");
	}

	# Create the widgets.
	my $new_thing = "new_$type";
	my $w = $self->$new_thing(-name => 'scrolled',   %opt);
	my $x = $self->_scrollbar(-name => 'xscrollbar', -orient => 'horizontal');
	my $y = $self->_scrollbar(-name => 'yscrollbar', -orient => 'vertical');

	# Create widget bindings. If the scrolled widget is a megawidget (e.g.
	# Tkx::ROText) any method delegation it does won't work because the
	# scrollbar widgets operate in Tcl/Tk; they are oblivious to the Perl layer
	# above it. We use _mpath() to resolve any delegation now and provide the
	# Tcl pathname of the delegate for use by the scrollbars.
	$x->configure(-command        => [$w->_mpath('xview'), 'xview']);
	$y->configure(-command        => [$w->_mpath('yview'), 'yview']);
	$w->configure(-xscrollcommand => [\&_set, $self, 'xscrollbar']);
	$w->configure(-yscrollcommand => [\&_set, $self, 'yscrollbar']);

	# Determine the placement of the scrollbars. The corner between the
	# scrollbars is left empty; this keeps the ends of the scrollbars from
	# overlapping.
	my ($r, $c);
	for ($self->_data->{-scrollbars}) {
		/n/ && do { $r = 0 };
		/s/ && do { $r = 2 };
		/e/ && do { $c = 2 };
		/w/ && do { $c = 0 };
	}

	# Layout the widgets
	$w->g_grid(-row => 1,  -column => 1,  -sticky => 'nsew');
	$x->g_grid(-row => $r, -column => 1,  -sticky => 'ew'  ) if defined $r;
	$y->g_grid(-row => 1,  -column => $c, -sticky => 'ns'  ) if defined $c;

	Tkx::grid('columnconfigure', $self, 1, '-weight', 1);
	Tkx::grid('rowconfigure',    $self, 1, '-weight', 1);

	Tkx::grid('remove', $x) if $data->{xscrollbar}{optional};
	Tkx::grid('remove', $y) if $data->{yscrollbar}{optional};

	return $self;
}


#-------------------------------------------------------------------------------
# Method  : _mpath
# Purpose : Delegate all method calls to the scrolled subwidget.
# Notes   : 
#-------------------------------------------------------------------------------
sub _mpath { $_[0] . '.scrolled' }


#-------------------------------------------------------------------------------
# Method  : _scrollbar
# Purpose : Create a scrollbar widget using the tile setting.
# Notes   : 
#-------------------------------------------------------------------------------
sub _scrollbar {
	my $self = shift;

	return $self->_data->{-tile}
		? $self->new_ttk__scrollbar(@_)
		: $self->new_scrollbar(@_);
}


#-------------------------------------------------------------------------------
# Method  : _set
# Purpose : Set a scrollbar, possibly hiding/showing it if it's optional
# Notes   :
#    * $self is the *third* argument due to the way the Tcl bridge works.
#    * There is a (literal) corner case that can cause optional scrollbars to 
#      flicker when:
#         1) A line of text is at the bottom of the scrolled area.
#         2) The line is the only one long enough to require scrolling.
#         3) Drawing the horizontal scrollbar hides the line (making
#            scrolling unnecessary).
#      Tk doesn't provide a good mechanism for detecting this and handling it
#      robustly. Instead we kludge it it by briefly inhibiting removal of a
#      scrollbar after drawing it.
#-------------------------------------------------------------------------------
sub _set {
	my ($first, $last, $self, $kid) = @_;
	my $sb  = $self->_kid($kid);
	my $cfg = $self->_data()->{$kid};

	$sb->set($first, $last);

	return unless $cfg->{optional};

	if ($first > 0 || $last < 1) {
		return if Tkx::grid('info', $sb);  # Already visible
		$sb->g_grid();                     # Make visible

		# inhibit immediate removal
		$cfg->{inhibit} = 1;
		Tkx::after(10, sub { $cfg->{inhibit} = 0 });
	}
	else {
		return unless Tkx::grid('info', $sb);  # Already hidden
		return if     $cfg->{inhibit};         # Can't hide yet
		Tkx::grid('remove', $sb);              # Hide scrollbar
	}
}


1;

__END__

=pod

=head1 NAME

Tkx::Scrolled - Tkx megawidget for scrolled widgets

=head1 SYNOPSIS

	use Tkx::Scrolled;

	my $text = $mw->new_tkx_Scrolled('text');

=head1 DESCRIPTION

Tkx::Scrolled is a Tkx megawidget that simplifies that task of adding scrollbars 
to your widgets.

=head1 OPTIONS

The options below are for the Tkx::Scrolled megawidget. All other options are 
passed through to the constructor for the scrolled subwidget.

=head2 -scrollbars

Where the scrollbars should be drawn relative to the scrolled widget: 
C<n>, C<s>, C<e>, C<w> or a combination of them. If a position is prefixed with
C<o> the corresponding scrollbar is optional and will only be drawn if needed.
The default value is C<se>.

=head2 -tile

Use tiled (ttk) scrollbars if available. Defaults to 1.

=head1 SUBWIDGETS

=head2 scrolled

The scrolled widget.

=head2 xscrollbar

The scrollbar widget used for horizontal scrolling.

=head2 yscrollbar

The scrollbar widget used for vertical scrolling.

=head1 METHODS

None. All method calls are delgated to the scrolled subwidget. This means that 
you don't need to access the subwidget directly and can make existing widgets 
scrolled without needing to change any of the code that references them.

Method delgation to other megawidgets (e.g. Tkx::ROText) only works with Tkx 
version 1.06 or greater and only if the embedded megawidget's method names 
include the 'm_' prefix. If you can't rely on this you'll have to fall back
to the C<< $w->_kid('scrolled')->method(...) >> syntax.

=head1 AUTHOR

Michael J. Carman, C<< <mjcarman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tkx-scrolled at 
rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tkx-Scrolled>.  I will be 
notified, and then you'll automatically be notified of progress on your bug as I 

make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Tkx::Scrolled

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tkx-Scrolled>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tkx-Scrolled>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tkx-Scrolled>

=item * Search CPAN

L<http://search.cpan.org/dist/Tkx-Scrolled>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2009-2010 Michael J. Carman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
