=head1 NAME

WWW::Mechanize::Plugin::Cookbook - how to write plugins for WWW::Mechanize::Pluggable

=head1 DESCRIPTION

This document describes what a C<WWW::Mechanize::Pluggable> plugin is, 
how they work in connection with the base module, and gives examples
of how one would design a new plugin.

=over 4

This cookbook addresses the current state of the C<Pluggable> interface;
future versions are expected to greatly streamline the process of creating
plugins and hooks.

=back

=head1 PLUGIN BASICS

A plugin is basically as specially-named package that is automatically loaded
by a parent class. This document outlines the interface between 
C<WWW::Mechanize::Pluggable> and its plugin classes. 

=head2 Flow of Control

When C<WWW::Mechanize::Pluggable> is loaded, it searches C<@INC> for
modules whose names begin with C<WWW::Mechanize::Plugin> and calls 
C<import> for the package, using the arguments supplied on 
C<WWW::Mechanize::Pluggable>'s own C<use> line. This allows you to 
parameterize the plugins if you wish.

When a C<WWW::Mechanize::Pluggable> object is instantiated, its
C<new> method calls each of the plugins' C<init> method.
Typically, C<init()> exports methods back into
the caller's namespace, and also calls C<pre_hook> and C<post_hook>
to wrap any of C<WWW::Mechanize>'s methods it desires.

When a C<WWW::Mechanize> method is called, C<WWW::Mechanize::Pluggable>'s
C<AUTOLOAD> takes control. It calls any pre-hooks that have been installed
for the method; if any of them return a true value, the actual method
call is skipped. C<WW::Mechanize::Pluggable> then calls the method
(if it should) using the same context in which the method was originally
callled, saving the return value. The post-hooks are then called, and the
return value from the method is returned to the original caller.

=head2 What you can do

Essentially, you now have complete control over what any method in the base
class does. You can 

=over 4

=item * alter the parameter list

=item * process the call yourself

=item * conditionally get involved, or not

=item * post-process the results after the call

=back

=head1 API TO WWW::MECHANIZE::PLUGGABLE

=head2 import

Called as C<import($class, %args)>.

This routine is optional; it is called when your plugin is loaded
by C<WWW::Mechanize::Pluggable>. You can use this to parameterize
your plugin via arguments on the C<use> statement.

It's recommended that you supply arguments as key-value pairs;
this will make it possible for C<WWW::Mechanize::Pluggable>
to remove the "used-up" parameters from the c<use> line by
returning the keys you want to have removed.

Here's a sample C<import> method:

  sub import {
    my($class, %args) = @_;
    if defined(my $value = $args{'mine'}) {
      if (_is_appropriate($value)) {
        # do whatever ,,,
      }
    }
    return ("mine");
  }

This looks for the C<mine> parameter on the C<use>.
It processes it as appropriate and returns the 
key so that C<WWW::Mechanize::Pluggable> will delete it.

=head2 init

Called as C<init($pluggable)>.

The C<init> method allows your plugin a chance to export
subroutines and store information appropriate for its
proper functioning in the parent C<WWW::Mechanize::Pluggable>
object. It also can be used to set up pre-hooks and 
post-hooks for methods. 

=over 4

Note that at present it isn't possible to add hooks for
methods installed by other plugins; a future release of
this software may be able to do this.

=back

Because other plugins will be doing the same thing, it's 
important to choose unique method names and field names.
It's proabably a good idea to prefix field names with the
name of your plugin, like C<_MyPlugin_data>.

It's possible that we may change the interface in a future
release of C<WWW::Mechanize::Pluggable> to support 
"inside-out" objects (see http://www.windley.com/archives/2005/08/best_practices.shtml
for an example).

Sample init function:

  sub init {
    my($parent_object, %args) = @_;
    $parent_object->{_myplugin_foo} = "my data";
    *{caller() . '::myplugin_method'} = \&my_implementation;
    $parent_object->pre_hook('get', sub { &my_prehook(@_) } );
    $parent_object->post_hook('get', sub { &my_prehook(@_) } );
    my @removed;
    if ($args{'my_arg'}) {
       # process my_arg
       push @removes, 'my_arg';
    }
    @removed;
  }

The anonymous subroutine wrapping the hook setup currently is
necessary to prevent the hook from being called during its
installation; this needs to be fixed. The anonymous subroutine
works for the moment, and will work in future releases, so
go head and use it for now.

Also note that we have the same kind of interface that we do
in C<import>; you can parameterize a particular plugin by 
putting the parameters (key=>value-style) on the C<new>
and then processing them in C<init>, and deleting them
after processing by returning the list of names.

=head2 pre_hook

Called as C<$parent_object->pre_hook('method_name", $subref)>.

Installs the referenced subroutine as a pre-hook for the
named method. Currently, only C<WWW::Mechanize> methods can
be hooked; future releases may allow methods supplied by plugins
to be hooked as well.

=head2 post_hook

Called as C<$parent_object->pre_hook('method_name", $subref)>.

Installs the referenced subroutine as a post-hook for the
named method. Currently, only C<WWW::Mechanize> methods can
be hooked; future releases may allow methods supplied by plugins
to be hooked as well.

=head1 YOUR CODE

Since pre-hooks and post-hooks are all about getting your
code involved in things, this section details how all that
works.

=head2 Prehooks and posthooks

Called as C<your_hook($pluggable, $internal_mech, @args)>.

This is the subroutine that you passed a reference to in 
the call to either C<pre_hook> or C<post_hook>. It can do 
anything you like; it has access to both the 
\C<WWW::Mechanize::Pluggable> object and to the 
internal C<WWW::Mechanize> object, as well as to the 
parameters with which the method was called.

If your code is a pre-hook, it can cause 
C<WWW::Mechanize::Pluggable> to skip the method
call altogether by returning a true value.

Sample pre-hook:

  sub my_prehook {
    my($pluggable, $mech, @args) = @_;
    
    # We'll assume that this is a hook for 'get'.
    if ($args[0] =~ /$selected_url/) {

      # alter the URL to what we want
      $args[0] =~ s/$what_we_dont_want/$what_we_do/;
    }
    # force another try with the altered URL.
    $pluggable->get(@args);

    # don't actually do the get with the old URL.
    return 'skip';
  }

We used this approach because the interface currently doesn't 
allow us to alter the parameter list; this is something we
probably should do in the next release.

=head1 RECIPIES

=head2 Adding a new acessor

To avoid doing a lot extra monkey coding, C<Class::Accessor::Fast> is highly recommended.

  package WWW::Mechanize::Plugin::MyPlugin;
  use base qw(Class::Accessor::Fast);
  __PACKAGE__->mk_accessors(qw(foo bar baz));

You can now use the newly-created accessors any way you like; often
you'll use them to store data for other methods that are exported to
C<WWW::Mechanize::Pluggable>.

=head2 Adding a new method

This is done (for the moment) by using a construct like this:

  *{caller() . '::new_method'} = \&localsub;

This would call any subroutine or method call to new_method
via the Mech::Pluggable object to be dispatched to localsub
in this package.

=head2 Replacing a method

In init, install a pre_hook for the method which does 
something like this:

  sub init {
    pre_hook('desired_method', sub { \&substitute(@_) });

  sub substitute {
    my($pluggable, $mech, @_) = @_;
    # Do whatever you want;
    return "skip";
  }

Note the anonymous sub construct in the call to pre_hook.
This is necessary because the construct C<\&substitute>
tries to call substitute() immediately, which we do
I<not> want.

We return "skip" as a mnemonic that a true value causes 
the real call to be skipped.

=head2 Retrying a method call

This is done with a prehook to count how many times 
we've tried to retry an action, and a posthook to

=over 4 

=item * take whatever action is needed to set up for the retry

=item * call back() on the Mech object

=item * repeat the last action again on the Mech object

=item * up the count of tries 

=back

The prehook is needed to keep the retry from going into
an infinite loop.

=head1 CREDITS

The Perl Advent Calendar (http://www.perladvent.org/2004/6th/) for bringing Module::Pluggable to my attention.

Damian Conway, for showing us how to do things that Just Work.

Andy Lester, for WWW::Mechanize.

=cut

use strict;  # or get dinged by CPANTS

"It's only documentation but I like it";
