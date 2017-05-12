package asa;

=pod

=head1 NAME

asa - Lets your class/object say it works like something else

=head1 SYNOPSIS

  #########################################
  # Your Code
  
  package My::WereDuck;
  
  use base 'My::Lycanthrope';
  use asa  'Duck';
  
  sub quack {
      return "Hi! errr... Quack!";
  }
  
  ################################################
  # Their Code
  
  sub strangle {
      my $duck = shift;
      unless ( $duck->isa('Duck') ) {
          die "We only strangle ducks";
      }
      print "Farmer Joe wrings the duck's neck\n";
      print "Said the duck, '" . $duck->quack . "'\n";
      print "We ate well that night.\n";
  }

=head1 DESCRIPTION

Perl 5 doesn't natively support Java-style interfaces, and it doesn't
support Perl 6 style roles either.

You can get both of these things in half a dozen different ways via
various CPAN modules, but they usually require that you buy into "their
way" of implementing your code.

Other have turned to "duck typing".

This is, for the most part, a fairly naive check that says "can you do
this method", under the "if it looks like a duck, and quacks like a duck,
then it must be a duck".

It assumes that if you have a C<-E<gt>quack> method, then they will treat
you as a duck, because doing things like adding C<Duck> to your C<@ISA>
array means you are also forced to take their implementation.

There is, of course, a better way.

For better or worse, Perl's C<-E<gt>isa> functionality to determine if
something is or is not a particular class/object is defined as a B<method>,
not a function, and so that means that as well as adding something to you
C<@ISA> array, so that Perl's C<UNIVERSAL::isa> method can work with it,
you are also allowed to simply overload your own C<isa> method and answer
directly whether or not you are something.

The simplest form of the idiom looks like this.

  sub isa {
      return 1 if $_[1] eq 'Duck';
      shift->SUPER::isa(@_);
  }

This reads "Check my type as normal, but if anyone wants to know if I'm a
duck, then tell them yes".

Now, there are a few people that have argued that this is "lying" about
your class, but this argument is based on the idea that C<@ISA> is
somehow more "real" than using the method directly.

It also assumes that what you advertise you implement needs to be in sync
with the method resolution for any given function. But in the best and
cleanest implementation of code, the API is orthogonal (although most often
related) to the implementation.

And although C<@ISA> is about implementation B<and> API, overloading C<isa>
to let you change your API is not at all bad when seen in this light.

=head2 What does asa.pm do?

Much as L<base> provides convenient syntactic sugar for loading your
parent class and setting C<@ISA>, this pragma will provide convenient
syntactic sugar for creating your own custom overloaded isa functions.

Beyond just the idiom above, it implements various workarounds for some
edge cases, so you don't have to, and allows clear seperation of concerns.

You should just be able to use it, and if something ever goes wrong, then
it's my fault, and I'll fix it.

=head2 What doesn't asa.pm do?

In Perl, highly robust introspection is B<really> hard. Which is why most
modules that provide some level of interface functionality require you to
explicitly define them in multiple classes, and start to tread on your
toes.

This class does B<not> do any strict enforcement of interfaces. 90% of the
time, what you want to do, and the methods you need to implement, are going
to be pretty obvious, so it's your fault if you don't provide them.

But at least this way, you can implement them however you like, and C<asa>
will just take care of the details of safely telling everyone else you are
a duck :)

=head2 What if a Duck method clashes with a My::Package method?

Unlike Perl 6, which implements a concept called "multi-methods", Perl 5
does not have a native approach to solving the problem of "API collision".

Originally from the Java/C++ world, the problem of overcoming language
API limitations can be done through the use of one of several "design
patterns".

For you, the victim of API collision, you might be interested in the
"Adapter" pattern.

For more information on implementing the Adapter pattern in Perl, see
L<Class::Adapter>, which provides a veritable toolkit for creating
an implementation of the Adapter pattern which can solve your problem.

=cut

use 5.005;
use strict;
use Carp ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.03';
}

sub import {
	my $class = shift;
	my $have  = caller(0);
	my $code  = join '',
		"package $have;\n",
		"\n",
		"sub isa {\n",
		( map { "\treturn 1 if \$_[1] eq '$_';\n" } @_ ),
		"\tshift->SUPER::isa(\@_);\n",
		"}\n";
	eval( $code );
	Carp::croak( "Failed to create isa method: $@" ) if $@;
	return 1;
}

1;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=asa>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2006 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
