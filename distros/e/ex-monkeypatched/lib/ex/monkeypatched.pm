package ex::monkeypatched;

use strict;
use warnings;

use Sub::Name qw<subname>;
use Carp qw<croak>;

our $VERSION = '0.03';

sub import {
    my $invocant = shift;
    my $norequire = @_ && $_[0] && $_[0] eq '-norequire' && shift;
    if (@_) {
        my @injections = _parse_injections(@_)
            or croak "Usage: use $invocant \$class => %methods
or:    use $invocant (class => \$class, methods => \\%methods)
or:    use $invocant (method => \$name, implementations => \\%impl)";
        _require(map { $_->[0] } @injections)
            if !$norequire;
        _inject_methods(@injections);
    }
}

sub _require {
    for (@_) {
        (my $as_file = $_) =~ s{::|'}{/}g;
        require "$as_file.pm";  # dies if no such file is found
    }
}

sub _parse_injections {

    if (@_ == 1 && ref $_[0] eq 'HASH') {
        my $opt = shift;
        if (defined $opt->{class} && ref $opt->{methods} eq 'HASH') {
            return map { [$opt->{class}, $_, $opt->{methods}{$_}] }
                keys %{ $opt->{methods} };
        }
        elsif (defined $opt->{method} && ref $opt->{implementations} eq 'HASH') {
            return map { [$_, $opt->{method}, $opt->{implementations}{$_}] }
                keys %{ $opt->{implementations} };
        }
    }
    elsif (@_ % 2) {
        my @injections;
        my $target = shift;
        push @injections, [$target, splice @_, 0, 2]
            while @_;
        return @injections;
    }

    return;
}

sub inject {
    my $invocant = shift;
    my @injections = _parse_injections(@_)
        or croak "Usage: $invocant->inject(\$class, %methods)
or:    $invocant->inject({ class => \$class, methods => \\%methods })
or:    $invocant->inject({ method => \$name, implementations => \\%impl })";
    _inject_methods(@injections);
}

sub _inject_methods {
    for (@_) {
        my ($target, $name, undef) = @$_;
        croak qq[Can't monkey-patch: $target already has a method "$name"]
            if $target->can($name);
    }
    _install_subroutine(@$_) for @_;
}

sub _install_subroutine {
    my ($target, $name, $code) = @_;
    my $full_name = "$target\::$name";
    my $renamed_code = subname($full_name, $code);
    no strict qw<refs>;
    *$full_name = $renamed_code;
}

1;
__END__

=head1 NAME

ex::monkeypatched - Experimental API for safe monkey-patching

=head1 SYNOPSIS

    use ex::monkeypatched 'Third::Party::Class' => (
        clunk => sub { ... },
        eth   => sub { ... },
    );

    use Foo::TopLevel; # provides Foo::Bar, which isn't a module
    use ex::monkeypatched -norequire => 'Foo::Bar' => (
        thwapp => sub { ... },
        urkk   => sub { ... },
    );

=head1 BACKGROUND

The term "monkey patching" describes injecting additional methods into a
class whose implementation you don't control.  If done without care, this is
dangerous; the problematic case arises when:

=over 4

=item *

You add a method to a class;

=item *

A newer version of the monkey-patched class adds another method I<of the
same name>

=item *

And uses that new method in some other part of its own implementation.

=back

C<ex::monkeypatched> lets you do this sort of monkey-patching safely: before
it injects a method into the target class, it checks whether the class
already has a method of the same name.  If it finds such a method, it throws
an exception (at compile-time with respect to the code that does the
injection).

See L<http://aaroncrane.co.uk/talks/monkey_patching_subclassing/> for more
details.

=head1 DESCRIPTION

C<ex::monkeypatched> injects methods when you C<use> it.  There are two ways
to invoke it with C<use>: one is easy but inflexible, and the other is more
flexible but also more awkward.

In the easy form, your C<use> call should supply the name of a class to
patch, and a listified hash from method names to code references
implementing those methods:

    use ex::monkeypatched 'Some::Class' => (
        m1 => sub { ... },  # $x->m1 on Some::Class will now run this
        m2 => sub { ... },  # $x->m2 on Some::Class will now run this
    );

In the flexible form, your C<use> call supplies a single hashref saying what
methods to create.  That last example can be done exactly like this:

    use ex::monkeypatched { class => 'Some::Class', methods => {
        m1 => sub { ... },  # $x->m1 on Some::Class will now run this
        m2 => sub { ... },  # $x->m2 on Some::Class will now run this
    } };

However, this flexible form also lets you add a method of a single name to
several classes at once:

    use ex::monkeypatched { method => 'm3', implementations => {
        'Some::BaseClass'     => sub { ... },
        'Some::Subclass::One' => sub { ... }
        'Some::Subclass::Two' => sub { ... },
    } };

This is helpful when you want to provide a method for several related
classes, with a different implementation in each of them.

The classes to be patched will normally be loaded automatically before any
patching is done (thus ensuring that all their base classes are also
loaded).

That doesn't work when you're trying to modify a class which can't be loaded
directly; for example, the L<XML::LibXML> CPAN distribution provides a class
named C<XML::LibXML::Node>, but trying to C<use XML::LibXML::Node> fails.
In that situation, you can tell C<ex::monkeypatched> not to load the
original class:

    use ex::monkeypatched -norequire => 'XML::LibXML::Node' => (
        clunk => sub { ... },
        eth   => sub { ... },
    );

    # Equivalently:
    use ex::monkeypatched -norequire => {
        class   => 'XML::LibXML::Node',
        methods => {
            clunk => sub { ... },
            eth   => sub { ... },
        },
    };

Alternatively, you can inject methods after a class has already been loaded,
using the C<inject> method:

    use ex::monkeypatched;

    ex::monkeypatched->inject('XML::LibXML::Node' => (
        clunk => sub { ... },
        eth   => sub { ... },
    );

    # Equivalently:
    ex::monkeypatched->inject({ class => 'XML::LibXML::Node', methods => {
        clunk => sub { ... },
        eth   => sub { ... },
    }});

Neither of these approaches (C<-norequire> and C<inject>) loads the class in
question, so when you use them, C<ex::monkeypatched> is unable to guarantee
that all the target class's methods have been loaded at the point the new
methods are injected.

The C<ex::> prefix on the name of this module indicates that its API is
still considered experimental.  However, the underlying code has been in use
in production for an extended period, and seems to be reliable.

=head1 CAVEATS

If the class you're monkeying around in uses C<AUTOLOAD> to implement some
of its methods, and doesn't also implement its own C<can> method to
accurately report which method names are autoloaded, C<ex::monkeypatched>
will incorrectly assume that an autoloaded method does not exist.  The
solution is to fix the broken class; implementing C<AUTOLOAD> but not C<can>
is always an error.

=head1 AUTHOR

Aaron Crane E<lt>arc@cpan.orgE<gt>

=head1 LICENCE

This library is free software; you can redistribute it and/or modify it
under the terms of either the GNU General Public License version 2 or, at
your option, the Artistic License.

=cut
