
package Tk::SignalSlot;

use strict;
use Carp;

our $VERSION = 0.1;

my %connected;
my @ids;
my $newID = 0;

sub connect {
    my ($parent, $event, $code) = @_;

    unless ($event && $code) {
	croak "connect usage - need an event description and a callback";
    }

    # create the callback object.
    my $cb = Tk::Callback->new($code);

    # if this is the first time we connect to this event,
    # create the Tk binding for it.
    unless (exists $connected{$parent}{$event}) {
	$parent->Tk::bind($event => sub {
	    $_ && $_->Call() for @{$connected{$parent}{$event}};
	});

	$connected{$parent}{$event} = [];
    }

    my $index = @{$connected{$parent}{$event}};
    $connected{$parent}{$event}[$index] = $cb;

    $ids[$newID] = [$parent, $event, $index];
    return $newID++;
}

sub disconnect {
    my ($w, $id) = @_;

    if ($id > $#ids) {
	carp "disconnect - Callback ID $id not defined!";
	return undef;
    }

    my ($parent, $event, $index) = @{$ids[$id]};

    unless (defined $connected{$parent}{$event}[$index]) {
	carp "disconnect - Callback ID $id already disconnected!";
	return undef;
    }

    $connected{$parent}{$event}[$index] = undef;

    return 1;
}

sub is_connected {
    my ($w, $id) = @_;

    return 0 if $id > $#ids;

    my ($parent, $event, $index) = @{$ids[$id]};
    return 0 unless defined $connected{$parent}{$event}[$index];

    return 1;
}

package Tk;

use strict;

*connect      = \&Tk::SignalSlot::connect;
*disconnect   = \&Tk::SignalSlot::disconnect;
*is_connected = \&Tk::SignalSlot::is_connected;

1;

__END__

=head1 NAME

Tk::SignalSlot - An alternative to Tk::bind

=head1 SYNOPSIS

    use Tk::SignalSlot;

    $w->connect('<1>' => \&callback1);
    $w->connect('<1>' => \&callback2);

    my $id = $w->connect('<<Event>>' => \&callback3);
    ...
    $w->disconnect($id) if $w->is_connected($id);

=head1 DESCRIPTION

B<Tk::SignalSlot> provides an alternative to Tk::bind that is more similar to
Qt's signal/slot mechanism. The main idea is that multiple callbacks
can now be bound to one event. This allows for a more modular and
object-oriented approach to Tk::bind which results in simpler, and
easier to maintain code.

Please see L<"RESTRICTIONS"> for some important information.

=head1 METHODS

B<Tk::SingalSlot> exports three new methods into the B<Tk::> namespace:

=over 4

=item I<$widget>-E<gt>B<connect>(I<event>, I<callback>)

This method connects the given callback to the event. This means that
when the event is triggered, this callback will be executed. Any
number of callbacks can be connected to any one event. When the event
fires, all connected callbacks will execute in the order they were
connected. I<event> is any valid Tk event, and I<callback> is
any valid Tk callback.

Upon success, this method returns a unique ID that can
be used in the B<disconnect()> method below.

=item I<$widget>-E<gt>B<disconnect>(I<ID>);

Given a valid ID (returned by the B<connect() method>), this
method disconnects the associated callback from the event.
Obviously, this means that when the event fires, this callback
will not be executed.

=item I<$widget>-E<gt>B<is_connected>(I<ID>);

Returns 1 if the given ID is that of a validly connected callback.
Otherwise, returns 0;

=back

=head1 RESTRICTIONS

If you decide to use B<Tk::SignalSlot>, then you should stick with it
thoroughtout your program. Intermixing B<Tk::SignalSlot> with B<Tk::bind>
can have some unpredictable effects since B<Tk::SignalSlot> uses
B<Tk::bind> internally.

=head1 BUGS

None so far.

=head1 AUTHOR

B<Ala Qumsieh> <aqumsieh@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006 Ala Qumsieh. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
