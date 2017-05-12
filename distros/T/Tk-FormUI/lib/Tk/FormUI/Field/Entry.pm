package Tk::FormUI::Field::Entry;
##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##****************************************************************************
##****************************************************************************
## NOTES:
##  * Before comitting this file to the repository, ensure Perl Critic can be
##    invoked at the HARSH [3] level with no errors
##****************************************************************************

=head1 NAME

Tk::FormUI::Field::Entry - FormUI Entry field that should only be used
by Tk::FormUI and not directly by the user;

=head1 VERSION

Version 0.3

=head1 SYNOPSIS

  use Tk::FormUI;

=cut

##****************************************************************************
##****************************************************************************
use Moo;
## Moo enables strictures
## no critic (TestingAndDebugging::RequireUseStrict)
## no critic (TestingAndDebugging::RequireUseWarnings)
use Readonly;

##--------------------------------------------------------

our $VERSION = qq{0.3};

## The role for all Fields
with (qq{Tk::FormUI::Field});

##****************************************************************************
## Object Attributes
##****************************************************************************

=head1 ATTRIBUTES

=cut

##****************************************************************************
##****************************************************************************

=head2 trim_leading

=over 2

If true, trim leading whitespace characters before returning the value

DEFAULT: 1

=back

=cut

##----------------------------------------------------------------------------
has trim_leading => (
  is => qq{rw},
  default => 1,
);

##****************************************************************************
##****************************************************************************

=head2 trim_trailing

=over 2

If true, trim trailing whitespace characters before returning the value

DEFAULT: 1

=back

=cut

##----------------------------------------------------------------------------
has trim_trailing => (
  is => qq{rw},
  default => 1,
);

##****************************************************************************
## Object Methods
##****************************************************************************

=head1 METHODS

=cut

##****************************************************************************
##****************************************************************************

=head2 value()

=over 2

=item B<Description>

Return the current value of the field

=item B<Parameters>

NONE

=item B<Return>

NONE

=back

=cut

##----------------------------------------------------------------------------
sub value
{
  my $self = shift;
  my $data = $self->widget->get;
  
  ## See if we have any data
  if (defined($data))
  {
    $data =~ s/^\s+//g if ($self->trim_leading);  ## Remove leading spaces
    $data =~ s/\s+$//g if ($self->trim_trailing); ## Remove trailing spaces
  }
  return($data);
}

##****************************************************************************
##****************************************************************************

=head2 build_widget($parent)

=over 2

=item B<Description>

Build the widget associated with this field

=item B<Parameters>

$parent - Parent widget for this widget

=item B<Return>

Widget object

=back

=cut

##----------------------------------------------------------------------------
sub build_widget
{
  my $self   = shift;
  my $parent = shift;

  ## Create the widget
  my $widget = $parent->Entry(
    -font  => $self->font,
    -width => $self->width,
    -text  => $self->default // qq{},
  );
  
  ## Set our widget
  $self->_set_widget($widget);
  
  return($widget);
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

