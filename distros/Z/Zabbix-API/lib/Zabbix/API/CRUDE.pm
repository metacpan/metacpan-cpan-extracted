package Zabbix::API::CRUDE;

use strict;
use warnings;
use 5.010;
use Carp;

sub new {

    my ($class, %args) = @_;

    my $self = \%args;

    bless $self, $class;

    return $self;

}

sub id {

    croak 'Class '.(ref shift).' does not implement required mutator id()';

}

sub node_id {

    my ($self, $value) = @_;
    
    if (defined $value) {

        croak 'Accessor node_id() called as mutator';

    }

    return unless $self->id;
    return unless $self->id > 100000000000000;
    # this is how Zabbix operates, don't blame me
    return int($self->id/100000000000000);

}

sub prefix {

    croak 'Class '.(ref shift).' does not implement required method prefix()';

}

sub extension {

    croak 'Class '.(ref shift).' does not implement required method extension()';

}

sub name {

    croak 'Class '.(ref shift).' does not implement required method name()';

}

sub data {

    ## accessor for data

    my ($self, $value) = @_;

    if (defined $value) {

        croak 'Accessor data() called as mutator';

    } else {

        $self->{data} = {} unless exists $self->{data};

        return $self->{data};

    }

}

sub pull {

    my ($self, $data) = @_;

    if (defined $data) {

        $self->{data} = $data;

    } else {

        croak sprintf('Cannot pull data from server into a %s without ID', $self->prefix)
            unless $self->id;

        $self->{data} = $self->{root}->query(method => $self->prefix('.get'),
                                             params => {
                                                 $self->prefix('ids') => [ $self->id ],
                                                 $self->extension
                                             })->[0];

    }

    return $self;

}

sub created {

    my $self = shift;

    return $self->id if $self->{root}->{lazy};

    return @{$self->{root}->query(method => $self->prefix('.get'),
                                  params => {
                                      $self->prefix('ids') => [$self->id],
                                      $self->extension
                                  })};

}

sub collides {

    croak 'Class '.(ref shift).' does not implement required method collides()';

}

sub push {

    my ($self, $data) = @_;

    $data //= $self->data;

    my @colliders;

    if ($self->id and $self->created) {

        say sprintf('Updating %s %s', $self->prefix, $self->id)
            if $self->{root}->{verbosity};

        $self->{root}->query(method => $self->prefix('.update'),
                             params => $data);

        $self->pull unless $self->{root}->{lazy};

    } elsif ($self->id) {

        croak sprintf('%s has a %s but does not exist on server', $self->id, $self->prefix('id'));

    } elsif (@colliders = $self->collides and $colliders[0]) {

        say sprintf('Updating %s (match by collisions)', $self->prefix)
            if $self->{root}->{verbosity};

        if (@colliders > 1) {

            croak sprintf('Cannot push %s: too many possible targets', $self->prefix);

        }

        my $class = ref $self;

        # not referenced! and that's the way we want it
        my $collider = $class->new(root => $self->{root}, data => $colliders[0]);

        $self->id($collider->id);

        $self->push;

    } else {

        say 'Creating '.$self->prefix
            if $self->{root}->{verbosity};

        my $id = $self->{root}->query(method => $self->prefix('.create'),
                                      params => $data)->{$self->prefix('ids')}->[0];

        $self->id($id);

        $self->pull unless $self->{root}->{lazy};

    }

    return $self;

}

sub delete {

    my $self = shift;

    if ($self->id) {

        say sprintf('Deleting %s %s', $self->prefix, $self->id)
            if $self->{root}->{verbosity};

        $self->{root}->query(method => $self->prefix('.delete'),
                             params => [ $self->id ]);

    } else {

        carp sprintf(q{Useless call of delete() on a %s that does not have a %s}, $self->prefix, $self->prefix('id'));

    }

    return $self;

}

1;
__END__
=pod

=head1 NAME

Zabbix::API::CRUDE -- Base abstract class for most Zabbix::API::* objects

=head1 SYNOPSIS

  package Zabbix::API::Unicorn;

  use parent qw/Zabbix::API::CRUDE/;

  # now override some virtual methods so that it works for the specific case of
  # unicorns

  sub id { ... }
  sub prefix { ... }
  sub extension { ... }

=head1 DESCRIPTION

This module handles most aspects of pushing, pulling and deleting the various
types of Zabbix objects.  You do not want to use this directly; a few abstract
methods need to be implemented by a subclass.

=head2 WHY "CRUDE"?

=over 4

=item 1

On top of Create, Read, Update and Delete, the Zabbix API also implements an
Exists operation.

=item 2

It I<was> written in a hurry.

=back

=head1 METHODS

=over 4

=item new([DATA]) (constructor)

This is the standard, boilerplate Perl OO constructor.  It returns a blessed
hashref with the contents of C<DATA>, which should be a hash.

=item id([NEWID]) (abstract method)

This method must implement a mutator for the relevant unique Zabbix ID (e.g. for
hosts, C<hostid>).  What this means is, it must accept zero or one argument; if
zero, return the current ID or undef; if one, set the current ID in the raw data
hash (see the C<data()> method) and return it.

=item node_id()

This method returns the current object's node ID, for distributed
setups.  For objects in non-distributed setups, whose IDs do not
include a node ID, and objects that have never been pushed to the
server, this method will return false.

=item prefix([SUFFIX]) (abstract method)

This method must return a string that corresponds to its type (e.g. C<host>).
It should accept one optional argument to concatenate to the type; this kludge
is necessary for types that have a different name depending on where they are
used (e.g. graph items -- not currently implemented as such -- have a
C<graphitemid> but are referred to as C<gitems> elsewhere).

This is a class and instance method (and it returns the same thing in both cases
so far).  Warning: do not rely too much on this returning the correct compound
name for any SUFFIX, as I have implemented only those special cases that were of
interest for the rest of the distribution.

=item extension() (abstract method)

This method must return a list that contains the various parameters necessary to
fetch more data.  (Returning an empty hash means that in most cases, only the
IDs will be sent by the server.)  E.g. for hosts, this is C<< return (output =>
'extend') >>.

=item name() (abstract method)

This method must return a preferably unique human-readable identifier.  For
instance, hosts return the C<host> attribute.

=item data()

This is a standard accessor for the raw data as fetched from Zabbix and
converted into a hashref.  You can use C<pull()> as a mutator on the same (but
not for long).

=item pull([DATA])

Without an argument, fetches the raw data from the Zabbix server and updates the
Perl object appropriately.  Calling C<pull> on objects that do not have an ID
set (they have not been fetched from the server, have never been pushed, or you
have removed the ID yourself for obscure reasons) throws an exception.

With a hashref argument, sets the raw data on the object directly, although this
will change in a future version.

In any case, this does not save your modifications for you.  If you have changed
the object's data in any way and not pushed the modifications to the server,
they will be overwritten.

=item created()

This checks that the server knows about the object (has an object of the same
type with the same ID).

=item collides() (abstract method)

This method must return a list of objects (hashrefs of data, not instances of
C<Zabbix::API>!)  that would cause the Zabbix server to reply "... already
exists" if the invocant were created (as with a push).

=item push()

Create the object on the server if it doesn't exist, update it if it does.  This
distinction means that an object which has an ID, but not a server
representation, is in an illegal state; calling C<push> on such an object throws
an exception.  Some classes (e.g. C<Screen>) override this to ensure that other
objects they depend on are created before they are.

=item delete()

Deletes the object on the server and the local index (if you fetch it again it
will be a different object from the one you're "holding").

=back

=head1 SEE ALSO

L<Zabbix::API>, the Zabbix API documentation at
L<http://www.zabbix.com/documentation/start>.

=head1 AUTHOR

Fabrice Gabolde <fabrice.gabolde@uperto.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 SFR

This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
