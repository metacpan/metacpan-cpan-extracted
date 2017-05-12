package mixin::with;

use strict;
use warnings;
no strict 'refs';
use vars qw($VERSION);
$VERSION = 0.07;

=head1 NAME

mixin::with - declaring a mix-in class

=head1 SYNOPSIS

    package Dog::Retriever;
    use mixin::with 'Dog';


=head1 DESCRIPTION

mixin::with is used to declare mix-in classes.


=head2 When to use a mixin?

Mixin classes useful for those that I<add new functionality> to an
existing class.  If you find yourself doing:

    package Foo::ExtraStuff;
    use base 'Foo';
    sub new_method { ... }

    package Bar;
    use base qw(Foo Foo::ExtraStuff);

it's a good indication that Foo::ExtraStuff might do better as a mixin.

Instead of mixins, please consider using traits.  See L<Class::Trait> for an implementaiton.


=head2 How?

Basic usage is simple:

    package Foo::Extra;
    use mixin::with 'Foo';

    sub new_thing {
        my($self) = shift;
        ...normal method...
    }

C<use mixin::with 'Foo'> is I<similar> to subclassing from 'Foo'.

All public methods of Foo::Extra will be mixed in.  mixin::with
considers all methods that don't start with an '_' as public.


=head2 Limitations of mixins

There's one critical difference between a normal subclass and one
intended to be mixin.  It can have no private methods.  Instead, use lexical methods.

  my $private = sub { ... };
  $self->$private(@args);

instead of 

  sub _private { ... }
  $self->_private(@args);

Don't worry, it's the same thing.


=cut

my %Mixers = ();
my $Tmp_Counter = 0;
sub import {
    my($class, $mixed_with) = @_;
    my $mixin = caller;

    my $tmp_pkg = __PACKAGE__.'::tmp'.$Tmp_Counter++;
    $Mixers{$mixin} = { mixed_with => $mixed_with,
                        tmp_pkg    => $tmp_pkg,
                      };

    require base;

    eval sprintf q{
        package %s;
        base->import($mixed_with);
    }, $mixin;

    return 1;
}


sub __mixers {
    my($class, $mixin) = @_;

    return @{$Mixers{$mixin}}{'mixed_with', 'tmp_pkg'};
}


=head1 FAQ

=over 4

=item What if I want to mixin with anything?

Sometimes a mixin does not care what it mixes in with.  Consider a
logging or error handling mixin.  For these, simply mixin with
UNIVERSAL.

    package My::Errors;
    use mixin::with qw(UNIVERSAL);


=item Why do I have to declare what I mixin with?

Two reasons.  One is technical, it allows C<SUPER> to work.

The other is organizational.  It is rare that a mixin is intended to be mixed with any old class.  It often uses methods as if it were a subclass.  For this reason it is good that it declares this relationship explicitly else the mixee won't be aware of the mixin's expectations.


=item Why use mixins instead of traits?

Good question.  Traits are definately a better idea then mixins, but mixins have two advantages.  They're simpler to explain, acting like a gateway drug to traits by introducing the concept of OO reuse by class composition rather than inheritance.

The other is mixins work more like a drop-in replacement for multiple inheritance.  In a large, hairy hierarchy mixins can often be used to trim the inheritance bush and make sense of things with a minimum of modification to the code.  Once this basic repair is done, the work of converting to traits can begin.

If these advantages don't apply, proceed directly to traits.

=back

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 LICENSE

Copyright 2002-2010 by Michael G Schwern

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

L<http://dev.perl.org/licenses/>

=head1 SEE ALSO

L<mixin>, L<ruby> from which I stole this idea.

=cut

1;

