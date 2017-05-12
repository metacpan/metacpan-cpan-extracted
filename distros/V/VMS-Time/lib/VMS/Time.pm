package VMS::Time;

use strict;
use warnings;
use Carp;

use Exporter qw(import);
use AutoLoader;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use VMS::Time ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( routines => [ qw( bintim asctim gettim numtim
				       epoch_to_vms vms_to_epoch) ],
		     constants => [ qw( PACK LONGINT FLOAT HEX BIGINT ) ],
		     );

$EXPORT_TAGS{all} = [ @{$EXPORT_TAGS{routines}}, @{$EXPORT_TAGS{constants}} ];

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = ();

our $VERSION = '0.1';

require XSLoader;
XSLoader::load('VMS::Time', $VERSION);

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&VMS::Time::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';
            *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

VMS::Time - Manipulate OpenVMS binary time values

=head1 SYNOPSIS

  use VMS::Time ':all';

  $now = gettim();
  $bin = bintim('01-jan-2010 12:00:00.00');
  $asc = asctim($bin);
  ($year, $month, $day, $hr, $mn, $sc, $cc) = numtim($bin);
  $unix = vms_to_epoch($bin);
  $vms = epoch_to_vms(time());

=head1 DESCRIPTION

These functions provide access to the OpenVMS time system services
SYS$GETTIM, SYS$BINTIM, SYS$ASCTIM, and SYS$NUMTIM.  Also provided are
functions for converting between OpenVMS binary times and unix epoch
time values.

=head2 EXPORT

None by default.  Any function or constant may be imported by name.
All functions can be imported using the tag ':routines'. All constants
can be imported using the tag ':constants'.  Routines and constants
can be imported using the tag ':all'.

=head1 OVERVIEW

VMS::Time can accept and return VMS times in various formats depending
upon the platform and how perl was built.  The routines that return
VMS time values accept a return mode argument that determines the
format for the returned value.  Constants are defined for the return
modes as follows.

=over 4

=item PACK - Pack format (default)

Returns the time as a string containing an 8 byte OpenVMS time value.

=item LONGINT - Integer

Returns the time value as an integer.  This is only supported if perl
was built with support for long integers.

=item FLOAT - Floating point

Returns the time value as a floating point number.  Precision may be
lost especially if perl was not built with support for long doubles.
FLOAT is not supported on VAX systems.

=item HEX - Hex string

Returns the time value as a hex encoded string with a leading '0x'.

=item BIGINT - Math::BigInt

Returns the time value as a Math::BigInt object.  Math::BigInt must
have been previously loaded.

=back

The format for input VMS time values is deduced from the attributes of
the perl variable passed to the function.  If the variable contains an
integer, LONGINT format is assumed.  If the variable containes a
floating point value, FLOAT format is assumed.  If the variable is a
string with a leading '0x', HEX format is assumed.  If the variable is
an 8 byte string, PACK format is assumed.  If the variable is a
Math::BigInt object, BIGINT format is assumed.

=head2 FUNCTIONS

bintim - convert ascii time string to binary

    $bin = bintim('01-jan-2010 12:00:00.00'[,$retmode]);

Converts the time string to a VMS time value.  $retmode indicates the
format for the returned value as described in the overview section.

asctim - convert binary time to ascii string

    $text = asctim([$bin])

Converts an OpenVMS time to its textual presentation.  If a binary
time is not provided, the current time is used.

gettim - get current time as binary

    $bin = gettim([$retmode]);

Returns the current time.  $retmode specifies the format of the
returned value as described in the overview section.

numtim - get current time as array or convert binary time to array

    @a = numtim();	    # current time
    @a = numtim($bin);	    # supplied time value

Returns an array of numeric values representing the current time.  The
values are returned in the order year, month, day, hour, minute,
second, hundredth of seconds.

If no binary time value is provided the current time is used.

epoch_to_vms - convert unix epoch time value to vms time

    $bin = epoch_to_vms($tm);

Converts the provided unix time value to OpenVMS binary time format.

vms_to_epoch - convert vms time to unix epoch time value

    $tm = vms_to_epoch($bin);

Converts an 8 byte OpenVMS binary time to a unix time value.

=head1 SEE ALSO

See the OpenVMS System Services Reference Manual for descriptions of
the referenced system services.

=head1 AUTHOR

Thomas Pfau, E<lt>tfpfau@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

VMS::Time is Copyright (C) 2013 by Thomas Pfau

This module is free software.  You can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

This module is distributed in the hope that it will be useful but it
is provided "as is"and without any express or implied warranties.

=cut
