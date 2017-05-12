package autobox::Closure::Attributes;
use strict;
use warnings;
use base 'autobox';
our $VERSION = '0.05';

sub import {
    shift->SUPER::import(CODE => 'autobox::Closure::Attributes::Methods');
}

package autobox::Closure::Attributes::Methods;
use PadWalker;

sub AUTOLOAD {
    my $code = shift;
    (my $attr = our $AUTOLOAD) =~ s/.*:://;

    # we want the scalar unless the method name already a sigil
    $attr = "\$$attr" unless $attr =~ /^[\$\@\%\&\*]/;

    my $closed_over = PadWalker::closed_over($code);
    exists $closed_over->{$attr}
        or Carp::croak "$code does not close over $attr";

    my $ref = ref $closed_over->{$attr};

    if (@_) {
        return @{ $closed_over->{$attr} } = @_ if $ref eq 'ARRAY';
        return %{ $closed_over->{$attr} } = @_ if $ref eq 'HASH';
        return ${ $closed_over->{$attr} } = shift;
    }

    return $closed_over->{$attr} if $ref eq 'HASH' || $ref eq 'ARRAY';
    return ${ $closed_over->{$attr} };
}

1;

__END__

=head1 NAME

autobox::Closure::Attributes - closures are objects are closures

=head1 SYNOPSIS

    use autobox::Closure::Attributes;
    use feature 'say';

    sub accgen {
        my $n = shift;
        return sub { ++$n }
    }

    my $from_3 = accgen(3);

    say $from_3->n;     # 3
    say $from_3->();    # 4
    say $from_3->n;     # 4
    say $from_3->n(10); # 10
    say $from_3->();    # 11
    say $from_3->();    # 12
    say $from_3->m;     # "CODE(0xDEADBEEF) does not close over $m"

=head1 DESCRIPTION

The venerable master Qc Na was walking with his student, Anton. Hoping to
prompt the master into a discussion, Anton said "Master, I have heard that
objects are a very good thing - is this true?" Qc Na looked pityingly at his
student and replied, "Foolish pupil -- objects are merely a poor man's
closures."

Chastised, Anton took his leave from his master and returned to his cell,
intent on studying closures. He carefully read the entire "Lambda: The
Ultimate..." series of papers and its cousins, and implemented a small Scheme
interpreter with a closure-based object system. He learned much, and looked
forward to informing his master of his progress.

On his next walk with Qc Na, Anton attempted to impress his master by saying
"Master, I have diligently studied the matter, and now understand that objects
are truly a poor man's closures." Qc Na responded by hitting Anton with his
stick, saying "When will you learn? Closures are a poor man's objects." At that
moment, Anton became enlightened.

=head1 IMPLEMENTATION

This module uses powerful tools to give your closures accessors for each of the
closed-over variables. You can get I<and> set them.

You can get and set arrays and hashes too, though it's a little more annoying:

    my $code = do {
        my ($scalar, @array, %hash);
        sub { return ($scalar, @array, %hash) }
    };

    $code->scalar # works as normal

    my $array_method = '@array';
    $code->$array_method(1, 2, 3); # set @array to (1, 2, 3)
    $code->$array_method; # [1, 2, 3]

    my $hash_method = '%hash';
    $code->$hash_method(foo => 1, bar => 2); # set %hash to (foo => 1, bar => 2)
    $code->$hash_method; # { foo => 1, bar => 2 }

If you're feeling particularly obtuse, you could do these more concisely:

    $code->${\ '%hash' }(foo => 1, bar => 2);
    $code->${\ '@array' }

I recommend instead keeping your hashes and arrays in scalar variables if
possible.

The effect of L<autobox> is lexical, so you can localize the nastiness to a
particular section of code -- these mysterious closu-jects will revert to their
inert state after L<autobox>'s scope ends.

=head1 HOW DOES IT WORK?

Go ahead and read the source code of this, it's not very long.

L<autobox> lets you call methods on coderefs (or any other scalar).

L<PadWalker> will let you see and change the closed-over variables of a coderef
.

L<AUTOLOAD|perlsub/"Autoloading"> is really just an accessor. It's just harder
to manipulate the "attributes" of a closure-based object than it is for
hash-based objects.

=head1 WHY WOULD YOU DO THIS?

    <#moose:jrockway> that reminds me of another thing that might be insteresting:
    <#moose:jrockway> sub foo { my $hello = 123; sub { $hello = $_[0] } }; my $closure = foo(); $closure->hello # 123
    <#moose:jrockway> basically adding accessors to closures
    <#moose:jrockway> very "closures are just classes" or "classes are just closures"

=head1 AUTHOR

Shawn M Moore, C<sartak@gmail.com>

=head1 SEE ALSO

L<autobox>, L<PadWalker>

The L</DESCRIPTION> section is from Anton van Straaten: L<http://people.csail.mit.edu/gregs/ll1-discuss-archive-html/msg03277.html>

=head1 BUGS

    my $code = do {
        my ($x, $y);
        sub { $y }
    };
    $code->y # ok
    $code->x # CODE(0xDEADBEEF) does not close over $x

This happens because Perl optimizes away the capturing of unused variables.

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2016 Shawn M Moore.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

