package Tk::FormUI::Field::Radiobutton;
##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##****************************************************************************
##****************************************************************************
## NOTES:
##  * Before comitting this file to the repository, ensure Perl Critic can be
##    invoked at the HARSH [3] level with no errors
##****************************************************************************

=head1 NAME

Tk::FormUI::Field::Radiobutton - FormUI Entry field that should only be used
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

##--------------------------------------------------------

our $VERSION = qq{0.2};

## The role for all Fields
with qq{Tk::FormUI::Field}, qq{Tk::FormUI::Choices};

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
  
  return(${$self->_selected});
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

  ## initialize the selected variable 
  ${$self->_selected} = $self->default if (defined($self->default));

  ## Create the frame to hold the buttons
  my $frame = $parent->Frame;
  
  my $idx = 0;
  $self->reset_row_column;
  foreach my $choice (@{$self->choices})
  {
    ## Build the button
    my $widget = $frame->Radiobutton(
      -font     =>  $self->font,
      -text     =>  $choice->{label},
      -value    =>  $choice->{value},
      -variable =>  $self->_selected,
    )
    ->grid(
      -column => $self->_col,
      -row    => $self->_row,
      -sticky => qq{w},
    );
    
    ## Increment row / col
    $self->next_row_column;
    
    ## See if widget should be selected
    if (defined($self->default) && ($self->default eq $choice->{value}))
    {
      $widget->select;
    }
    
    ## Increment our counter
    $idx++;
  }
  
  ## Set our widget
  $self->_set_widget($frame);
  
  return($frame);
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

