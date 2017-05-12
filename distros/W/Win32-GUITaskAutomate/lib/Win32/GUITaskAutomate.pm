package Win32::GUITaskAutomate;

use strict;
use warnings;


our $VERSION = '0.06';

use Carp;
use Win32::GUIRobot qw(:all);
use Win32::Clipboard;


sub new {
    my ( $class, %args ) = @_;

    my $self = { PICS => {} };
    bless $self, $class;

    if ( ref $args{load} ) {
        if ( ref $args{load} eq 'HASH' ) {
            $self->load( $args{load} );
        }
        else {
            croak "`load` argument must be a hashref";
        }
    }
    $self->clip( Win32::Clipboard );

    return $self;
}

sub load {
    my ( $self, $pics_ref )= @_;

    keys %$pics_ref;
    my $robot_pics_ref = $self->pics;
    while ( my ( $name, $filename ) = each %$pics_ref ) {
    my $image = LoadImage( $filename );
    croak "Cannot load '$filename': $@" unless $image;

    croak "Image '$filename' is of different depth than the screen"
        if ImageDepth( $image ) != ScreenDepth();
    croak "Image '$filename' is wider than the screen"
        if ImageWidth( $image ) > ScreenWidth();
    croak "Image '$filename' is higher than the screen"
        if ImageHeight( $image ) > ScreenHeight();

        $robot_pics_ref->{ $name } = $image;
    }
}

sub pics {
    my $self = shift;
    if ( @_ ) {
        $self->{ PICS } = shift;
    }
    return $self->{ PICS };
}

sub find_do {
    my ( $self, $name, $what_ref, $wait) = @_;
    croak '$what_ref must be an ARRAYREF!!'
        unless ref $what_ref eq 'ARRAY';

    $wait ||= 100.1;
    my $pic = $self->pics->{ $name }
        or croak "Invalid image name in find_do{}";
    my $wait_ref = WaitForImage( $pic, maxwait => $wait );

    unless ( ref $wait_ref and exists $wait_ref->{ok} ) {
        carp "Could not find image $name :(";
        return;
    }

    $self->do( $what_ref, @{ $wait_ref }{ qw(x y) } );

    return 1;
}

sub do {
    my ( $self, $what_ref, $origin_x, $origin_y ) = @_;
    $origin_x ||= 0;
    $origin_y ||= 0;
    foreach my $action ( @$what_ref ) {
        if ( ref $action eq 'HASH' ) {
            $action->{x} ||= 0;
            $action->{y} ||= 0;

            my $m_x = $origin_x + $action->{x};
            my $m_y = $origin_y + $action->{y};

            if ( $action->{lmb} ) {
                $self->click_mouse( $m_x, $m_y, 'Left' );
            }
            elsif ( $action->{rmb} ) {
                $self->click_mouse( $m_x, $m_y, 'Right' );
            }
            elsif ( $action->{lmbd} ) {
                $self->click_mouse( $m_x, $m_y, 'Left', 2);
            }
            elsif ( $action->{rmbd} ) {
                $self->click_mouse( $m_x, $m_y, 'Right', 2);
            }
            elsif ( $action->{mw} ) {
                MouseMoveWheel( $action->{mw} );
            }
            elsif ( $action->{mmb} ) {
                $self->click_mouse( $m_x, $m_y, 'Middle' );
            }
            elsif ( $action->{mmbd} ) {
                $self->click_mouse( $m_x, $m_y, 'Middle', 2 );
            }
            elsif ( $action->{drag} ) {
                $self->drag_mouse(
                    'LEFT',
                    $m_x,
                    $m_y,
                    $origin_x + $action->{d_x},
                    $origin_y + $action->{d_y},
                );
            }
            elsif ( $action->{rdrag} ) {
                $self->drag_mouse(
                    'RIGHT',
                    $m_x,
                    $m_y,
                    $origin_x + $action->{d_x},
                    $origin_y + $action->{d_y},
                );
            }
            elsif ( $action->{mdrag} ) {
                $self->drag_mouse(
                    'MIDDLE',
                    $m_x,
                    $m_y,
                    $origin_x + $action->{d_x},
                    $origin_y + $action->{d_y},
                );
            }
            elsif ( $action->{save} ) {
                $self->mouse_coords( [  GetCursorPos() ] );
            }
            elsif ( $action->{restore} ) {
                return 1
                    unless ref $self->mouse_coords() eq 'ARRAY';
                MouseMoveAbsPix( @{ $self->mouse_coords } );
            }
        }
        elsif ( ref $action eq 'ARRAY' ) {
            Sleep( $action->[0] );
        }
        elsif ( ref $action eq 'SCALAR' ) {
            $self->set_clip( $$action );
        }
        else {
            SendKeys( $action );
        }
    }

    return 1;
}

sub drag_mouse {
    my ( $self, $button, $x, $y, $d_x, $d_y ) = @_;
    $button = ucfirst lc $button;
    croak "Invalid mouse button in ->drag_mouse (must be 'Left',"
        . " 'Right', or 'Middle'"
    unless $button eq 'Left'
        or $button eq 'Right'
        or $button eq 'Middle';

    $x   ||= 0;
    $y   ||= 0;
    $d_x ||= 0;
    $d_y ||= 0;

    MouseMoveAbsPix( $x, $y );
    SendMouse( "{${button}DOWN}" );
    MouseMoveAbsPix( $d_x, $d_y );
    SendMouse( "{${button}UP}" );
    return 1;
}

sub click_mouse {
    my ( $self, $x, $y, $button, $times ) = @_;
    $button = ucfirst lc $button;
    croak "Invalid mouse button in ->click_mouse (must be 'Left',"
        . " 'Right', or 'Middle'"
    unless $button eq 'Left'
        or $button eq 'Right'
        or $button eq 'Middle';

    $times ||= 1;
    SendMouseClick( $x, $y, $button )  for 1 .. $times;
    return 1;
}

sub get_clip {
    my $self = shift;
    return $self->clip->Get;
}

sub set_clip {
    my ( $self, $what ) = @_;
    $self->clip->Set( $what );
    return 1;
}

sub clip {
    my $self = shift;
    if ( @_ ) {
        $self->{ CLIP } = shift;
    }
    return $self->{ CLIP };
}

sub mouse_coords {
    my $self = shift;
    if ( @_ ) {
        $self->{ MOUSE_COORDS } = shift;
    }
    return $self->{ MOUSE_COORDS };
}


1;



1;
__END__

=encoding utf8

=head1 NAME

Win32::GUITaskAutomate - A module for automating GUI tasks.

=head1 SYNOPSIS

    use Win32::GUITaskAutomate;
    my $robot = Win32::GUITaskAutomate->new(
        load => {
            pic1 => 'pic1.PNG', # load picture
        }
    );

    $robot->find_do( 'pic1', # wait for loaded pic to appear
        [
            { save => 1 }, # save mouse cursor position
            \ "ZOMG!!!!.pl",  # put this text into clipboard
            { rmb => 1, x => 10, y => 20 }, # click right mouse button
            "{UP}{UP}~^v",  # press UP arrow twice, ENTER and CTRL+V
            { lmb => 1, x => 100, y => 100 }, # click left mouse button
            { restore => 1 }, # restore original mouse cursor position
        ]
    );

    my $clipboard_contents = $robot->get_clip;

    $robot->set_clip( "New clipboard contents" );

=head1 DESCRIPTION

I wrote this module because I needed to automate certain GUI tasks in a limited amount of time. Win32::GUIRobot was very helpful to me
with that, however I wanted some interface that would allow me to
write "robot instructions" more easily and quickly. This is how
Win32::GUITaskAutomate came to existance and I want to share it with
the world, even though I do not have time to perfect it.

=head1 METHODS

=head2 new

    my $robot = Win32::GUITaskAutomate->new;

    my $robot = Win32::GUITaskAutomate->new(
        load => {
            pic1 => 'pic1.png',
            pic2 => 'pic2.png',
            pic3 => 'pic3.png',
        }
    );

This method creates a new Win32::GUITaskAutomate object. You
may want to pass it an optional C<load> argument which accepts a
hashref with keys being the picture names (see C<find_do> method
below) and values being the filenames of those pictures.

=head2 load

    $robot->load( { pic1 => 'pic1.png', pic2 => 'pic2.png' } );

This method loads image(s). It takes a hashref with picure names (see C<find_do> method below) as keys and filenames as values. You
may want to use C<load> argument to the C<new> method instead.

=head2 do

    $robot->do( [
        { lmb => 1, x => 10, y => 10 }, # click left mouse
        { rmb => 1, x => -10, y => -10 }, # right click
        { lmbd => 1, x => 10, y => 10 }, # left double click
        { mw => 2 }, # move mouse wheel.
        "{UP}{DOWN}~", # press Up, Down and Enter keys
        \ "Clip!", # copy text 'Clip!' into the clipboard
        [ 2 ], # wait for 2 seconds
    ], 400, 500 );

This method instructs your robot to do some "stuff". The first
argument is an arrayref with instructions (See ROBOT INSTRUCTIONS below for descriptions). The second and third arguments are "x origin" and "y origin" respectively. Those two values will be basically added to any 'x' and 'y' values in the
mouse related actions, they default to '0'.

=head2 find_do

    $robot->find_do( 'picture_name', # name of the picture from ->load
        [
            { lmb => 1, x => 10, y => 10 }, # left click
            "foos!" # type "foos!"
        ],
        $wait_time
    );

This method is similar to ->do method, except it first tries to find
a picture on the screen. The ->load method as well as C<load>
argument to the ->new method is where you'd get your "picture name".
The first argument to ->find_do method is picture name. The second
argument is an arrayref with instructions (see ROBOT INSTRUCTIONS
below). Third I<optional> argument is the time in seconds to wait for the picture to appear on the screen, defaults to 100. The
instructions will be passed to the ->do method when the picture is
found, and 'origin x' and 'origin y' arguments will correspond
to coordinates of where the picture was spotted.


=head1 ROBOT INSTRUCTIONS

Robot instructions are passed to ->do and ->find_do methods in the
form of an arrayref, and are executed sequentually.

Each element of the arrayref can be one of the following:

=head2 A scalar

    "{UP}^l{DOWN}~"

When an element is a scalar, the instruction will be interpreted
as a request to press some keys, it will be sent directly to
SendKeys() subroutine. See L<Win32::GuiTest> C<SendKeys> function for explanation of the keys

=head2 A scalar reference

    \ "Clipper"

When an element is a scalar reference, the content will be stuffed
into the clipboard. If you want your robot to type up a large chunk
of text, it will be significantly faster to drop that text into the
clipboard and then issue a "^v" (CTRL+V) to paste it instead of
asking the robot to type it all out key by key.

=head2 An arrayref

    [10]

When an element is an arrayref, it is interpreted as a request to
sleep for that number of seconds, the request will be passed to
C<Win32::GUIRobot::Sleep> subroutine, B<not> perl's C<sleep>.

=head2 A hashref

When an element is a hashref, it is interpreted as a mouse action
(so far at least). One of the keys is an action key and the codes
for those are:

=over 5

=item lmb

Left Mouse Button

=item rmb

Right Mouse Button

=item lmbd

Left Mouse Button Double (double left click)

=item rmbd

Right Mouse Button Double (double right click)

=item mw

Mouse Wheel

=item drag

Left mouse button drag

=item rdrag

Right mouse button drag

=item mdrag

Middle mouse button drag

=item save

Save mouse cursor position

=item restore

Restore mouse cursor position to an earlier save setting ( see C<save> )

=back



=head3 General Principal for HashRef Instructions

Hashref instructions deal with mouse actions. Some accept
several arguments, which default to C<0> if not specified.
The arguments, unless specified otherwise, are offset
coordinates relative to B<origin>. By origin is understood
either "origin x", and "origin y" coordinates of the ->do
method, or the location where the image was found of the
->find_do method

=head3 lmb (Left Mouse Button)

    { lmb => 1, x => 10, y => -22 }


Key C<lmb> stands for B<L>eft B<M>ouse B<B>utton. It instructs
the robot to make a B<left mouse click>. The two optional
arguments are C<x> and C<y> are the coordinates relative to
the origin. Omitted arguments default to zero. The value for
C<lmb> key must be a I<true value> in order for the instruction
to be executed, this allows some dynamic decision making, such
as:
    { lmb => $do_we_need_to_click....

=head3 rmb (Right Mouse Button)

    { rmb => 1, x => 10, y => -22 }

Same as C<lmb> except this instructs the robot to B<right> click.

=head3 mmb (Middle Mouse Button)

    { mmb => 1, x => 10, y => -22 }

Same as C<lmb> except this instructs the robot to B<middle> click.

=head3 lmbd (Left Mouse Button Double)

    { lmbd => 1, x => 10, y => -22 }

Same as C<lmb> except this instructs the robot to B<double left>
click.

=head3 rmbd (Right Mouse Button Double)

    { rmbd => 1, x => 10, y => -22 }

Same as C<lmb> except this instructs the robot to B<double right>
click.

=head3 mmbd (Middle Mouse Button Double)

    { mmbd => 1, x => 10, y => -22 }

Same as C<lmb> except this instructs the robot to B<double middle>
click.

=head3 mw (Mouse Wheel)

    { mw => 2 }
    { mw => -10 }

This argument instructs the robot to move the I<mouse wheel>. It
B<does not> take any extra arguments. Positive values spin the
wheel "up" and negative values spin the wheel "down".

=head3 drag (Drag with left mouse button)

    { drag => 1, x => 1, y => 20, d_x => 100, d_y => -20 }
    { drag => 1, d_x => -100 }
    { drag => 1, x => 200, d_y => -200 }

Instructs the robot to drag with left mouse button (as in left
mouse button down => move mouse => left mouse button up).
As with C<lmb>, the value for the C<drag> key must be a I<true value>
in order for the instruction to be executed. Takes I<four> optional
arguments. They all will default to C<0> if not specified. C<x> and
C<y> are the starting point of the drag (relative to the origin) and
C<d_x> and C<d_y> are ending points of the drag (again relative to
the B<origin>, not the place of the start of the drag).

=head3 rdrag (Drag with right mouse button)

    { rdrag => 1, x => 1, y => 20, d_x => 100, d_y => -20 }
    { rdrag => 1, d_x => -100 }
    { rdrag => 1, x => 200, d_y => -200 }

Same as C<drag> except drags with B<right> mouse button.

=head3 mdrag (Drag with middle mouse button)

    { mdrag => 1, x => 1, y => 20, d_x => 100, d_y => -20 }
    { mdrag => 1, d_x => -100 }
    { mdrag => 1, x => 200, d_y => -200 }

Same as C<drag> except drags with B<middle> mouse button.

=head3 save

    { save => 1 }

Instructs the robot to save current mouse cursor position. This is
useful if you want your robot to do some mouse clickety and restore
the original cursor position when finished (see C<restore> below). The value
of the key must be a true value or nothing will happen.

=head3 restore

    { restore => 1 }

Instructs the robot to restore saved mouse cursor position. This is
useful if you want your robot to do some mouse clickety and restore
the original cursor position when finished (see C<save> above). The value
of the key must be a true value or nothing will happen. If you never
saved any positions with C<save> (see above) nothing will happen.

=head1 OTHER METHODS


=head2 drag_mouse

    $robot->drag_mouse( 'Left', $x_from, $y_from, $x_to, $y_to );

Instructs the robot to make a mouse drag. First argument is the
button to use for dragging. It can be either C<'Left'>, C<'Right'>
or C<'Middle'>. Sub will C<croak> if incorrect button is passed
(names are case I<insensitive>).

C<$x_from> and C<$y_from> are coordinates of the starting
point of the drag and C<$x_to> and C<$y_to> are the endining
points of the drag. All will default to zero if are not set.

=head2 click_mouse

    $robot->click_mouse( $x, $y, $button, $times )

Instructs the robot to click the mouse. C<$x> and C<$y> are
the coordinates of the click. C<$button> is the button to press,
can be either C<'Left'>, C<'Right'>
or C<'Middle'>. Sub will C<croak> if incorrect button is passed
(names are case I<insensitive>). C<$times> is the number of times
to press the button, which defaults to C<1> if not specified.
C<$x> and C<$y> default to C<0>.

=head2 set_clip

    $robot->set_clip( 'Text to put into the clipboard' );

Takes one argument which will be put into the clipboard. Technically this
can be anything accepted by the L<Win32::Clipboard> C<Set()> method, but
was tested only with textual content.

=head2 get_clip

    my $clipboard_stuff = $robot->get_clip;

Takes no arguments. Returns clipboard contents. Technically this may be
anything returned by L<Win32::Clipboard> C<Get()> method, but was tested
only with textual content.

=head2 clip

    my $clipboard = $robot->clip;

Returns Win32::Clipboard object if you'll ever need it.

=head2 pics

    my $pics_ref = $robot->pics;

Returns a hashref of loaded images. It's the one from the C<load>
option of the ->new methods as well as from the ->load method.
You might want to check if a certain picture was already loaded.

=head2 mouse_coords

    my $mouse_coords_ref = $robot->mouse_coords;

    $robot->mouse_coords( [ 200, 100 ] );

Returns an arrayref with two elements: x and y coordinates of the mouse
cursor which were stored with C<save> intruction (see ROBOT INSTRUCTIONS
for more info). Will return C<undef> if you never saved any positions
and never set them with C<mouse_coords()> method. Takes one I<optional>
argument which is an arrayref with two elements: x and y coordinates.
I<Note:> if you specificly set coordinates with this method they will
distroy the ones that were saved with C<save> robot instruction and will
be used by C<restore> robot instruction.

=head1 EXAMPLES

Here are some examples with explanations of how the robot would behave

=head2 Example 1

    use Win32::GUITaskAutomate;
    my $robot = Win32::GUITaskAutomate->new(
    load => {
        task  => 'task.png',
        task2 => 'task2.png',
    }
    );

    $robot->find_do( 'task', [
    { lmb => 1, x => 5, y => 5 },
    [2],
    ]);

    $robot->find_do( 'task2', [
    "^t",
    [1.1],
    \ "Hello World!",
    "^v~",
    ]);

The code is interpreted as follows:

=over 3

=item *

Load two images from files 'task.png' and 'task2.png' and name them
'task' and 'task2' respectively.

=item *

Start watching the screen for 'task' image to appear with the default
100 second timeout.

=item *

When 'task' image is seen on screen, click left mouse button 5 pixels
to the right and 5 pixels to the left of where the image was found
(starting at the top left corner of the image)

=item *

Sleep for 2 seconds

=item *

Start watching the screen for 'task2' image to appear with the
default 100 second timeout.

=item *

When found -- press C<CTRL+T> key, wait for 1.1 seconds.

=item *

Push string "Hello World!" intro the clipboard, paste it
with C<CTRL+V> and press C<ENTER> key.


=back


=head2 Example 2

    use Win32::GUITaskAutomate;
    my $robot = Win32::GUITaskAutomate->new(
    load => {
        pic => 'pic1.png',
    }
    );

    $robot->find_do( 'pic',
    { lmb => $do_click, x => 10, y => 20 },
    "~{TAB}OH HAI~",
    { drag => $do_drag, d_x => 100, d_y => 200 },
    );

    if ( $do_click ) {
    $robot->load( { pic2 => 'pic2.png } );
    $robot->find_do(
        "~~~{TAB}~",
    );
    }

The code is interpreted as follows, consider that C<$do_click>
variable is assigned to earlier in the source code from somewhere.

=over 3

=item *

Load up image from file 'pic1.png' and give it name 'pic'

=item *

Start looking for 'pic' to appear on the screen.

=item *

When found, left click 10 pixels to the right and 20 pixels down
relative to the left right corner of where we have spotted 'pic'.
B<Note:> the click will not happen if C<$do_click> variable is set
to a false value.

=item *

Press C<ENTER>, C<TAB>, type "OH HAI" and press C<ENTER> again.

=item *

If variable C<$do_click> B<is> set to true value, load another image
from file 'pic2.png' and name it 'pic2'

=item *

Start looking for 'pic2' to appear on the screen.

=item *

When it's found: press C<ENTER> key B<three> times, press
C<TAB> key and press C<ENTER> again.

=back

=head1 SEE ALSO

L<Win32::GUIRobot>, L<Win32::GuiTest>, L<Win32::Clipboard>

=head1 PREREQUISITES

This module requires L<Win32::GUIRobot>, L<Win32::Clipboard> as
well as L<Test::More> for C<make test>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-win32-guitaskautomate at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-GUITaskAutomate>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Win32::GUITaskAutomate

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Win32-GUITaskAutomate>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Win32-GUITaskAutomate>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Win32-GUITaskAutomate>

=item * Search CPAN

L<http://search.cpan.org/dist/Win32-GUITaskAutomate>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

