package Test2::Tools::Expressive;

use 5.008001;
use strict;
use warnings;

=head1 NAME

Test2::Tools::Expressive -- Expressive tools for Perl's Test2 framework

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

use parent 'Exporter';

our @EXPORT_OK = qw(
    is_undef

    is_blank
    is_nonblank

    is_empty_array
    is_nonempty_array

    is_empty_hash
    is_nonempty_hash
);

our @EXPORT = @EXPORT_OK;

use Test2::API qw( context );
use Test2::Tools::Explain;

=head1 SYNOPSIS

    use Test2::Tools::Expressive;

    my $user = get_user_object( $bogus_id );
    is_undef( $user, 'Should not be able to find a user with a bogus ID' );

=head1 WHY TEST::EXPRESSIVE?

Test2::Tools::Expressive is designed to make your code more readable,
based on the idea that reading English is easier and less prone to
misinterpretation than reading Perl, and less prone to error by reducing
common cut & paste tasks.

The module's functions also provide diagnostics to make it easier to
see why your test failed.  For example this test:

    my $errors = try_something();
    is_empty_array( $errors, 'Did errors come back empty?' );

Gives this:

    # Failed test 'Did errors come back empty?'
    # at t/test.t line 37.
    # Expected ARRAY reference but got HASH

=head1 EXPORTS

All functions in this module are exported by default.

=head1 SUBROUTINES

=head2 is_undef( $got [, $name ] )

Verifies that C<$got> is undefined.

You must pass at least one argument.  Otherwise, calling C<is_undef>
with no parameters would pass.

=cut

sub is_undef {
    my $nargs = scalar @_;

    my $got  = shift;
    my $name = shift;

    my $ok;
    my $ctx = context();

    if ( $nargs == 0 ) {
        $ok = $ctx->ok( 0, $name );
        $ctx->diag( 'Must pass a value to is_undef' );
    }
    else {
        $ok = $ctx->ok( !defined $got, $name );
    }

    $ctx->release;

    return $ok;
}


=head2 is_blank( $got [, $name ] )

Verifies that C<$got> is a defined scalar, is not a reference and is an
empty string.  Note that the string must be empty, so an all-whitespace
string will fail.

=cut

sub is_blank {
    my $got  = shift;
    my $name = shift;

    my $ok;
    my $ctx = context();

    my $ref = ref $got;
    if ( $ref ne '' ) {
        $ok = $ctx->ok( 0, $name );
        my $article = ($ref =~ /^[AI]/) ? 'an' : 'a';
        $ctx->diag( "Got $article $ref reference" );
    }
    elsif ( $got ne '' ) {
        $ok = $ctx->ok( 0, $name );
        $ctx->diag( 'Got a nonempty string' );
    }
    else {
        $ok = $ctx->ok( 1, $name );
    }

    $ctx->release;

    return $ok;
}


=head2 is_nonblank( $got [, $name ] )

Verifies that C<$got> is a defined scalar, is not a reference and is
not an empty string.

=cut

sub is_nonblank {
    my $got  = shift;
    my $name = shift;

    my $ok;
    my $ctx = context();

    my $ref = ref $got;
    if ( $ref ne '' ) {
        $ok = $ctx->ok( 0, $name );
        my $article = ($ref =~ /^[AI]/) ? 'an' : 'a';
        $ctx->diag( "Got $article $ref reference" );
    }
    elsif ( $got eq '' ) {
        $ok = $ctx->ok( 0, $name );
        $ctx->diag( 'Got an empty string' );
    }
    else {
        $ok = $ctx->ok( 1, $name );
    }

    $ctx->release;

    return $ok;
}


=head2 is_nonempty_array( $got [, $name ] )

Verifies that C<$got> is an arrayref, and that the array contains at
least one element.

=cut

sub is_nonempty_array {
    my $got  = shift;
    my $name = shift;

    my $ok;
    my $ctx = context();

    my $ref = ref $got;
    if ( $ref eq '' ) {
        $ok = $ctx->ok( 0, $name );
        $ctx->diag( 'Not a reference' );
    }
    elsif ( $ref ne 'ARRAY' ) {
        $ok = $ctx->ok( 0, $name );
        $ctx->diag( "Expected ARRAY reference but got $ref." );
    }
    elsif ( !@{$got} ) {
        $ok = $ctx->ok( 0, $name );
        $ctx->diag( 'Array contains no elements' );
    }
    else {
        $ok = $ctx->ok( 1, $name );
    }

    $ctx->release;

    return $ok;
}


=head2 is_empty_array( $got [, $name ] )

Verifies that C<$got> is an arrayref, and that the array it refers to
has no elements.

If the array contains anything, they will be dumped as a diagnostic
using Test2::Tools::Explain.

=cut

sub is_empty_array {
    my $got  = shift;
    my $name = shift;

    my $ok;
    my $ctx = context();

    my $ref = ref $got;
    if ( $ref eq '' ) {
        $ok = $ctx->ok( 0, $name );
        $ctx->diag( 'Not a reference' );
    }
    elsif ( $ref ne 'ARRAY' ) {
        $ok = $ctx->ok( 0, $name );
        $ctx->diag( "Expected ARRAY reference but got $ref." );
    }
    elsif ( (my $n = @{$got}) > 0 ) {
        $ok = $ctx->ok( 0, $name );
        my $s = $n == 1 ? '' : 's';
        $ctx->diag( "Array contains $n element$s" );
        $ctx->diag( explain( $got ) );
    }
    else {
        $ok = $ctx->ok( 1, $name );
    }

    $ctx->release;

    return $ok;
}


=head2 is_empty_hash( $got [, $name ] )

Verifies that C<$got> is a hashref, and that the hash it refers to has
no elements.

If the hash contains any elements, they will be dumped as a diagnostic
using Test2::Tools::Explain.

=cut

sub is_empty_hash {
    my $got  = shift;
    my $name = shift;

    my $ok;
    my $ctx = context();

    my $ref = ref $got;
    if ( $ref eq '' ) {
        $ok = $ctx->ok( 0, $name );
        $ctx->diag( 'Not a reference' );
    }
    elsif ( $ref ne 'HASH' ) {
        $ok = $ctx->ok( 0, $name );
        $ctx->diag( "Expected HASH reference but got $ref." );
    }
    elsif ( (my $n = scalar keys %{$got}) > 0 ) {
        $ok = $ctx->ok( 0, $name );
        my $s = $n == 1 ? '' : 's';
        $ctx->diag( "Hash contains $n element$s" );
        $ctx->diag( explain( $got ) );
    }
    else {
        $ok = $ctx->ok( 1, $name );
    }

    $ctx->release;

    return $ok;
}


=head2 is_nonempty_hash( $got [, $name ] )

Verifies that C<$got> is a hashref, and that the hash contains at least
one entry.

=cut

sub is_nonempty_hash {
    my $got  = shift;
    my $name = shift;

    my $ok;
    my $ctx = context();

    my $ref = ref $got;
    if ( $ref eq '' ) {
        $ok = $ctx->ok( 0, $name );
        $ctx->diag( 'Not a reference' );
    }
    elsif ( $ref ne 'HASH' ) {
        $ok = $ctx->ok( 0, $name );
        $ctx->diag( "Expected HASH reference but got $ref." );
    }
    elsif ( scalar keys %{$got} == 0 ) {
        $ok = $ctx->ok( 0, $name );
        $ctx->diag( 'Hash contains no entries.' );
    }
    else {
        $ok = $ctx->ok( 1, $name );
    }

    $ctx->release;

    return $ok;
}


=head1 AUTHOR

Andy Lester, C<< <andy at petdance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/petdance/test2-tools-expressive>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test2::Tools::Expressive

You can also look for information at:

=over 4

=item * GitHub project page

L<https://github.com/petdance/test2-tools-expressive>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test2-Tools-Expressive>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test2-Tools-Expressive>

=item * Search CPAN

L<http://search.cpan.org/dist/Test2-Tools-Expressive/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Andy Lester.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Test2::Tools::Expressive
