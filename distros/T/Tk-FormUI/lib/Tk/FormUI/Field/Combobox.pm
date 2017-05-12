package Tk::FormUI::Field::Combobox;
##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##****************************************************************************
##****************************************************************************
## NOTES:
##  * Before comitting this file to the repository, ensure Perl Critic can be
##    invoked at the HARSH [3] level with no errors
##****************************************************************************

=head1 NAME

Tk::FormUI::Field::Combobox - FormUI Entry field that should only be used
by Tk::FormUI and not directly by the user;

=head1 VERSION

Version 0.2

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
use Tk::BrowseEntry;

##--------------------------------------------------------

our $VERSION = qq{0.2};

## The role for all Fields
with (qq{Tk::FormUI::Field});
with (qq{Tk::FormUI::Choices});

##****************************************************************************
## Object Attributes
##****************************************************************************

=head1 ATTRIBUTES

No additional attributes.

=cut

##****************************************************************************
## Object Methods
##****************************************************************************

=head1 METHODS

=cut

=for Pod::Coverage BUILD
  This causes Test::Pod::Coverage to ignore the list of subs 
=cut
##----------------------------------------------------------------------------
##     @fn BUILD()
##  @brief Moo calls BUILD after the constructor is complete
## @return 
##   @note 
##----------------------------------------------------------------------------
sub BUILD
{
  my $self = shift;

  ## Create refernce to an anonymous scalar
  $self->_selected(\my $selected);
  
  ## Validate the choices
  unless ($self->valid_choices)
  {
    confess(qq{Not all choices contained a label and value key!});
  }
   
  return($self);
}

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
  my $selected = ${$self->_selected};
  if (defined($selected))
  {
    foreach my $choice (@{$self->choices})
    {
      return($choice->{value}) if ($selected eq $choice->{label});
    }
  }
  return;
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
  my $widget = $parent->BrowseEntry(
    -font            => $self->font,
    -variable        => $self->_selected,
    -listheight      => 5,
    -autolimitheight => 1,
    -autolistwidth   => 1,
  );

  ## Iterate trhough the choices
  foreach my $choice (@{$self->choices})
  {
    ## Add the entry
    $widget->insert(qq{end}, $choice->{label});
    
    ## See if this is the default entry
    if (defined($self->default) && ($choice->{value} eq $self->default))
    {
      ## Set the item as selected
      ${$self->_selected} = $choice->{label};
    }
  }
  
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

