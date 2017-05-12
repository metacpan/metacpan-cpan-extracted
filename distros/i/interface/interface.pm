package interface;

#
# given the name of package that specifies an interface, verify that we do 
# indeed implement everything required by that interface.
#

use 5.006;

# we just aren't the kind of module you'd bring home to meet the parents

# use strict;
# use warnings;

our $VERSION = '0.03';

# per-package locks to avoid reentry when we make them finish loading

my @checkqueue;

sub import {

  my $callerpackage = caller;

  shift; my @interfaces = @_;

  foreach my $i (@interfaces) {

    push @checkqueue, [$callerpackage, $i];

  }

}


sub CHECK {

  for my $thingie (@checkqueue) {

    my $callerpackage = $thingie->[0];
    my $implements = $thingie->[1];

    my $gripes;
    my $newgripes;
  
    do {
      eval "package $callerpackage; use $implements;"; 
      die "$callerpackage: interface $implements could not be loaded: $@" if($@);
    };
    
    foreach my $i (grep { defined &{$implements.'::'.$_} } keys %{$implements.'::'}) {
  
      # since they implement all required methods, nothing in $i will ever be called.
      # however, we need this so that $callerpackage->isa($i) is true.
  
      # warn "can: implements: $implements method: $i callerpackage: $callerpackage result: " . $callerpackage->can($i);

      # unless(defined &{$callerpackage.'::'.$i}) { 
      unless(UNIVERSAL::can($callerpackage, $i)) {
        $gripes .= ', ' if $gripes;
        $gripes .= "$i from $implements";
      }
  
      $gripes .= ", and " if $gripes and $newgripes;
      $gripes .= $newgripes if $newgripes;
      $newgripes = undef;

    }
  
    if($gripes) {
  
      die "$callerpackage is missing methods: $gripes";
  
    }
  
    push @{$callerpackage.'::ISA'}, $implements;

  }
    
}

1;

__END__

=head1 NAME

interface - simple compile time interface checking for OO Perl

=head1 SYNOPSIS

  package Foo;

  use interface 'Iterator', 'Generator', 'Clonable', 'DBI::DBD';

=head1 ABSTRACT

Compile-time interface compliance testing. Inspects the methods defined
in your module, and compares them against the methods defined in the
modules you list. Requires no special or additional syntax.

Should you fail to implement any method contained in any of the listed
classes, compile will abort with an error message.
  
=head1 DESCRIPTION

Methods starting with an underscore are ignored, and assumed not to
be part of the interface.

The modules listed on the C<use interface> line will be added to your
C<@ISA> array. This isn't done to re-use code from them - interface
definitions should be empty code stubs, or perhaps a reference 
implementation. It is done so that your module asses the C<< ->isa() >>
test for the name of the package that you're implementing the interface
of. This tells Perl that your module may be used in place of the
modules you implement the interface of.

Sample interface definition:

  package TestInterface;

  sub foo { }

  sub bar { }

  sub baz { }

  1;

A package claiming to implement the interface "TestInterface" would need to 
define the methods C<foo()>, C<bar()>, and C<baz()>.

An "interface" may need some explaination. It's an Object Orientation
idea, also known as polymorphism, that says that you should be able
to use interchangeable objects interchangably. Thank heavens the OO
people came and showed us the light!

The flip side of polymorphism is type safety. In Perl, C<< ->isa() >> lets
you check to make sure something is derived from a base class. The
logic goes that if its derived from a base class, and we're looking
for an object that fills the need of the base class, then the subclass
will work just as well, and we can accept it. Extending objects is
done by subclassing base classes and passing off the subclasses as
versions of the original. 

While this OO rote might almost have you convinced that the world
works this way, this turns out to be almostly completely useless.
In the real world, there are only a few reasons that one object is
used in place of another: Someone wrote some really horrible code,
and you want to swap out their object with a better version of the
same thing. You're switching to an object that does the same thing
but in a different way, for example using a database store instead
of a flat file store. You're making some minor changes to an existing
object and you want to be able to extend the base class in other
directions in the future. Only in the last case is inherited code
with subclassing even useful. 
In fact, there is a move towards using composition (has-a) instead 
of inheritance (is-a) across the whole
industry, mainly because they got tired of people pointing out that
OO sucks because inheritance only serves to make a great big mess
of otherwise clean code.

Seperating the interface from the implementation lets you make
multiple implementations of an idea. They can share code with 
each other, but they don't have to. The programmer has assured
us that their module does what is required by stating that it
implements the interface. While this isn't proof that the
code works, climaing to implement an interface is a kind of
contract. The programmer knows what work is required of him and
she has agreed to deliver on it.

The interface definition can be a package full of stub methods
that don't do anything, or it could be an actual working 
implementation of an object you're striving for compatability
with. The first case is cleanist, and the package full of stubs
serves as good documentation. The second case can be handy
in cases where the first case wasn't done but someone ignored
the Wisdom of the Interface and wrote a package anyway.

The Wisdom of the Interface says to write an interface for each
new kind of object that could have multiple implementations.
The interfaces serves as a contract for the minimum features
needed to implement an object of that type. When working with
objects - creating them, checking types when you accept them, etc -
always work with the interface type, never the type of an
individual implementation. This keeps your code generic. 

In order to do the composition thing (has-a), you contain one or
more objects that you need to do your work, you implement an
interface that dispatches method calls to those objects. Perhaps
your new() method creates those objects and stores them in instance
variables.

=head2 EXPORT

None. EXPORT is silly. You stay in your namespace, I'll stay in mine.

=head1 DIAGNOSTICS

Failing to implement a required method will generate a fatal similar to the following:

Baz is missing methods: bar from Stub, and import from your, and import from ImplicitThis at interface.pm line 47.
BEGIN failed--compilation aborted at Baz.pm line 5.

=head2 AGNOSTICS

Hear the one about the insomniac dyslexic agnostic? He stayed up all night wondering
if there was a Dog.

=head1 SEE ALSO

See http://www.perldesignpatterns.com/ for more on Perl OO, including information
about how and why to use interfaces.

Damian Conway. Speaking of Damian, this is a cheap knockoff of his Class::Contract module.
However, we have no special syntax!

Speaking of speaking of Damian Conway, if you ever get a chance to see him talk, you
should go.

NEXT.pm, by Damian Conway.

Object::Lexical, also by myself.

protocol.pm, by James Smith, also on CPAN

=head1 CHANGES

  0.01: Initial release.
  0.02: Stephen Nelson submitted a typo report. Thanks!
        Mention of protocol.pm by James Smith 
        An object is now considered to implemenant an interface if it ->can()
        do something, not just if it has a method.
        Hacked on docs a bit.
  0.03: Doing an "eval $caller;" in our import() doesn't get perl to finish
        loading the module that called us.  Somewhere before 5.8.8, this seems
        to have stopped working.  So we use CHECK { } now like we should have
        always.

=head1 BUGS

Yes.

This will very likely break highly introspective code, for example, anything
Damian Conway might write.

Does not work with packages not stored in a file where "use" can find them. This
bug applies to programs run from "perl -e" and in subpackages burried in 
other packages. Code in the "main" package cannot use this module for this reason.

Does not work when AUTOLOAD is used to dispatch method calls. Modules that use AUTOLOAD
cannot be used as an interface definition, and modules that use AUTOLOAD cannot be
tested to comply with an interface definition.

It should be an error to use two different interfaces that both declare a method
of the same name, as it would be ambigious which you are intending to implement.
I haven't decided. Perhaps I'll just make this warning.

This module was done in pragma-style without permission. I'm interested on
feedback on how to handle this.

Another arrangement worth considering is to create a Class::Interface thing
that the interface uses, not your code. When you use that interface, the code
is awaken, and import() inspects your code without exporting anything. This
would just move the logic around. Interfaces would be marked interfaces
rather than the people who use the interfaces making them as interfaces.
Once again, thoughts and suggestions encouraged.

The code is frightening.

There are spelling and grammar errors in this POD documentation.

My Wiki is really slow because my computer is slow, doesn't have much memory, and
its 4000 lines of code. I need to trim that down. I think I could do it in about 400
lines. Update: TinyWiki is borne. TinyWiki is no more than 100 lines, now by
definition. It is fast enough.

=head1 AUTHOR

Scott Walters, SWALTERS, Root of all Evil, E<lt>scott@slowass.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002, 2003 by Scott Walters

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. If you don't believe in free
software, just remember that free software programmers are gnome-like.
I wouldn't want to be visited by gnomes.

=cut
