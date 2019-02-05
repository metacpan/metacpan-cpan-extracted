package Test::Mocha::Util;
# ABSTRACT: Internal utility functions
$Test::Mocha::Util::VERSION = '0.66';
use strict;
use warnings;

use Carp 'croak';
use Exporter 'import';
use Test::Mocha::Types 'Slurpy';
use Types::Standard qw( ArrayRef HashRef );

our @EXPORT_OK = qw(
  check_slurpy_arg
  extract_method_name
  find_caller
);

sub check_slurpy_arg {
    # """
    # Checks the arguments list for the presence of a slurpy argument matcher.
    # It will throw an error if it is used incorrectly.
    # Otherwise it will just return silently.
    # """
    # uncoverable pod
    my @args = @_;

    my $i = 0;
    foreach (@args) {
        if ( Slurpy->check($_) ) {
            croak 'No arguments allowed after a slurpy type constraint'
              if $i < $#args;

            my $slurpy = $_->{slurpy};
            croak 'Slurpy argument must be a type of ArrayRef or HashRef'
              unless $slurpy->is_a_type_of(ArrayRef)
              || $slurpy->is_a_type_of(HashRef);
        }
        $i++;
    }
    return;
}

sub extract_method_name {
    # """Extracts the method name from its fully qualified name."""
    # uncoverable pod
    my ($method_name) = @_;
    $method_name =~ s/.*:://sm;
    return $method_name;
}

sub find_caller {
    # """Search the call stack to find an external caller"""
    # uncoverable pod
    my ( $package, $file, $line );

    my $i = 1;
    while () {
        ( $package, $file, $line ) = caller $i++;
        last if $package ne 'UNIVERSAL::ref';
    }
    return ( $file, $line );
}

# sub print_call_stack {
#     # """
#     # Returns whether the given C<$package> is in the current call stack.
#     # """
#     # uncoverable pod
#     my ( $message ) = @_;
#
#     print $message, "\n";
#     my $level = 1;
#     while ( my ( $caller, $file, $line, $sub ) = caller $level++ ) {
#         print "\t[$caller] $sub\n";
#     }
#     return;
# }

1;
