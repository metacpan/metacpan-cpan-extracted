package Text::ProgressBar;
our $VERSION = '0.3';

$|++; # disable buffering on STDOUT - autoflush
use Moose;
use Text::ProgressBar::Percentage;
use Text::ProgressBar::Bar;
use Text::ProgressBar::Widget;
use List::Util qw(max);
use Term::ReadKey;

has 'widgets'           => (is => 'rw', isa => 'ArrayRef', builder => '_build_widgets' );
has 'maxval'            => (is => 'rw', isa => 'Int', default => 100);
has 'term_width'        => (is => 'rw', isa => 'Int', builder => '_handle_resize');

has 'fd'                => (is => 'rw', isa => 'FileHandle', default => sub { \*STDOUT });
has 'left_justify'      => (is => 'rw', isa => 'Bool', default => 1);
has 'next_update'       => (is => 'rw', isa => 'Int', default => 0);
has 'update_interval'   => (is => 'rw', isa => 'Int', default => 1);
has 'start_time'        => (is => 'rw', isa => 'Int');
has 'currval'           => (is => 'rw', isa => 'Int', default => 0);
has '_time_sensitive'   => (is => 'rw', isa => 'Int');
has 'last_update_time'  => (is => 'rw', isa => 'Num', default => 0);
has 'seconds_elapsed'   => (is => 'rw', isa => 'Int', default => 0);
has 'finished'          => (is => 'rw', isa => 'Bool', default => 0);
has 'poll'              => (is => 'rw', isa => 'Int', default => 1);

sub BUILD {
    my $self = shift; 
    $self->_update_widgets();
    $self->setup_signal();
}

sub setup_signal { # signal handler for WINCH (window change)
    my $self = shift; 
    $SIG{WINCH} = sub { $self->term_width( $self->_handle_resize ) };
}

sub _handle_resize {
    my $self = shift; 
    my ($wchar, $hchar, $wpixels, $hpixels) = GetTerminalSize();
    return (int $wchar)-5; # TODO - calculate the right length: _format_widgets
}

sub _build_widgets {
  return [Text::ProgressBar::Percentage->new(), Text::ProgressBar::Bar->new()];
}

sub percentage {
    my $self = shift; 
    return int($self->currval * 100.0 / $self->maxval);
}

sub _format_widgets {
    my $self      = shift;
    my @result    = ();
    my @expanding = ();
    my $width     = $self->term_width;
    for my $w ( @{ $self->widgets } ) { push @result, $w->update($self, $width); }
    return join('',@result);
}

sub _format_line {
    my $self    = shift;
    my $widgets = join('', $self->_format_widgets);
    my $width   = $self->term_width;
    if ($self->left_justify) {
        return sprintf("%-${width}s", $widgets);}
    else {
        return sprintf("%${width}s", $widgets);}
}

sub _need_update {
    my $self = shift;
    return 1 if ($self->currval >= $self->next_update);
    return 1 if $self->finished;
    if ($self->_time_sensitive && ((time - $self->last_update_time) > $self->poll)) {return 0} else {return 1}
}

sub _update_widgets {
    my $self = shift;
    my $i = 0;
    for my $w ( @{ $self->widgets } ) { $i += $w->TIME_SENSITIVE }
    $self->_time_sensitive($i);
}

sub update {
    my $self = shift; 
    my $value = shift; 
    return if (not $self->_need_update);

    $self->currval($value);
    my $now = time();
    $self->seconds_elapsed($now - $self->start_time);
    $self->next_update($self->currval + $self->update_interval);
    print ${$self->fd} ($self->_format_line."\r");
    $self->last_update_time($now);
}

sub start {
    my $self = shift;
    my $now = time();
    $self->update_interval (int($self->maxval / max(100, $self->term_width)));
    $self->start_time($now);
    $self->last_update_time($now);
    $self->update(0);
}

sub finish {
    my $self = shift;
    $self->finished(1);
    $self->update($self->maxval);
    print ${$self->fd} ("\n");
}

__PACKAGE__->meta->make_immutable();
1; # End of Text::ProgressBar
__END__

=head1 NAME

Text::ProgressBar - indicates the progress of a lengthy operation
visually on your terminal

=head1 VERSION

Version 0.3

=head1 SYNOPSIS

    use Text::ProgressBar::Bar;

    my $pbar = Text::ProgressBar->new();
    $pbar->start();
    for my $i (1..100) {
        sleep 0.2;
        $pbar->update($i);
    }
    $pbar->finish;

=head1 DESCRIPTION

The Text::ProgressBar is customizable, you can specify different kinds of
widgets so as you can create your own widget. It is also possible that
you combine more than one widget to find your own style.

The printing (output ascii) characters can also be modified and changed.
A default set is defined for each widget, but user can change them
during calling constructor or later by calling the corresponding methods
(see individual widget).

Each 'widget' draws a different text on the screen. For an example for
each 'widget' see its class POD!

When implementing your own widget, you create an I<update> method and
pass a reference current object of ProgressBar to it. As a result, you
have access to the ProgressBar methods and attributes.

Following 'widgets' (class inheritance structure illustrated) are
currently implemented. They can be used or extended or a new widgets can
be created similar to them.

    Widget
    |-- AnimatedMarker
    |-- Counter
    |-- FileTransferSpeed
    |-- Percentage
    |-- SimpleProgress
    |-- Timer
    |   |-- ETA
    |   `-- FormatLabel
    `-- WidgetHFill
        `-- Bar
            |-- BouncingBar
            `-- ReverseBar

Useful methods and attributes include (Public API):

=over 4

=item * term_width : current terminal width, if it is given, it sets the
terminal width, otherwise actual terminal length will be get from system

=item * currval: current progress (0 <= currval <= maxval)

=item * maxval: maximum (and final) value

=item * finished: True if the bar has finished (reached 100%)

=item * start_time: the time when start() method of ProgressBar was called

=item * seconds_elapsed: seconds elapsed since start_time and last
call to update

=item * percentage: progress in percent [0..100]

=back

=head1 SUBROUTINES/METHODS

=head2 BUILD

=head2 _handle_resize

Tries to catch resize signals sent from the terminal

=head2  setup_signal

handle terminal window resize events (transmitted via the WINCH signal)

=head2 _build_widgets

builder for all widgets - used by Moose

=head2 percentage

Returns the progress as a percentage

=head2 _format_widgets

format all widgets

=head2 _format_line

Joins the widgets and justifies the line

=head2 _need_update

Returns whether the ProgressBar should redraw the line

=head2 _update_widgets

Checks all widgets for the time sensitive bit

=head2 update

Updates the ProgressBar to a new value.

=head2 start

Starts measuring time, and prints the bar at 0%

=head2 finish

Puts the ProgressBar bar in the finished state.

=head1 AUTHOR

Farhad Fouladi, C<< <farhad at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-progressbar at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-ProgressBar>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::ProgressBar

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-ProgressBar>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-ProgressBar>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-ProgressBar>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-ProgressBar/>

=back

=head1 ACKNOWLEDGEMENTS

'Nilton Volpato' for original idea

=head1 SEE ALSO

There are many 'ProgressBar' in CPAN written in Perl. But only through this
module user can choose from a set of different 'widgets' in different
forms and behaviours and addititionally combine these widgets to make a
nicer output.

There are currently a good number of widgets, you can put them in any
type in any order, but you can write your own widget. A new user-defined
widget can be easily implemented. Herefor user can add a new subclass of
existing widgets and add his own widget with new functionalities in it.

This module support resizing of terminal during execution, not all other
'ProgressBar' module support that.

Some of the other modules:

L<Smart::Comments>, L<Term::ProgressBar>, L<Term::Spinner>,
L<String::ProgressBar>, L<ProgressBar::Stack>
 
=cut

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Farhad Fouladi.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
