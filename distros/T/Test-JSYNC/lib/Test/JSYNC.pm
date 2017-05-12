package Test::JSYNC;

use 5.006;
use strict;
use parent 'Test::Builder::Module';
use English qw( -no_match_vars );
use Carp;
use JSYNC;
use Test::Differences;

our $VERSION   = '0.02';
our @EXPORT    = qw( jsync_ok jsync_is );
our @EXPORT_OK = qw( is_valid_jsync is_jsync );

*is_valid_jsync = \&jsync_ok;
*is_jsync       = \&jsync_is;

sub jsync_ok ($;$) {
    my ($input, $test_name) = @_;
    my $test = __PACKAGE__->builder;

    croak 'usage: jsync_ok(input, test_name)'
        if !defined $input;

    eval { JSYNC::load($input) };

    if (my $error = $EVAL_ERROR) {
        $test->ok(0, $test_name);
        $test->diag("Input was not valid JSYNC: $error");
        return;
    }

    $test->ok(1, $test_name);
    return 1;
}

sub jsync_is ($$;$) {
    my ($input, $expected, $test_name) = @_;
    my $test = __PACKAGE__->builder;
    my %result_for;

    croak 'usage: jsync_is(input, expected, test_name)'
        if !defined $input || !defined $expected;

    for my $item (
        { key => 'input',    value => $input    },
        { key => 'expected', value => $expected },
    ) {
        $result_for{ $item->{key} } = eval { JSYNC::load( $item->{value} ) };

        if (my $error = $EVAL_ERROR) {
            $test->ok(0, $test_name);
            $test->diag(ucfirst "$item->{key} was not valid JSYNC: $error");
            return;
        }
    }

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    return eq_or_diff($result_for{input}, $result_for{expected}, $test_name);
}

1;

__END__

=head1 NAME

Test::JSYNC - Test JSYNC data

=head1 VERSION

This document describes Test::JSYNC version 0.02.

=cut

=head1 SYNOPSIS

   use Test::JSYNC;

   jsync_ok $jsync,                  'jsync is well formed';
   jsync_is $jsync, $expected_jsync, 'jsync matches what we expected';

=head1 DESCRIPTION

JSON YAML Notation Coding (JSYNC) is an extension of JSON that can serialize
any data objects.  Test::JSYNC makes it easy to verify that you have built
valid JSYNC and that it matches your expected output.

This module uses the L<JSYNC> module, which is currently the only CPAN module
to support JSYNC; however, the module itself states that it "is a very early
release of JSYNC, and should not be used at all unless you know what you are
doing."

=head1 EXPORTED TESTS

=head2 jsync_ok

Test passes if the string passed is valid JSYNC.

   jsync_ok $jsync, 'jsync is well formed';

C<is_valid_jsync> is provided as an alternative to C<jsync_ok> using the same
naming convention as L<Test::JSON> but is not exported by default.

=head2 jsync_is

Test passes if the two JSYNC strings are valid JSYNC and evaluate to the same
data structure.

   jsync_is $jsync, $expected_jsync, 'jsync matches what we expected';

L<Test::Differences> is used to provide easy diagnostics of why the JSYNC
structures did not match.  For example:

      Failed test 'jsync matches what we expected'
      in t/jsync.t at line 10.
    +----+---------------------------+---------------------------+
    | Elt|Got                        |Expected                   |
    +----+---------------------------+---------------------------+
    |   0|{                          |{                          |
    |   1|  bool => '1',             |  bool => '1',             |
    |   2|  description => bless( {  |  description => bless( {  |
    |   3|    value => undef         |    value => undef         |
    |   4|  }, 'Foo' ),              |  }, 'Foo' ),              |
    |   5|  id => '1',               |  id => '1',               |
    *   6|  name => 'foo'            |  name => 'fo'             *
    |   7|}                          |}                          |
    +----+---------------------------+---------------------------+

C<is_jsync> is provided as an alternative to C<jsync_is> using the same naming
convention as L<Test::JSON> but is not exported by default.

=head1 SEE ALSO

This module uses L<JSYNC> and L<Test::Differences>, and is based on
L<Test::JSON>.

=head1 AUTHOR

Nick Patch <patch@cpan.org>

=head1 ACKNOWLEDGEMENTS

This module was forked from L<Test::JSON> by Curtis "Ovid" Poe.

=head1 COPYRIGHT & LICENSE

Copyright 2011 Nick Patch

Copyright 2005-2007 Curtis "Ovid" Poe.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
