package Tk::TickitBridge;

use v5.36;
use Carp qw(croak);
use Scalar::Util qw(blessed refaddr weaken);
use Tickit 0.70 ();
use Tk qw(Ev);

our $VERSION = '0.001';

my %SPECIAL = (
    BackSpace => 'Backspace', Return => 'Enter', KP_Enter => 'Enter',
    Escape => 'Escape', Tab => 'Tab', ISO_Left_Tab => 'Tab', space => 'Space',
    Up => 'Up', Down => 'Down', Left => 'Left', Right => 'Right',
    Insert => 'Insert', Delete => 'Delete', Prior => 'PageUp',
    Next => 'PageDown', Home => 'Home', End => 'End',
);

sub new ($class, %args) {
    my $term = $args{term} // croak 'term is required';
    my $widget = $args{widget} // croak 'widget is required';
    croak 'term must provide emit_key()'
        unless blessed($term) && $term->can('emit_key');
    croak 'widget must be a Tk widget'
        unless blessed($widget) && $widget->isa('Tk::Widget');
    my $policy = $args{forward} // 'outside';
    croak 'forward must be outside, always, or a coderef'
        unless ref($policy) eq 'CODE'
            || (!ref($policy) && $policy =~ /\A(?:outside|always)\z/);
    croak 'on_error must be a coderef'
        if exists($args{on_error}) && ref($args{on_error}) ne 'CODE';
    my $self = bless {
        term => $term, widget => $widget, queue => [], attached => [],
        forward => $policy, consume => $args{consume} // 1,
        shift_mask => $args{shift_mask} // 0x0001,
        control_mask => $args{control_mask} // 0x0004,
        alt_mask => $args{alt_mask} // 0x0008,
        on_error => $args{on_error} // sub ($message) { warn "$message\n" },
    }, $class;
    $self->{tag} = 'TkTickitBridge_' . refaddr($self);
    weaken($self->{widget});
    return $self;
}

sub install ($self) {
    return $self if $self->{installed};
    my $widget = $self->{widget};
    croak 'Tk widget has been destroyed' unless Tk::Exists($widget);
    my $weak = $self;
    weaken($weak);
    $widget->bind($self->{tag}, '<KeyPress>' => [
        sub ($source, $keysym, $char, $state) {
            return unless $weak;
            $weak->_on_tk_key($source, $keysym, $char, $state);
        }, Ev('K'), Ev('A'), Ev('s'),
    ]);
    $self->{installed} = 1;
    $self->attach($widget);
    return $self;
}

# Attach the current subtree. Call again for widgets created after install().
sub attach ($self, $widget) {
    croak 'Call install() before attach()' unless $self->{installed};
    croak 'Cannot attach a destroyed widget' unless Tk::Exists($widget);
    my @tags = $widget->bindtags;
    unless (grep { $_ eq $self->{tag} } @tags) {
        $widget->bindtags([$self->{tag}, @tags]);
        push $self->{attached}->@*, $widget;
        weaken($self->{attached}[-1]);
    }
    $self->attach($_) for $widget->children;
    return $self;
}

sub uninstall ($self) {
    $self->_cancel_drain;
    $self->{queue} = [];
    for my $widget ($self->{attached}->@*) {
        next unless Tk::Exists($widget);
        my @tags = grep { $_ ne $self->{tag} } $widget->bindtags;
        $widget->bindtags(\@tags);
    }
    $self->{attached} = [];
    my $widget = $self->{widget};
    $widget->bind($self->{tag}, '<KeyPress>' => '') if Tk::Exists($widget);
    $self->{installed} = 0;
    return $self;
}

sub enqueue ($self, %event) {
    croak 'type must be text or key'
        unless ($event{type} // '') =~ /\A(?:text|key)\z/;
    croak 'str must be a nonempty string'
        unless defined($event{str}) && length($event{str});
    push $self->{queue}->@*, {
        type => $event{type}, str => $event{str}, mod => $event{mod} // 0,
    };
    $self->_schedule_drain;
    return;
}

sub pending ($self) { scalar $self->{queue}->@* }

sub drain ($self) {
    $self->_cancel_drain;
    # A handler may enqueue another event. Leave it for the next idle turn.
    my $batch = $self->{queue};
    $self->{queue} = [];
    for my $event ($batch->@*) {
        my $ok = eval { $self->{term}->emit_key($event->%*); 1 };
        $self->{on_error}->("Unable to inject Tk key into Tickit: $@") unless $ok;
    }
    $self->_schedule_drain if $self->pending;
    return;
}

sub _on_tk_key ($self, $source, $keysym, $char, $state) {
    my $policy = $self->{forward};
    if (ref($policy) eq 'CODE') {
        return unless $policy->($source, $keysym, $char, $state);
    }
    elsif ($policy eq 'outside') {
        my $widget = $self->{widget} or return;
        my ($x, $y) = $widget->pointerxy;
        return if $x >= 0 && $y >= 0 && $widget->containing($x, $y);
    }
    my $event = $self->translate_key($keysym, $char, $state) or return;
    $self->enqueue($event->%*);
    Tk->break if $self->{consume};
    return;
}

sub translate_key ($self, $keysym, $char, $state) {
    $keysym //= '';
    $char //= '';
    $state //= 0;
    my $mod = 0;
    $mod |= Tickit::MOD_SHIFT() if $state & $self->{shift_mask};
    $mod |= Tickit::MOD_CTRL() if $state & $self->{control_mask};
    $mod |= Tickit::MOD_ALT() if $state & $self->{alt_mask};
    if (my $name = $SPECIAL{$keysym}) {
        $mod |= Tickit::MOD_SHIFT() if $keysym eq 'ISO_Left_Tab';
        return { type => 'key', str => $name, mod => $mod };
    }
    return { type => 'key', str => $keysym, mod => $mod }
        if $keysym =~ /\AF\d+\z/;
    if (length($char) && $char !~ /[\x00-\x1f\x7f]/) {
        return { type => 'text', str => $char, mod => 0 }
            unless $mod & (Tickit::MOD_CTRL() | Tickit::MOD_ALT());
        $mod &= ~Tickit::MOD_SHIFT();
        return { type => 'key', str => $char, mod => $mod };
    }
    if (($mod & Tickit::MOD_CTRL()) && $keysym =~ /\A[A-Za-z]\z/) {
        $mod &= ~Tickit::MOD_SHIFT();
        return { type => 'key', str => lc($keysym), mod => $mod };
    }
    return;
}

sub _schedule_drain ($self) {
    return if $self->{idle} || !$self->pending;
    my $widget = $self->{widget};
    return unless Tk::Exists($widget);
    my $weak = $self;
    weaken($weak);
    $self->{idle} = $widget->afterIdle(sub {
        return unless $weak;
        delete $weak->{idle};
        $weak->drain;
    });
    return;
}

sub _cancel_drain ($self) {
    my $idle = delete $self->{idle} or return;
    $idle->cancel;
    return;
}

sub DESTROY ($self) { local $@; eval { $self->uninstall } }

1;

__END__

=head1 NAME

Tk::TickitBridge - forward Perl/Tk keyboard events to Tickit

=head1 SYNOPSIS

    use Tk::TickitBridge;
    use Tk::TickitBridge::Loop;

    # Create Tk widgets and a Tickit::Async object first.
    $loop->add($tickit);
    my $bridge = Tk::TickitBridge->new(
        widget => $mw,
        term   => $tickit->term,
    )->install;
    my $pump = Tk::TickitBridge::Loop->new(
        widget => $mw, loop => $loop,
    )->start;

    Tk::MainLoop();
    $pump->stop;
    $bridge->uninstall;
    $tickit->term->teardown;

=head1 DESCRIPTION

This module extracts Nama's Tk-to-Tickit keyboard bridge into an independent
distribution. It translates Tk keysyms, printable Unicode text, function keys,
and Shift/Control/Alt modifiers into C<Tickit::Term-E<gt>emit_key()> calls.
Delivery is queued until Tk's next idle turn, avoiding delivery inside the
original Tk key binding.

It does not embed a terminal in a Tk window. Tk and Tickit keep their own
windows and share a single process. See F<examples/bridge-demo.pl>.

=head1 CONSTRUCTOR

C<new(widget =E<gt> $widget, term =E<gt> $term, ...)> takes a live Tk widget
and a Tickit terminal supporting C<emit_key> (Tickit 0.70 or later).

=over 4

=item forward

C<outside> (default) forwards only when the mouse pointer is outside the
application's Tk windows, preserving Nama's pointer-based policy. C<always>
forwards every supported key received by an attached widget. A coderef receives
C<($source_widget, $keysym, $character, $state)> and returns true to forward.
These policies only apply to events Tk actually receives; they do not capture
keys globally or move keyboard focus.

=item consume

Defaults to true. A forwarded key stops further Tk binding processing. Set to
false to allow both interfaces to handle it. A private bindtag runs before the
widget's normal tags, so consumption also protects native Tk entry widgets.

=item on_error

A coderef receiving a message when C<emit_key> throws. Defaults to C<warn>.
Errors from a custom forwarding policy are handled by Tk's error mechanism.

=item shift_mask, control_mask, alt_mask

Tk modifier masks; defaults are C<0x0001>, C<0x0004>, and C<0x0008>.
Alt normally uses X11 Mod1; customize it for other mappings. Bare modifiers,
unsupported keysyms, and input-method composition are not synthesized.

=back

=head1 METHODS

=over 4

=item install

Installs a private binding and prepends its bindtag to C<widget> and its current
descendants. Repeated installation is harmless. Keep the bridge object alive.
Existing application-wide C<all> bindings are not changed.

=item attach($widget)

Attaches another widget and its current descendants. Use this for widgets or
toplevels created after C<install>. Attach widgets from the same Tk application.

=item uninstall

Removes this bridge's tags and binding, cancels pending idle delivery, and
discards queued keys. Other bindings and bindtag changes are preserved.
Safe to repeat, including after the Tk window has been destroyed. The object
can subsequently be installed again.

=item translate_key($keysym, $character, $state)

Returns an event hashref containing C<type>, C<str>, and C<mod>, or undef for an
unsupported key. Does not enqueue or deliver it.

=item enqueue(type =E<gt> 'text' | 'key', str =E<gt> $string, mod =E<gt> $mask)

Queues a synthetic event and schedules idle delivery. C<mod> defaults to zero.
This also works before C<install> for applications using only synthetic input.

=item pending

Returns the number of queued events.

=item drain

Delivers the current batch immediately. Events enqueued by a handler are left
for a later idle turn.

=back

=head1 EVENT LOOPS

Keyboard forwarding does not service terminal input, redraws, IO::Async timers,
or file descriptors. For that use L<Tk::TickitBridge::Loop>, which periodically
calls C<loop_once(0)> while Tk owns the main loop. Callbacks remain cooperative:
a blocking callback in either interface blocks both.

=head1 AUTHOR AND LICENSE

Copyright (c) 2026 Joel Roth. This is free software; you may redistribute it and/or modify it under the
same terms as Perl itself.
Extracted from Audio::Nama; see F<LICENSE>.

=cut
