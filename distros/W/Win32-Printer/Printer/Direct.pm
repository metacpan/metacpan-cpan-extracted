#------------------------------------------------------------------------------#
# Win32::Printer::Direct                                                       #
# V 0.0.2 (2008-04-28)                                                         #
# Copyright (C) 2005 Edgars Binans                                             #
#------------------------------------------------------------------------------#

package Win32::Printer::Direct;

use 5.006;
use strict;
use warnings;

use Carp;

require Exporter;

use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD );

$VERSION = '0.0.2';

@ISA = qw( Exporter );

@EXPORT = qw( Printfile );

@EXPORT_OK = qw( );

use Win32::Printer;

#------------------------------------------------------------------------------#

sub AUTOLOAD {

  my $constname = $AUTOLOAD;
  $constname =~ s/.*:://;

  croak "Unknown Win32::Printer::Direct macro $constname.\n";

}

#------------------------------------------------------------------------------#

sub Printfile {

  if ($#_ != 1) { croak "ERROR: Wrong number of parameters!\n"; }

  my $printer = shift;
  my $filename = shift;

  return Win32::Printer::_Printfile($printer, $filename);

}

#------------------------------------------------------------------------------#

1;

__END__

=head1 NAME

Win32::Printer::Direct - Perl extension for direct Win32 printing

=head1 SYNOPSIS

  use Win32::Printer::Direct;

  Printfile("HP LaserJet 8150", "test.prn");

=head1 ABSTRACT

Win32 direct printing

=head1 INSTALLATION

See L<Win32::Printer>! This module depends on it.

=head2 Printfile

  Printfile($printer_name, $file_name);

B<$printer_name> is printer's friendly name and B<$file_name> is name of the file to print.

Return value is error code:

   1	Success
  -1	Memory allocation error
  -2	Error opening the file
  -3	Error opening the printer
  -4	Error startint the print job
  -5	Error writing to printer
  -6	Error ending the print job
  -7	Error closing printer

=head1 DESCRIPTION

=head1 SEE ALSO

L<Win32::Printer>, Win32 Platform SDK GDI documentation.

=head1 AUTHOR

B<Edgars Binans>

=head1 COPYRIGHT AND LICENSE

B<Win32::Printer, Copyright (C) 2005 Edgars Binans.>

B<THIS LIBRARY IS LICENSED UNDER THE TERMS OF GNU LESSER GENERAL PUBLIC LICENSE
V2.1>

=cut
