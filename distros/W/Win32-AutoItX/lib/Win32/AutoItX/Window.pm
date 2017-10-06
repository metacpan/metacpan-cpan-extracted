package Win32::AutoItX::Window;

=head1 NAME

Win32::AutoItX::Window - OO interface for Windows

=head1 SYNOPSIS

    use Win32::AutoItX;

    my $a = Win32::AutoItX->new;

    my $pid = $a->Run('calc.exe');
    my $window = $a->get_window('Calculator');
    $window->wait;

    local $\ = "\n";
    print "Handle: $window";
    print "Title: ", $window->title;
    print "PID: ", $window->process;
    print "x = ", $window->x, " y = ", $window->y;
    print "width = ", $window->width, " height = ", $window->height;
    $window->maximize;
    sleep 2;
    $window->restore;
    sleep 2;
    $window->move($window->x + 50, $window->y + 50);

    my $control = $window->get_focus;
    print "Focused control is $control with text = ", $control->text;

    # List all buttons
    my @buttons = $window->find_controls(undef, class => 'Button');
    foreach my $c (@buttons) {
        print "Button '$c' has text ", $c->text;
    }

=head1 DESCRIPTION

Win32::AutoItX::Window provides an object-oriented interface for AutoItX
methods to operate with Windows.

=cut

use strict;
use warnings;

our $VERSION = '1.00';

use Carp;
use Scalar::Util qw{ blessed };
use Win32::AutoItX::Control;

use overload fallback => 1, '""' => sub { $_[0]->handle };

my %Helper_Methods = qw{
    handle           WinGetHandle
    process          WinGetProcess
    state            WinGetState
    exists           WinExists
    is_active        WinActive
    text             WinGetText
    title            WinGetTitle
    x                WinGetPosX
    y                WinGetPosY
    width            WinGetPosWidth
    height           WinGetPosHeight
    client_width     WinGetClientSizeWidth
    client_height    WinGetClientSizeHeight
    activate         WinActivate
    close            WinClose
    kill             WinKill
    select_menu_item WinMenuSelectItem
    move             WinMove
    set_on_top       WinSetOnTop
    set_state        WinSetState
    set_title        WinSetTitle
    set_transparency WinSetTrans
    wait             WinWait
    wait_active      WinWaitActive
    wait_not_active  WinWaitNotActive
    wait_close       WinWaitClose
};

=head1 METHODS

=head2 new

    $window = Win32::AutoItX::Window->new($autoitx, $window_title, $window_text)

creates the window object.

=cut

sub new {
    my $class = shift;
    my %self;
    $self{autoitx} = shift;
    $self{title}   = shift;
    $self{text}    = shift;
    $self{text} = '' unless defined $self{text};
    croak "The first argument should be a Win32::AutoItX object"
        unless blessed $self{autoitx} and $self{autoitx}->isa('Win32::AutoItX');
    return bless \%self, $class;
}
#-------------------------------------------------------------------------------

=head2 get_class_list

    @class_list = $window->get_class_list()

retrieves list with classes from the window.

=cut

sub get_class_list {
    my $self = shift;
    my @classes = split /\r?\n/,
                  $self->WinGetClassList($self->{title}, $self->{text});
    return @classes;
}
#-------------------------------------------------------------------------------

=head2 get_control

    $control = $window->get_control($control_id)

returns a L<Win32::AutoItX::Control> object for the control specified by id.

=cut

sub get_control {
    my $self       = shift;
    my $control_id = shift;
    return Win32::AutoItX::Control->new(
        $self->{autoitx}, $self->{title}, $self->{text}, $control_id
    );
}
#-------------------------------------------------------------------------------

=head2 get_focus

    $control = $window->get_focus()

returns a L<Win32::AutoItX::Control> object for the control that has keyboard
focus within the window.

=cut

sub get_focus {
    my $self = shift;
    return Win32::AutoItX::Control->new(
        $self->{autoitx}, $self->{title}, $self->{text},
        $self->ControlGetFocus($self->{title}, $self->{text})
    );
}
#-------------------------------------------------------------------------------

=head2 find_controls

    $control  = $window->find_controls($text, %options)
    @controls = $window->find_controls($text, %options)

returns a L<Win32::AutoItX::Control> object (or a list of objects in the list
context) for matched contols. C<$text> is a raw string or a C<Regexp>.

Available options to filter controls:

=over

=item class

a raw string or a C<Regexp> to filter by Control's class.

=item visible

get visible controls only (set by default).

=item enabled

get enabled controls only.

=back

=cut

sub find_controls {
    my $self = shift;
    my $text = shift;
    my %args = (
        class   => undef,
        visible => 1,
        enabled => 0,
        @_
    );

    my %by_classes;
    my @controls;
    foreach my $class ($self->get_class_list) {
        if (defined $args{class}) {
            if (ref $args{class} and ref $args{class} eq 'Regexp') {
                next if $class !~ /$args{class}/;
            } else {
                next if $class ne $args{class};
            }
        }
        $by_classes{$class}++;
        my $control = $self->get_control(
            "[CLASS:$class; INSTANCE:$by_classes{$class}]"
        );
        next if $args{visible} and not $control->is_visible;
        next if $args{enabled} and not $control->is_enabled;
        if (defined $text) {
            my $control_text = $control->text;
            next unless defined $control_text;
            if (ref $text and ref $text eq 'Regexp') {
                next if $control_text !~ /$text/;
            } else {
                next if $control_text ne $text;
            }
        }
        return $control unless wantarray;
        push @controls, $control;
    }
    return @controls;
}
#-------------------------------------------------------------------------------

=head2 wait_control

    $control = $w->wait_control(%options)

waits until the control will be visible and enabled (optionally) and returns a
L<Win32::AutoItX::Control> object.

Optional arguments:

=over

=item control

the control id

=item class

a raw string or a C<Regexp> to filter controls by class

=item text

a raw string or a C<Regexp> to filter controls by text

=item enabled

if true wait until the control will be enabled

=item timeout

timeout in seconds to wait the control (60 by default)

=back

=cut

sub wait_control {
    my $self = shift;
    my %args = (
        control => undef,
        text    => undef,
        class   => undef,
        timeout => undef,
        enabled => 0,
        @_
    );
    $args{timeout} = 60 unless defined $args{timeout};
    my $control;
    $control = $self->get_control($args{control}) if defined $args{control};

    my $start = time;
    while (time - $start < $args{timeout}) {
        if (defined $control) {
            return $control if $control->is_visible
                and (not $args{enabled} or $control->is_enabled);
        } else {
            if (my $c = $self->find_controls($args{text},
                    class   => $args{class},
                    visible => 1,
                    enabled => $args{enabled},
            )) {
                return $c;
            }
        }
        sleep 1 if time - $start < $args{timeout};
    }
    croak "Timed out ($args{timeout} seconds)";
}
#-------------------------------------------------------------------------------

=head2 handle

    $handle = $window->handle()

retrieves the internal handle of the window.

=head2 process

    $process = $window->process()

retrieves the Process ID (PID) associated with the window.

=head2 state

    $state = $window->state()

returns a value indicating the state of the window. Multiple values are added
together so use biwise Bitwise And (C<&>) to examine the part you are interested
in:

    1 = Window exists
    2 = Window is visible
    4 = Windows is enabled
    8 = Window is active
    16 = Window is minimized
    32 = Windows is maximized

For example:

    print "Window is visible and enabled." if $window->state() & 6;

=head2 exists

    $boolean = $window->exists()

checks to see if the specified window exists.

=head2 is_active

    $boolean = $window->is_active()

checks to see if the window exists and is currently active.

=head2 text

    $text = $window->text()

retrieves the text from the window. Up to 64KB of window text can be retrieved.
It works on minimized windows, but only works on hidden windows if you've set
    
    $window->AutoItSetOption(WinDetectHiddenText => 1)

=head2 title

    $title = $window->title()

retrieves the full title from the window.

=head2 x

    $x = $window->x()

retrieves the X coordinate of the window.

=head2 y

    $y = $window->y()

retrieves the Y coordinate of the window.

=head2 width

    $width = $window->width()

retrieves the width of the window.

=head2 height

    $height = $window->height()

retrieves the height of the window.

=head2 client_width

    $client_width = $window->client_width()

retrieves the width of the window's client area.

=head2 client_height

    $client_height = $window->client_height()

retrieves the height of the window's client area.

=head2 activate

    $window->activate()

activates (gives focus to) the window.

=head2 close

    $window->close()

closes the window.

=head2 kill
    
    $window->kill()

forces the window to close.

=head2 select_menu_item

    $window->select_menu_item($item1, $item2, ..., $item7)

invokes a menu item of the window. You should note that underlined menu items
actually contain a & character to indicate the underlining. You can access menu
items up to six levels deep; and the window can be inactive, minimized, and/or
even hidden. It will only work on standard menus. Unfortunately, many menus in
use today are actually custom written or toolbars "pretending" to be menus.
This is true for most Microsoft applications.

=head2 move

    $window->move($x, $y)
    $window->move($x, $y, $width, $height)

moves and/or resizes the window. It has no effect on minimized windows, but it
works on hidden windows. If very width and height are small (or negative), the
window will go no smaller than 112 x 27 pixels. If width and height are large,
the window will go no larger than approximately C<12+DesktopWidth> x
C<12+DesktopHeight> pixels. Negative values are allowed for the x and y
coordinates. In fact, you can move a window off screen; and if the window's
program is one that remembers its last window position, the window will appear
in the corner (but fully on-screen) the next time you launch the program.

=head2 set_on_top

    $window->set_on_top($flag)

changes the window's "Always On Top" attribute. C<$flag> determines whether the
window should have the "TOPMOST" flag set: 1=set on top flag, 0 = remove on top
flag.

=head2 hide

    $window->hide()

hides the window.

=cut

sub hide { $_[0]->set_state($_[0]->SW_HIDE) }

=head2 show

    $window->show()

shows the previously hidden window.

=cut

sub show { $_[0]->set_state($_[0]->SW_SHOW) }

=head2 minimize

    $window->minimize()

minimizes the window.

=cut

sub minimize { $_[0]->set_state($_[0]->SW_MINIMIZE) }

=head2 maximize

    $window->maximize()

maximizes the window.

=cut

sub maximize { $_[0]->set_state($_[0]->SW_MAXIMIZE) }

=head2 restore

    $window->restore()

undoes the window minimization or maximization.

=cut

sub restore { $_[0]->set_state($_[0]->SW_RESTORE) }

=head2 set_title

    $window->set_title($title)

changes the title of the window.

=head2 set_transparency

    $window->set_transparency($transparency)

sets the transparency of the window: a number in the range 0 - 255. The larger
the number, the more transparent the window will become.

=head2 wait

    $window->wait()
    $window->wait($timeout)

pauses execution until the window exists. C<$timeout> in seconds.

=head2 wait_active

    $window->wait_active()
    $window->wait_active($timeout)

pauses execution until the window is active. C<$timeout> in seconds.

=head2 wait_not_active

    $window->wait_not_active()
    $window->wait_not_active($timeout)

pauses execution until the window is not active. C<$timeout> in seconds.

=head2 wait_close

    $window->wait_close()
    $window->wait_close($timeout)

pauses execution until the window does not exist. C<$timeout> in seconds.

=head2 AutoItX native methods

This module also autoloads all AutoItX methods. For example:

    $window->WinActivate($win_title) unless $window->WinActive($win_title);

Please see AutoItX Help file for documenation of all available methods.

=cut

sub AUTOLOAD {
    my $self = shift;
    my $method = our $AUTOLOAD;
    $method =~ s/.*:://;

    my @params = @_;
    if (exists $Helper_Methods{$method}) {
        $method = $Helper_Methods{$method};
        unshift @params, $self->{title}, $self->{text};
    }
    print "Call AutoItX method $method with params: @params\n"
        if $self->{autoitx}->debug;
    $self->{autoitx}->{autoit}->$method(@params);
}
#-------------------------------------------------------------------------------

=head1 SEE ALSO

=over

=item L<Win32::AutoItX::Control>

=item L<Win32::AutoItX>

=item AutoItX Help

=back

=head1 AUTHOR

Mikhail Telnov E<lt>Mikhail.Telnov@gmail.comE<gt>

=head1 COPYRIGHT

This software is copyright (c) 2017 by Mikhail Telnov.

This library is free software; you may redistribute and/or modify it
under the same terms as Perl itself.

=cut

1;
