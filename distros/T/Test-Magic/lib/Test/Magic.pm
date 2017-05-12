package Test::Magic;
    use warnings;
    use strict;
    use Carp;
    use Test::More;
    our @ISA = 'Test::More';
    our @EXPORT = ('test', @Test::More::EXPORT);
    our $VERSION = '0.21';

=head1 NAME

Test::Magic - terse tests with useful error feedback

=head1 VERSION

Version 0.21

=cut

    sub import {
        require Exporter;
        local $Test::Builder::Level
            = $Test::Builder::Level + 1;
        plan splice @_, 1, $#_ if @_ > 1;
        goto &{Exporter->can('import')}
    }

    my %invert = qw(
        == !=   eq ne
        <  >=   lt ge
        >  <=   gt le
    );
    @invert{values %invert} = keys %invert;

    use overload fallback => 0, 'nomethod' => sub {
        my ($self, $expect, $flip, $op) = @_;
        my ($got, $invert) = @$self{qw/got invert/};

        croak 'is/isnt unsupported on rhs of operator' if $flip;
        croak "unsupported op: $op"                unless $invert{$op}
                                                       or $op eq '~~';
        bless do {
            ($op eq '~~' or
            ($op =~ /[!=]=/ and ref $expect eq ref qr//))
                ? sub {
                    ref or $_ = qr/$_/ for $expect;
                    @_ = ($got, $expect, $_[0]);
                    ($invert xor $op eq '!=')
                        ? goto &unlike
                        : goto &like
                }
            : ($op eq '==' and ref $expect)
                ? do {
                    croak 'unable to invert is_deeply' if $invert;
                    sub {
                       @_ = ($got, $expect, $_[0]);
                       goto &is_deeply
                    }
                }
            : sub {
                $op = $invert{$op} if $invert;
                @_ = ($got, $op, $expect, $_[0]);
                goto &cmp_ok
            }
        } => 'Test::Magic::Test'
    };

    sub test {
        my $name = shift;
        if (grep {ref ne 'Test::Magic::Test'} @_) {
            croak "invalid arguments for test:\n".
                  "    did you use parenthesis around your comparison?\n".
                  "        good: is 1 == 1;\n".
                  "        bad:  is(1 == 1);\n"
        }
        local $Test::Builder::Level
            = $Test::Builder::Level + 1;
        if (@_ == 1) {
            $_[0]($name)
        } else {
            my $num = 1;
            $_->($name.' '.$num++) for @_
        }
    }
    BEGIN {undef $_ for *is, *isnt}
    sub is   ($) {bless {got => $_[0]}}
    sub isnt ($) {bless {got => $_[0], invert => 1}}

=head1 SYNOPSIS

    use Test::Magic tests => 9;

    test 'numbers',
      is 1 == 1,
      is 1 > 2; 

    test 'strings',
      is 'asdf' eq 'asdf',
      is 'asdf' gt 'asdf';

    test 'regex',
      is 'abcd' == qr/bc/,   # == is overloaded when rhs is a regex
      is 'abcd' ~~ q/bc/,    # ~~ can be used with a string rhs in perl 5.10+
      is 'badc' ~~ q/bc/;

    test 'data structures',
      is [1, 2, 3] == [1, 2, 3],   # also overloaded when rhs is a reference
      is {a => 1, b => 2} == {a => 1, b => 1};

results in the following output:

    1..9
    ok 1 - numbers 1
    not ok 2 - numbers 2
    #   Failed test 'numbers 2'
    #   at example.t line 3.
    #     '1'
    #         >
    #     '2'
    ok 3 - strings 1
    not ok 4 - strings 2
    #   Failed test 'strings 2'
    #   at example.t line 7.
    #     'asdf'
    #         gt
    #     'asdf'
    ok 5 - regex 1
    ok 6 - regex 2
    not ok 7 - regex 3
    #   Failed test 'regex 3'
    #   at example.t line 11.
    #                   'badc'
    #     doesn't match '(?-xism:bc)'
    ok 8 - data structures 1
    not ok 9 - data structures 2
    #   Failed test 'data structures 2'
    #   at example.t line 16.
    #     Structures begin differing at:
    #          $got->{b} = '2'
    #     $expected->{b} = '1'
    # Looks like you failed 4 tests of 9.

you get the output of L<Test::More>'s C< cmp_ok >, C< like >, or C< is_deeply >
with a more natural syntax, and the test's name is moved before the test and is
numbered if you have more than one test.

=head1 EXPORT

C< test is isnt > and everything from L<Test::More> except C< is > and C< isnt >

=head1 SUBROUTINES

=over 4

=item C< test NAME, LIST_OF_TESTS >

C< test > runs a list of tests.  if there is one test, C< NAME > is used
unchanged. otherwise, each test is sequentially numbered (C< NAME 1 >,
C< NAME 2 >, ...)

=item C< is GOT OPERATOR EXPECTED >

prepares a test for C< test >. do not use parenthesis with C< is >.
if you must, it needs to be written C< (is 1 == 1) > and never C< is(1 == 1) >

=item C< isnt GOT OPERATOR EXPECTED >

prepares a test for C< test > that expects to fail. do not use parenthesis with
C< isnt >. if you must, it needs to be written C< (isnt 1 == 1) > and never
C< isnt(1 == 1) >

=back

=head1 NOTES

this module does B<not> use source filtering. for those interested in how it
does work, the code:

    test 'my test',
      is 1 == 1,
      is 1 == 2;

is parsed as follows:

    test( 'my test,
       (is(1) == 1),
       (is(1) == 2)
    );

the C< is > function binds tightly to its argument, making the parenthesis
unnecessary. it returns an overloaded object that then captures the comparison
operator and the rhs argument.  the overloading operation returns a code
reference which expects to be passed its test name. the C< test > function does
just that.  so ultimately, the code becomes something like this:

   Test::More::cmp_ok( 1, '==', 1, 'my test 1' );
   Test::More::cmp_ok( 1, '==', 2, 'my test 2' );

C< cmp_ok > is used for most comparisons, C< like > or C< unlike > for regex,
and C< is_deeply > when the operator is C< == > and the rhs (the expected value)
is a reference.

if you need to do some setup before the test:

    test 'this test requires setup', do {
      my $obj = Package->new();
      ...
      is ref $obj eq 'Package',
      is $obj->value eq 'some value'
    };

=head1 AUTHOR

Eric Strom, C<< <asg at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-magic at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Magic>. I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 ACKNOWLEDGEMENTS

this module uses C< Test::More > internally

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Eric Strom.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

'Test::Magic' if 'first require'
