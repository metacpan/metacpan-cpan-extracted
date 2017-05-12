use strict;
use warnings;

package Test::Numeric;

our $VERSION = '0.3';

use Test::Builder;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(
  is_number isnt_number
  is_integer isnt_integer
  is_even is_odd
  is_formatted isnt_formatted
  is_money isnt_money
);

my $Test = Test::Builder->new;

sub import {
    my ($self) = shift;
    my $pack = caller;

    $Test->exported_to($pack);
    $Test->plan(@_);

    $self->export_to_level( 1, $self, $_ ) for @EXPORT;
}

=head1 NAME

Test::Numeric - Testing utilities for numbers.

=head1 SYNOPSIS

 use Test::Numeric tests => 8;

 # The following functions are all exported by Test::Numeric

=for example
use Test::Numeric;

=for example begin

 is_number   '12.34e56',  "valid number";
 is_number   '-12.34E56', "valid number";
 isnt_number 'test',      "not a number";

 is_even 2, "an even number";
 is_odd  3, "an odd number";
 
 is_integer   '123',    'an integer';
 isnt_integer '123.45', 'not an integer';
 
 is_formatted   '1-.2', '123.45';
 isnt_formatted '1-.2', '123.4';

=for example end

=head1 DESCRIPTION

This is a simple testing module that lets you do several tests on
numbers. You can check that it is a number, check that it is an
integer, check if they are odd or even and finally check if they are
of a certain form.

=cut

################################################################################

sub _test_number {
    my $number = shift;

    return 0 unless defined $number && length $number;

    # Accept obviously right things.
    return 1 if $number =~ m/^\d+$/;

    # Throw out obviously wrong things.
    return 0 if $number =~ m/[^+\-\.eE0-9]/;

    # Split the number into parts.
    my ( $num, $e, $exp ) = split /(e|E)/, $number, 2;

    # Check that the exponent is valid.
    if ($e) { return 0 unless $exp =~ m/^[+\-]?\d+$/; }

    # Check the number.
    return 0 unless $num =~ m/\d/;
    return 0 unless $num =~ m/^[+\-]?\d*\.?\d*$/;

    return 1;
}

=pod

=over 4

=item is_number

 is_number $number, $name;

C<is_number> tests whether C<$number> is a number. The number can be
positive or negative, it can have a formatted point and an
exponent. These are all valid numbers: 1, 23, 0.34, .34, -12.34e56

=item isnt_number

The opposite of C<is_number>.

=cut

sub is_number {
    my ( $test, $name ) = @_;
    $Test->ok( _test_number($test), $name );
}

sub isnt_number {
    my ( $test, $name ) = @_;
    $Test->ok( !_test_number($test), $name );
}

################################################################################

sub _test_integer {
    my $number = shift;
    return undef unless _test_number($number);
    return 1 if $number =~ m/^[+\-]?\d+\.?0*$/;
    #return int($number) == $number;
    return 0;
}

sub is_integer {
    my ( $test, $name ) = @_;
    my $result = _test_integer( $test );
    $Test->diag("The value given is not a number - failing test.")
	unless defined $result;
    $Test->ok( defined $result && $result, $name );
}

sub isnt_integer {
    my ( $test, $name ) = @_;
    my $result = _test_integer( $test );
    $Test->diag("The value given is not a number - failing test.")
	unless defined $result;
    $Test->ok( defined $result && ! $result, $name );
}

=pod

=item is_integer

 is_integer $number, $name;

C<is_integer> tests if C<$number> is an integer, ie a whole
number. Fails if the number is not a number r not a number at all.

=item isnt_integer

The opposite of C<is_integer>. Note that C<isnt_integer> will fail if
the number is not a number. So 'abc' may not be an integer but
C<isnt_integer> will still fail.

=cut

################################################################################

sub _test_even {
    my $number = shift;
    return undef unless _test_integer($number);
    return $number % 2 == 0 ? 1 : 0;
}

sub _test_odd {
    my $number = shift;
    return undef unless _test_integer($number);
    return $number % 2 == 0 ? 0 : 1;
}

=pod

=item is_even

 is_even $number, $name;

C<is_even> tests if the number given is even. Fails for non-integers. Zero is even.

=item is_odd

As C<is_even>, but for odd numbers.

=cut

sub is_even {
    my ( $test, $name ) = @_;
    my $result = _test_even( $test );
    $Test->diag('The number in not an integer - failing test.')
	unless defined $result;
    $Test->ok( defined $result && $result, $name );
}

sub is_odd {
    my ( $test, $name ) = @_;
    my $result = _test_odd( $test );
    $Test->diag('The number in not an integer - failing test.')
	unless defined $result;
    $Test->ok( defined $result && $result, $name );
}

################################################################################

sub _split_format_error {
    my $format = shift;
    $Test->diag("The format '$format' is not valid");
    return 0;
}

sub _split_format {
    my $format  = shift;
    my @returns = ();

    my ( $pre, $suf ) = split /\./, $format, 2;

    foreach my $arg ( $pre, $suf ) {
        return _split_format_error($format) unless defined $arg && length $arg;

        my ( $min, $sep, $max ) = split /(\-)/, $arg, 2;

        unless ( defined $max && length $max ) {
            $max = $sep ? undef: $min;
        }

        return _split_format_error($format)
          unless _test_integer($min) && $min >= 0;

        if ( defined $max && length $max ) {
            return _split_format_error($format)
              unless _test_integer($max) && $max >= $min;
        }

        push @returns, $min, $max;
    }

    return @returns;
}

sub _test_formatted {
    my $format = shift;
    my $number = shift;

    my ( $pre_min, $pre_max, $suf_min, $suf_max ) = _split_format($format);
    return undef unless defined $suf_min;

    my ( $pre_len, $suf_len ) = map { defined $_ ? length $_ : 0 } split /\./,
      $number, 2;

    return 0 unless $pre_len >= $pre_min;
    return 0 unless $suf_len >= $suf_min;

    if ( defined $pre_max ) { return 0 unless $pre_len <= $pre_max }
    if ( defined $suf_max ) { return 0 unless $suf_len <= $suf_max }

    return 1;
}

sub is_formatted {
    my ( $format, $test, $name ) = @_;
    my $result = _test_formatted( $format, $test );
    $Test->ok( defined $result && $result, $name );
}

sub isnt_formatted {
    my ( $format, $test, $name ) = @_;
    my $result = _test_formatted( $format, $test );
    $Test->ok( defined $result && !$result, $name );
}

=pod

=item is_formatted

  is_formatted $format, $number, $name;

C<is_formatted> allows you to test that the number complies with a
certain format. C<$format> tells the function what to check for and is
of the form C<pre.suf> where C<pre> and C<suf> are the number of
digits before and after the decimal point. They are either just a
number ( eg. '3.2' for something like 123.12 ) or a range (
eg. '3.1-2' ) for either 123.1 or 123.12 ).

The range can be open-ended, for example '0-.2' will match any number
of digits before the decimal place, and exactly two after.

If the format is incorrect then the test will fail and a warning printed.

This test is intended for things such as id numbers where the number must be something like C<000123>.

=item isnt_formatted

The same as is_formatted but negated.

=cut 

sub is_money {
    my ( $test, $name ) = @_;
    my $result = _test_formatted( '0-.2', $test );
    $Test->ok( defined $result && $result, $name );
}

sub isnt_money {
    my ( $test, $name ) = @_;
    my $result = _test_formatted( '0-.2', $test );
    $Test->ok( defined $result && ! $result, $name );
}

=pod

=item is_money

 is_money $number, $name;

This is a conveniance function to test if the value looks like money,
ie has a format of C<0-.2> - which is tw decimal points. Internally it
just calls is_formatted with the correct format.

=item isnt_money

The opposite of C<is_money>.

=back

=head1 TODO

=over

=item *

Create appropriate test names if none is given.

=item *

Add tests to see if a number looks like hex, octal, binary etc.

=back

=head1 AUTHOR

Edmund von der Burg <evdb@ecclestoad.co.uk>

Bug reports, patches, suggestions etc are all welcomed.

=head1 COPYRIGHT

Copyright 2004 by Edmund von der Burg <evdb@ecclestoad.co.uk>.  

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=head1 SEE ALSO

L<Test::Tutorial> for testing basics, L<Test::Builder> for the module on
which this one is built.

=cut

1;
