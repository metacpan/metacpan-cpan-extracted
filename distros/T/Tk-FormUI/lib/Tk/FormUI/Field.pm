package Tk::FormUI::Field;
##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##****************************************************************************
##****************************************************************************
## NOTES:
##  * Before comitting this file to the repository, ensure Perl Critic can be
##    invoked at the HARSH [3] level with no errors
##****************************************************************************

=head1 NAME

Tk::FormUI::Field - A role common to all form fields

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

=over 2

=item B<key>

  The hash key used when returning data from this field

=back

=cut

##----------------------------------------------------------------------------
has key => (
  is => qq{rw},
  required => 1,
);

##****************************************************************************
##****************************************************************************

=over 2

=item B<label>

  The label displayed for the field in the dialog

=back

=cut

##----------------------------------------------------------------------------
has label => (
  is => qq{rw},
  required => 1,
);

##****************************************************************************
##****************************************************************************

=over 2

=item B<type>

  The type of field

=back

=cut

##----------------------------------------------------------------------------
has type => (
  is => qq{rw},
  required => 1,
);

##****************************************************************************
##****************************************************************************

=over 2

=item B<default>

  The default or initial value of the field

=back

=cut

##----------------------------------------------------------------------------
has default => (
  is => qq{rw},
);

##****************************************************************************
##****************************************************************************

=over 2

=item B<widget>

  The Tk widget associated with this field

=back

=cut

##----------------------------------------------------------------------------
has widget => (
  is => qq{rwp},
);

##****************************************************************************
##****************************************************************************

=over 2

=item B<label_font>

  The font to use for the field's label
  DEFAULT: 'times 12 bold'

=back

=cut

##----------------------------------------------------------------------------
has label_font => (
  is => qq{rw},
  default => qq{times 12 bold},
);

##****************************************************************************
##****************************************************************************

=over 2

=item B<font>

  The font to use for the field's widget
  DEFAULT: 'times 12 bold'

=back

=cut

##----------------------------------------------------------------------------
has font => (
  is => qq{rw},
  default => qq{times 12},
);
##****************************************************************************
##****************************************************************************

=over 2

=item B<readonly>

  Indicates if the field is read only
  DEFAULT: 0

=back

=cut

##----------------------------------------------------------------------------
has readonly => (
  is => qq{rw},
  default => 0,
);

##****************************************************************************
##****************************************************************************

=over 2

=item B<width>

  The width of the field
  DEFAULT: 40

=back

=cut

##----------------------------------------------------------------------------
has width => (
  is => qq{rw},
  required => 1,
  default => 40,
);

##****************************************************************************
##****************************************************************************

=over 2

=item B<error>

  Error string associated with the field
  DEFAULT: ''

=back

=cut

##----------------------------------------------------------------------------
has error => (
  is => qq{rw},
  default => qq{},
);

##****************************************************************************
##****************************************************************************

=over 2

=item B<validation>

  Optional code reference of function to call to verify the field data
  is valid.
  The field object will be passed as the only parameter to the function.
  The function should return the empty string if there is no error, or
  provide an error string if the data is not valid.

=back

=cut

##----------------------------------------------------------------------------
has validation => (
  is => qq{rw},
);

##****************************************************************************
## Object Methods
##****************************************************************************

=head1 METHODS

=cut

##****************************************************************************
##****************************************************************************

=head2 is_type($type)

=over 2

=item B<Description>

Returns 1 if the field is the specified type

=item B<Parameters>

BOOLEAN indicating if the field is the specified type

=item B<Return>

1 if the field is the specified type otherwise 0

=back

=cut

##----------------------------------------------------------------------------
sub is_type
{
  my $self = shift;
  my $type = shift;
  
  return ((uc($self->type) eq uc($type)) ? 1 : 0);
}

##****************************************************************************
##****************************************************************************

=head2 build_label($parent)

=over 2

=item B<Description>

Build the label widget for the field

=item B<Parameters>

$parent - Parent widget

=item B<Return>

widget object

=back

=cut

##----------------------------------------------------------------------------
sub build_label
{
  my $self   = shift;
  my $parent = shift;

  ## Create the label
  my $label = $parent->Label(
    -text   => $self->label . qq{: },
    -font   => $self->label_font,
    -anchor => qq{e},
  );
  
  return($label);
}

##****************************************************************************
##****************************************************************************

=head2 build_widget($parent)

=over 2

=item B<Description>

Build the widget associated with this field.
NOTE: This method should be overridden in the class for the field!

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
  
  ## Set our widget
  $self->_set_widget(undef);

  return;
}

##****************************************************************************
##****************************************************************************

=head2 validate()

=over 2

=item B<Description>

Validate the field data

=item B<Parameters>

NONE

=item B<Return>



=back

=cut

##----------------------------------------------------------------------------
sub validate
{
  my $self = shift;
  
  ## Get the validation attribute
  my $function = $self->validation;
  
  ## See if the validation attribute is a code reference
  if (ref($function) eq qq{CODE})
  {
    ## Call the function
    if (my $error = $function->($self))
    {
      ## Set the field's error message
      $self->error($error);
    }
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

