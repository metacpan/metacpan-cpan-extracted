package Tk::MenuDialog;
##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##****************************************************************************
## NOTES:
##  * Before comitting this file to the repository, ensure Perl Critic can be
##    invoked at the HARSH [3] level with no errors
##****************************************************************************
=head1 NAME

Tk::MenuDialog - A  Moo based object oriented interface for creating and
display a dialog of buttons to be used as a menu using Tk

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

  use Tk::MenuDialog;
  use File::Basename qw(dirname);

  my $menu = Tk::MenuDialog->new;

  ## Add the script's directory to the icon path
  ## when searching for icon files
  $menu->add_icon_path(dirname(__FILE__));
  
  ## Add menu items to the menu
  $menu->add_item(
    label => qq{&Configure},
    icon  => qq{settings.png},
    );
  $menu->add_item(
    label => qq{&Run Tests},
    icon  => qq{run.png},
    );
    
  ## Allow operator to cancel the menu
  $menu->can_cancel(1);
  
  ## Display the menu and return hash reference of the selected item, 
  ## or UNDEF if canceled
  my $selection = $menu->show;

=cut

##****************************************************************************
##****************************************************************************
use 5.010;
use Moo;
## Moo enables strictures
## no critic (TestingAndDebugging::RequireUseStrict)
## no critic (TestingAndDebugging::RequireUseWarnings)
use Readonly;
use Carp qw(confess cluck);
use Tk;
use Tk::Photo;
use Tk::PNG;
use Tk::JPEG;
use Data::Dumper;
use JSON;
use Try::Tiny;

## Version string
our $VERSION = qq{0.05};

## Used when importing a form, these are "simple" non-array attributes
Readonly::Array my @SIMPLE_ATTRIBUTES => (
  qw(title button_font min_width min_height can_cancel button_spacing)
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

Title of the menu

DEFAULT: ''

=back

=cut

##----------------------------------------------------------------------------
has title => (
  is      => qq{rw},
  default => qq{},
);

##****************************************************************************
##****************************************************************************

=head2 can_cancel

=over 2

Indicates if the operator can close the dialog without a selection

DEFAULT: 1

=back

=cut

##----------------------------------------------------------------------------
has can_cancel => (
  is      => qq{rw},
  default => 1,
);

##****************************************************************************

=head2 cancel_on_escape

=over 2

Boolean value indicating if pressing the Escape key should simulate closing
the window and canceling the dialog.

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

=head2 items

=over 2

Array reference of items contained in this menu.

=back

=cut

##----------------------------------------------------------------------------
has items => (
  is => qq{rwp},
);

##****************************************************************************
##****************************************************************************

=head2 icon_path

=over 2

An array containing various paths to use when locating icon image files.

=back

=cut

##----------------------------------------------------------------------------
has icon_path => (
  is => qq{rwp},
);

##****************************************************************************

=head2 button_font

=over 2

Font to use for the buttons.

DEFAULT: 'times 10'

=back

=cut

##----------------------------------------------------------------------------
has button_font => (
  is => qq{rw},
  default => qq{times 10},
);

##****************************************************************************

=head2 button_spacing

=over 2

Number of pixels between each button

DEFAULT: 0

=back

=cut

##----------------------------------------------------------------------------
has button_spacing => (
  is => qq{rw},
  default => 0,
);

##****************************************************************************

=head2 min_width

=over 2

Minimum width of the dialog.

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

Minimum height of the dialog.

DEFAULT: 80

=back

=cut

##----------------------------------------------------------------------------
has min_height => (
  is => qq{rw},
  default => 80,
);

##****************************************************************************
## "Private" atributes
##***************************************************************************

## Holds reference to variable Tk watches for dialog completion 
has _watch_variable  => (
  is      => qq{rw},
);

## Grid row for placing the next widget
has _grid_row  => (
  is      => qq{rw},
  default => 0,
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

  ## Create an empty list of items
  $self->_set_items([]);
  
  ## Create an empty list
  $self->_set_icon_path([]);
  
  return($self);
}

##****************************************************************************
##****************************************************************************

=head2 add_item($hash)

=over 2

=item B<Description>

Add a field to the form.

=item B<Parameters>

A hash reference with the following key / value pairs:
  label         - Required paramater with 
  icon          - Optional filename of the icon to display
  icon_location - Optional location relative to button
                  text for the icon 
                  DEFAULT: "left"

=item B<Return>

UNDEF on error, or the hash reference of the item created

=back

=cut

##----------------------------------------------------------------------------
sub add_item
{
  my $self  = shift;
  my $param = shift;

  ## Check for missing keys
  my @missing = ();
  foreach my $key (qw(label))
  {
    push(@missing, $key) unless(exists($param->{$key}));
  }
  if (scalar(@missing))
  {
    cluck(qq{Item missing the following reuired key(s): "}, 
      join(qq{", "}, @missing),
      qq{"}
      );
  }

  ## Save the item in the list of items
  push(@{$self->items}, $param) if ($param);
      
  return($param);
}

##****************************************************************************
##****************************************************************************

=head2 show()

=over 2

=item B<Description>

Show the dialog as a new MainWindow.

The function will return if the users cancels the dialog or clicks a button

=item B<Parameters>

NONE

=item B<Return>

UNDEF when canceled, or the hash reference associated with the button clicked.

=back

=cut

##----------------------------------------------------------------------------
sub show
{
  my $self   = shift;
  my $test   = shift;
  my $win;    ## Window widget
  my $result; ## Variable used to capture the result
  my $buttons = [];

  ## Create as a new MainWindow
  $win = MainWindow->new(-title => $self->title);
  
  ## Hide the window
  $win->withdraw;
  
  ## Do not allow user to resize
  $win->resizable(0,0);

  ## Now use the grid geometry manager to layout everything
  $self->_grid_row(0);
  
  ## Insert spacer (if needed)
  $self->_insert_spacer($win);
  
  my $first;
  ## Now add the itmes
  my $number = 0;
  foreach my $item (@{$self->items})
  {
    ## See if the widget was created
    if (my $widget = $self->_build_button($item, $win, $number))
    {
      ## Place the widget
      $widget->grid(
        -row        => $self->_next_row,
        -rowspan    => 1,
        -column     => 1,
        -columnspan => 1,
        -sticky     => qq{nsew},
      );
      
      ## See if button should be disabled
      $widget->configure(-state => qq{disabled}) if ($item->{disabled});

      ## See if this is our first non-disabled field
      $first = $widget if (!$first && !$item->{disabled});
    }
    $number++;
    
    ## Insert spacer (if needed)
    $self->_insert_spacer($win);
  }
  
  $self->_watch_variable(\$result);
  
  ## Setup any keyboard bindings
  $self->_set_key_bindings($win);
  
  ## Calculate the geometry
  $self->_calc_geometry($win);

  ## Display the window
  $win->deiconify;
  
  ## Detect user closing the window
  $win->protocol('WM_DELETE_WINDOW' =>
    sub
    {
      return unless ($self->can_cancel);
      $result = -1;
    });

  ## See if we are testing
  if ($test)
  {
    ## Make sure the string is the correct format
    if ($test =~ /TEST:\s+(-?\d+)/x)
    {
      ## < 0  means CANCEL
      ## >= 0 means select item indicated
      $test = $1;
      
      ## Set a callback to close the window
      $win->after(1500, sub {$result = $test;});
    }
  }

  ## Set the focus to the item
  $first->focus() if ($first);

  ## Wait for variable to change
  $win->waitVariable(\$result);

  ## Hide the window
  $win->withdraw();

  ## See if we have a result
  if (defined($result))
  {
    ## See if the result is a valid index
    if (($result >= 0) && ($result < scalar(@{$self->items})))
    {
      ## Return the item object
      $result = $self->items->[$result];
    }
    else
    {
      ## Invalid index, so return UNDEF
      $result = undef;
    }
    ## Build the result
  }
  
  ## Destroy the window and all its widgets
  $win->destroy();
  
  return($result);
}

##****************************************************************************
##****************************************************************************

=head2 add_icon_path()

=over 2

=item B<Description>

Description goes here

=item B<Parameters>

NONE

=item B<Return>

NONE

=back

=cut

##----------------------------------------------------------------------------
sub add_icon_path
{
  my $self = shift;
  my $path = shift;
  
  push(@{$self->icon_path}, $path) if ($path);
  
  return;
}

##----------------------------------------------------------------------------
##     @fn _build_button($item, $win)
##  @brief Build the button for the given item in the specified window
##  @param $item - HASH reference containing button information
##  @param $win - Parent object for the button
## @return 
##   @note 
##----------------------------------------------------------------------------
Readonly::Scalar my $IMAGE_SPACER => qq{ - };
sub _build_button
{
  my $self   = shift;
  my $item   = shift;
  my $win    = shift;
  my $number = shift;
  my $widget;
  
  my $button_text = $item->{label};
  my $underline   = index($button_text, qq{&});
  $button_text =~ s/\&//gx; ## Remove the &
  
  my $image;
  if (my $filename = $item->{icon})
  {
    unless (-f qq{$filename})
    {
      $filename = qq{};
      FIND_ICON_FILE_LOOP:
      foreach my $dir (@{$self->icon_path})
      {
        my $name = File::Spec->catfile(File::Spec->splitdir($dir), $item->{icon});
        if (-f qq{$name})
        {
          $filename = $name;
          last FIND_ICON_FILE_LOOP;
        }
      }
    }
    
    ## See if we have a filename
    if ($filename)
    {
      ## Load the filename
      $image = $win->Photo(-file => $filename)
    }
    else
    {
      cluck(
        qq{Could not locate icon "$item->{icon}"\nSearch Path:\n  "} .
        join(qq{"\n  "}, (qq{.}, @{$self->icon_path})) . 
        qq{"\n}
        );
    }
  }

  ## Create the button
  if ($image)
  {
    $button_text = $IMAGE_SPACER . $button_text . qq{  };
    $underline += length($IMAGE_SPACER) if ($underline >= 0);
    $widget = $win->Button(
      -text      => $button_text,
      -font      => $self->button_font,
#      -width     => length($button_text) + 2,
      -anchor    => qq{w},
      -command   => sub {${$self->_watch_variable} = $number;},
      -underline => $underline,
      -image     => $image,
      -compound  => qq{left},
    );
  }
  else
  {
    $widget = $win->Button(
      -text      => $button_text,
      -font      => $self->button_font,
      -width     => length($button_text) + 2,
      -command   => sub {${$self->_watch_variable} = $number;},
      -underline => $underline,
    );
  }
  
  return($widget);
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
  my $number = 0;
  foreach my $item (@{$self->items})
  {
    ## Skip disabled buttons
    unless ($item->{disabled})
    {
      ## Look for an ampersand in the label
      my $underline = index($item->{label}, qq{&});
      
      ## See if an ampersand was found
      if ($underline >= 0)
      {
        $underline++;
        ## Find the key within the string
        my $keycap = lc(substr($item->{label}, $underline, 1));
        
        ## Bind the key
        $win->bind(
          qq{<Alt-Key-$keycap>} => [
            sub
            {
              my $widget = shift;
              my $ref = shift;
              my $val = shift;
              ${$ref} = $val;
            },
            $self->_watch_variable,
            $number,
            ]
          );
      }
    }
    $number++;
  }
  
  ## See if option set
  if ($self->can_cancel and $self->cancel_on_escape)
  {
    $win->bind(qq{<Key-Escape>} => sub {${$self->_watch_variable} = -1;});
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
    title      => 'My Menu',
    can_cancel => 0,
    items => [
      {
        label => '&Configure',
        icon  => 'settings.png',
      },
      {
        label => '&Run',
        icon  => 'run.png',
      },
      {
        label => 'E&xit',
        icon  => 'exit.png',
      },
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
    
  unless (defined($param))
  {
    cluck(qq{Parameter missing in call to initialize()\n});
    return $self;
  }
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
  
  ## Import the items
  if (exists($param->{items}) && (ref($param->{items}) eq qq{ARRAY}))
  {
    foreach my $entry (@{$param->{items}})
    {
      unless (my $field = $self->add_item($entry))
      {
        cluck(
          qq{Unable to create an item\n}, 
          Data::Dumper->Dump([$entry], [qw(entry)]), 
          qq{\n}
        );
      }
    }
  }
  
  if (exists($param->{icon_path}) && (ref($param->{icon_path}) eq qq{ARRAY}))
  {
    foreach my $entry (@{$param->{icon_path}})
    {
      unless (my $field = $self->add_icon_path($entry))
      {
        cluck(
          qq{Unable to add to the icon path\n}, 
          Data::Dumper->Dump([$entry], [qw(entry)]), 
          qq{\n}
        );
      }
    }
  }
  return;
}

##----------------------------------------------------------------------------
##     @fn _next_row()
##  @brief Return the current grid row and increment
##  @param NONE
## @return SCALAR containing the next grid row
##   @note 
##----------------------------------------------------------------------------
sub _next_row
{
  my $self = shift;
  
  my $row = $self->_grid_row;
  
  $self->_grid_row($row + 1);
  
  return($row);
}

##----------------------------------------------------------------------------
##     @fn _insert_spacer($win)
##  @brief Insert a spacer (if needed) into the given window
##  @param $win - Tk window object
## @return 
##   @note 
##----------------------------------------------------------------------------
sub _insert_spacer
{
  my $self = shift;
  my $win  = shift;
  
  return unless ($self->button_spacing);
  
  ## Use an empty frame as a spacer 
  $win->Frame(-height => $self->button_spacing)->grid(
    -row => $self->_next_row,
    );

  
  
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
