package Tk::FormUI::Choices;
##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##****************************************************************************
##****************************************************************************
## NOTES:
##  * Before comitting this file to the repository, ensure Perl Critic can be
##    invoked at the HARSH [3] level with no errors
##****************************************************************************

=head1 NAME

Tk::FormUI::Choices - A role common to all form fields with choices

=head1 VERSION

Version 0.2

=head1 SYNOPSIS


=cut

##****************************************************************************
##****************************************************************************
use Moo::Role;
## Moo enables strictures
## no critic (TestingAndDebugging::RequireUseStrict)
## no critic (TestingAndDebugging::RequireUseWarnings)
use Readonly;
use Carp qw(confess);

## Version string
our $VERSION = qq{0.2};


##****************************************************************************
## Object attribute
##****************************************************************************

=head1 ATTRIBUTES

=cut

##****************************************************************************
##****************************************************************************

=head2 choices

=over 2

Array of hash references representing the possible choices.
The hash should have the following keys defined:
  label - Text to be displayed
  value - Value to return if item is selected

=back

=cut

##----------------------------------------------------------------------------
has choices => (
  is       => qq{rwp},
  required => 1,
);

##****************************************************************************
##****************************************************************************

=head2 max_per_line

=over 2

The maximum number of choices displayed per line

DEFAULT: 3

=back

=cut

##----------------------------------------------------------------------------
has max_per_line => (
  is      => qq{rw},
  default => 3,
);

##****************************************************************************
## "Private" attributes
##****************************************************************************
## Currently selected choice(s)
has _selected => (
  is => qq{rw},
);

## Row for the current choice
has _row => (
  is      => qq{rw},
  default => 0,
);

## Column for the current choice
has _col => (
  is      => qq{rw},
  default => 0,
);

##****************************************************************************
## Object Methods
##****************************************************************************

=head1 METHODS

=cut

##****************************************************************************
##****************************************************************************

=head2 valid_choices()

=over 2

=item B<Description>

Verifies that all choices contain a label and value key

=item B<Parameters>

NONE

=item B<Return>

NONE

=back

=cut

##----------------------------------------------------------------------------
sub valid_choices
{
  my $self = shift;
  
  foreach my $choice (@{$self->choices})
  {
    unless (exists($choice->{label}) && exists($choice->{value}))
    {
      confess(qq{Choice is missing label or value key});
    }
  }
  return(1);
}

##****************************************************************************
##****************************************************************************

=head2 next_row_column($row, $col)

=over 2

=item B<Description>

Increment the column and row if needed based on the field's settings

=item B<Parameters>

$row - The current row
$col - The current column

=item B<Return>

ARRAY consisting of the new row and column

=back

=cut

##----------------------------------------------------------------------------
sub next_row_column
{
  my $self = shift;
  my $col  = $self->_col;
  
  ## Increment row / col
  $col++;
  if ($col >= $self->max_per_line)
  {
    $self->_row($self->_row + 1);
    $col = 0;
  }
  $self->_col($col);

  return;
  
}

##****************************************************************************
##****************************************************************************

=head2 reset_row_column()

=over 2

=item B<Description>

Reset the row and column to 0

=item B<Parameters>

NONE

=item B<Return>

NONE

=back

=cut

##----------------------------------------------------------------------------
sub reset_row_column
{
  my $self = shift;
  
  $self->_row(0);
  $self->_col(0);
  
  return;
}


##****************************************************************************
## Additional POD documentation
##****************************************************************************

=head1 AUTHOR

Paul Durden E<lt>alabamapaul AT gmail.comE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2015 by Paul Durden.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    ## End of module
__END__

