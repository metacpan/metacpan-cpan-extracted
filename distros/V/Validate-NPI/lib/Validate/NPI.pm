use strict;
use warnings;
package Validate::NPI;
# ABSTRACT: Validates National Provider Identifier (NPI) numbers

use vars qw{ $VERSION @ISA @EXPORT };
$VERSION = '0.03';

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(validate_npi);

sub validate_npi {
   my ($value,$msg)=@_;

# Assume the 9-position identifier part of the NPI is 123456789.
# Using the Luhn formula on the identifier portion, the check digit is calculated as follows:
# NPI without check digit: 1 2 3 4 5 6 7 8 9
# Step 1: Double the value of alternate digits, beginning with the rightmost digit.
# 2 6 10 14 18
# Step 2: Add constant 24, to account for the 80840 prefix that would be present on a card issuer 
# identifier, plus the individual digits of products of doubling, plus unaffected digits.
# 24 + 2 + 2 + 6 + 4 + 1 + 0 + 6 + 1 + 4 + 8 + 1 + 8 = 67
# Step 3: Subtract from next higher number ending in zero.
# 70 - 67 = 3
# Check digit = 3
# NPI with check digit = 1234567893

   if ($value!~/^\d{10}$/) {
      push @$msg,"NPI must be exactly 10 digits long" if ref $msg eq 'ARRAY';
      return 0;
   }
   my @digits=split(//,$value);
   map { $digits[$_]*=2 } (0,2,4,6,8);
   my $sum=24;
   for my $d (@digits[0..8]) {
      if ($d>9) {
         $sum+=int($d/10)+$d%10;   # individual digits
      } else {
         $sum+=$d;
      }
   }
   my $m=10*(int($sum/10)+1);
   $m-=$sum;
   if ($m!=$digits[9]) {
      push @$msg,"NPI does not validate" if ref $msg eq 'ARRAY';
      return 0;
   }
   1;
}

1;

__END__

=pod

=head1 NAME

Validate::NPI - Validates National Provider Identifier (NPI) numbers

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  $fValidated=validate_npi('1234567893');    # will return 1 (true)

=head1 METHODS

=head2 validate_npi($value,$msg)

Call with a scalar value for validation and an optional array reference for an explanation
of why validation failed.   Returns 1 (true) if the NPI validates correctly.

=head1 ACKNOWLEDGEMENTS

Adapted from a code fragment found at http://javatechnicals.blogspot.com/2009/03/npi-check-digit-validation-peoplecode.html

=head1 AUTHOR

Stephen Flitman <sflitman@xenoscience.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Stephen Flitman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
