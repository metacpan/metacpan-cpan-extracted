=head1 NAME

WWW::Mechanize::Pluggable::Design - the architecture of WWW::Mechanize::Pluggable

=head1 DESCRIPTION

This document describes C<WWW::Mechanize::Pluggable>'s design
and explains how it works, including plugins and how they 
interact with the base module.

=head1 BASICS

=head2 Why write this module?

Previous to the creation of C<WWW::Mechanize::Pluggable>, anyone who wanted
an extended version of C<WWW::Mechanize> had to subclass it to add new
features.

This in itself is not a bad thing: many modules have been created to 
address specific behaviors that C<WWW::Mechanize> doesn't support
itself:

=over 4

=item C<WWW::Mechanize::Sleepy> - pauses between requests

=item C<WWW::Mechanize::Cached> - caches requests

=item C<WWW::Mechanize::Timed> - times requests

=back

And so on. The problem is, what if you want both the C<Sleepy> behavior 
and the C<Cached> behavior simultaneously? The answer is you can't do that
unless you write a module which inherits from both. 

This approach isn't viable in the long term because the number of possible
combinations of behavior grows too fast. So how can we address this problem?

=head2 Enter C<Module::Pluggable>

A partial solution comes from C<Module::Pluggable>. This module allows
you to create I<plugins> - specially-named packages, installed just like
regular modules. A base package, which uses C<Module::Pluggable>, can
then automatically search for and load extra functions via these 
plugin classes.

This solves the problem of extending a base class - if you're the one
who controls the base class's source code. 

=head2 C<WWW::Mechanize::Pluggable> - plugins with a twist

The simplest way to solve the problem is just to create a subclass of
the class you want to add plugin functionality to - in our case, 
C<WWW::Mechanize> - and then write plugins. And as long as all you're 
doing is just adding new functions, you're in good shape.

But what if you want to I<change> the way something functions, rather than
just add something new? You have a problem, because a plugin can't do
that - or rather, two different plugins that want to alter the same base-class
method can't do so without knowing about each other. This might seem like
a good-enough solution, but it has the same problem as the "subclass the
subclasses" approach: you have a combinatorial explosion of checks that
have to be made every time a new module that wants to alter the same
base-class method gets into the act.

=head2 Proxy and Decorator

The approach used in C<WWW::Mechanize::Pluggable> is to combine the
proxy pattern (one class intercepts all the calls for another and
then passes them on) and the decorator pattern (one class 
instantiates another, then exposes methods matching all of the
second classes methods, with its own code inserted before 
and/or after the calls to the contained class).

Perl provides us with very flexible ways to deal with this 
process. 

=head3 AUTOLOAD

We use C<AUTOLOAD> to "catch" all the calls to the class. 
We actually implement very little in C<WWW::Mechanize::Pluggable>;
only enough to be able to create the base object and its contained
C<WWW::Mechanize> object. 

To decorate, we add  a hash of pre-hook and post-hook lists.
These are subroutines to be called before (pre-hook) and after
(post-hook) the base-class methods. Now it's possible to alter 
either the behavior of a given method, or to feed it different
parameters "behind the back" of the main program.

=head1 PLUGIN STRUCTURE

We'll speak specifically about C<WWW::Mechanize::Pluggable>
here; wo hope to extract the "pluggability" into a completely
separate module in the very near future, allowing the creation
of C<::Pluggable> versions of any module you please.

=head2 The Pluggable interface



=cut

use strict;  # or get dinged by CPANTS
1;

