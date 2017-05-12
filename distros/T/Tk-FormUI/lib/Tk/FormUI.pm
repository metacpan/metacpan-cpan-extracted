package Tk::FormUI;
##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##****************************************************************************
## NOTES:
##  * Before comitting this file to the repository, ensure Perl Critic can be
##    invoked at the HARSH [3] level with no errors
##****************************************************************************

=head1 NAME

Tk::FormUI - A  Moo based object oriented interface for creating forms for
use with Tk

=head1 VERSION

Version 1.07

=head1 SYNOPSIS

  use Tk::FormUI;

  my $form = Tk::FormUI->new;

  ## Add an Entry field for text
  $form->add_field(
    key     => 'user_name',
    label   => 'User name',
    type    => $Tk::FormUI::ENTRY,
    width   => 40,
    default => 'John Doe',
  );

  ## Add a Radio Button field
  $form->add_field(
    key   => 'gender',
    label => 'Gender',
    type  => $Tk::FormUI::RADIOBUTTON,
    choices => [
      {
        label => 'Male',
        value => 'male',
      },
      {
        label => 'Female',
        value => 'female',
      },
    ],
  );
  
  ## Display the form and capture the data returned
  my $data = $form->show;

=cut

##****************************************************************************
##****************************************************************************
use Moo;
## Moo enables strictures
## no critic (TestingAndDebugging::RequireUseStrict)
## no critic (TestingAndDebugging::RequireUseWarnings)
use Readonly;
use Carp qw(confess cluck);
use Tk;
use Tk::FormUI::Field::Entry;
use Tk::FormUI::Field::Radiobutton;
use Tk::FormUI::Field::Checkbox;
use Tk::FormUI::Field::Combobox;
use Tk::FormUI::Field::Directory;
use Data::Dumper;
use JSON;
use Try::Tiny;

## Version string
our $VERSION = qq{1.07};

Readonly::Scalar our $READONLY    => 1;

## Used when importing a form, these are "simple" non-array attributes
Readonly::Array my @SIMPLE_ATTRIBUTES => (
  qw(title message message_font button_label button_font min_width min_height)
);

##****************************************************************************
## Various Types
##****************************************************************************

=head1 TYPES

The Tk::FormUI recognizes the following values for the "type" key when
adding or defing a field.

=cut

##****************************************************************************
##****************************************************************************


=head2 Entry

=over 2

A Tk::Entry widget

CONSTANT: $Tk::FormUI::ENTRY

=back 

=cut

##----------------------------------------------------------------------------
Readonly::Scalar our $ENTRY => qq{Entry};

##****************************************************************************
##****************************************************************************

=head2 Checkbox

=over 2

A group of Tk::CheckButton widgets that correspond to the choices

CONSTANT: $Tk::FormUI::CHECKBOX

=back

=cut

##----------------------------------------------------------------------------
Readonly::Scalar our $CHECKBOX => qq{Checkbox};

##****************************************************************************
##****************************************************************************

=head2 RadioButton

=over 2

A group of Tk::RadioButton widgets that correspond to the choices

CONSTANT: $Tk::FormUI::RADIOBUTTON

=back

=cut

##----------------------------------------------------------------------------
Readonly::Scalar our $RADIOBUTTON => qq{RadioButton};

##****************************************************************************
##****************************************************************************

=head2 Combobox

=over 2

A Tk::BrowserEntry widget with a drop-down list that correspond to the choices

CONSTANT: $Tk::FormUI::COMBOBOX

=back

=cut

##----------------------------------------------------------------------------
Readonly::Scalar our $COMBOBOX => qq{Combobox};

##****************************************************************************
##****************************************************************************


=head2 Directory

=over 2

A Tk::Entry widget with a button that will open a Tk::chooseDirectory window

CONSTANT: $Tk::FormUI::DIRECTORY

=back 

=cut

##----------------------------------------------------------------------------
Readonly::Scalar our $DIRECTORY => qq{Directory};

Readonly::Array my @KNOWN_FIELD_TYPES => (
  $ENTRY, $CHECKBOX, $RADIOBUTTON, $COMBOBOX, $DIRECTORY,
);

##****************************************************************************
## Object attribute
##****************************************************************************

=head1 ATTRIBUTES

=cut

##****************************************************************************
##****************************************************************************

=head2 title

=over 2

Title of the form.

DEFAULT: 'Form'

=back

=cut

##----------------------------------------------------------------------------
has title => (
  is      => qq{rw},
  default => qq{Form},
);

##****************************************************************************
##****************************************************************************

=head2 B<message>

=over 2

Message to display at the top of the form.

DEFAULT: ''

=back

=cut

##----------------------------------------------------------------------------
has message => (
  is      => qq{rw},
  default => qq{},
);

##****************************************************************************
##****************************************************************************

=head2 message_font

=over 2

Font to use for the form's message

DEFAULT: 'times 12 bold'

=back

=cut

##----------------------------------------------------------------------------
has message_font => (
  is      => qq{rw},
  default => qq{times 12 bold},
);

##****************************************************************************
##****************************************************************************

=head2 fields

=over 2

The fields contained in this form.

=back

=cut

##----------------------------------------------------------------------------
has fields => (
  is => qq{rwp},
);

##****************************************************************************
##****************************************************************************

=head2 button_label

=over 2

The text to appear on the button at the bottom of the form.

You may place the ampersand before the character you want to use as
a "hot key" indicating holding the Alt key and the specified character
will do the same thing as pressing the button.

DEAULT: '&OK'

=back

=cut

##----------------------------------------------------------------------------
has button_label => (
  is => qq{rw},
  default => qq{&OK},
);

##****************************************************************************

=head2 button_font

=over 2

Font to use for the form's button.

DEFAULT: 'times 10'

=back

=cut

##----------------------------------------------------------------------------
has button_font => (
  is => qq{rw},
  default => qq{times 10},
);

##****************************************************************************

=head2 min_width

=over 2

Minimum width of the form window.

DEFAULT: 300

=back

=cut

##----------------------------------------------------------------------------
has min_width => (
  is => qq{rw},
  default => 300,
);

##****************************************************************************

=head2 min_height

=over 2

Minimum height of the form window.

DEFAULT: 80

=back

=cut

##----------------------------------------------------------------------------
has min_height => (
  is => qq{rw},
  default => 80,
);

##****************************************************************************

=head2 submit_on_enter

=over 2

Boolean value indicating if pressing the Enter key should simulate clicking
the button to submit the form.

DEFAULT: 1

=back

=cut

##----------------------------------------------------------------------------
has submit_on_enter => (
  is => qq{rw},
  default => 1,
);

##****************************************************************************

=head2 cancel_on_escape

=over 2

Boolean value indicating if pressing the Escape key should simulate closing
the window and canceling the form.

DEFAULT: 1

=back

=cut

##----------------------------------------------------------------------------
has cancel_on_escape => (
  is => qq{rw},
  default => 1,
);

##****************************************************************************
##****************************************************************************

=head2 error_font

=over 2

Font to use for the form's error messages.

DEFAULT: 'times 12 bold'

=back

=cut

##----------------------------------------------------------------------------
has error_font => (
  is      => qq{rw},
  default => qq{times 12 bold},
);

##****************************************************************************
##****************************************************************************

=head2 error_marker

=over 2

String used to indicate an error

DEFAULT: '!'

=back

=cut

##----------------------------------------------------------------------------
has error_marker => (
  is      => qq{rw},
  default => qq{!},
);

##****************************************************************************
##****************************************************************************

=head2 error_font_color

=over 2

Font color to use when displaying error message and error marker

DEFAULT: 'red'

=back

=cut

##----------------------------------------------------------------------------
has error_font_color => (
  is      => qq{rw},
  default => qq{red},
);

##****************************************************************************
## "Private" atributes
##***************************************************************************

## Holds reference to variable Tk watches for dialog completion 
has _watch_variable  => (
  is      => qq{rw},
);

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

  ## Create an empty list of fields
  $self->_set_fields([]);
  
  return($self);
}

##****************************************************************************
##****************************************************************************

=head2 add_field(...)

=over 2

=item B<Description>

Add a field to the form.

=item B<Parameters>

A list of key / value pairs should be provide

  type     - Type of field
  key      - Key to use in hash returned by the show() method
  label    - Text to display next to the field
  readonly - Boolean indicating if field is read only and cannot be
             modified
  choices  - ARRAY reference containing hashes that define the possible
             values for the field.
             REQUIRED for Checkbox, RadioButton, and Combobox
             Each hash must have the following key/value pairs
                label - String to be displayed
                value - Value to return if selected

=item B<Return>

UNDEF on error, or the field object created

=back

=cut

##----------------------------------------------------------------------------
sub add_field ## no critic (RequireArgUnpacking,ProhibitUnusedPrivateSubroutines)
{
  my $self = shift;
  my %params = (@_);

  ## Check for missing keys
  my @missing = ();
  foreach my $key (qw(type key label))
  {
    push(@missing, $key) unless(exists($params{$key}));
  }
  if (scalar(@missing))
  {
    cluck(qq{Field missing the following reuired key(s): "}, 
      join(qq{", "}, @missing),
      qq{"}
      );
  }

  ## Now see what type field this is
  foreach my $type (@KNOWN_FIELD_TYPES)
  {
    if (uc($params{type}) eq uc($type))
    {
      my $class = qq{Tk::FormUI::Field::} . ucfirst(lc($type));
      my $field = $class->new(@_);
      
      confess(qq{Could not create $class}) unless ($field);
      
      ## Save the field in the object's fields attribute
      push(@{$self->fields}, $field) if ($field);
      
      return($field);
    }
  }
  cluck(qq{Unknown field type "$params{type}"});
  return;

}

##****************************************************************************
##****************************************************************************

=head2 show($parent)

=over 2

=item B<Description>

Show the form as a child of the given parent, or as a new MainWindow if
a parent is not specified.

The function will return if the users cancels the form or submits a 
form with no errors.

=item B<Parameters>

$parent - Parent window, if none is specified, a new MainWindow will be
created

=item B<Return>

UNDEF when canceled, or a HASH reference containing whose keys correspond 
to the key attributes of the form's fields

=back

=cut

##----------------------------------------------------------------------------
sub show
{
  my $self   = shift;
  my $parent = shift;
  my $test   = shift;
  
  my $data;
  my $finished;
  while (!$finished)
  {
    ## Set the current data
    $self->set_field_data($data) if ($data);
  
    ## Show the form
    $data = $self->show_once($parent, $test);
    
    if ($data)
    {
      ## Finished only if there are no errors
      $finished = !$self->has_errors;
    }
    else
    {
      $finished = 1;
    }
  }
  
  return($data);
}

##****************************************************************************
##****************************************************************************

=head2 show_once($parent)

=over 2

=item B<Description>

Show the form as a child of the given parent, or as a new MainWindow if
a parent is not specified.

Once the user submits or cancels the form, the function will return.

=item B<Parameters>

$parent - Parent window, if none is specified, a new MainWindow will be
created

=item B<Return>

UNDEF when canceled, or a HASH reference containing whose keys correspond 
to the key attributes of the form's fields

=back

=cut

##----------------------------------------------------------------------------
sub show_once
{
  my $self   = shift;
  my $parent = shift;
  my $test   = shift;
  my $win;    ## Window widget
  my $result; ## Variable used to capture the result

  ## Create the window
  if ($parent)
  {
    ## Create as a TopLevel to the specified parent
    $win = $parent->TopLevel(-title => $self->title);
  }
  else
  {
    ## Create as a new MainWindow
    $win = MainWindow->new(-title => $self->title);
  }
  
  ## Hide the window
  $win->withdraw;
  
  ## Do not allow user to resize
  $win->resizable(0,0);

  ## Now use the grid geometry manager to layout everything
  my $grid_row = 0;
  
  ## See if we have a message
  if ($self->message)
  {
    ## Leave space for the message and a spacer
    ## but wait to create the widget
    $grid_row = 2;
  }

  my $first_field;
  ## Now add the fields
  foreach my $field (@{$self->fields})
  {
    ## See if the widget was created
    if (my $widget = $field->build_widget($win))
    {
      ## See if there's an error
      my $err = $field->error;
      if ($err)
      {
        ## Display the error message
        $win->Label(
          -text        => $err,
          -font        => $self->error_font,
          -anchor      => qq{w},
          -justify     => qq{left},
          -foreground  => $self->error_font_color,
        )
        ->grid(
          -row        => $grid_row++,
          -rowspan    => 1,
          -column     => 0,
          -columnspan => 2,
          -sticky     => qq{w},
        );
      }

      ## Create the label
      my $label = $field->build_label($win);
      
      ## See if there's an error
      if ($err)
      {
        ## Update the field's label to use the error marker, font,
        ## and font color
        $label->configure(
          -text        => $self->error_marker . qq{ } . $field->label . qq{:},
          -font        => $self->error_font,
          -foreground  => $self->error_font_color,
        );
      }
      
      ## Place the label
      $label->grid(
        -row        => $grid_row,
        -rowspan    => 1,
        -column     => 0,
        -columnspan => 1,
        -sticky     => qq{ne},
      );

      ## Place the widget
      $widget->grid(
        -row        => $grid_row,
        -rowspan    => 1,
        -column     => 1,
        -columnspan => 1,
        -sticky     => qq{w},
      );
      
      ## Increment the row index
      $grid_row++;
      
      ## See if this is our first non-readonly field
      if (!$first_field && !$field->readonly)
      {
        $first_field = $field;
      }
    }
  }
  
  ## Use an empty frame as a spacer 
  $win->Frame(-height => 5)->grid(-row => $grid_row++);
  
  ## Create the button
  my $button_text = $self->button_label;
  my $underline   = index($button_text, qq{&});
  $button_text =~ s/\&//gx; ## Remove the &
  $win->Button(
    -text      => $button_text,
    -font      => $self->button_font,
    -width     => length($button_text) + 2,
    -command   => sub {$result = 1;},
    -underline => $underline,
  )
  ->grid(
    -row        => $grid_row++,
    -rowspan    => 1,
    -column     => 0,
    -columnspan => 2,
    -sticky     => qq{},
  );
  
  ## Set the form's message
  $self->_set_message($win);
  
  $self->_watch_variable(\$result);
  
  ## Setup any keyboard bindings
  $self->_set_key_bindings($win);
  
  ## Calculate the geometry
  $self->_calc_geometry($win);

  ## Display the window
  $win->deiconify;
  
  ## Detect user closing the window
  $win->protocol('WM_DELETE_WINDOW',sub {$result = 0;});

  ## See if we are testing
  if ($test)
  {
    ## Make sure the string is the correct format
    if ($test =~ /TEST:\s+(\d)/x)
    {
      ## 0 == "CANCEL" 1 == "SUBMIT"
      $test = $1;
      
      ## Set a callback to close the window
      $win->after(1500, sub {$result = $test;});
    }
  }

  ## See if we have a first field specified
  if ($first_field)
  {
    if ($first_field->is_type($ENTRY))
    {
      ## If this is an entry field, select the entire string
      ## and place the cursor at the end of the string
      $first_field->widget->selectionRange(0, 'end');
      $first_field->widget->icursor('end');
    }
    
    ## Set the focus to the field
    $first_field->widget->focus();

  }
  ## Wait for variable to change
  $win->waitVariable(\$result);

  ## Hide the window
  $win->withdraw();
  
  ## Clear all errors until form data is validated again
  $self->clear_errors;
  
  if ($result)
  {
    ## Build the result
    $result = {};
    $result->{$_->key} = $_->value foreach (@{$self->fields});
    
    ## Validate each field
    $_->validate() foreach (@{$self->fields});
    
  }
  else
  {
    $result = undef;
  }
  
  ## Destroy the window and all its widgets
  $win->destroy();
  
  return($result);
}

##----------------------------------------------------------------------------
##     @fn _determine_dimensions($parent)
##  @brief Determine the overal dimensions of the given widgets
##  @param $parent - Refernce to parent widget
## @return ($width, $height) - The width and height
##   @note 
##----------------------------------------------------------------------------
sub _determine_dimensions
{
  my $parent     = shift;
  my @children   = $parent->children;
  my $max_width  = 0;
  my $max_height = 0;

  foreach my $widget (@children)
  {
    my ($width, $height, $x_pos, $y_pos) = split(/[x\+]/x, $widget->geometry());
    $width += $x_pos;
    $height += $y_pos;
    
    $max_width = $width if ($width > $max_width);
    $max_height = $height if ($height > $max_height);
    
  }
  
  return($max_width, $max_height);
}

##----------------------------------------------------------------------------
##     @fn _calc_geometry($parent)
##  @brief Calculate window geometry to place the given window in the center
##         of the screen
##  @param $parent - Reference to the Main window widget
## @return void
##   @note 
##----------------------------------------------------------------------------
sub _calc_geometry
{
  my $self   = shift;
  my $parent = shift;

  return if (!defined($parent));
  return if (ref($parent) ne "MainWindow");
  
  ## Allow the geometry manager to update all sizes
  $parent->update();
  
  ## Determine the windows dimensions
  my ($width, $height)   = _determine_dimensions($parent);

  ## Determine the width and make sure it is at least $self->min_width
  $width = $self->min_width if ($width < $self->min_width);
  
  ## Determine the height and make sure it is at least $self->min_height
  $height = $self->min_height if ($height < $self->min_height);
  
  ## Calculate the X and Y to center on the screen
  my $pos_x = int(($parent->screenwidth - $width) / 2);
  my $pos_y = int(($parent->screenheight - $height) / 2);
  
  ## Update the geometry with the calculated values
  $parent->geometry("${width}x${height}+${pos_x}+${pos_y}");
  
  return;
}

##----------------------------------------------------------------------------
##     @fn _set_key_bindings($win)
##  @brief Set key bindings for the given window
##  @param $win - Window to use for binding keyboard events
## @return NONE
##   @note 
##----------------------------------------------------------------------------
sub _set_key_bindings
{
  my $self = shift;
  my $win  = shift;
  
  ## Now add the "hot key"
  my $button_text = $self->button_label;
  my $underline   = index($button_text, qq{&});
  if ($underline >= 0)
  {
    my $keycap = lc(substr($button_text, $underline + 1, 1));
    
    $win->bind(qq{<Alt-Key-$keycap>} => sub {${$self->_watch_variable} = 1;});
  }
  
  ## See if option set
  if ($self->submit_on_enter)
  {
    $win->bind(qq{<Key-Return>} => sub {${$self->_watch_variable} = 1;});
  }
  
  ## See if option set
  if ($self->cancel_on_escape)
  {
    $win->bind(qq{<Key-Escape>} => sub {${$self->_watch_variable} = 0;});
  }
  
  return;
}

##----------------------------------------------------------------------------
##     @fn _set_message($win)
##  @brief Set the message at the top of the form's window
##  @param $win - Window object
## @return NONE
##   @note 
##----------------------------------------------------------------------------
sub _set_message
{
  my $self = shift;
  my $win  = shift;
  
  ## See if we have a message
  if ($self->message)
  {
    ## To keep the message from making the dialog box too
    ## large, we will look at the current window width and
    ## wrap the message accordingly
    
    ## Allow gemoetry manager to calculate all widgets
    $win->update;
    
    ## Determine number of rows and columns in the grid 
    my ($columns, $rows) = $win->gridSize();
    
    ## Use the dialog's minimum width as the starting point
    my $max_x = $self->min_width;
    
    ## Iterate through all rows and columns
    my $row = 0;
    while ($row < $rows)
    {
      my $col = 0;
      while ($col < $columns)
      {
        ## Get the bounding box of the widget
        my ($x, $y, $width, $height) = $win->gridBbox($col, $row);
        ## Get the max x of the widget
        $x += $width;
        ## See if this is larger than our current max x
        $max_x = $x if ($x > $max_x);
        
        ## Increment the colums
        $col++;
      }
      ## Increment the rows
      $row++;
    }
    
    ## Create a label widget
    $win->Label(
      -wraplength => $max_x,
      -text       => $self->message,
      -justify    => qq{left},
      -font       => $self->message_font,
    )
    ->grid(
      -row        => 0,
      -rowspan    => 1,
      -column     => 0,
      -columnspan => 2,
      -sticky     => qq{},
    );
    
    ## Use an empty frame as a spacer 
    $win->Frame(-height => 5)->grid(-row => 1);
  }
  
  return;
}



##****************************************************************************
##****************************************************************************

=head2 initialize($param)

=over 2

=item B<Description>

initialize the form from a HASH reference, JSON string, or JSON file.
In all cases, the hash should have the following format

  {
    title  => 'My Form',
    fields => [
      {
        type  => 'Entry',
        key   => 'name',
        label => 'Name',
      },
      {
        type  => 'Radiobutton',
        key   => 'sex',
        label => 'Gender',
        choices => [
          {
            label => 'Male',
            value => 'male',
          },
          {
            label => 'Female',
            value => 'female',
          },
        ],
      }
    ]
  }

=item B<Parameters>

$param - HASH reference, or scalar containin JSON string, or filename

=item B<Return>

NONE

=back

=cut

##----------------------------------------------------------------------------
sub initialize
{
  my $self  = shift;
  my $param = shift;
    
  unless (ref($param))
  {
    my $str = qq{};
    if (-f qq{$param})
    {
      if (open(my $fh, qq{<}, $param))
      {
        ## Read the file
        while (my $line = <$fh>)
        {
          ## trim leading whitespace
          $line =~ s/^\s+//x;
          ## trim trailing whitespace
          $line =~ s/\s+$//x;
  
          ## See if this is a comment and should be ignored
          next if ($line =~ /^[#;]/x);
  
          ## Add this line to the option string
          $str .= $line . qq{ };
        }
        close($fh);
      }
    }
    else
    {
      $str = $param;
    }
    
    try
    {
      $param = JSON->new->utf8(1)->relaxed->decode($str);
    };
  }

  $self->_import_hash($param);
  
  ## Return object to allow chaining
  return $self;
}

##----------------------------------------------------------------------------
##     @fn _import_hash($hash)
##  @brief Load a form using the hash parameters
##  @param $param - Hash reference
## @return NONE
##   @note 
##----------------------------------------------------------------------------
sub _import_hash
{
  my $self = shift;
  my $param = shift;

  ## Import the "simple" non-array attributes
  foreach my $attr (@SIMPLE_ATTRIBUTES)
  {
    $self->$attr($param->{$attr}) if (exists($param->{$attr}));
  }
  
  ## Import the fields
  if (exists($param->{fields}) && (ref($param->{fields}) eq qq{ARRAY}))
  {
    foreach my $entry (@{$param->{fields}})
    {
      unless (my $field = $self->add_field(%{$entry}))
      {
        cluck(
          qq{Unable to create a field\n}, 
          Data::Dumper->Dump([$entry], [qw(entry)]), 
          qq{\n}
        );
      }
    }
  }
  
  return;
}

##****************************************************************************
##****************************************************************************

=head2 set_field_data($hash)

=over 2

=item B<Description>

Use the key/values of the provided hash to set the corresponding field 
values

=item B<Parameters>

$hash - Hash reference containing key /values whose keys correspnd to the
various field keys

=item B<Return>

NONE

=back

=cut

##----------------------------------------------------------------------------
sub set_field_data
{
  my $self = shift;
  my $hash = shift;
  
  ## Silently return if we did not receive a parameter
  return if (!defined($hash));
  
  ## Bail out if the parameter is NOT a hash reference
  confess(qq{Expected a HASH reference!}) unless (ref($hash) eq qq{HASH});
  
  foreach my $key (keys(%{$hash}))
  {
    my $found;
    INNER_FIELD_LOOP:
    foreach my $field (@{$self->fields})
    {
      if ($key eq $field->key)
      {
        $field->default($hash->{$key});
        $found = 1;
        last INNER_FIELD_LOOP;
      }
    }
  }

  return;
}

##****************************************************************************
##****************************************************************************

=head2 clear_errors()

=over 2

=item B<Description>

Clear errors on all form fields

=item B<Parameters>

NONE

=item B<Return>

NONE

=back

=cut

##----------------------------------------------------------------------------
sub clear_errors
{
  my $self = shift;

  ## Clear all field errors
  $_->error(qq{}) foreach (@{$self->fields});
  
  return($self);
}

##****************************************************************************
##****************************************************************************

=head2 field_by_key($key)

=over 2

=item B<Description>

Return the field associated with the provided key or UNDEF if not found.

=item B<Parameters>

$key - The key associated with the desired field

=item B<Return>

UNDEF if not found, or a Tk::FormUI field object

=back

=cut

##----------------------------------------------------------------------------
sub field_by_key
{
  my $self = shift;
  my $key  = shift // qq{};
  
  return unless($key);
  
  foreach my $field (@{$self->fields})
  {
    return($field) if ($key eq $field->key);
  }
  
  return;
}

##****************************************************************************
##****************************************************************************

=head2 error_by_key($key, $error)

=over 2

=item B<Description>

Set the error for the field associated with the given key

=item B<Parameters>

$key - The key associated with the desired field

$error - Error message for the given field

=item B<Return>

NONE

=back

=cut

##----------------------------------------------------------------------------
sub error_by_key
{
  my $self  = shift;
  my $key   = shift;
  my $error = shift // qq{};
  
  if (my $field = $self->field_by_key($key))
  {
    $field->error($error);
    return($error);
  }
  
  return;
}

##****************************************************************************
##****************************************************************************

=head2 has_errors()

=over 2

=item B<Description>

Returns TRUE if any field in the form has an error

=item B<Parameters>

NONE

=item B<Return>

TRUE if any field has an error

=back

=cut

##----------------------------------------------------------------------------
sub has_errors
{
  my $self = shift;
  
  foreach my $field (@{$self->fields})
  {
    return(1) if ($field->error);
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

