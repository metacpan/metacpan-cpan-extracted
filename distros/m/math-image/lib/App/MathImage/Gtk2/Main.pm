# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Image is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.


package App::MathImage::Gtk2::Main;
use 5.008;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use POSIX ();
use Module::Util;
use Glib::Ex::ConnectProperties 8;  # v.8 for write_only
use Glib 1.220; # for SOURCE_REMOVE
use Gtk2 1.220;
use Gtk2::Ex::ActionTooltips;
use Gtk2::Ex::NumAxis 2;
use Locale::TextDomain 1.19 ('App-MathImage');
use Locale::Messages 'dgettext';

use Glib::Ex::EnumBits;
use Glib::Ex::ObjectBits 'set_property_maybe';
use Gtk2::Ex::ToolItem::OverflowToDialog;
use Gtk2::Ex::ToolItem::ComboEnum;

use App::MathImage::Gtk2::Drawing;
use App::MathImage::Gtk2::Drawing::Values;
use App::MathImage::Gtk2::Params;
use App::MathImage::Gtk2::Ex::Statusbar::PointerPosition;

# uncomment this to run the ### lines
# use Smart::Comments;


our $VERSION = 110;

use Glib::Object::Subclass
  'Gtk2::Window',
  signals => { window_state_event => \&_do_window_state_event,
               destroy => \&_do_destroy,
             },
  properties => [ Glib::ParamSpec->boolean
                  ('fullscreen',
                   __('Full screen'),
                   'Blurb.',
                   0,           # default
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->object
                  ('menubar',
                   'Menu bar',
                   'Blurb.',
                   'Gtk2::MenuBar',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->object
                  ('toolbar',
                   'Tool bar',
                   'Blurb.',
                   'Gtk2::Toolbar',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->object
                  ('statusbar',
                   'Status bar',
                   'Blurb.',
                   'Gtk2::Statusbar',
                   Glib::G_PARAM_READWRITE),

                ];

my %_values_to_mnemonic =
  (Primes             => __('_Primes'),
   TwinPrimes         => __('_Twin Primes'),
   Squares            => __('S_quares'),
   Pronic             => __('Pro_nic'),
   Triangular         => __('Trian_gular'),
   Cubes              => __('_Cubes'),
   Tetrahedral        => __('_Tetrahedral'),
   Perrin             => __('Perr_in'),
   Padovan            => __('Pado_van'),
   Fibonacci          => __('_Fibonacci'),
   FractionDigits  => __('F_raction Digits'),
   Polygonal       => __('Pol_ygonal Numbers'),
   PiBits          => __('_Pi Bits'),
   Ln2Bits         => __x('_Log Natural {logarg} Bits', logarg => 2),
   Ln3Bits         => __x('_Log Natural {logarg} Bits', logarg => 3),
   Ln10Bits        => __x('_Log Natural {logarg} Bits', logarg => 10),
   Odd             => __('_Odd Integers'),
   Even            => __('_Even Integers'),
   All             => __('_All Integers'),
  );
sub _values_to_mnemonic {
  my ($str) = @_;
  return ($_values_to_mnemonic{$str}
          || Glib::Ex::EnumBits->to_display_default($str));
}

my %_path_to_mnemonic =
  (SquareSpiral    => __('_Square Spiral'),
   SacksSpiral     => __('_Sacks Spiral'),
   VogelFloret     => __('_Vogel Floret'),
   DiamondSpiral   => __('_Diamond Spiral'),
   PyramidRows     => __('_Pyramid Rows'),
   PyramidSides    => __('_Pyramid Sides'),
   HexSpiral       => __('_Hex Spiral'),
   HexSpiralSkewed => __('_Hex Spiral Skewed'),
   KnightSpiral    => __('_Knight Spiral'),
   Corner          => __('_Corner'),
   Diagonals       => __('_Diagonals'),
   Rows            => __('_Rows'),
   Columns         => __('_Columns'),
  );
sub _path_to_mnemonic {
  my ($str) = @_;
  return ($_path_to_mnemonic{$str}
          || Glib::Ex::EnumBits::to_display_default($str));
}

my $actions_array
  = [
     { name  => 'FileMenu',
       label => dgettext('gtk20-properties','_File'),
     },
     { name     => 'SaveAs',
       stock_id => 'gtk-save-as',
       tooltip  => __('Save the image to a file.'),
       callback => sub {
         my ($action, $self) = @_;
         $self->popup_save_as;
       },
     },
     { name     => 'SetRoot',
       label    => __('Set _Root Window'),
       callback => \&_do_action_setroot,
       tooltip  => __('Set the current image as the root window background.'),
     },
     { name     => 'Print',
       stock_id => 'gtk-print',
       tooltip  => __('Print image to a printer.  Currently this merely draws at the screen resolution so might not scale well on a printer with limited resolution.'),
       callback => sub {
         my ($action, $self) = @_;
         $self->print_image;
       },
     },
     { name        => 'Quit',
       stock_id    => 'gtk-quit',
       accelerator => __p('Main-accelerator-key','<Control>Q'),
       callback    => sub {
         my ($action, $self) = @_;
         $self->destroy;
       },
     },

     { name  => 'ViewMenu',
       label => dgettext('gtk20-properties','_View'),
     },
     { name  => 'PathMenu',
       label => dgettext('gtk20-properties','_Path'),
     },
     { name  => 'ValuesMenu',
       label => dgettext('gtk20-properties','_Values'),
     },
     { name     => 'Centre',
       accelerator => __p('Main-accelerator-key','C'),
       label    => __('_Centre'),
       tooltip  => __('Scroll to centre the origin 0,0 on screen (or at the left or bottom if no negatives in the path).'),
       callback => sub {
         my ($action, $self) = @_;
         $self->{'draw'}->centre;
       },
     },

     { name  => 'ToolsMenu',
       label => dgettext('gtk20-properties','_Tools'),
     },
     { name  => 'ToolbarMenu',
       label => __('_Toolbar'),
     },
     { name     => 'RunGolly',
       label    => __('Run _Golly Program'),
       callback => \&_do_action_golly,
       tooltip  => __('Run the "golly" game-of-life program on the current display.'),
     },

     { name  => 'HelpMenu',
       label => dgettext('gtk20-properties','_Help'),
     },
     { name     => 'About',
       stock_id => 'gtk-about',
       callback => sub {
         my ($action, $self) = @_;
         $self->popup_about;
       },
     },
     (defined (Module::Util::find_installed('Gtk2::Ex::PodViewer'))
      ? ({ name     => 'PodDialog',
           label    => __('_Program POD'),
           tooltip  => __('Display the Math-Image program POD documentation (using Gtk2::Ex::PodViewer).'),
           callback => \&_do_action_pod_dialog,
         },
         { name     => 'PodDialogPath',
           label    => __('Pa_th POD'),
           tooltip  => __('Display the Math::PlanePath module documentation for the current path (using Gtk2::Ex::PodViewer).'),
           callback => \&_do_action_pod_dialog_path,
         },
         { name     => 'PodDialogValues',
           label    => __('_Values POD'),
           tooltip  => __('Display the Math::NumSeq module documentation for the current path (using Gtk2::Ex::PodViewer).'),
           callback => \&_do_action_pod_dialog_values,
         })
      : ()),
     (defined (Module::Util::find_installed('Browser::Open'))
      ? ({ name     => 'OeisBrowse',
           label    => __('_OEIS Web Page'),
           callback => sub {
             my ($action, $self) = @_;
             if (my $url = _oeis_url($self)) {
               require Browser::Open;
               Browser::Open::open_browser ($url);
             }
           },
         })
      : ()),

     { name     => 'Random',
       label    => __('Random'),
       callback => \&_do_action_random,
       tooltip  => __('Choose a random path, values, scale, etc.
Click repeatedly to see interesting things.'),
     },
    ];

my $toolbar_radio_actions_array
  = [
     { name        => 'ToolbarHorizontal',
       label       =>  __('_Horizontal'),
       value       => 0,
       is_active   => 0,
       tooltip     => __('Show the toolbar horizontally.'),
     },
     { name        => 'ToolbarVertical',
       label       =>  __('_Vertical'),
       value       => 1,
       is_active   => 0,
       tooltip     => __('Show the toolbar vertically.'),
     },
     { name        => 'ToolbarHide',
       label       =>  __('Hi_de'),
       value       => 2,
       is_active   => 0,
       tooltip     => __('Hide the toolbar.'),
     },
    ];

my $toggle_actions_array
  = [
     # { name    => 'Toolbar',
     #   label   => __('_Toolbar'),
     #   tooltip => __('Whether to show the toolbar.'),
     # },

     { name    => 'Axes',
       label   => __('A_xes'),
       tooltip => __('Whether to show axes beside the image.'),
       is_active  => 1,
     },

     (Module::Util::find_installed('Gtk2::Ex::CrossHair')
      ? { name        => 'Cross',
          label       =>  __('_Cross'),
          # "C" as an accelerator steals that key from the Gtk2::Entry of an
          # expression.  Is that supposed to happen?
          #   accelerator => __p('Main-accelerator-key','C'),
          callback    => \&_do_action_crosshair,
          is_active   => 0,
          tooltip     => __('Display a crosshair of horizontal and vertical lines following the mouse.'),
        } : ()),
    ];

sub ui_string {
  my ($self) = @_;
  my $ui_str = <<'HERE';
<ui>
  <menubar name='MenuBar'>
    <menu action='FileMenu'>
      <menuitem action='SetRoot'/>
      <menuitem action='SaveAs'/>
      <menuitem action='Print'/>
      <menuitem action='Quit'/>
    </menu>
    <menu action='ViewMenu'>
      <menu action='ValuesMenu'>
HERE
  foreach my $values (App::MathImage::Generator->values_choices) {
    $ui_str .= "      <menuitem action='Values-$values'/>\n";
  }
  $ui_str .= <<'HERE';
      </menu>
      <menu action='PathMenu'>
HERE
  foreach my $path (App::MathImage::Generator->path_choices) {
    $ui_str .= "      <menuitem action='Path-$path'/>\n";
  }
  $ui_str .= <<'HERE';
      </menu>
    <menuitem action='Centre'/>
    </menu>
    <menu action='ToolsMenu'>
HERE
  if ($self->{'actiongroup'}->get_action('Cross')) {
    $ui_str .= "<menuitem action='Cross'/>\n";
  }
  $ui_str .= <<'HERE';
      <menuitem action='Fullscreen'/>
      <menuitem action='DrawProgressive'/>
      <menu action='ToolbarMenu'>
        <menuitem action='ToolbarHorizontal'/>
        <menuitem action='ToolbarVertical'/>
        <menuitem action='ToolbarHide'/>
      </menu>
      <menuitem action='Axes'/>
      <menuitem action='RunGolly'/>
    </menu>
    <menu action='HelpMenu'>
      <menuitem action='About'/>
HERE
  foreach my $name ('PodDialog', 'PodDialogPath', 'PodDialogValues',
                    'OeisBrowse') {
    if ($self->{'actiongroup'}->get_action($name)) {
      $ui_str .= "<menuitem action='$name'/>\n";
    }
  }
  $ui_str .= <<'HERE';
    </menu>
  </menubar>
  <toolbar  name='ToolBar'>
    <toolitem action='Random'/>
    <separator/>
  </toolbar>
</ui>
HERE
  return $ui_str;
}

sub init_actiongroup {
  my ($self) = @_;
  my $actiongroup = $self->{'actiongroup'} = Gtk2::ActionGroup->new ('main');
  $actiongroup->add_actions ($actions_array, $self);
  $actiongroup->add_toggle_actions ($toggle_actions_array, $self);
  $actiongroup->add_radio_actions ($toolbar_radio_actions_array,
                                   0,  # initial selection
                                   \&_toolbar_radio_change, $self);

  {
    my $action = Gtk2::ToggleAction->new (name => 'Fullscreen',
                                          label => __('_Fullscreen'),
                                          tooltip => __('Toggle between full screen and normal window.'));
    $actiongroup->add_action ($action);
    # Control-F clashes with Emacs style keybindings in the spin and
    # expression entry boxes, you get fullscreen toggle instead of
    # forward-character.
    #     $actiongroup->add_action_with_accel
    #       ($action, __p('Main-accelerator-key','<Control>F'));
    Glib::Ex::ConnectProperties->new ([$self,  'fullscreen'],
                                      [$action,'active']);
  }
  {
    my $action = Gtk2::ToggleAction->new (name => 'DrawProgressive',
                                          label => __('_Draw Progressively'),
                                          active => 1,
                                          tooltip => __('Whether to draw progressively on the screen, or show the final image when ready.'));
    $actiongroup->add_action ($action);
    Glib::Ex::ConnectProperties->new ([$action,'active'],
                                      [$self->{'draw'}, 'draw-progressive']);
  }
  return $actiongroup;
}

sub INIT_INSTANCE {
  my ($self) = @_;

  my $vbox = $self->{'vbox'} = Gtk2::VBox->new (0, 0);
  $vbox->show;
  $self->add ($vbox);

  my $draw = $self->{'draw'} = App::MathImage::Gtk2::Drawing->new;
  $draw->signal_connect ('notify::values' => \&_do_values_changed);
  $draw->signal_connect ('notify::values-parameters' => \&_do_values_changed);

  my $actiongroup = $self->init_actiongroup;

  {
    my $n = 0;
    my $group;
    my %hash;
    foreach my $values (App::MathImage::Generator->values_choices) {
      my $action = Gtk2::RadioAction->new (name  => "Values-$values",
                                           label => _values_to_mnemonic($values),
                                           value => $n);
      $action->set_group ($group);
      $group ||= $action;
      $actiongroup->add_action ($action);
      $hash{$values} = $n;
      $hash{$n++} = $values;
    }
    Glib::Ex::ConnectProperties->new
        ([$draw,  'values'],
         [$group, 'current-value', hash_in => \%hash, hash_out => \%hash ]);
  }
  {
    my $n = 0;
    my $group;
    my %hash;
    foreach my $path (App::MathImage::Generator->path_choices) {
      my $action = Gtk2::RadioAction->new (name  => "Path-$path",
                                           label => _values_to_mnemonic($path),
                                           value => $n);
      $action->set_group ($group);
      $group ||= $action;
      $actiongroup->add_action ($action);
      $hash{$path} = $n;
      $hash{$n++} = $path;
    }
    Glib::Ex::ConnectProperties->new
        ([$draw,  'path'],
         [$group, 'current-value', hash_in => \%hash, hash_out => \%hash]);
  }

  my $ui = $self->{'ui'} = Gtk2::UIManager->new;
  $ui->insert_action_group ($actiongroup, 0);
  $self->add_accel_group ($ui->get_accel_group);
  my $ui_str = $self->ui_string;
  $ui->add_ui_from_string ($ui_str);

  {
    my $menubar = $self->get('menubar');
    $menubar->show;
    $vbox->pack_start ($menubar, 0,0,0);
  }

  my $table = $self->{'table'} = Gtk2::Table->new (3, 3);
  $vbox->pack_start ($table, 1,1,0);

  my $toolbar = $self->get('toolbar');
  $toolbar->show;
  $table->attach ($toolbar, 1,3, 0,1, ['expand','fill'],[],0,0);
  # $vbox->pack_start ($toolbar, 0,0,0);
  # Glib::Ex::ConnectProperties->new
  #     ([$toolbar,'visible'],
  #      [$actiongroup->get_action('ToolbarVertical'),'sensitive']);

  my $vbox2 = $self->{'vbox2'} = Gtk2::VBox->new;
  $table->attach ($vbox2, 1,2, 1,2, ['expand','fill'],['expand','fill'],0,0);

  $draw->add_events ('pointer-motion-mask');
  # $draw->signal_connect (motion_notify_event => \&_do_motion_notify);
  $table->attach ($draw, 1,2, 1,2, ['expand','fill'],['expand','fill'],0,0);

  {
    my $hadj = $draw->get('hadjustment');
    my $haxis = Gtk2::Ex::NumAxis->new (adjustment => $hadj,
                                        orientation => 'horizontal');
    set_property_maybe # tooltip-text new in 2.12
      ($haxis, tooltip_text => __('Drag with mouse button 1 to scroll.'));
    $haxis->add_events (['button-press-mask',
                         'button-release-mask',
                         'button-motion-mask',
                         'scroll-mask']);
    $haxis->signal_connect (button_press_event => \&_do_numaxis_button_press);
    $table->attach ($haxis, 1,2, 2,3, ['expand','fill'],[],0,0);

    my $vadj = $draw->get('vadjustment');
    my $vaxis = Gtk2::Ex::NumAxis->new (adjustment => $vadj,
                                        inverted => 1);
    set_property_maybe # tooltip-text new in 2.12
      ($vaxis, tooltip_text => __('Drag with mouse button 1 to scroll.'));
    $vaxis->add_events (['button-press-mask',
                         'button-release-mask',
                         'button-motion-mask',
                         'scroll-mask']);
    $vaxis->signal_connect (button_press_event => \&_do_numaxis_button_press);
    $table->attach ($vaxis, 2,3, 1,2, [],['expand','fill'],0,0);

    my $quadbutton;
    if (Module::Util::find_installed('Gtk2::Ex::QuadButton::Scroll')) {
      # quadbutton if available
      require Gtk2::Ex::QuadButton::Scroll;
      $quadbutton = Gtk2::Ex::QuadButton::Scroll->new
        (hadjustment => $hadj,
         vadjustment => $vadj,
         vinverted   => 1);
      set_property_maybe # tooltip-text new in 2.12
        ($quadbutton, tooltip_text => __('Click to scroll up/down/left/right, hold the control key down to scroll by a page.'));
      $table->attach ($quadbutton, 2,3, 2,3,
                      ['fill','shrink'],['fill','shrink'],2,2);
    }

    my $action = $actiongroup->get_action ('Axes');
    Glib::Ex::ConnectProperties->new
        ([$action,'active'],
         [$haxis,'visible'],
         [$vaxis,'visible'],
         ($quadbutton ? [$quadbutton,'visible'] : ()));
  }
  $table->show_all;

  {
    my $statusbar = $self->{'statusbar'} = Gtk2::Statusbar->new;
    $statusbar->show;
    $vbox->pack_start ($statusbar, 0,0,0);
    my $pointerposition = $self->{'statusbar_pointerposition'}
      = App::MathImage::Gtk2::Ex::Statusbar::PointerPosition->new
        (widget => $draw,
         statusbar => $statusbar);
    $pointerposition->signal_connect
      (message_string => \&_statusbar_pointerposition_message);
  }
  # {
  #   my $action = $actiongroup->get_action ('Toolbar');
  #   Glib::Ex::ConnectProperties->new ([$toolbar,'visible'],
  #                                     [$action,'active']);
  # }

  my $toolpos = -999;
  my $path_combobox;
  {
    my $toolitem = Gtk2::Ex::ToolItem::ComboEnum->new
      (enum_type => 'App::MathImage::Gtk2::Drawing::Path',
       overflow_mnemonic => __('_Path'));
    set_property_maybe
      ($toolitem, # tooltip-text new in 2.12
       tooltip_text  => __('The path for where to place values in the plane.'));
    $toolitem->show;
    $toolbar->insert ($toolitem, $toolpos++);

    $path_combobox = $self->{'path_combobox'} = $toolitem->get_child;
    set_property_maybe ($path_combobox,
                        # tearoff-title new in 2.10
                        tearoff_title => __('Math-Image: Path'));

    Glib::Ex::ConnectProperties->new ([$draw,'path'],
                                      [$toolitem,'active-nick']);


    my $path_params = $self->{'path_params'}
      = App::MathImage::Gtk2::Params->new (toolbar => $toolbar,
                                           after_toolitem => $toolitem);
    ### path_params path to parameter_info_array...
    Glib::Ex::ConnectProperties->new
        ([$draw,'path'],
         [$path_params,'parameter-info-array',
          write_only => 1,
          func_in => sub {
            my ($path) = @_;
            ### Main path parameter info: $path
            App::MathImage::Generator->path_class($path)->parameter_info_array;
          }]);
    ### path_params values to draw...
    Glib::Ex::ConnectProperties->new ([$path_params,'parameter-values'],
                                      [$draw,'path-parameters']);
  }

  {
    my $separator = Gtk2::SeparatorToolItem->new;
    $separator->show;
    $toolbar->insert ($separator, $toolpos++);
  }
  my $values_combobox;
  {
    my $toolitem = $self->{'values_toolitem'}
      = Gtk2::Ex::ToolItem::ComboEnum->new
        (enum_type => 'App::MathImage::Gtk2::Drawing::Values',
         overflow_mnemonic => __('_Values'));
    $toolitem->show;
    $toolbar->insert ($toolitem, $toolpos++);

    $values_combobox = $self->{'values_combobox'} = $toolitem->get_child;
    set_property_maybe ($values_combobox, # tearoff-title new in 2.10
                        tearoff_title => __('Math-Image: Values'));

    Glib::Ex::ConnectProperties->new ([$draw,'values'],
                                      [$values_combobox,'active-nick']);
    ### values combobox initial: $values_combobox->get('active-nick')


    require App::MathImage::Gtk2::Params;
    my $values_params = $self->{'values_params'}
      = App::MathImage::Gtk2::Params->new (toolbar => $toolbar,
                                           after_toolitem => $toolitem);
    ### values_params values to parameter_info_array...
    Glib::Ex::ConnectProperties->new
        ([$draw,'values'],
         [$values_params,'parameter-info-array',
          write_only => 1,
          func_in => sub {
            my ($values) = @_;
            ### Main values parameter info for: $values
            my $values_class = App::MathImage::Generator->values_class($values);
            ### arrayref: $values_class->parameter_info_array
            return $values_class->parameter_info_array;
          }]);
    Glib::Ex::ConnectProperties->new ([$draw,'values-parameters'],
                                      [$values_params,'parameter-values']);
  }


  {
    my $separator = Gtk2::SeparatorToolItem->new;
    $separator->show;
    $toolbar->insert ($separator, $toolpos++);
  }
  {
    my $toolitem = Gtk2::Ex::ToolItem::ComboEnum->new
      (enum_type => 'App::MathImage::Gtk2::Drawing::Filters',
       overflow_mnemonic => __('Filter'));
    set_property_maybe ($toolitem, # tooltip-text new in 2.12
                        tooltip_text  => __('Filter the values to only odd, or even, or primes, etc.'));
    $toolitem->show;
    $toolbar->insert ($toolitem, $toolpos++);

    my $combobox = $toolitem->get_child;
    set_property_maybe ($combobox,
                        tearoff_title => __('Math-Image: Filter'));

    Glib::Ex::ConnectProperties->new
        ([$draw,'filter'],
         [$combobox,'active-nick']);
  }
  {
    my $toolitem = Gtk2::Ex::ToolItem::OverflowToDialog->new
      (overflow_mnemonic => __('_Scale'));
    $toolbar->insert ($toolitem, $toolpos++);

    my $hbox = Gtk2::HBox->new;
    set_property_maybe ($toolitem,
                        # tooltip-text new in 2.12
                        tooltip_text => __('How many pixels per square.'));
    $toolitem->add ($hbox);

    $hbox->pack_start (Gtk2::Label->new(__('Scale')), 0,0,0);
    my $adj = Gtk2::Adjustment->new (1,        # initial
                                     1, 9999,  # min,max
                                     1,10,     # step,page increment
                                     0);       # page_size
    Glib::Ex::ConnectProperties->new ([$draw,'scale'],
                                      [$adj,'value']);
    my $spin = Gtk2::SpinButton->new ($adj, 10, 0);
    $spin->set_width_chars(3);
    $hbox->pack_start ($spin, 0,0,0);
    $toolitem->show_all;

    # hide for LinesLevel
    Glib::Ex::ConnectProperties->new
        ([$values_combobox,'active-nick'],
         [$toolitem,'visible',
          write_only => 1,
          func_in => sub { $_[0] ne 'LinesLevel' }]);
  }
  {
    my $toolitem = Gtk2::Ex::ToolItem::ComboEnum->new
      (enum_type => 'App::MathImage::Gtk2::Drawing::FigureType',
       overflow_mnemonic => __('_Figure'));
    set_property_maybe ($toolitem,
                        tooltip_text  => __('The figure to draw at each position.'));
    $toolitem->show;
    $toolbar->insert ($toolitem, $toolpos++);

    my $combobox = $toolitem->get_child;
    set_property_maybe ($combobox, # tearoff-title new in 2.10
                        tearoff_title => __('Math-Image: Figure'));

    Glib::Ex::ConnectProperties->new
        ([$draw,'figure'],
         [$combobox,'active-nick']);
  }

  Gtk2::Ex::ActionTooltips::group_tooltips_to_menuitems ($actiongroup);
  if (my $action = $actiongroup->get_action ('OeisBrowse')) {
    Gtk2::Ex::ActionTooltips::action_tooltips_to_menuitems_dynamic ($action);
  }
}

# 'destroy' class closure
sub _do_destroy {
  my ($self) = @_;
  ### Main FINALIZE_INSTANCE(), break circular refs...
  delete $self->{'actiongroup'};
  delete $self->{'ui'};
  return shift->signal_chain_from_overridden(@_);
}

sub _update_values_tooltip {
  my ($self) = @_;
  ### _update_values_tooltip() ...

  {
    my $tooltip = __('The values to display.');
    my $toolitem = $self->{'values_toolitem'};
    my $values_combobox = $self->{'values_combobox'} || return;
    my $enum_type = $values_combobox->get('enum_type');
    my $values = $values_combobox->get('active-nick');

    my $gen_object = $self->{'draw'}->gen_object;
    if (my $values_seq = $gen_object->values_seq_maybe) {
      {
        my $name = Glib::Ex::EnumBits::to_display ($enum_type, $values);
        $tooltip .= "\n\n" . __x('Current setting: {name}', name => $name);
      }
      if (my $desc = $values_seq->description) {
        $tooltip .= "\n" . $desc;
      }
      if (my $anum = $values_seq->oeis_anum) {
        $tooltip .= "\n" . __x('OEIS {anum}', anum => $anum);
      }
    }
    ### $tooltip
    set_property_maybe ($toolitem, tooltip_text => $tooltip);
  }

  if (my $action = $self->{'actiongroup'}->get_action('OeisBrowse')) {
    my $url = _oeis_url($self);
    $action->set (tooltip => __x("Open browser at Online Encyclopedia of Integer Sequences (OEIS) web page for the current values\n{url}",
                                 url => ($url||'')),
                  sensitive => defined($url));
  }
}
sub _do_values_changed {
  my ($widget) = @_;
  ### _do_values_changed(): "$widget"
  my $self = $widget->get_ancestor(__PACKAGE__) || return;
  _update_values_tooltip($self);
}

sub _oeis_url {
  my ($self) = @_;
  my ($values_seq, $anum);
  return (($values_seq = $self->{'draw'}->gen_object->values_seq)
          && ($anum = $values_seq->oeis_anum)
          && "http://oeis.org/$anum");
}


sub _statusbar_pointerposition_message {
  my ($pointerposition, $draw, $x, $y) = @_;
  if (my $self = $draw->get_ancestor (__PACKAGE__)) {
    return $draw->gen_object->xy_message ($x, $y);
  }
  return undef;
}
sub _do_motion_notify {
  my ($draw, $event) = @_;
  ### Main _do_motion_notify()...

  my $self;
  if (($self = $draw->get_ancestor (__PACKAGE__))
      && (my $statusbar = $self->get('statusbar'))) {
    my $id = $statusbar->get_context_id (__PACKAGE__);
    $statusbar->pop ($id);

    my $message = $draw->gen_object->xy_message ($event->x, $event->y);
    ### $message
    if (defined $message) {
      $statusbar->push ($id, $message);
    }
  }
  return Gtk2::EVENT_PROPAGATE;
}

my %ui_widget = (menubar => '/MenuBar',
                 toolbar => '/ToolBar');
sub GET_PROPERTY {
  my ($self, $pspec) = @_;
  my $pname = $pspec->get_name;
  if (my $uname = $ui_widget{$pname}) {
    return $self->{'ui'}->get_widget($uname);
  }
  return (exists $self->{$pname} ? $self->{$pname} : $pspec->get_default_value);
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;
  ### SET_PROPERTY: $pname, $newval

  if ($pname eq 'fullscreen') {
    # hide the draw widget until fullscreen change takes effect, so as not
    # to do the slow drawing stuff until the new size is set by the window
    # manager
    if ($self->mapped) {
      $self->{'draw'}->hide;
    }
    if ($newval) {
      ### fullscreen
      $self->fullscreen;
    } else {
      ### unfullscreen
      $self->unfullscreen;
    }
  }
  ### SET_PROPERTY done...
}

# 'window-state-event' class closure
sub _do_window_state_event {
  my ($self, $event) = @_;
  ### _do_window_state_event: "@{[$event->new_window_state]}"

  my $visible = ! ($event->new_window_state & 'fullscreen');
  $self->get('toolbar')->set (visible => $visible);
  $self->get('statusbar')->set (visible => $visible);
  $self->{'draw'}->show;

  # reparent the menubar
  my $menubar = $self->get('menubar');
  my $vbox = ($visible ? $self->{'vbox'} : $self->{'vbox2'});
  if ($menubar->parent != $vbox) {
    $menubar->parent->remove ($menubar);
    $vbox->pack_start ($menubar, 0,0,0);
    $vbox->reorder_child ($menubar, 0); # at the start
    if ($self->{'draw'}->window) {
      $self->{'draw'}->window->raise;
    }
  }
}

sub menubar {
  my ($self) = @_;
  return $self->{'ui'}->get_widget('/MenuBar');
}

sub toolbar {
  my ($self) = @_;
  return $self->{'ui'}->get_widget('/ToolBar');
}
sub _toolbar_radio_change {
  my ($first_action, $selected_action, $self) = @_;
  ### _toolbar_radio_change() ...

  my $toolbar = $self->get('toolbar');
  my $n = $selected_action->get_current_value;
  ### $n
  if ($n == 0) {
    $toolbar->set (orientation => 'horizontal');
    $self->{'table'}->child_set_property ($toolbar,
                                          left_attach => 1,
                                          right_attach => 3,
                                          top_attach => 0,
                                          bottom_attach => 1,
                                          x_options => ['expand','fill'],
                                          y_options => [],
                                          );
    $toolbar->show;
  } elsif ($n == 1) {
    $toolbar->set (orientation => 'vertical');
    $self->{'table'}->child_set_property ($toolbar,
                                          left_attach => 0,
                                          right_attach => 1,
                                          top_attach => 1,
                                          bottom_attach => 3,
                                          x_options => [],
                                          y_options => ['expand','fill'],
                                          );
    $toolbar->show;
  } elsif ($n == 2) {
    $toolbar->hide;
  }
}

sub popup_save_as {
  my ($self) = @_;
  require App::MathImage::Gtk2::SaveDialog;
  my $dialog = ($self->{'save_dialog'}
                ||= App::MathImage::Gtk2::SaveDialog->new
                (draw => $self->{'draw'},
                 transient_for => $self));
  $dialog->present;
}

sub _do_action_setroot {
  my ($action, $self) = @_;
  ### _do_action_setroot() ...

  # Use X11::Protocol when possible so as to preserve colormap entries
  my $rootwin = $self->get_root_window;
  if ($rootwin->can('XID') && eval { require App::MathImage::Gtk2::X11; 1 }) {
    ### use X11-Protocol drawing ...
    require App::MathImage::Gtk2::X11;
    $self->{'x11'} = App::MathImage::Gtk2::X11->new
      (gdk_window => $self->get_root_window,
       gen        => $self->{'draw'}->gen_object);
  } else {
    ### use gtk2 drawing ...
    $self->{'draw'}->start_drawing_window ($rootwin);
  }
}

my $golly_tempfh;
sub _do_action_golly {
  my ($action, $self) = @_;

  require Gtk2::Ex::WidgetCursor;
  Gtk2::Ex::WidgetCursor->busy;

  my $draw = $self->{'draw'};
  my (undef, undef, $width, $height) = $draw->allocation->values;
  my $scale = $draw->get('scale');
  $width = POSIX::ceil ($width / $scale);
  $height = POSIX::ceil ($height / $scale);
  my $x_left = int ($draw->{'hadjustment'}->value / $scale);
  my $y_bottom  = int ($draw->{'vadjustment'}->value / $scale);
  my $gen = $draw->gen_object (foreground => 'o',
                               background => 'b',
                               width    => $width,
                               height   => $height,
                               x_left   => $x_left,
                               y_bottom => $y_bottom,
                               scale  => 1);

  require App::MathImage::Image::Base::LifeRLE;
  my $image = App::MathImage::Image::Base::LifeRLE->new
    (-width  => $width,
     -height => $height,
     -file_format => 'png',
     -zlib_compression => 0);
  $gen->draw_Image ($image);

  require File::Temp;
  $golly_tempfh = File::Temp->new (TEMPLATE => "MathImageXXXXXX",
                                   SUFFIX => '.rle',
                                   TMPDIR => 1,
                                   UNLINK => 1);
  my $filename =  $golly_tempfh->filename;
  $image->save ($filename);

  require Proc::SyncExec;
  Proc::SyncExec::sync_exec ('golly', $filename);
}

sub popup_about {
  my ($self) = @_;
  require App::MathImage::Gtk2::AboutDialog;
  my $about = App::MathImage::Gtk2::AboutDialog->new
    (screen => $self->get_screen);
  $about->present;
}

sub _do_action_pod_dialog {
  my ($action, $self, $initial_pod) = @_;
  require Gtk2::Ex::WidgetCursor;
  Gtk2::Ex::WidgetCursor->busy;
  require App::MathImage::Gtk2::PodDialog;
  my $dialog = App::MathImage::Gtk2::PodDialog->new
    (screen => $self->get_screen,
     pod => $initial_pod);
  $dialog->present;
}
sub _do_action_pod_dialog_path {
  my ($action, $self) = @_;
  _do_action_pod_dialog ($action, $self,
                         $self->{'draw'}->get('path'));
}
sub _do_action_pod_dialog_values {
  my ($action, $self) = @_;
  _do_action_pod_dialog ($action, $self,
                         $self->{'draw'}->get('values'));
}

sub _do_action_random {
  my ($action, $self) = @_;
  my $draw = $self->{'draw'};
  my %options = App::MathImage::Generator->random_options;
  $draw->set(%options);

  # foreach my $key (keys %options) {
  #   my $pname = "values-$key";
  #   if (! $draw->find_property($pname)) {
  #     $pname = $key;
  #   }
  #   $draw->set($pname => $options{$key});
  # }
}

sub _do_action_crosshair {
  my ($action, $self) = @_;
  $self->{'crosshair_connp'} ||=  do {
    require Gtk2::Ex::CrossHair;
    require Gtk2::Ex::Units;
    my $draw = $self->{'draw'};
    my $cross = $self->{'crosshair'}
      = Gtk2::Ex::CrossHair->new (widget => $draw,
                                  foreground => 'orange',
                                  active => 1);
    Glib::Ex::ConnectProperties->new ([$action,'active'],
                                      [$cross,'active']);
    my $max_line_width = POSIX::ceil (Gtk2::Ex::Units::width($draw, ".5mm"));
    Glib::Ex::ConnectProperties->new ([$draw,'scale'],
                                      [$cross,'line-width',
                                       write_only => 1,
                                       func_in => sub { min($_[0],$max_line_width) }]);
    #     $self->{'draw'}->signal_connect
    #       ('notify::scale' => sub {
    #          my ($draw) = @_;
    #          my $scale = $draw->get('scale');
    #          $cross->set (line_width => min($scale,3));
    #        });
    #     $self->{'draw'}->notify('scale'); # initial
  };
}

# my %type_to_adjname = (left  => 'hadjustment',
#                        right => 'hadjustment',
#                        up    => 'vadjustment',
#                        down  => 'vadjustment');
# my %type_factor = (left  => -1,
#                    right => 1,
#                    up    => -1,
#                    down  => 1);
# sub _do_arrow_button_clicked {
#   my ($button) = @_;
#   my $self = $button->get_ancestor (__PACKAGE__);
#   my $arrow = $button->get_child;
#   my $type = $arrow->get('arrow-type');
#   ### _do_arrow_button_clicked(): $type
#   my $adj = $self->{'draw'}->get($type_to_adjname{$type});
#
#   ### adj value was: $adj->value.' page='.$adj->page_size
#   ### add: $adj->step_increment
#   ### value upper limit: $adj->upper - $adj->page_size
#   $adj->set_value ($adj->value + $adj->step_increment * $type_factor{$type});
#   ### adj value now: $adj->value
# }

my %orientation_to_adjname = (horizontal => 'hadjustment',
                              vertical   => 'vadjustment');
my %orientation_to_cursorname = (horizontal => 'sb-h-double-arrow',
                                 vertical   => 'sb-v-double-arrow');
# axis 'button-press-event' handler
sub _do_numaxis_button_press {
  my ($axis, $event) = @_;
  ### _do_numaxis_button_press(): $event->button
  if ($event->button == 1) {
    my $dragger = ($axis->{'dragger'} ||= do {
      my $self = $axis->get_ancestor (__PACKAGE__);
      my $orientation = $axis->get('orientation');
      my $adjname = $orientation_to_adjname{$orientation};
      my $adj = $self->{'draw'}->get($adjname);
      require Gtk2::Ex::Dragger;
      Gtk2::Ex::Dragger->new (widget    => $axis,
                              $adjname  => $adj,
                              vinverted => 1,
                              cursor    => $orientation_to_cursorname{$orientation})
      });
    $dragger->start ($event);
  }
  return Gtk2::EVENT_PROPAGATE;
}

#------------------------------------------------------------------------------
# printing

sub print_image {
  my ($self) = @_;
  my $print = Gtk2::PrintOperation->new;
  $print->set_n_pages (1);
  if (my $settings = $self->{'print_settings'}) {
    $print->set_print_settings ($settings);
  }
  Scalar::Util::weaken (my $weak_self = $self);
  $print->signal_connect (draw_page => \&_print_draw_page, \$weak_self);

  my $result = $print->run ('print-dialog', $self);
  if ($result eq 'apply') {
    $self->{'print_settings'} = $print->get_print_settings;
  }
}

sub _print_draw_page {
  my ($print, $pcontext, $pagenum, $ref_weak_self) = @_;
  ### _print_draw_page()...
  my $self = $$ref_weak_self || return;
  my $c = $pcontext->get_cairo_context;

  my $draw = $self->{'draw'};
  my $gen = $draw->gen_object;
  my $str = $gen->description . "\n\n";

  my $pwidth = $pcontext->get_width;
  my $layout = $pcontext->create_pango_layout;
  $layout->set_width ($pwidth * Gtk2::Pango::PANGO_SCALE);
  $layout->set_text ($str);
  my (undef, $str_height) = $layout->get_pixel_size;
  ### $str_height
  $c->move_to (0, 0);
  Gtk2::Pango::Cairo::show_layout ($c, $layout);

  my $pixmap = $draw->pixmap;
  my $pixmap_context = Gtk2::Gdk::Cairo::Context->create ($pixmap);
  my ($pixmap_width, $pixmap_height) = $pixmap->get_size;
  ### $pixmap_width
  ### $pixmap_height

  my $pheight = $pcontext->get_height - $str_height;
  ### $pwidth
  ### $pheight
  $c->translate (0, $str_height);
  my $factor = min ($pwidth / $pixmap_width,
                    $pheight / $pixmap_height);

  if ($factor < 1) {
    $c->scale ($factor, $factor);
  }
  $c->set_source_surface ($pixmap_context->get_target, 0,0);

  $c->rectangle (0,0, $pixmap_width,$pixmap_height);
  $c->paint;
}

#------------------------------------------------------------------------------
# command line

sub command_line {
  my ($class, $mathimage) = @_;
  $mathimage->try_gtk || die "Cannot initialize Gtk";

  Glib::set_application_name (__('Math Image'));
  # if (eval { require Gtk2::Ex::ErrorTextDialog::Handler }) {
  #   Glib->install_exception_handler
  #     (\&Gtk2::Ex::ErrorTextDialog::Handler::exception_handler);
  #   $SIG{'__WARN__'}
  #     = \&Gtk2::Ex::ErrorTextDialog::Handler::exception_handler;
  # }

  my $gen_options = $mathimage->{'gen_options'};
  my $width = delete $gen_options->{'width'};
  my $height = delete $gen_options->{'height'};

  if ($mathimage->{'gui_options'}->{'flash'}) {
    my $rootwin = Gtk2::Gdk->get_default_root_window;
    if (! $width) {
      ($width, $height) = $rootwin->get_size;
    }

    require Image::Base::Gtk2::Gdk::Pixmap;
    my $image = Image::Base::Gtk2::Gdk::Pixmap->new
      (-for_drawable => $rootwin,
       -width        => $width,
       -height       => $height);
    my $gen = $mathimage->make_generator;
    $gen->draw_Image ($image);
    my $pixmap = $image->get('-pixmap');

    _flash (pixmap => $pixmap, time => .75);
    return 0;
  }

  my $self = $class->new
    (fullscreen => delete $mathimage->{'gui_options'}->{'fullscreen'});
  $self->signal_connect (destroy => sub { Gtk2->main_quit });

  my $draw = $self->{'draw'};
  if (defined $width) {
    require Gtk2::Ex::Units;
    Gtk2::Ex::Units::set_default_size_with_subsizes
        ($self, [ $draw, $width, $height ]);
  } else {
    $self->set_default_size (map {$_*0.8} $self->get_root_window->get_size);
  }
  ### draw set: $gen_options
  $draw->modify_fg ('normal',
                    Gtk2::Gdk::Color->parse
                    (delete $gen_options->{'foreground'}));
  $draw->modify_bg ('normal',
                    Gtk2::Gdk::Color->parse
                    (delete $gen_options->{'background'}));
  my $path_parameters = delete $gen_options->{'path_parameters'};
  my $values_parameters = delete $gen_options->{'values_parameters'};
  ### draw set gen_options: keys %$gen_options
  foreach my $key (keys %$gen_options) {
    $draw->set ($key, $gen_options->{$key});
  }
  $draw->set (path_parameters => $path_parameters);
  $draw->set (values_parameters => $values_parameters);
  ### draw values now: $draw->get('values')
  ### values_parameters: $draw->get('values_parameters')
  ### path: $draw->get('path')
  ### path_parameters: $draw->get('path_parameters')

  $self->show;
  Gtk2->main;
  return 0;
}

sub _flash {
  my %options = @_;
  my $time = delete $options{'time'};
  require Gtk2::Ex::Splash;
  my $splash = Gtk2::Ex::Splash->new (%options);
  $splash->show;
  my $timeout = Glib::Ex::SourceIds->new
    (Glib::Timeout->add (($time||.75) * 1000,
                         \&_run_timeout_handler));
  Gtk2->main;
  undef $timeout;
  $splash->destroy;
}
sub _run_timeout_handler {
  Gtk2->main_quit;
  return Glib::SOURCE_REMOVE();
}

1;
