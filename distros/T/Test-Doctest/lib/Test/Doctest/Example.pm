package Test::Doctest::Example;

use 5.005;
use strict;
use warnings;

# You can test this module from the command line:
# $ perl -MTest::Doctest -e run Test/Doctest/Example.pm

=head1 Example

=head2 This is only an example.

    >>> 1 + 1
    2

=head2 Checked values are perl expressons.

    >>> 'foo'
    'foo'
    >>> undef
    undef

=head2 They are compared in deep manner.

    >>> [1, 2, 3, {foo => 'bar', bar => 'foo'}]
    [1, 2, 3, {bar => 'foo', foo => 'bar'}]

=head2 Multiline statements are supported.

    >>> 90 / (
    ...     4 + 5
    ... )
    10

=head2 Result could also be multiline

    >>> [1, 2, 3, {foo => 'bar', bar => 'foo'}]
    [
            1, 2, 3,
            {bar => 'foo', foo => 'bar'}
    ]

=head2 Test::Deep helpers work

    >>> [1, 2, 3, {foo => 'bar', bar => 'foo'}]
    [1, 2, 3, ignore]

    >>> [1, 2, 3]
    bag(3, 1, 2)

=head2 Original Test::Doctest one-line statements are supported too.

    $ 1 + 1
    2

=head2 Variables that were localized inside pod block...

    >>> my $foo = 10
    10

...are local to the end of the block.

    >>> $foo *= 2
    20

=head2 Variables that were localized inside pod block...

...and to the end of consequent blocks with the same name.

    >>> $foo *= 2
    40

=head2 But no longer.

    >>> no strict 'vars'
    >>> $foo
    undef

=head2 Tests are being run in the package namespace, so you can easily call subs.

    >>> foo()
    5

=head2 Changing result doesn't break testing

    >>> my $a = [1, 2, 3]
    >>> $a
    [1, 2, 3]

    >>> push(@$a, 4)
    >>> $a
    [1, 2, 3, 4]

=cut

sub foo {
    return 5;
}

1;
