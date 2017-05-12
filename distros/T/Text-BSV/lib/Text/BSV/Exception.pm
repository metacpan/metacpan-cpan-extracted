####
# Exception.pm:  A Perl module defining a package for creating a
# Text::BSV::Exception object, which can be thrown using the Perl "die"
# function and caught using "eval".
#
# In addition to the class-name argument, which is passed in automatically
# when you use the Text::BSV::Exception->new() syntax, the constructor takes
# an exception type (one of the contants defined within the package), a
# message string, and an optional hash reference that points to arbitrary
# structured data pertaining to the exception.
#
# The constructor returns a reference to a Text::BSV::Exception object,
# which is implemented internally as a hash.
#
# The Text::BSV::Exception package provides the following public
# accessor methods:
#
#     get_type()
#     get_message()
#     get_data()
#
# If there is no structured data, the get_data() method returns a reference
# to an empty hash.
#
####
#
# Copyright 2010 by Benjamin Fitch.
#
# This library is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
####
package Text::BSV::Exception;

use 5.010001;
use strict;
use warnings;
use utf8;

use English "-no_match_vars";
use Hash::Util ("lock_keys");
use List::Util ("first", "max", "min", "sum");
use Scalar::Util ("looks_like_number");

# Version:
our $VERSION = '1.04';

# Exception types:
our $DIRECTORY_NOT_FOUND   = 0;
our $FILE_NOT_FOUND        = 1;
our $GENERAL               = 2;
our $ILLEGAL_ARGUMENT      = 3;
our $INVALID_CHARACTER     = 4;
our $INVALID_DATA_FORMAT   = 5;
our $INVALID_REGEX         = 6;
our $IO_ERROR              = 7;
our $NULL_POINTER          = 8;
our $UNSUPPORTED_OPERATION = 9;

# Reference types:
my $SCALAR_TYPE = ref \(my $foo);
my $ARRAY_TYPE  = ref [];
my $HASH_TYPE   = ref {};
my $CODE_TYPE   = ref sub { };
my $REGEX_TYPE  = ref qr//;

# General constants:
my $POUND     = "#";
my $SQ        = "'";
my $DQ        = "\"";
my $SEMICOLON = ";";
my $CR        = "\r";
my $LF        = "\n";
my $SPACE     = " ";
my $EMPTY     = "";
my $TRUE      = 1;
my $FALSE     = 0;

# Constructor:
sub new {
    my ($class, @args) = @_;
    my %exception = ("_type" => $args[0], "_message" => $args[1]);

    unless (defined($exception{"_type"})
      && looks_like_number($exception{"_type"})
      && $exception{"_type"} == int($exception{"_type"})
      && $exception{"_type"} >= 0 && $exception{"_type"} <= 9) {
        $exception{"_type"} = $GENERAL;
    } # end unless

    unless (defined $exception{"_message"}) {
        $exception{"_message"} = $EMPTY;
    } # end unless

    $exception{"_data"} = ref($args[2]) eq $HASH_TYPE
      ? $args[2] : {};

    # Bless the hash into the class:
    bless \%exception, $class;

    # Restrict the hash keys:
    lock_keys(%exception, "_type", "_message", "_data");

    # Return the object:
    return \%exception;
} # end constructor

# Methods:
sub get_type {
    return $_[0]->{"_type"};
} # end sub

sub get_message {
    return $_[0]->{"_message"};
} # end sub

sub get_data {
    return $_[0]->{"_data"};
} # end sub

# Module return value:
1;
__END__

=head1 NAME

Text::BSV::Exception - create an object that can be thrown using the Perl
"die" function (which can accept a reference instead of a string) and caught
using "eval", which stores the object in $EVAL_ERROR ($@).

=head1 SYNOPSIS

  use Text::BSV::Exception;
  my $exception = Text::BSV::Exception->new($Text::BSV::Exception::GENERAL,
    "Couldn't do stuff because of the thing.");
  my $fancy_exception = Text::BSV::Exception->new(
    $Text::BSV::Exception::NULL_POINTER,
    "Couldn't do stuff because the thing was pointing to nothing.",
    {"IsFatal" => $TRUE, "Time" => "17:47:18"});
  my $exception_type = $exception->get_type();
  my $message_string = $exception->get_message();
  my $hash_ref = $fancy_exception->get_data();

=head1 DESCRIPTION

This module defines a package for creating a Text::BSV::Exception object,
which can be thrown using the Perl "die" function and caught using "eval".

In addition to the class-name argument, which is passed in automatically
when you use the C<Text::BSV::Exception-E<gt>new()> syntax, the constructor
takes an exception type, a message string, and an optional hash reference
that points to arbitrary structured data pertaining to the exception.

The exception type must be one of the following constants defined in the
Text::BSV::Exception package:

    $DIRECTORY_NOT_FOUND
    $FILE_NOT_FOUND
    $GENERAL
    $ILLEGAL_ARGUMENT
    $INVALID_CHARACTER
    $INVALID_DATA_FORMAT
    $INVALID_REGEX
    $IO_ERROR
    $NULL_POINTER
    $UNSUPPORTED_OPERATION

The constructor returns a reference to a Text::BSV::Exception object,
which is implemented internally as a hash.  All functionality is exposed
through methods.

=head1 PREREQUISITES

This module requires Perl 5, version 5.10.1 or later.

=head1 METHODS

=over

=item Text::BSV::Exception->new($exception_type, $message,
  $optional_hash_ref);

This is the constructor.

=item $exception->get_type();

This is the accessor method for retrieving the exception type, which
must be one of the following constants defined in the
Text::BSV::Exception package:

    $DIRECTORY_NOT_FOUND
    $FILE_NOT_FOUND
    $GENERAL
    $ILLEGAL_ARGUMENT
    $INVALID_CHARACTER
    $INVALID_DATA_FORMAT
    $INVALID_REGEX
    $IO_ERROR
    $NULL_POINTER
    $UNSUPPORTED_OPERATION

=item $exception->get_message();

This is the accessor method for retrieving the message.

=item $exception->get_data();

This is the accessor method for retrieving any structured data provided
with the exception.  If there is no structured data, the C<get_data()>
method returns a reference to an empty hash.

=back

=head1 AUTHOR

Benjamin Fitch, <blernflerkl@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Benjamin Fitch.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
