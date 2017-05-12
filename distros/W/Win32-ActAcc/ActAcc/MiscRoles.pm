# Copyright 2001-2004, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility)

package Win32::ActAcc::Scrollbar;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Grip;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Sound;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Cursor;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Caret;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Alert;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Tooltip;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Application;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Document;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Pane;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Chart;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Dialog;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Border;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Grouping;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Separator;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Toolbar;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::StatusBar;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Table;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::ColumnHeader;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::RowHeader;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Column;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Row;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Cell;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Link;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::HelpBalloon;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Character;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::List;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::ListItem;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::PageTab;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::PropertyPage;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Indicator;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Graphic;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::StaticText;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Text;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Pushbutton;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Checkbox;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Radiobutton;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Combobox;
use strict;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

sub button_open
  {
    my $self = shift;
    return $self->memoize_member(+['{push button}'], 'button_open');
  }

# testable('Combobox::edit_box')
sub edit_box
  {
    my $self = shift;
    return $self->memoize_member(+['{window}', '{editable text}'], 'edit_box');
  }

# testable('Combobox::spinner')
sub spinner
  {
    my $self = shift;
    return $self->memoize_member(+['{window}', '{spin box}'], 'spinner');
  }

package Win32::ActAcc::DropList;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::ProgressBar;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Dial;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::HotKeyField;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Slider;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::SpinButton;
use strict;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

sub button_up
  {
    my $self = shift;
    return $self->memoize_member(+['{push button}Up'], 'pushbutton_up');
  }

# testable('SpinButton::button_down')
sub button_down
  {
    my $self = shift;
    return $self->memoize_member(+['{push button}Down'], 'pushbutton_down');
  }

package Win32::ActAcc::Diagram;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Animation;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Equation;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::ButtonDropDown;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::ButtonDropDownGrid;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Whitespace;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::PageTabList;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::Clock;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

1;
