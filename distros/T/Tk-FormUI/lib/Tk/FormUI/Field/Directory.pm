package Tk::FormUI::Field::Directory;
##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##****************************************************************************
##****************************************************************************
## NOTES:
##  * Before comitting this file to the repository, ensure Perl Critic can be
##    invoked at the HARSH [3] level with no errors
## 2015-09-29 PDurden 
##  * The -mustexist option causes the chooseDirectory dialog to not work 
##    properly in Ubuntu 14.04. Filed RT issue 107416 about the issue
## 
##****************************************************************************

=head1 NAME

Tk::FormUI::Field::Directory - FormUI Directory selection field that should
only be used by Tk::FormUI and not directly by the user;

=head1 VERSION

Version 1.05

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

our $VERSION = qq{1.05};

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
##****************************************************************************

=head2 browse_label

=over 2

Label for the browse button

DEFAULT: "Browse"

=back

=cut

##----------------------------------------------------------------------------
has browse_label => (
  is => qq{rw},
  default => qq{Browse},
);

##****************************************************************************
## "Private" attributes
##****************************************************************************
has _entry_widget => (
  is => qq{rw},
  predicate => 1,
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

  return unless ($self->_has_entry_widget);
  
  my $data = $self->_entry_widget->get;
  
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

  ## Create Frame
  $self->_set_widget($parent->Frame);
  
  ## Create and place the Entry widget
  $self->_entry_widget(
    $self->widget->Entry(
      -font  => $self->font,
      -width => $self->width,
      -text  => $self->default // qq{},
    )
  )->grid(
    -row        => 0,
    -rowspan    => 1,
    -column     => 0,
    -columnspan => 1,
    -sticky     => qq{e},
    );
  
  if ($self->browse_label)
  {
    $self->_entry_widget->grid(
      -row        => 0,
      -rowspan    => 1,
      -column     => 0,
      -columnspan => 1,
      -sticky     => qq{e},
      );
    
    $self->widget->Frame(-width => 3,)->grid(
      -row        => 0,
      -rowspan    => 1,
      -column     => 1,
      -columnspan => 1,
      -sticky     => qq{e},
      );
    
    ## Create and place the Button
    $self->widget->Button(
      -font    => $self->font,
      -text    => $self->browse_label,
      -width   => 2 + length($self->browse_label),
      -command => [sub { my $self = shift; $self->_browse;}, $self],
      )->grid(
      -row        => 0,
      -rowspan    => 1,
      -column     => 2,
      -columnspan => 1,
      -sticky     => qq{e},
      );
  }
    
  ## Return the widget  
  return($self->widget);
}

##----------------------------------------------------------------------------
##     @fn _browse()
##  @brief Create a Tk::chooseDirectory dialog
##  @param NONE
## @return NONE
##   @note 
##----------------------------------------------------------------------------
sub _browse
{
  my $self = shift;
  
  my $initial_dir = $self->_entry_widget->get // qq{};
  
  my $selected = $self->widget->chooseDirectory(
    -initialdir => $initial_dir,
    -title      => $self->label,
##    -mustexist  => 0,
    );
  
  if ($selected)
  {
    ## Delete current text in Entry widget
    $self->_entry_widget->delete(0, 'end');
    ## Add selected directory to text in Entry widget
    $self->_entry_widget->insert('end', $selected);
  }
  
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

