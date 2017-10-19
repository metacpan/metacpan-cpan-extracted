package UNIVERSAL::Object;
# ABSTRACT: A useful base class

use strict;
use warnings;

use 5.006;

use Carp ();

our $VERSION   = '0.12';
our $AUTHORITY = 'cpan:STEVAN';

BEGIN {
    eval('use ' . ($] >= 5.010 ? 'mro' : 'MRO::Compat'));
    Carp::croak($@) if $@;
}

sub new {
    my $class = shift;
       $class = ref $class if ref $class;
    my $proto = $class->BUILDARGS( @_ );
    my $self  = $class->BLESS( $proto );
    $self->can('BUILD') && UNIVERSAL::Object::Util::BUILDALL( $self, $proto );
    return $self;
}

sub BUILDARGS {
    my $class = shift;
    if ( scalar @_ == 1 && ref $_[0] ) {
        Carp::croak('Invalid BUILDARGS args for '.$class.', expected a HASH reference but got a '.$_[0])
            unless ref $_[0] eq 'HASH';
        return +{ %{ $_[0] } };
    }
    else {
        Carp::croak('Invalid BUILDARGS args for '.$class.', expected an even sized list, but got '.(scalar @_).' element(s) instead')
            unless ((scalar @_) % 2) == 0;
        return +{ @_ };
    }
}

sub BLESS {
    my $class = $_[0];
       $class = ref $class if ref $class;
    my $proto = $_[1];

    Carp::croak('Invalid BLESS args for '.$class.', You must specify an instance prototype as a HASH ref')
        unless $proto && ref $proto eq 'HASH';

    return bless $class->CREATE( $proto ) => $class;
}

sub CREATE {
    my $class = $_[0];
       $class = ref $class if ref $class;
    my $proto = $_[1];

    my $self  = $class->REPR( $proto );
    my %slots = $class->SLOTS;

    $self->{ $_ } = exists $proto->{ $_ }
        ? $proto->{ $_ }
        : $slots{ $_ }->( $self, $proto )
            foreach keys %slots;

    return $self;
}

sub REPR () { +{} }

sub SLOTS {
    my $class = $_[0];
       $class = ref $class if ref $class;
    no strict   'refs';
    no warnings 'once';
    return %{$class . '::HAS'};
}

sub DESTROY {
    my $self = $_[0];
    $self->can('DEMOLISH') && UNIVERSAL::Object::Util::DEMOLISHALL( $self );
    return;
}

## Utils

sub UNIVERSAL::Object::Util::BUILDALL {
    my $self  = $_[0];
    my $proto = $_[1];
    foreach my $super ( reverse @{ mro::get_linear_isa( ref $self ) } ) {
        my $fully_qualified_name = $super . '::BUILD';
        $self->$fully_qualified_name( $proto )
            if defined &{ $fully_qualified_name };
    }
}

sub UNIVERSAL::Object::Util::DEMOLISHALL {
    my $self = $_[0];
    foreach my $super ( @{ mro::get_linear_isa( ref $self ) } ) {
        my $fully_qualified_name = $super . '::DEMOLISH';
        $self->$fully_qualified_name()
            if defined &{ $fully_qualified_name };
    }
}

1;

__END__

=pod

=head1 NAME

UNIVERSAL::Object - A useful base class

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    package Person;
    use strict;
    use warnings;
    use UNIVERSAL::Object;

    our @ISA = ('UNIVERSAL::Object');
    our %HAS = (
        name   => sub { die 'name is required' }, # required in constructor
        age    => sub { 0 },                      # w/ default value
        gender => sub {},                         # no default value
    );

    sub name   { $_[0]->{name}   }
    sub age    { $_[0]->{age}    }
    sub gender { $_[0]->{gender} }

    package Employee;
    use strict;
    use warnings;

    our @ISA = ('Person');
    our %HAS = (
        %Person::HAS, # inheritance :)
        job_title => sub { die 'job_title is required' },
        manager   => sub {},
    );

    sub job_title { $_[0]->{job_title} }
    sub manager   { $_[0]->{manager}   }

    # ...

    my $ceo = Employee->new(
        name      => 'Alice',
        job_title => 'CEO',
    );

    my $manager = Employee->new(
        name      => 'Bob',
        job_title => 'Middle Manager',
        manager   => $ceo,
    );

    my $pawn = Employee->new(
        name      => 'Joe',
        job_title => 'Line Worker',
        manager   => $manager,
    );

=head1 DESCRIPTION

This is a simple base class that provides a protocol for object
construction and destruction. It aims to be as simple as possible
while still being complete.

=head1 SLOT MANAGEMENT

One of the key contributions of this module is to provide a
mechanism for declaring the slots that a given class is expected
to have. These are used in the object construction process to ensure
that all slots are created and initialized.

=head2 C<%HAS>

This is a public (C<our>) package variable that contains an entry
for each slot expected in the instance. The key is the slot's name,
while the value is a CODE reference which, when called, will produce
a default value for the slot.

B<NOTE:>
No inheritance of slot definitions is done between classes, this is
left as an exercise to the author, however it is easily accomplished
with the pattern shown above in the L<SYNOPSIS>.

=head2 C<SLOTS ($class)>

This is an accessor method for the C<%HAS> variable in the C<$class>
package.

B<NOTE:>
If you choose to store the slot definitions elsewhere (not in C<%HAS>)
or store them in a different form (not C<< key => CODE >> hash
entries), it is possible to then override this method to return the
expected values in the expected form.

=head1 INSTANCE REPRESENTATION

=head2 C<REPR>

This returns a new HASH reference to use as the instance.

B<NOTE:>
If you wish to use a different instance type of some kind then you
will need to override this method.

B<NOTE:>
The HASH that gets returned from here will eventually be blessed,
which means you are limited to C<tie> or XS C<MAGIC> based solutions
if you want this HASH reference to behave differently.

=head1 CONSTRUCTION PROTOCOL

Once we know the expected slots it is very easy to create a default
constructor. This is the second key contribution of this module, to
provide a consistent and complete protocol for the construction and
destruction of instances.

B<NOTE:>
The method documentation is meant to be read from top to bottom,
in that they are documented in the same order they are called.

=head2 C<new ($class, @args)>

This is the entry point for object construction, from here the
C<@args> are passed into C<BUILDARGS>. The return value of C<new>
should always be a fully constructed and initialized instance.

=head2 C<BUILDARGS ($class, @args)>

This method takes the original C<@args> to the C<new> constructor
and is expected to turn them into a canonical form, which is a
HASH ref of name/value pairs. This form is considered a prototype
candidate for the instance, and what C<BLESS> and subsequently
C<CREATE> expect to receive.

B<NOTE:>
The values in the prototype candidate should be shallow copies of
what was originally contained in C<@args>, but this is not actually
enforced, just suggested to provide better ownership distinctions.

=head2 C<BLESS ($class, $proto)>

This method receives the C<$proto> candidate from C<BUILDARGS> and
from it, ultimately constructs a blessed instance of the class.

This method really has two responsibilities, first is to call
C<CREATE>, passing it the C<$proto> instance. Then it will take
the return value of C<CREATE> and C<bless> it into the C<$class>.

B<NOTE:>
This method is mostly here to make it easier to override the
C<CREATE> method, which, along with the C<REPR> method, can be
used to change the behavior and/or type of the instance
structure. By keeping the C<bless> work here we make the work
done in C<CREATE> simpler with less mechanics.

=head2 C<CREATE ($class, $proto)>

This method receives the C<$proto> candidate from C<BLESS> and
return from it an unblessed instance structure that C<BLESS> will
then C<bless> into the C<$class>.

First it must call C<SLOTS> (described above), followed by C<REPR>
(also described above) to get both the slot definitions and a newly
minted HASH ref instance. Using these two things, along with the
C<$proto> candidate, we construct a complete blessed instance.
This is accomplished by looping through the list of slots, using
values in the C<$proto> when available, otherwise using the slot
initializers. The final unblessed HASH ref based instance is then
returned.

B<NOTE:>
If you wish to use a different instance type of some kind then you
will need to override this method.

=head2 C<BUILD ($self, $proto)>

The newly blessed instance supplied by C<BLESS> must still be
initialized. We do this by calling all the available C<BUILD> methods
in the inheritance hierarchy in the correct (reverse mro) order.

C<BUILD> is an optional initialization method which receives the
blessed instance as well as the prototype candidate. There are no
restrictions as to what this method can do other then just common
sense.

B<NOTE:>
It is worth noting that because we call all the C<BUILD> methods
found in the object hierarchy, the return values of these methods
are completely ignored.

=head1 DESTRUCTION PROTOCOL

The last thing this module provides is an ordered destruction
protocol for instances.

=head2 C<DEMOLISH ($self)>

This is an optional destruction method, similar to C<BUILD>, all
available C<DEMOLISH> methods are called in the correct (mro) order
by C<DESTROY>.

=head2 C<DESTROY ($self)>

The sole function of this method is to kick off the call to all the
C<DEMOLISH> methods during destruction.

=head1 SEE ALSO

=over 4

=item L<UNIVERSAL::Object::Immutable>

=back

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016, 2017 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
