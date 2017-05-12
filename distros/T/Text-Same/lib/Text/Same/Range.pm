=head1 NAME

Text::Same::Range

=head1 DESCRIPTION

A class representing a range of integers

=head1 SYNOPSIS

 my $range = new Text::Same::Range($start, $end);

=head1 METHODS

See below.  Methods private to this module are prefixed by an
underscore.

=cut

package Text::Same::Range;

use warnings;
use strict;
use Carp;

use vars qw($VERSION);
$VERSION = '0.07';

=head2 new

 Title   : new
 Usage   : $range = new Text::Same::Range($start, $end)
 Function: Creates a new Range object with the given start and end
 Returns : A Text::Same::Range object

=cut

sub new
{
  my $self  = shift;
  my $class = ref($self) || $self;

  if (scalar(@_) != 2) {
    die "Range constructor needs 2 arguments\n";
  }

  if (!defined $_[0] || !defined $_[1]) {
    croak "undefined value passed to Range->new\n";
  }

  return bless [@_], $class;
}

=head2 start

 Title   : start
 Usage   : $start = $range->start
 Function: Returns the start position that was passed to new()

=cut

sub start
{
  my $self = shift;
  return $self->[0];
}

=head2 end

 Title   : end
 Usage   : $end = $range->end
 Function: Returns the end position that was passed to new()

=cut

sub end
{
  my $self = shift;
  return $self->[1];
}

=head2 as_string

 Title   : as_string
 Usage   : my $str = $range->as_string
 Function: return a string representation of this Range
 Args    : none

=cut

sub as_string
{
  my $self = shift;
  return $self->[0] . ".." . $self->[1];
}

=head1 AUTHOR

Kim Rutherford <kmr+same@xenu.org.uk>

=head1 COPYRIGHT & LICENSE

Copyright 2005,2006 Kim Rutherford.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER

This module is provided "as is" without warranty of any kind. It
may redistributed under the same conditions as Perl itself.

=cut

1;
