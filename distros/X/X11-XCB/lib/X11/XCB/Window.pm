package X11::XCB::Window;

use Mouse;
use Mouse::Util::TypeConstraints;
use X11::XCB::Rect;
use X11::XCB::Connection;
use X11::XCB::Atom;
use X11::XCB::Color;
use X11::XCB::Sizehints;
use X11::XCB qw(:all);
use Data::Dumper;
use v5.10;

# A valid window type is every string, which, appended to _NET_WM_WINDOW_TYPE_
# returns an existing atom.
subtype 'ValidWindowType'
    => as 'Str'
    => where {
        X11::XCB::Atom->new(name => '_NET_WM_WINDOW_TYPE_' . uc($_))->exists;
    }
    => message { "The window type you provided ($_) does not exist" };

# We can make an Atom out of a valid window type
coerce 'X11::XCB::Atom'
    => from 'ValidWindowType'
    => via { X11::XCB::Atom->new(name => '_NET_WM_WINDOW_TYPE_' . uc($_)) };

has 'class' => (is => 'ro', isa => 'Str', required => 1);
has 'id' => (is => 'ro', isa => 'Int', lazy_build => 1);
has 'parent' => (is => 'ro', isa => 'Int', required => 1);
has '_rect' => (is => 'ro', isa => 'X11::XCB::Rect', required => 1, init_arg => 'rect', coerce => 1);
has 'window_type' => (is => 'rw', isa => 'X11::XCB::Atom', coerce => 1, trigger => \&_update_type);
has 'transient_for' => (is => 'rw', isa => 'X11::XCB::Window', trigger => \&_update_transient_for);
has 'wm_class' => (is => 'rw', isa => 'Str', trigger => \&_update_wm_class);
has 'instance' => (is => 'rw', isa => 'Str', trigger => \&_update_wm_class);
has 'client_leader' => (is => 'rw', isa => 'X11::XCB::Window', trigger => \&_update_client_leader);
has 'override_redirect' => (is => 'ro', isa => 'Int', default => 0);
has 'background_color' => (is => 'ro', isa => 'X11::XCB::Color', coerce => 1, predicate => '_has_background_color');
has 'name' => (is => 'rw', isa => 'Str', trigger => \&_update_name);
has 'fullscreen' => (is => 'rw', isa => 'Int', trigger => \&_update_fullscreen);
has 'border' => (is => 'rw', isa => 'Int', default => 0, trigger => \&_update_border);
has 'hints' => (is => 'rw', isa => 'X11::XCB::Sizehints', lazy_build => 1);
has 'event_mask' => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub { [] },
);
has 'protocols' => (
    is => 'ro',
    isa => 'ArrayRef[X11::XCB::Atom]',
    default => sub { [] },
);
has '_hints' => (is => 'rw', isa => 'ArrayRef', default => sub { [ ] });
has '_conn' => (is => 'ro', required => 1);
has '_mapped' => (is => 'rw', isa => 'Int', default => 0);
has '_created' => (is => 'rw', isa => 'Int', default => 0);

# Theese two are PP implementation of MouseX::NativeTraits for 'protocols' Array
sub no_protocols { !! @{ $_[0]->protocols } };
sub protocols_count { 0+ @{ $_[0]->protocols } };

sub _build_id {
    my $self = shift;

    return $self->_conn->generate_id();
}

sub _build_hints {
    my $self = shift;

    return X11::XCB::Sizehints->new(_conn => $self->_conn, window => $self->id);
}

=encoding utf-8

=head1 NAME

X11::XCB::Window - represents an X11 window

=head1 METHODS

=head2 rect

As long as the window is not mapped, this returns the planned geometry. As soon
as the window is mapped, this returns its geometry B<including> the window
decorations.

Thus, after the window is mapped, every time you access C<rect>, the geometry
will be determined by querying X11 about it, thus generating at least 1 round-
trip for non-reparenting window managers and two or more round-trips for
reparenting window managers.

In scalar context it returns only the window’s geometry, in list context it
returns the window’s geometry and the geometry of the top window (the one
containing this window but the first one under the root window in hierarchy).
=cut
sub rect {
    my $self = shift;
    my $conn = $self->_conn;

    my $arg = shift;

    if ($arg) {
        # Set the given geometry
        my $mask = CONFIG_WINDOW_X |
                   CONFIG_WINDOW_Y |
                   CONFIG_WINDOW_WIDTH |
                   CONFIG_WINDOW_HEIGHT;
        my @values = ($arg->x, $arg->y, $arg->width, $arg->height);
        $conn->configure_window($self->id, $mask, @values);
        $conn->flush;
        return;
    }

    # Return the planned geometry if we’re not yet mapped
    return $self->_rect unless $self->_mapped;

    # Get the relative geometry
    my $cookie = $conn->get_geometry($self->id);
    my $relative_geometry = $conn->get_geometry_reply($cookie->{sequence});

    my $last_id = $self->id;

    while (1) {
        $cookie = $conn->query_tree($last_id);
        my $reply = $conn->query_tree_reply($cookie->{sequence});

        # If this is the root window, we stop here
        last if ($reply->{root} == $reply->{parent}) or $reply->{parent} == 0;

        $last_id = $reply->{parent};
    }

    # If this window is a direct child of the root window, the relative
    # geometry is equal to the absolute geometry
    return X11::XCB::Rect->new($relative_geometry) if ($last_id == $self->id);

    $cookie = $conn->get_geometry($last_id);
    my $parent_geometry = $conn->get_geometry_reply($cookie->{sequence});

    my $absolute = X11::XCB::Rect->new(
            x => $parent_geometry->{x} + $relative_geometry->{x},
            y => $parent_geometry->{y} + $relative_geometry->{y},
            width => $relative_geometry->{width},
            height => $relative_geometry->{height},
    );

    return wantarray ? ($absolute, X11::XCB::Rect->new($parent_geometry)) : $absolute;
}

sub _create {
    my $self = shift;
    my $mask = 0;
    my @values;

    my $x = $self->_conn;

    if ($self->_has_background_color) {
        $mask |= CW_BACK_PIXEL;
        push @values, $self->background_color->pixel;
    }


    if ($self->override_redirect == 1) {
        $mask |= CW_OVERRIDE_REDIRECT;
        push @values, 1;
    }

    my @event_mask = @{$self->event_mask};
    if (@event_mask > 0) {
        $mask |= CW_EVENT_MASK;
        my $value = 0;
        for my $flag (@event_mask) {
            my $name = 'EVENT_MASK_' . uc($flag);
            no strict 'refs';
            $value |= $name->();
        }
        push @values, $value;
    }

    $x->create_window(
            WINDOW_CLASS_COPY_FROM_PARENT,
            $self->id,
            $self->parent,
            $self->_rect->x,
            $self->_rect->y,
            $self->_rect->width,
            $self->_rect->height,
            $self->border, # border
            $self->class,
            0, # copy visual TODO
            $mask,
            @values
    );

    $self->_created(1);

    $self->_update_type if defined($self->window_type);
    $self->_update_name if defined($self->name);
    $self->_update_transient_for if defined($self->transient_for);
    $self->_update_client_leader if defined($self->client_leader);
    $self->_update_wm_class if defined($self->wm_class) || defined($self->instance);

    if (!$self->no_protocols) {
        my $atomname = $x->atom(name => 'WM_PROTOCOLS', create => 1);
        my $atomtype = $x->atom(name => 'ATOM'); # predefined
        my $atoms = pack('L*', map { $_->id } @{$self->protocols});

        $x->change_property(
            PROP_MODE_REPLACE,
            $self->id,
            $atomname->id,
            $atomtype->id,
            32,
            $self->protocols_count,
            $atoms,
        );
    }
}

=head2 attributes

Returns the X11 attributes of this window.

=cut
sub attributes {
    my $self = shift;
    my $conn = $self->_conn;

    my $cookie = $conn->get_window_attributes($self->id);
    my $attributes = $conn->get_window_attributes_reply($cookie->{sequence});

    return $attributes;
}

=head2 map

Maps the window on the screen, that is, makes it visible.

=cut
sub map {
    my $self = shift;

    $self->_create unless ($self->_created);

    $self->_conn->map_window($self->id);
    $self->_conn->flush;
    $self->_mapped(1);
}

=head2 unmap

The opposite of L<map>, that is, makes your window invisible.

=cut
sub unmap {
    my $self = shift;

    $self->_conn->unmap_window($self->id);
    $self->_conn->flush;
    $self->_mapped(0);
}

=head2 destroy

Destroys the window completely

=cut
sub destroy {
    my $self = shift;

    $self->_conn->destroy_window($self->id);
    $self->_conn->flush;
    $self->_created(0);
}

=head2 mapped

Returns whether the window is actually mapped (no internal state, but gets
the window attributes from X11 and checks for MAP_STATE_VIEWABLE).

=cut
sub mapped {
    my $self = shift;

    my $attributes = $self->attributes;

    # MAP_STATE_UNVIEWABLE is used when the window itself is mapped but one
    # of its ancestors is not
    return ($attributes->{map_state} == MAP_STATE_VIEWABLE);
}

sub _update_name {
    my $self = shift;

    # Make sure the window is created first. _create calls _update_name, so we
    # are done.
    return $self->_create unless $self->_created;

    my $conn = $self->_conn;
    my $atomname = $conn->atom(name => '_NET_WM_NAME', create => 1);
    my $atomtype = $conn->atom(name => 'UTF8_STRING', create => 1);
    my $strlen;

    # Disable UTF8 mode to get the raw amount of bytes in this string
    { use bytes; $strlen = length($self->name); }

    $self->_conn->change_property(
            PROP_MODE_REPLACE,
            $self->id,
            $atomname->id,
            $atomtype->id,
            8,      # 8 bit per entity
            $strlen,    # length(name) entities
            $self->name
    );
    $self->_conn->flush;
}

sub _update_fullscreen {
    my $self = shift;
    my $conn = $self->_conn;
    my $atomname = $conn->atom(name => '_NET_WM_STATE', create => 1);

    $self->_create unless ($self->_created);

    # If we’re already mapped, we have to send a client message to the root
    # window containing our request to change the _NET_WM_STATE atom.
    #
    # (See EWMH → Application window properties)
    if ($self->_mapped) {
        my %event = (
                response_type => CLIENT_MESSAGE,
                format => 32,   # 32-bit values
                sequence => 0,  # filled in by xcb
                window => $self->id,
                type => $atomname->id,
        );

        my $packed = pack('CCSLL(LLLL)',
                $event{response_type},
                $event{format},
                $event{sequence},
                $event{window},
                $event{type},
                ($self->fullscreen ? _NET_WM_STATE_ADD : _NET_WM_STATE_REMOVE),
                $conn->atom(name => '_NET_WM_STATE_FULLSCREEN', create => 1)->id,
                0,
                1, # normal application
        );

        $conn->send_event(
                0, # don’t propagate (= send only to matching clients)
                $conn->get_root_window(),
                EVENT_MASK_SUBSTRUCTURE_REDIRECT,
                $packed
        );
    } else {
        my $atomtype = $conn->atom(name => 'ATOM'); # predefined
        my $atoms;
        if ($self->fullscreen) {
            my $atom = $conn->atom(name => '_NET_WM_STATE_FULLSCREEN', create => 1);
            $atoms = pack('L', $atom->id);
        }

        $conn->change_property(
                PROP_MODE_REPLACE,
                $self->id,
                $atomname->id,
                $atomtype->id,
                32,         # 32 bit integer
                1,
                $atoms,
        );
    }

    $conn->flush;
}

sub _update_border {
    my $self = shift;
    my $conn = $self->_conn;

    return unless $self->_created;

    my $mask = CONFIG_WINDOW_BORDER_WIDTH;
    my @values = ($self->border);
    $conn->configure_window($self->id, $mask, @values);
    $conn->flush;
}

sub _update_type {
    my $self = shift;
    my $conn = $self->_conn;
    my $atomname = $conn->atom(name => '_NET_WM_WINDOW_TYPE', create => 1);
    my $atomtype = $conn->atom(name => 'ATOM'); # predefined

    # If we are not mapped, this property will be set when creating the window
    return unless ($self->_created);

    $self->_conn->change_property(
        PROP_MODE_REPLACE,
        $self->id,
        $atomname->id,
        $atomtype->id,
        32,         # 32 bit integer
        1,
        pack('L', $self->window_type->id)
    );
    $self->_conn->flush;
}

sub _update_transient_for {
    my $self = shift;
    my $conn = $self->_conn;
    my $atomname = $conn->atom(name => 'WM_TRANSIENT_FOR', create => 1);
    my $atomtype = $conn->atom(name => 'WINDOW'); # predefined

    # If we are not mapped, this property will be set when creating the window
    return unless ($self->_created);

    $self->_conn->change_property(
        PROP_MODE_REPLACE,
        $self->id,
        $atomname->id,
        $atomtype->id,
        32,         # 32 bit integer
        1,
        pack('L', $self->transient_for->id)
    );
    $self->_conn->flush;
}

sub _update_wm_class {
    my $self = shift;
    return unless $self->_created;

    my $conn = $self->_conn;
    my $atomname = $conn->atom(name => 'WM_CLASS'); # predefined
    my $atomtype = $conn->atom(name => 'STRING'); # predefined

    # Fall back to the wm_class if instance is not defined.
    my $instance = $self->instance // $self->wm_class;

    $conn->change_property(
        PROP_MODE_REPLACE,
        $self->id,
        $atomname->id,
        $atomtype->id,
        8,
        length($self->wm_class) + length($instance) + 2,
        "$instance\x00" . $self->wm_class . "\x00",
    );

}

sub _update_client_leader {
    my $self = shift;
    my $conn = $self->_conn;
    my $atomname = $conn->atom(name => 'WM_CLIENT_LEADER', create => 1);
    my $atomtype = $conn->atom(name => 'WINDOW'); # predefined

    # If we are not mapped, this property will be set when creating the window
    return unless ($self->_created);

    $self->_conn->change_property(
        PROP_MODE_REPLACE,
        $self->id,
        $atomname->id,
        $atomtype->id,
        32,         # 32 bit integer
        1,
        pack('L', $self->client_leader->id)
    );
    $self->_conn->flush;
}

=head2 create_child(options)

Creates a new C<X11::XCB::Window> as a child window of the current window.

=cut
sub create_child {
    my $self = shift;

    return X11::XCB::Window->new(
        _conn => $self->_conn,
        parent => $self->id,
        @_,
    );
}

=head2 add_hint($hint)

Adds the given C<$hint> (one of "urgency") to the window’s set of hints.

=cut
sub add_hint {
    my ($self, $hint) = @_;

    # check if $self->_hints contains the hint already, then do nothing
    return if (scalar grep { $_ eq $hint } @{$self->_hints}) > 0;

    # else add the hint to array
    push @{$self->_hints}, $hint;

    $self->_update_hints;
}

=head2 delete_hint($hint)

Opposite of L<add_hint>.

=cut
sub delete_hint {
    my ($self, $hint) = @_;

    @{$self->_hints} = grep { !/$hint/ } @{$self->_hints};

    $self->_update_hints;
}

sub _update_hints {
    my ($self) = @_;

    my $hints = X11::XCB::ICCCM::WMHints->new;

    for my $hint (@{$self->_hints}) {
        if ($hint eq 'urgency') {
            $hints->set_urgency();
        }
        if ($hint eq 'input') {
            $hints->set_input(1);
        }
    }

    X11::XCB::ICCCM::set_wm_hints($self->_conn, $self->id, $hints);
    $self->_conn->flush;
}

=head2 warp_pointer($x, $y)

Moves the pointer to the offsets ($x, $y) relative to the origin of the
window on which it is called. If $x and $y are undef, moves the pointer
into the center of the window.

=cut
sub warp_pointer {
    my ($self, $x, $y) = @_;

    # If no coordinates were given, we warp the pointer into the center
    if (!defined($x) and !defined($y)) {
        my $rect = $self->rect;
        $x = $rect->{width} / 2;
        $y = $rect->{height} / 2;
    }

    # If just one coordinate was undef, we use 0
    $x ||= 0;
    $y ||= 0;

    # TODO: s/0/XCB_NONE
    $self->_conn->warp_pointer(0, $self->id, 0, 0, 0, 0, $x, $y);
    $self->_conn->flush;
}

=head2 state

Returns the WM_STATE of this window (normal, withdrawn, iconic).

=cut
sub state {
    my ($self) = @_;

    my $conn = $self->_conn;
    my $state = $conn->atom(name => 'WM_STATE')->id; # predefined
    my $cookie = $conn->get_property(0, $self->id, $state, 0, 0, 8);
    my $reply = $conn->get_property_reply($cookie->{sequence});
    return unpack('L', $reply->{value});
}

1
# vim:ts=4:sw=4:expandtab
