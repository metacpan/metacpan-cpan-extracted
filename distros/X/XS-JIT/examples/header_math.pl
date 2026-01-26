#!/usr/bin/env perl
#
# Example: Using XS::JIT::Header to bind math.h functions
#
# Usage: perl -Mblib examples/header_math.pl
#

use strict;
use warnings;
use File::Temp qw(tempdir);

use XS::JIT::Header;

my $cache_dir = tempdir(CLEANUP => 1);

print "Creating XS::JIT::Header bindings for math.h...\n\n";

# Create bindings from math.h
my $math = XS::JIT::Header->new(
    header    => 'math.h',
    package   => 'FastMath',
    cache_dir => $cache_dir,
);

# Show what functions were discovered
my @funcs = $math->functions;
print "Found ", scalar(@funcs), " functions in math.h\n";
print "First 10: ", join(', ', @funcs[0..9]), "...\n\n";

# Attach specific functions we want
print "Attaching functions: sin, cos, tan, sqrt, pow, floor, ceil, log, exp\n";
$math->attach('sin');
$math->attach('cos');
$math->attach('tan');
$math->attach('sqrt');
$math->attach('pow');
$math->attach('floor');
$math->attach('ceil');
$math->attach('log');
$math->attach('exp');

# Compile (generates XS code and compiles to .so)
print "Compiling...\n\n";
$math->compile;

# Now use the functions!
print "Testing FastMath functions:\n";
print "-" x 40, "\n";

my $pi = 3.14159265358979;

printf "FastMath::sin(π/2)     = %.6f\n", FastMath::sin($pi / 2);
printf "FastMath::cos(0)       = %.6f\n", FastMath::cos(0);
printf "FastMath::tan(π/4)     = %.6f\n", FastMath::tan($pi / 4);
printf "FastMath::sqrt(2)      = %.6f\n", FastMath::sqrt(2);
printf "FastMath::pow(2, 10)   = %.0f\n", FastMath::pow(2, 10);
printf "FastMath::floor(3.7)   = %.0f\n", FastMath::floor(3.7);
printf "FastMath::ceil(3.2)    = %.0f\n", FastMath::ceil(3.2);
printf "FastMath::log(2.718)   = %.6f\n", FastMath::log(2.718281828);
printf "FastMath::exp(1)       = %.6f\n", FastMath::exp(1);

print "\n";
print "All functions work! The compiled module is cached at:\n";
print "  $cache_dir\n";
print "\nSubsequent runs will skip compilation and use the cached version.\n";

__END__

=head1 NAME

header_math.pl - Example of XS::JIT::Header with math.h

=head1 DESCRIPTION

This example demonstrates how to use XS::JIT::Header to create
Perl bindings for C library functions by parsing the header file.

The workflow is:

1. Create an XS::JIT::Header object with the header path
2. Attach the functions you want to expose
3. Call compile() to generate and compile XS code
4. Use the functions as normal Perl subroutines

=head1 SEE ALSO

L<XS::JIT::Header>, L<XS::JIT>

=cut
