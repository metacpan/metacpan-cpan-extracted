package Test::Lazy;

use warnings;
use strict;

=head1 NAME

Test::Lazy - A quick and easy way to compose and run tests with useful output.

=head1 VERSION

Version 0.061

=cut

our $VERSION = '0.061';

=head1 SYNOPSIS

	use Test::Lazy qw/check try/;

    # Will evaluate the code and check it:
	try('qw/a/' => eq => 'a');
	try('qw/a/' => ne => 'b');
	try('qw/a/' => is => ['a']);

    # Don't evaluate, but still compare:
	check(1 => is => 1);
	check(0 => isnt => 1);
	check(a => like => qr/[a-zA-Z]/);
	check(0 => unlike => qr/a-zA-Z]/);
	check(1 => '>' => 0);
	check(0 => '<' => 1);

    # A failure example:

	check([qw/a b/] => is => [qw/a b c/]);

    # Failed test '['a','b'] is ['a','b','c']'
    # Compared array length of $data
    #    got : array with 2 element(s)
    # expect : array with 3 element(s)


    # Custom test explanation:

	try('2 + 2' => '==' => 5, "Math is hard: %?");

    # Failed test 'Math is hard: 2 + 2 == 5'
    #      got: 4
    # expected: 5

=head1 DESCRIPTION

Ever get tired of coming up with a witty test message? Think that the best explanation for a test is the code behind it? Test::Lazy is for you.
Test::Lazy will take a stringified piece of code, evaluate it, and use a comparator to match the result to an expectation. If the test fails, then Test::Lazy will use the
code as the test explanation so you can exactly what went wrong.

You can even put in your own amendment to Test::Lazy's response, just use the '%?' marker in your explanation.

=head1 COMPARISON

If <expect> is an ARRAY or HASH reference, then Test::Lazy will do a structure comparison, using cmp_structure as opposed to cmp_scalar. Generally, this means using Test::Deep
to do the comparison.

For try or check, <compare> should be one of the below:

=head2 Scalar

    ok: Test::More::ok

    not_ok: ! Test::More::ok

    < > <= >= lt gt le ge == != eq ne: Test::More::cmp_ok

    is isnt like unlike: Test::More::{is,isnt,like,unlike}

=head2 Structural

    ok: Test::More::ok

    not_ok: ! Test::More::ok

    bag same_bag samebag: Test::Deep::cmp_bag

    set same_set sameset: Test::Deep::cmp_set

    same is like eq ==: Test::Deep::cmp_deeply

    isnt unlink ne !=: Test::More::ok(!Test::Deep::eq_deeply)

=cut

BEGIN {
	our @EXPORT_OK = qw/check try template/;
	use base qw/Exporter/;
}

use Test::Lazy::Tester;
use Test::Builder;

{
    my $singleton;
    sub _singleton() {
        return $singleton ||= Test::Lazy::Tester->new;
    }
    *singleton = \&_singleton
}

=head1 EXPORTS

=head2 check( <got>, <compare>, <expect>, [ <notice> ] )

Compare <got> to <expect> using <compare>.
Optionally provide a <notice> to display on failure. If <notice> is not given,
then one will be automatically made from <got>, <compare>, and <expect>.

Note, if <expect> is an ARRAY or HASH, try will do structural comparison instead of scalar
comparison.

	check([qw/a b/] => is => [qw/a b c/]);

	# This will produce the following output:

	#   Failed test '["a","b"] is ["a","b","c"]'
	#   at __FILE__ line __LINE__.
	#         got: '["a","b"]'
	#    expected: '["a","b","c"]'

=cut

sub check {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return _singleton->check(@_);
}

=head2 try( <statement>, <compare>, <expect>, [ <notice> ] )

Evaluate <statement> and compare the result to <expect> using <compare>.
Optionally provide a <notice> to display on failure. If <notice> is not given,
then one will be automatically made from <statement>, <compare>, and <expect>.

C<try> will also try to guess what representation is best for the result of
the statement, whether that be single value, ARRAY, or HASH. It'll do this based
on what is returned by the statement, and the type of <expect>.
See `perldoc -m Test::Lazy` for more detail.

Note, if <expect> is an ARRAY or HASH, try will do structural comparison instead of scalar
comparison.


	try("2 + 2" => '==' => 5);

	# This will produce the following output:

	#   Failed test '2 + 2 == 5'
	#   at __FILE__ line __LINE__.
	#          got: '4'
	#     expected: '5'

=cut

sub try {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return _singleton->try(@_);
}

=head2 template( ... ) 

Convenience function for creating a C<Test::Lazy::Template>. All arguments are directly passed to
C<Test::Lazy::Template::new>.

See L<Test::Lazy::Template> for more details.

Returns a new L<Test::Lazy::Template> object.

=cut

sub template {
    return _singleton->template(@_);
}

=head1 METHODS

=head2 Test::Lazy->singleton

Access the underlying Test::Lazy::Tester object to customize comparators or renderers.

    Test::Lazy->singleton->cmp_scalar->{xyzzy} = sub {
        Test::More::cmp_ok($_[0] => eq => "xyzzy", $_[2]);
    };

    # ... meanwhile ...

	check("xyzy" => "is_xyzzy");

    # Failed test 'xyzy is_xyzzy'
    #      got: 'xyzy'
    # expected: 'xyzzy'

Returns a L<Test::Lazy::Tester> object.

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-lazy at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Lazy>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Lazy

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Lazy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Lazy>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Lazy>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Lazy>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Test::Lazy
