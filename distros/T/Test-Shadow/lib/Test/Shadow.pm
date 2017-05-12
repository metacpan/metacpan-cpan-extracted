package Test::Shadow;

use strict; use warnings;

use parent 'Test::Builder::Module';
use Test::Deep::NoTest qw(deep_diag cmp_details);
use Scalar::Util 'reftype';

our @EXPORT    = qw( with_shadow );
our @EXPORT_OK = qw( iterate );
our $VERSION = 0.0201;

=head1 NAME

Test::Shadow - override a class's methods in a scope, checking input/output

=head1 SYNOPSIS

Provides RSpec-like mocking with 'receive'/'and_return' functionality.  However
the interface is more explicit.  This may be considered a feature.

    use Test::More;
    use Test::Shadow;

    use Foo;

    with_shadow Foo => inner_method => {
        in => [ 'list', 'of', 'parameters' ],
        out => 'barry',
        count => 3
    }, sub {
        my $foo = Foo->new;
        $foo->outer_method();
    };

=head1 EXPORTED FUNCTIONS

=head2 with_shadow

Exported by default

    with_shadow $class1 => $method1 => $args1, ..., $callback;

Each supplied class/method is overridden as per the specification in the
supplied args.  Finally, the callback is run with that specification.

The args passed are as follows:

=over 4

=item in

A list of parameters to compare every call of the method against.  This will be
checked each time, until the first failure, if any.  The parameters can be
supplied as an arrayref:

    in => [ 'list', 'of', 'parameters' ]

or a hashref:

    in => { key => 'value', key2 => 'value2 },

and the comparison may be made using any of the extended routines in L<Test::Deep>

    use Test::Deep;
    with_shadow Foo => inner_method => {
        in => { foo => any(1,2,3) },
        ...

=item out

Stub the return value.  This can be

=over 4

=item *

a simple (non-reference) scalar value

    ...
    out => 100,

=item *

a subroutine ref, which will be passed at every invocation the parameters C<($orig, $self, @args)>.

=back

Note that the subroutine args are the same as if you were creating a L<Moose>
or L<Class::Method::Modifiers> C<around> wrapper, but dynamically scoped to the test.

    out => sub { my ($orig, $self, @args) = @_; ... },

If you want to return a reference (including a subroutine reference) return this from the
subroutine: We require wrapping in a subroutine ref for the same reason that Moose's
C<default> does: otherwise we would end up passing the same reference to each invocation,
with possibly surprising results.

    out => sub { [] }, # return a new, empty arrayref on each invocation

Of course you can simply ignore the call args and invoke as a subroutine.  See also
the L</iterate> function.

=item count

The number of times you expect the method to be called.  This is checked at the end
of the callback scope.

This may be an exact value:

    count => 4,

Or a hashref with one or both of C<min> and C<max> declared:

    count => { min => 5, max => 10 },

=back

=head2 iterate

We provide a helper function to iterate over a number of scalar return values.  This
can be attached to C<out>, and takes a list of values to be provided as the stubbed
return value on each successive call.

    use Test::Shadow 'iterate';

    with_shadow ...
        out => iterate(1,2,3,4), # return 1 on first invocation, 2 on second, etc.
        ...

The values wrap if they run out: you may want to use a C<count> argument to
diagnose that this has happened.

As well as simple values, C<iterate> handles method calls in exactly the same format
as they are normally passed to C<out>.

    with_shadow ...
        out => iterate(
            sub { my ($orig, $self, $arg) = @_; ... },
            ...

=cut

sub with_shadow {
    my $sub = pop @_;
    my $tb = __PACKAGE__->builder;

    my ($class, $method, $shadow_params) = splice @_, 0, 3;
    my ($wrapped, $reap) = mk_subs($tb, $class, $method, $shadow_params);

    {
        no strict 'refs';
        no warnings 'redefine';
        local *{"${class}::${method}"} = $wrapped;

        if (@_) {
            with_shadow(@_, $sub);
        }
        else {
            $sub->();
        }
    }

    $reap->();
}

sub mk_subs {
    my ($tb, $class, $method, $shadow_params) = @_;

    my $orig = $class->can($method) or die "$class has no such method $method";
    my $count = 0;
    my $failed;

    my $stubbed_out = $shadow_params->{out};
    if (ref $stubbed_out) {
        die "out is not a code ref!" unless reftype $stubbed_out eq 'CODE';
    }

    my $wrapped = sub {
        $count++;
        my ($self, @args) = @_;

        if (!$failed and my $expected_in = $shadow_params->{in}) {
            my $got = (ref $expected_in eq 'HASH') ? { @args } : \@args;
            my ($ok, $stack) = cmp_details($got, $expected_in);
            if (!$ok) {
                $tb->ok(0, sprintf '%s->%s unexpected parameters on call no. %d', $class, $method, $count);
                $tb->diag( deep_diag($stack) );
                $tb->diag( '(Disabling wrapper)' );
                $failed++;
            }
        }
        if ($stubbed_out) {
            # we use stub even if test has failed, as otherwise we risk calling
            # mocked service unnecessarily

            return stubbed($stubbed_out, $orig, $self, @args);
        }
        else {
            return $self->$orig(@args);
        }
    };
    my $reap = sub {
        return if $failed;
        if (my $expected_in = $shadow_params->{in}) {
            $tb->ok(1, "$class->$method parameters as expected"); 
        }
        if (my $expected_count = $shadow_params->{count}) {
            if (ref $expected_count) {
                if (my $min = $expected_count->{min}) {
                    $tb->ok($count >= $min, "$class->$method call count >= $min");
                }
                if (my $max = $expected_count->{max}) {
                    $tb->ok($count <= $max, "$class->$method call count <= $max");
                }
            }
            else {
                $tb->is_num($count, $expected_count, 
                    "$class->$method call count as expected ($expected_count)"); 
            }
        }
    };
    return ($wrapped, $reap);
}

sub stubbed {
    my ($stubbed_out, $orig, $self, @args) = @_;
    if (ref $stubbed_out) {
        return $stubbed_out->($orig, $self, @args);
    }
    else {
        return $stubbed_out;
    }
}

sub iterate {
    my @array = my @orig_array = @_;
    return sub {
        my ($orig, $self, @args) = @_;
        @array = @orig_array unless @array;
        return stubbed((shift @array), $orig, $self, @args);
    };
}

=head1 SEE ALSO

There are several other modules that deal with mocking objects.  One of them may well
serve your needs better.  I was having RSpec envy, about the call expectation side of
things (not about the "English-like" DSL, which I found both confusing, and slightly
filthy) so Test::Shadow is designed to cover that use case with an API that is less
magical and more Perlish (thanks to ribasushi, haarg, tobyink, vincent, ether on
#perl-qa for pointing out that my first implementation with the lovely-but-frightening
L<Scope::Upper> may not have been the poster child for sanity I'd intended.)

=over 4

=item *

L<Test::MockObject> is the oldest CPAN library I'm aware of.  It has a very different
usage, where you create an I<object instance> and stub methods on it, rather
than mocking a class.

=item *

L<Test::MockModule> does mock a class's methods, but hasn't been updated since 2005,
and doesn't give the control over return value stubbing and call count tracing.

=item *

L<Mock::Quick> looks like a more modern mocking implementation.  Again, it looks like
this works on an object instance.

=item *

L<Test::Spec> looks like a good reimplementation of RSpec, which means that
personally I dislike aspects of the API -- the monkey-patching and the
confusing C<expects> and C<returns> keywords, but this may be a good choice.
Note that the ::Mocks routines are "currently only usable from within tests
built with the Test::Spec BDD* framework".  

=back

* my current (snarky) understanding is that "BDD" means something to do with
using C<it> and C<describe> as synonyms for C<subtest>.

=head1 AUTHOR and LICENSE

Copyright 2014 Hakim Cassimally <osfameron@cpan.org>

This module is released under the same terms as Perl.

=cut

1;
