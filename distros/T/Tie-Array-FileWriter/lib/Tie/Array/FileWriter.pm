package Tie::Array::FileWriter;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.1';

use FileHandle;
use Carp;


#
# TIEARRAY()
#

sub TIEARRAY
{
  my ($class, $file, $fdelim, $rdelim) = @_;

  $fdelim = "|"  unless defined $fdelim;
  $rdelim = "\n" unless defined $rdelim;

  my $fh;
  my $close_it;

  if (ref $file eq 'FileHandle') {
    croak "FileHandle is not open for writing!"
      unless $fh->opened;

    $fh       = $file;
    $close_it = 0;
  } else {
    $fh       = FileHandle->new(">$file");

    croak "Unable to open file '$file' for writing: $!"
      unless defined $fh;

    $close_it = 1;
  }

  return bless {
    FH       => $fh,
    CLOSE_IT => $close_it,
    FDELIM   => $fdelim,
    RDELIM   => $rdelim
  }, $class;
}


#
# PUSH()
#

sub PUSH
{
  my $self   = shift;
  my $fh     = $self->{FH};
  my $fdelim = $self->{FDELIM};
  my $rdelim = $self->{RDELIM};
  
  foreach my $elem (@_) {
    next unless defined $elem;
    next unless ref $elem eq 'ARRAY';
    print($fh join($fdelim, @$elem), $rdelim);
  }
}


#
# UNTIE():
#

sub UNTIE
{
  my $self = shift;
  $self->{FH}->close;
}


#
# FETCHSIZE()
#
# Pushing elements calls FETCHSIZE().
#

sub FETCHSIZE
{
  return 0;
}


#
# UNIMPLEMENTED FUNCTIONS:
#

sub CLEAR     { my $self = shift; croak("No CLEAR in "     . ref $self) }
sub DELETE    { my $self = shift; croak("No DELETE in "    . ref $self) }
sub EXISTS    { my $self = shift; croak("No EXISTS in "    . ref $self) }
sub EXTEND    { my $self = shift; croak("No EXTEND in "    . ref $self) }
sub FETCH     { my $self = shift; croak("No FETCH in "     . ref $self) }
sub POP       { my $self = shift; croak("No POP in "       . ref $self) }
sub SPLICE    { my $self = shift; croak("No SPLICE in "    . ref $self) }
sub SHIFT     { my $self = shift; croak("No SHIFT in "     . ref $self) }
sub STORE     { my $self = shift; croak("No STORE in "     . ref $self) }
sub STORESIZE { my $self = shift; croak("No STORESIZE in " . ref $self) unless shift == 0 }
sub UNSHIFT   { my $self = shift; croak("No UNSHIFT in "   . ref $self) }

1;
__END__

=head1 NAME

Tie::Array::FileWriter - A Perl module for writing records to files as items are pushed onto a virtual array

=head1 SYNOPSIS

  use Tie::Array::FileWriter;
  my @output;
  tie @output, 'file.dat', ',', "\n"; # Write to file 'file.dat', use comma as field delimiter
  push @output, [ qw(a b c d) ];
  push @output, [ qw(e f g h) ];
  untie @output;

=head1 DESCRIPTION

This is a write-only array that can only be written via B<push>. It ignores anything pushed onto it that
is not an array reference. Elements of array references are joined by the field delimiter and written to the
output file, followed by the record delimiter.

You can write fixed-length records by ensuring the fields that are passed in are preformatted to thier
desired fixed lengths and setting the field and record delimiters to empty strings.

The default field delimiter is the vertical bar ('|', also known as 'pipe'), and  
the default record delimiter is newline ("\n").

You can pass in either an already opened FileHandle object, or a file name. If you pass in a FileHandle
object, the file will not be closed by Tie::Array::FileWriter.

=head1 AUTHOR

Gregor N. Purdy E<lt>gregor@focusresearch.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2001 Gregor N. Purdy. All rights reserved.

=head1 LICENSE

This program is free software. It is subject to the same license as Perl itself.

=cut
