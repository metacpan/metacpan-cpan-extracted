
package Verby;

use strict;
use warnings;

our $VERSION = "0.05";

__PACKAGE__

__END__

=head1 NAME

Verby - A framework for compositing and sequencing steps of execution.

=head1 SYNOPSIS

	use Verby::Dispatcher;
	use Verby::Step::Closure qw/step/;

	my $d = Verby::Dispatcher->new;

	my $s = step "Verby::Action::Foo";
	my $other = step "Verby::Action::Bar";

	$s->depends($other);

	$d->add_step($s);

	$d->do_all; # first $other, then $s

=head1 DESCRIPTION

L<Verby> was originally written to implement the backend of an installer.

An installer conceptually has two inputs, which are combined to get the job
done.

The first is the user's configuration (regardless of how it's provided) - the
parameters to influence the installation, and the second is the recipe for the
actual execution of the installation, a sort of template if you will, that the
configuration fills in.

L<Verby> defines the two concepts (not only for installers), and provides some
useful code to get them working.

In spirit it's very similar to C<Makefile>s, except that the data involved are
mentally closer to Perl than they are to sh(1).

=head1 CONFIGURATION

This core concept discusses the way that user inputs are handed down to the
execution sequence.

=head1 Config Sources

A config source is basically a key to value mapping.

It's an object where you ask

	$obj->key;

and you get the value.

If the object makes a query to the user, like displaying a prompt for a certain
key, then the answer should be cached, as each key will probably be asked for
about 3-5 times for each step.

=head1 Config Hub

A config hub is a union of several config sources. For example, a typical
command line app would have three config sources:

	my $args = Verby::Config::Source::ARGV->new; # foo --key=value
	my $config_file = Verby::Config::Source::XML->new("config.xml");
	my $conifg_prompt = Verby::Config::Source::Prompt; # last resort

	my $config_hub = Verby::Config::Data->new($args, $config_file, $config_prompt);

	$config_hub->key;

The config hub is sort of like an aggregate config source. It will ask it's
parents for the key.

The key ordering is symmetric (like role composition order), that is if two
parents both contain the key it's as if there is no match, and a warning is
emitted.

=head1 Context

A context is like a lexical config, for each step.

	my $context = $config_hub->derive;

It is mutable:

	$context->key("foo"); # set it

It can be further derived

	my $subcontext = $context->derive;
	$subcontext->key; # "foo"

It masks:

	$subcontext->key("bar");
	$subcontext->key; # "bar"
	$context->key; # still "foo";

And it can re-export:

	$subcontext->export("key");
	$context->key; # "bar" instead of "foo"

...as long as it's parent is mutable:

	$context->export("key"); # fatal error
	# because $config_hub is not mutable

It also provides a magic field:

	my $l = $c->logger;

See L<MooseX::LogDispatch>. If a logger is in a parent of the context it will
be returned instead.

=head1 EXECUTION

The L<Verby> execution model is much like a C<Makefile>'s.

There is a tree of dependant steps, which will all be executed when necessary
and possible.

By adding a step to a dispatcher, all it's dependencies are traversed and added
too.

Any step that is inserted is immediately asked whether it C<is_satisfied>.

Subsequently L<Verby::Dispatcher/do_all> is called. Dependencies are resolved,
and any step that has no dependencies, and has not yet claimed it's satisfied
is executed.

Every step gets it's own context to play around in. This context persists
between invocations of all the methods.

A step which C<provides_cxt> is a special case: Instead of deriving the global
context generated for the whole run, an intermediate context is derived first,
and then that step's context is derived from the intermediate one. Any step
which depends on this step, will have it's context derived from the
intermediate context too.

=head1 STYLE GUIDE

When writing actions to back steps up make sure they will fail properly. For
example, missing fields in C<verify> might be due to the fact that some step
did not export a necessary field yet. In this case C<verify> should just return
false, and will be asked again in due time.

An error, on the other hand, should be fatal. L<Verby> uses
L<MooseX::LogDispatch> to do this.

Actions should be short and sweet, doing as little as possible. Remember that a
step being a delegator for actions is not limited to using only one action, so
if you need to combine procedures, still try to refactor them.

Long running steps, especially ones which drive external processes, like ones
using L<Verby::Action::Run> should be asynchroneous. This allows
non-interdependant steps to be executed in parallel.

Actions should minimize partial side effects. Transactional behavior is desired
for the incremental process to be robust. Ideally the C<do> part of an action
will undo previous runs, and the C<verify> part will only be true if the side
effect is marked as consistent. 

Context fields should be exported from the verification stage, because
sometimes a step will not be executed. If execution is necessary to figure out
a field that may be exported, then verification should be false.

=head1 BUGS

None that we are aware of. Of course, if you find a bug, let us know, and we will be sure to fix it. 

=head1 CODE COVERAGE

We use B<Devel::Cover> to test the code coverage of the tests, below is the B<Devel::Cover> report on this module's test suite.

=head1 SEE ALSO

=head1 AUTHOR

Yuval Kogman, E<lt>nothingmuch@woobling.orgE<gt>
stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
