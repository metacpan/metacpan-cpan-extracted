package X11::Xlib::Display;
use strict;
use warnings;
use parent 'X11::Xlib';
use Scalar::Util;
use Carp;

# All modules in dist share a version
our $VERSION = '0.20';

require X11::Xlib::Screen;
require X11::Xlib::Colormap;
require X11::Xlib::Window;
require X11::Xlib::Pixmap;
require X11::Xlib::XserverRegion;

=head1 NAME

X11::Xlib::Display - Object-Oriented behavior for X11::Xlib

=head1 DESCRIPTION

This subclass of X11::Xlib provides perl-ish Object-Oriented behavior for
the API of Xlib.  Calling methods like XCreateWindow return L<Window|X11::Xlib::Window>
objects instead of integer XIDs.  It also contains a number of friendly helper
methods that wrap the Xlib API in a more intuitive manner.

=head1 ATTRIBUTES

=head2 connection_fh

Return the file handle to the X11 connection.  Useful for C<select>.

=cut

sub connection_fh {
    my $self= shift;
    $self->{connection_fh} ||= do {
        require IO::Handle;
        IO::Handle->new_from_fd( $self->ConnectionNumber, 'w+' );
    };
}

=head2 screen_count

   for (0 .. $display->screen_count - 1) { ... }

Number of screens available on this display.

=head2 screen

   my $screen= $display->screen();  # alias for $display->default_screen
   my $screen= $display->screen(3); # get some specific screen

Get a L<X11::Xlib::Screen> object, to query per-screen attributes.

=head2 default_screen_num

Number of the default screen

=head2 default_screen

Alias for C<< $display->screen( $display->default_screen_num ) >>.

=cut

sub screen_count { $_[0]{screen_count} }
sub default_screen_num { $_[0]{default_screen_num} }
sub default_screen { $_[0]{default_screen} }
sub screen {
    @_ > 1? $_[0]{screens}[$_[1]] : $_[0]{default_screen};
}

=head2 on_error

  $display->on_error(sub {
    my ($display, $event)= @_;
    if ($event) {
      # inspect $event (instance of XEvent) and handle/log as appropriate
    } else {
      # Fatal Xlib error, perform cleanup and prepare for program exit
    }
  });

See L<X11::Xlib/on_error>.

=head1 METHODS

=head2 new

  my $display= X11::Xlib::Display->new(); # uses $ENV{DISPLAY}
  my $display= X11::Xlib::Display->new( $connect_string );
  my $display= X11::Xlib::Display->new( connect => $connect_string, %attributes );

Create a new connection to an X11 server.

If you pass a single non-hashref argument, it is given to
L<XOpenDisplay|X11::Xlib/XOpenDisplay>.
If you omit the connect_string, it uses C<$ENV{DISPLAY}>.

If you pass a list or hashref of arguments, you can specify the connection
string as C<connect>.

If the call to C<XOpenDisplay> fails, this constructor dies.

=cut

sub new {
    my $class= shift;
    my $args= @_ == 1 && ref($_[0]) eq 'HASH'? { %{$_[0]} }
        : @_ == 1? { connect => $_[0] }
        : (1 & @_) == 0? { @_ }
        : croak "Expected hashref, single connection scalar, or even-length list";
    # Use the magic-enabled hashref that we get back from XOpenDisplay
    my $self= X11::Xlib::XOpenDisplay(defined $args->{connect}? (delete $args->{connect}) : () )
        or croak "Unable to connect to X11 server";
    # Apply all our arguments
    %$self= ( %$self, %$args );
    # Re-bless
    bless $self, $class;
    
    # initialize a few attributes that are commonly accessed
    $self->{screen_count}= $self->ScreenCount;
    $self->{default_screen_num}= $self->DefaultScreen;
    $self->{screens}[$_]= X11::Xlib::Screen->_new( display => $self, screen_number => $_ )
        for 0 .. $self->{screen_count} - 1;
    $self->{default_screen}= $self->{screens}[ $self->{default_screen_num} ];

    return $self;
}

=head2 COMMUNICATION/EVENT

=head3 wait_event

  my $event= $display->wait_event(
    window     => $window,
    event_type => $type,
    event_mask => $mask,
    timeout    => $seconds,
    loop       => $bool_keep_trying,
  );

Each argument is optional.  If you specify C<window>, it will only return events
for that window.  If you specify C<event_mask>, it will limit which types of
event can be returned.  if you specify C<event_type>, then only that type of
event can be returned.

C<timeout> is a number of seconds (can be fractional) to wait for a matching
event.  If C<timeout> is zero, the function acts like C<XCheckEvent> and returns
immediately.  If C<timeout> is not specified the function will wait indefinitely.
However, the wait is always interrupted by pending data from the X11 server, or
signals, so in practice the wait won't be very long and you should call it in
an appropriate loop.  Or, if you want this module to take care of that detail,
add "loop => 1" to the arguments and then wait_event will wait up to the full
timeout before returning false.

Returns an L<X11::Xlib::XEvent> on success, or undef on timeout or interruption.

=cut

sub wait_event {
    my ($self, %args)= @_;
    my $timeout= defined $args{timeout}? int($args{timeout} * 1000) : 0x7FFFFFFF;
    require Time::HiRes;
    my $start= Time::HiRes::time();
    my $event;
    do {
        $self->_wait_event(
            $args{window}||0,
            $args{event_type}||0,
            $args{event_mask}||0x7FFFFFFF,
            $event,
            $timeout
        ) and return $event;
    } while ($args{loop} and (Time::HiRes::time() - $start)*1000 < $timeout);
    return undef;
}

=head3 send_event

  $display->send_event( $xevent,
    window     => $wnd,
    propagate  => $bool,
    event_mask => $mask
  );

C<propogate> defaults to true.  C<window> defaults to the window field of the
event.  C<event_mask> must be specified but eventually I want to have it auto-
calculate from the event type.

=head3 putback_event

  $display->putback_event($event);

"un-get" or "unshift" an event back onto your own message queue.

=cut

sub send_event {
    my ($self, $event, %args)= @_;
    defined $args{event_mask} or croak "event_mask is required (for now)";
    defined $args{window} or $args{window}= $event->window;
    defined $args{propagate} or $args{propagate}= 1;
    $self->XSendEvent($args{window}, $args{propogate}, $args{event_mask}, $event);
}

sub putback_event {
    my ($self, $event)= @_;
    $self->XPutBackEvent($event);
}

=head3 flush

Push any queued messages to the X server.

=head3 flush_sync

Push any queued messages to the X server and wait for all replies.

=head3 flush_sync_discard

Push any queued messages to the server, wait for replies, and then delete the
entire input event queue.

=cut

sub flush              { shift->XFlush }
sub flush_sync         { shift->XSync }
sub flush_sync_discard { shift->XSync(1) }

=head3 fake_motion

  $display->fake_motion($screen, $x, $y, $send_delay = 10);

Generate a fake motion event on the server, optionally waiting
C<$send_delay> milliseconds.  If C<$screen> is -1, it references the
screen which the mouse is currently on.

=head3 fake_button

  $display->fake_button($button_number, $is_press, $send_delay = 10);

Generate a fake mouse button press or release.

=head3 fake_key

  $display->fake_key($key_code, $is_press, $send_delay = 10);

Generate a fake key press or release.  See L<X11::Xlib::Keymap/EXAMPLES>.

=cut

sub fake_motion { shift->XTestFakeMotionEvent(@_) }
sub fake_button { shift->XTestFakeButtonEvent(@_) }
sub fake_key    { shift->XTestFakeKeyEvent(@_) }

=head2 SCREEN

The following convenience methods pass-through to the default
L<screen|X11::Xlib::Screen> object:

=over

=item *

L<root_window|X11::Xlib::Screen/root_window>

=item *

L<width|X11::Xlib::Screen/width>

=item *

L<height|X11::Xlib::Screen/height>

=item *

L<width_mm|X11::Xlib::Screen/width_mm>

=item *

L<height_mm|X11::Xlib::Screen/height_mm>

=item *

L<visual|X11::Xlib::Screen/visual>

=item *

L<depth|X11::Xlib::Screen/depth>

=item *

L<colormap|X11::Xlib::Screen/colormap>

=back

=cut

sub root_window  { shift->{default_screen}->root_window }
sub width        { shift->{default_screen}->width }
sub height       { shift->{default_screen}->height }
sub width_mm     { shift->{default_screen}->width_mm }
sub height_mm    { shift->{default_screen}->height_mm }
sub visual       { shift->{default_screen}->visual }
sub depth        { shift->{default_screen}->depth }
sub colormap     { shift->{default_screen}->colormap }

=head2 VISUAL/COLORMAP

=head3 visual_info

  my $info= $display->visual_info();  # for default visual of default screen
  my $info= $display->visual_info($visual);
  my $info= $display->visual_info($visual_id);

Returns a L<X11::Xlib::XVisualInfo> for the specified visual, or undef if
none was found.  See L<X11::Xlib/Visual> for an explanation of the different
types of object.

=head3 match_visual_info

  my $info= $display->match_visual_info($screen_num, $color_depth, $class)
    or die "No matching visual";

Search for a visual on C<$scren_num> that matches the color depth and class.

=head3 search_visual_info

  # Search all visuals...
  my @infos= $display->search_visual_info(
    visualid      => $id,
    screen        => $screen,
    depth         => $depth,
    class         => $class,
    red_mask      => $mask,
    green_mask    => $mask,
    blue_mask     => $mask,
    colormap_size => $size,
    bits_per_rgb  => $n,
  );

Search for a visual by any of its L<X11::Xlib::XVisualInfo> members.
You can specify as many or as few fields as you like.

=cut

# Attach a pointer to self to each of the returned structs
sub XGetVisualInfo {
    my $self= $_[0];
    my @list= &X11::Xlib::XGetVisualInfo;
    $_->display($self) for @list;
    @list;
}

sub visual_info {
    my ($self, $visual_or_id)= @_;
    my $id= !defined $visual_or_id? $self->default_screen->visual->id
        : ref $visual_or_id? $visual_or_id->id
        : $visual_or_id;
    my $tpl= X11::Xlib::XVisualInfo->new({ visualid => $id });
    my ($match)= $self->XGetVisualInfo(X11::Xlib::VisualIDMask, $tpl);
    return $match;
}

sub match_visual_info {
    my ($self, $screen, $depth, $class)= @_;
    my $info;
    return $self->XMatchVisualInfo($screen, $depth, $class, $info)?
        $info : undef;
}

sub search_visual_info {
    my ($self, %args)= @_;
    $args{screen}= $args{screen}->screen_number
        if defined $args{screen} && ref $args{screen};
    my $flags= (defined $args{visualid}? X11::Xlib::VisualIDMask : 0)
        | (defined $args{screen}?        X11::Xlib::VisualScreenMask : 0)
        | (defined $args{depth}?         X11::Xlib::VisualDepthMask : 0)
        | (defined $args{class}?         X11::Xlib::VisualClassMask : 0)
        | (defined $args{red_mask}?      X11::Xlib::VisualRedMaskMask : 0)
        | (defined $args{green_mask}?    X11::Xlib::VisualGreenMaskMask : 0)
        | (defined $args{blue_mask}?     X11::Xlib::VisualBlueMaskMask : 0)
        | (defined $args{colormap_size}? X11::Xlib::VisualColormapSizeMask : 0)
        | (defined $args{bits_per_rgb}?  X11::Xlib::VisualBitsPerRGBMask : 0);
    return $self->XGetVisualInfo($flags, \%args);
}

=head2 RESOURCE CREATION

=head3 new_colormap

  my $cmap= $display->new_colormap($rootwindow, $visual, $alloc_flag);

Creates a new L<Colormap|X11::Xlib/Colormap> on the server, and wraps it with
a L<X11::Xlib::Colormap> object to track its lifespan.  If the object goes
out of scope it calls L<XFreeColormap|X11::Xlib/XFreeColormap>.

C<$rootwindow> defaults to the root window of the default screen.
C<$visual> defaults to the visual of the root window.
C<$allocFlag> defaults to C<AllocNone>.

=cut

sub new_colormap {
    shift->XCreateColormap(@_);
}
sub DefaultColormap {
    my $xid= X11::Xlib::DefaultColormap(@_);
    $_[0]->get_cached_colormap($xid);
}
sub XCreateColormap {
    my $xid= X11::Xlib::XCreateColormap(@_);
    $_[0]->get_cached_colormap($xid, autofree => 1);
}

=head3 new_pixmap

  my $pix= $display->new_pixmap($drawable, $width, $height, $color_depth);

Create a new L<Pixmap|X11::Xlib/Pixmap> on the server, and wrap it with a
L<X11::Xlib::Pixmap> object to track its lifespan.  If the object does
out of scope it calls L<XFreePixmap|X11::Xlib/XFreePixmap>.

C<$drawable>'s only purpose is to determine which screen to use, and so it
may also be a L<Screen|X11::Xlib::Screen> object.
C<$width> C<$height> and C<$color_depth> should be self-explanatory.

=cut

sub new_pixmap {
    my ($self, $drawable, $width, $height, $depth)= @_;
    $drawable ||= $self->screen->root_window;
    $drawable= $drawable->root_window
        if ref $drawable && $drawable->isa('X11::Xlib::Screen');
    return $self->XCreatePixmap($drawable, $width, $height, $depth);
}

sub XCreatePixmap {
    my ($self, $drawable, $width, $height, $depth)= @_;
    my $xid= &X11::Xlib::XCreatePixmap;
    return $self->get_cached_pixmap($xid,
        width    => $width,
        height   => $height,
        depth    => $depth,
        autofree => 1,
    );
}
sub XCreateBitmapFromData {
    my ($self, $drawable, $data, $width, $height)= @_;
    my $xid= &X11::Xlib::XCreateBitmapFromData;
    $self->get_cached_pixmap($xid,
        width    => $width,
        height   => $height,
        depth    => 1,
        autofree => 1,
    );
}
sub XCreatePixmapFromBitmapData {
    my ($self, $drawable, $data, $width, $height, $fg, $bg, $depth)= @_;
    my $xid= &X11::Xlib::XCreatePixmapFromBitmapData;
    $_[0]->get_cached_pixmap($xid,
        width    => $width,
        height   => $height,
        depth    => $depth,
        autofree => 1,
    );
}

*X11::Xlib::Display::XCompositeNameWindowPixmap= sub {
    my $xid= &X11::Xlib::XCompositeNameWindowPixmap;
    $_[0]->get_cached_pixmap($xid, autofree => 1);
} if X11::Xlib->can('XCompositeNameWindowPixmap');

=head3 new_window

  my $win= $display->new_window(
    parent => $window,  class    => $input_type,
    visual => $visual,  colormap => $colormap,  depth  => $color_depth,
    event_mask => $mask,  do_not_propagate_mask => $mask,
    override_redirect => $bool,
    x => $x,  y => $y,  width => $n_pix,  height => $n_pix,
    min_width         => $n_pix,      min_height       => $n_pix,
    max_width         => $n_pix,      max_height       => $n_pix,
    width_inc         => $n_pix,      height_inc       => $n_pix,
    min_aspect_x      => $numerator,  min_aspect_y     => $denominator,
    max_aspect_x      => $numerator,  max_aspect_y     => $denominator,
    base_width        => $width,      base_height      => $height,
    bit_gravity       => $val,        win_gravity      => $val,
    cursor            => $cursor,     border_width     => $n_pix,
    background_pixmap => $pixmap,     background_pixel => $color_int,
    border_pixmap     => $pixmap,     border_pixel     => $color_int,
    backing_store     => $val,        backing_planes   => $n_planes,
    backing_pixel     => $color_int,  save_under       => $bool,
  );

This method takes any argument to the XCreateWindow function and also any of
the fields of the L<X11::Xlib::XSetWindowAttributes> struct or L<X11::Xlib::XSizeHints>.
This saves you the trouble of calculating the attribute mask, and of a second
call to L<SetWMNormalHints|X11::Xlib/SetWMNormalHints> if you wanted to set those fields.

It first calls L</XCreateWindow>, which returns an XID, then wraps it with a
L<X11::Xlib::Window> object (which calls C<XDestroyWindow> if it goes out of
scope), then calls C<SetWMNormalHints> if you specified any of those fields.

=cut

my %attr_flags= (
    background_pixmap     => X11::Xlib::CWBackPixmap,
    background_pixel      => X11::Xlib::CWBackPixel,
    border_pixmap         => X11::Xlib::CWBorderPixmap,
    border_pixel          => X11::Xlib::CWBorderPixel,
    bit_gravity           => X11::Xlib::CWBitGravity,
    win_gravity           => X11::Xlib::CWWinGravity,
    backing_store         => X11::Xlib::CWBackingStore,
    backing_planes        => X11::Xlib::CWBackingPlanes,
    backing_pixel         => X11::Xlib::CWBackingPixel,
    save_undef            => X11::Xlib::CWSaveUnder,
    event_mask            => X11::Xlib::CWEventMask,
    do_not_propagate_mask => X11::Xlib::CWDontPropagate,
    override_redirect     => X11::Xlib::CWOverrideRedirect,
    colormap              => X11::Xlib::CWColormap,
    cursor                => X11::Xlib::CWCursor,
);
my @sizehint_specific_fields= qw(
    min_width min_height max_width max_height width_inc height_inc
    min_aspect_x min_aspect_y max_aspect_x max_aspect_y base_width
    base_height win_gravity
);
sub new_window {
    my ($self, %args)= @_;

    # Extract fields of XSetWindowAttributes
    my ($attrflags, %attrs)= (0);
    for (keys %attr_flags) {
        next unless defined $args{$_};
        $attrs{$_}= delete $args{$_};
        $attrflags |= $attr_flags{$_};
    }

    # Extract XCreateWindow args.
    # x,y,width,height are shared by XSizeHints
    my ($x, $y, $w, $h, $parent, $border, $depth, $class, $visual)
        = delete @args{qw( x y width height parent border_width depth class visual )};
    $x ||= 0;
    $y ||= 0;
    $w ||= $args{min_width} || 0;
    $h ||= $args{min_height} || 0;
    $border ||= 0;
    $depth= X11::Xlib::CopyFromParent unless defined $depth;
    $class= X11::Xlib::CopyFromParent unless defined $class;
    $visual= X11::Xlib::CopyFromParent unless defined $visual;

    # Now extract fields specific to XSizeHints
    my %sizehints;
    defined $args{$_} && ($sizehints{$_}= delete $args{$_})
        for @sizehint_specific_fields;

    # croak if there is anything left over
    croak("Unknown attributes passed to new_window: ".join(',', keys %args))
        if keys %args;

    my $wnd= $self->XCreateWindow(
        $args{parent} || $self->root_window,
        $x, $y, $w, $h, $border,
        $depth, $class, $visual,
        $attrflags, \%attrs
    );

    if (keys %sizehints) {
        # XSizeHints->pack will set its own flags for the fields that are present.
        @sizehints{qw( x y width height )}= ($x, $y, $w, $h);
        $self->XSetWMNormalHints($wnd, \%sizehints)
    }

    return $wnd;
}

sub RootWindow {
    $_[0]->get_cached_window( &X11::Xlib::RootWindow );
}

=head3 XCreateWindow

Like L<X11::Xlib/XCreateWindow>, but returns a L<X11::Xlib::Window> object.

=head3 XCreateSimpleWindow

Like L<X11::Xlib::XCreateSimpleWindow>, but returns a L<X11::Xlib::Window> object.

=cut

sub XCreateWindow {
    $_[0]->get_cached_window( &X11::Xlib::XCreateWindow, autofree => 1);
}

sub XCreateSimpleWindow {
    $_[0]->get_cached_window( &X11::Xlib::XCreateSimpleWindow, autofree => 1);
}

*X11::Xlib::Display::XCompositeGetOverlayWindow= sub {
    my $xid= &X11::Xlib::XCompositeGetOverlayWindow;
    $_[0]->get_cached_window( $xid, autofree => 0 ); # can be only one, and needs freed specially
} if X11::Xlib->can('XCompositeGetOverlayWindow');

*X11::Xlib::Display::XCompositeCreateRegionFromBorderClip= sub {
    my $self= $_[0];
    my $xid= &X11::Xlib::XCompositeCreateRegionFromBorderClip;
    $self->get_cached_region( $xid, autofree => 1 );
} if X11::Xlib->can('XCompositeCreateRegionFromBorderClip');

*X11::Xlib::Display::XFixesCreateRegion= sub {
    my $self= $_[0];
    my $xid= &X11::Xlib::XFixesCreateRegion;
    $self->get_cached_region( $xid, autofree => 1 );
} if X11::Xlib->can('XFixesCreateRegion');

=head2 INPUT

=head3 keymap

  my $keymap= $display->keymap; # lazy-loaded instance of X11::Xlib::Keymap

X11 Operates on keyboard scan codes, and leaves interpreting them to the
client.  The server holds a mapping table of scan codes and modifiers which
all clients share and can modify as needed, though the X server never uses the
table itself.
The details are hairy enough that I moved them to their own module.
See L<X11::Xlib::Keymap> for details.

The first time you access C<keymap> it fetches the tables from the server.
The tables may change on the fly, so you should watch for MappingNotify events
to know when to reload the keymap.

Note that if you only need Latin-1 translation of key codes, you can just use
L<X11::Xlib/XLookupString> and L<X11::Xlib/XRefreshKeyboardMapping> to have
Xlib do all the heavy lifting.

=cut

sub keymap {
    my $self= shift;
    if (@_) { $self->{keymap}= shift; }
    $self->{keymap} ||= $self->_build_keymap if defined wantarray;
}

sub _build_keymap {
    my $self= shift;
    require X11::Xlib::Keymap;
    return X11::Xlib::Keymap->new(
        display => $self,
    );
}

=head3 keyboard_leds

  my $bits= $display->keyboard_leds;
  printf("LED 1 is %s\n", $bits & 1? "lit" : "not lit");

Return an integer mask value for the currently-lit keyboard LEDs.
Each LED gets one bit of the integer, starting from the least significant.
(The docs make no mention of the meaning of each LED)

=cut

# comes from XS

=head2 CACHE MANAGEMENT

The Display object keeps weak references to the wrapper objects it creates so
that if you fetch the same resource again, you get the same object instance as
last time.  These methods are made public so that you can get the same behavior
when working with XIDs that weren't already wrapped by this module.

There is also a cache of wrapper objects of the opaque pointers allocated for
a display.  This cache is private.

=head3 get_cached_xobj

  my $obj= $display->get_cached_xobj( $xid, $class, @new_args );

If C<$xid> already references an object, return that object.  Else create
a new object of type C<$class> and initialize it with the list of arguments.
If C<$class> is not given it defaults to L<X11::Xlib::XID>.

=cut

sub _xid_cache { $_[0]{_xid_cache} }
sub get_cached_xobj {
    my ($self, $xid, $class)= (shift, shift, shift);
    my $obj;
    # In case an object is accidentally passed, prevent confusion by returning
    # the canonical version, or making the passed object the canonical one.
    if (ref $xid and ref($xid)->isa($class || 'X11::Xlib::XID')) {
        $obj= $xid;
        $xid= $obj->xid;
    }
    return $self->{_xid_cache}{$xid} || do {
        $obj ||= ($class || 'X11::Xlib::XID')->new(
            display => $self,
            xid => $xid,
            (@_==1 && ref $_[0] eq 'HASH'? %{$_[0]} : @_)
        );
        Scalar::Util::weaken( $self->{_xid_cache}{$xid}= $obj );
        $obj;
    };
}

=head3 get_cached_colormap

  my $colormap= $display->get_cached_colormap($xid, @new_args);

Shortcut for L</get_cached_xobj> that implies a class of L<X11::Xlib::Colormap>

=head3 get_cached_pixmap

  my $pixmap= $display->get_cached_pixmap($xid, @new_args);

Shortcut for L</get_cached_xobj> that implies a class of L<X11::Xlib::Pixmap>

=head3 get_cached_window

  my $window= $display->get_cached_window($xid, @new_args);

Shortcut for L</get_cached_xobj> that implies a class of L<X11::Xlib::Window>

=cut

sub get_cached_colormap {
    shift->get_cached_xobj(shift, 'X11::Xlib::Colormap', @_);
}
sub get_cached_pixmap {
    shift->get_cached_xobj(shift, 'X11::Xlib::Pixmap', @_);
}
sub get_cached_window {
    shift->get_cached_xobj(shift, 'X11::Xlib::Window', @_);
}
sub get_cached_region {
    shift->get_cached_xobj(shift, 'X11::Xlib::XserverRegion', @_);
}

1;

__END__

=head1 AUTHOR

Olivier Thauvin, E<lt>nanardon@nanardon.zarb.orgE<gt>

Michael Conrad, E<lt>mike@nrdvana.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2010 by Olivier Thauvin

Copyright (C) 2017-2020 by Michael Conrad

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
