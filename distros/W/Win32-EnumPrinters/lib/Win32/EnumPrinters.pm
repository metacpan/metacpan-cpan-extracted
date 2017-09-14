package Win32::EnumPrinters;

our $VERSION = '0.01';

use 5.010;
use strict;
use warnings;

use Win32::EnumPrinters::Constants;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS; # Win32::EnumPrinters::Constants initializes this!
$EXPORT_TAGS{subs} = [qw( EnumPrinters EnumForms GetDefaultPrinter)];

my %all;
@all{@$_} = @$_ for values %EXPORT_TAGS;
our @EXPORT_OK = keys %all;
$EXPORT_TAGS{all} = \@EXPORT_OK;

require XSLoader;
XSLoader::load('Win32::EnumPrinters', $VERSION);

1;
__END__

=head1 NAME

Win32::EnumPrinters - Enumerate printers in Windows.

=head1 SYNOPSIS

  use Win32::EnumPrinters qw(EnumPrinters);

  my @printers = EnumPrinters();

=head1 DESCRIPTION

This module wraps Win32 C<EnumPrinters> and some related functions.

Output C data structures are converted to Perl hashes. The names used
for their slots are as in C but with any type declaration or structure
name prefixes (i.e C<p> for pointer, C<dw> for C<DWORD>, C<dm> for
C<DEVMODE>, etc.) removed.

=head2 CONSTANTS

Any constant accepted by the supported functions in input parameters
or included in output data can be imported by the module. For
instance:

  use Win32::EnumPrinters qw(PRINTER_ATTRIBUTE_RAW_ONLY);

The constants have both an integer and a string value (in a similar
fashion to C<$!>). The string value is the C constant name lower-cased
and with any common prefix removed. For instance,
C<PRINTER_ATTRIBUTE_QUEUED> is both C<queued> and C<1>.

Enumeration values returned from the supported functions follow the
same rule.

The following tags can also be used at import time to pick sets of
constants:

    attribute => PRINTER_ATTRIBUTE_*
    dmbin => DMBIN_*
    dmcollate => DMCOLLATE_*
    dmcolor => DMCOLOR_*
    dmdfo => DMDFO_*
    dmdisplayflags => DM_*
    dmdither => DMDITHER_*
    dmdo => DMDO_*
    dmdup => DMDUP_*
    dmfield => DM_*
    dmicm => DMICM_*
    dmicmethod => DMICMMETHOD_*
    dmmedia => DMMEDIA_*
    dmnup => DMNUP_*
    dmpaper => DMPAPER_*
    dmres => DMRES_*
    dmtt => DMTT_*
    enum => PRINTER_ENUM_*
    formflag => FORM_*
    status => PRINTER_STATUS_*
    stringtype => STRING_*

=head2 FUNCTIONS

The following functions can be imported from the module:

=over 4

=item @printers = EnumPrinters($flags, $name, $level)

See L<EnumPrinters|https://msdn.microsoft.com/en-us/library/windows/desktop/dd162692(v=vs.85).aspx>.

=item $name = GetDefaultPrinter()

See L<GetDefaultPrinter|https://msdn.microsoft.com/en-us/library/windows/desktop/dd144876(v=vs.85).aspx>.

=item @forms = EnumForms($printer_name, $level)

See L<EnumForms|https://msdn.microsoft.com/en-us/library/windows/desktop/dd162624(v=vs.85).aspx>.

=back

=head1 SEE ALSO

L<Win32::Printer> and L<Win32::Printer::Enum> provide similar
functionality, but they are not thin wrappers around the C/C++
functions.

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Qindel FormaciE<oacute>n y Servicios SL

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
