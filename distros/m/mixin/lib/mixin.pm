package mixin;

use strict;
use warnings;
no strict 'refs';
use vars qw($VERSION);
$VERSION = '0.08';


=head1 NAME

mixin - Mix-in inheritance, an alternative to multiple inheritance

=head1 SYNOPSIS

  package Dog;
  sub speak { print "Bark!\n" }
  sub new { my $class = shift;  bless {}, $class }

  package Dog::Small;
  use base 'Dog';
  sub speak { print "Yip!\n"; }

  package Dog::Retriever;
  use mixin::with 'Dog';
  sub fetch { print "Get your own stinking $_[1]\n" }

  package Dog::Small::Retriever;
  use base 'Dog::Small';
  use mixin 'Dog::Retriever';

  my $small_retriever = Dog::Small::Retriever->new;
  $small_retriever->speak;          # Yip!
  $small_retriever->fetch('ball');  # Get your own stinking ball

=head1 DESCRIPTION

B<NOTE> You probably want to look into the similar but superior
concept of traits/roles instead.  See L</"SEE ALSO"> for suggested
modules.

Mixin inheritance is an alternative to the usual multiple-inheritance
and solves the problem of knowing which parent will be called.
It also solves a number of tricky problems like diamond inheritence.

The idea is to solve the same sets of problems which MI solves without
the problems of MI.  For all practical purposes you can think of a
mixin as multiple inheritance without the actual inheritance.

Mixins are a band-aid for the problems of MI.  A better solution is to
use traits (called "Roles" in Perl 6), which are like mixins on
steroids.  Class::Trait implements this.


=head2 Using a mixin class

There are two steps to using a mixin-class.

First, make sure you are inherited from the class with which the
mixin-class is to be mixed.

  package Dog::Small::Retriever;
  use base 'Dog::Small';

Since Dog::Small isa Dog, that does it.  Then simply mixin the new
functionality

  use mixin 'Dog::Retriever';

and now you can use fetch().


=head2 Writing a mixin class

See L<mixin::with>.


=head2 Mixins, Inheritance and SUPER

A class which uses a mixin I<does not> inherit from it.  However,
through some clever trickery, C<SUPER> continues to work.  Here's an
example.

    {
        package Parent;
        sub foo { "Parent" }
    }

    {
        package Middle;
        use mixin::with "Parent";

        sub foo {
            my $self = shift;
            return $self->SUPER::foo(), "Middle";
        }
    }

    {
        package Child;
        use base "Parent";
        use mixin "Middle";

        sub foo {
            my $self = shift;
            return $self->SUPER::foo(), "Child";
        }
    }

    print join " ", Child->foo;  # Parent Middle Child

This will print C<Parent Middle Child>.  You'll note that this is the
same result if Child inherited from Middle and Middle from Parent.
Its also the same result if Child multiply inherited from Middle and
Parent but I<NOT> if it inherited from Parent then Middle.  The
advantage of mixins vs multiple inheritance is such ambiguities do not
exist.

Note that even though both the Child and Middle define foo() the
Middle mixin does not overwrite Child's foo().  A mixin does not
simply export its methods into the mixer and thus does not blow over
existing methods.

=cut

sub import {
    my($class, @mixins) = @_;
    my $caller = caller;

    foreach my $mixin (@mixins) {
        # XXX This is lousy, but it will do for now.
        unless( defined ${$mixin.'::VERSION'} ) {
            eval qq{ require $mixin; };
            _croak($@) if $@ and $@ !~ /^Can't locate .*? at /;
            unless( %{$mixin."::"} ) {
                _croak(<<ERROR);
Mixin class package "$mixin" is empty.
    (Perhaps you need to 'use' the module which defines that package first?)
ERROR
            }
        }
        _mixup($mixin, $caller);
    }
}

sub _mixup {
    my($mixin, $caller) = @_;

    require mixin::with;
    my($with, $pkg) = mixin::with->__mixers($mixin);

    _croak("$mixin is not a mixin") unless $with;
    _croak("$caller must be a subclass of $with to mixin $mixin")
      unless $caller->isa($with);

    # This has to happen here and not in mixin::with because "use
    # mixin::with" typically runs *before* the rest of the mixin's
    # subroutines are declared.
    _thieve_public_methods( $mixin, $pkg );
    _thieve_isa( $mixin, $pkg, $with );

    unshift @{$caller.'::ISA'}, $pkg;
}


my %Thieved = ();
sub _thieve_public_methods {
    my($mixin, $pkg) = @_;

    return if $Thieved{$mixin}++;

    local *glob;
    while( my($sym, $glob) = each %{$mixin.'::'}) {
        next if $sym =~ /^_/;
        next unless defined $glob;
        *glob = *{$mixin.'::'.$sym};
        *{$pkg.'::'.$sym} = *glob{CODE} if *glob{CODE};
    }

    return 1;
}

sub _thieve_isa {
    my($mixin, $pkg, $with) = @_;

    @{$pkg.'::ISA'} = grep $_ ne $with, @{$mixin.'::ISA'};

    return 1;
}


sub _croak {
    require Carp;
    goto &Carp::croak;
}


=head1 NOTES

A mixin will not warn if the mixin and the user define the same method.


=head1 AUTHOR

Michael G Schwern E<lt>schwern@pobox.comE<gt>


=head1 LICENSE

Copyright 2002-2015 by Michael G Schwern

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

L<http://dev.perl.org/licenses/>


=head1 SEE ALSO

L<Role::Tiny> - A stand alone implementation of traits/roles, like mixins but better.

L<Moose::Role> - Moose's implementation of traits/roles.

L<mro> and L<Class::C3> make multiple inheritance work more sensibly.

=cut

1;
