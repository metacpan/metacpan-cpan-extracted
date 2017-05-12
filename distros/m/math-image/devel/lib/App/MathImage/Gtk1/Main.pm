# Copyright 2011, 2012, 2013 Kevin Ryde

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


package App::MathImage::Gtk1::Main;
use 5.008;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Scalar::Util;
use POSIX ();
use Locale::TextDomain 1.19 ('App-MathImage');
use Locale::Messages 'dgettext';

use App::MathImage::Gtk1::Drawing;
use App::MathImage::Gtk1::Ex::ComboBits;
use App::MathImage::Gtk1::Ex::SpinButtonBits;
use App::MathImage::Gtk1::Ex::WidgetBits;

# use Module::Util;
# use Gtk::Ex::NumAxis 2;
#
# use Glib::Ex::EnumBits;
# use Gtk::Ex::ToolItem::OverflowToDialog;
# use Gtk::Ex::ToolItem::ComboEnum;

# uncomment this to run the ### lines
#use Smart::Comments;

use vars '$VERSION', '@ISA';
$VERSION = 110;

use constant::defer init => sub {
  ### Main init(): @_
  require Gtk;
  Gtk->init;
  @ISA = ('Gtk::Window');
  Gtk::Window->register_subtype(__PACKAGE__);
  return undef;
};
sub new {
  ### Main new(): @_
  init();
  return Gtk::Widget->new(@_);
}

# sub DESTROY {
#   my ($self) = @_;
#   if (my $tooltips = delete $self->{'tooltips'}) {
#     $tooltips->destroy;
#   }
#   if (my $accel = delete $self->{'accel'}) {
#     $accel->destroy;
#   }
#   $self->SUPER::DESTROY;
# }

sub GTK_OBJECT_INIT {
  my ($self) = @_;
  ### Main GTK_OBJECT_INIT() ...

  my $vbox = $self->{'vbox'} = Gtk::VBox->new (0, 0);
  $self->add ($vbox);

  my $tooltips = $self->{'tooltips'} = Gtk::Tooltips->new;
  $tooltips->enable;

  my $accel_group = $self->{'accel_group'} = Gtk::AccelGroup->new;
  $self->add_accel_group ($accel_group);

  my $weak_self = $self;
  Scalar::Util::weaken ($weak_self);
  my $ref_weak_self = \$weak_self;

  my $menubar = Gtk::MenuBar->new;
  $vbox->pack_start ($menubar, 0,0,0);
  {
    my $menu = Gtk::Menu->new;
    {
      my $item = Gtk::MenuItem->new_with_label (__('File'));
      my $label = $item->child;
      my $keyval = 102; # $label->parse_uline ('_File');
      ### $keyval
      $item->add_accelerator ('activate', $accel_group,
                              $keyval, 'mod1-mask', 'locked');
      $menubar->append ($item);
      $item->set_submenu ($menu);
      $item->signal_connect(activate => sub {
                              ### File activate
                            });
    }
    {
      my $item = Gtk::MenuItem->new_with_label (__('Quit'));
      $item->signal_connect(activate => \&_do_menuitem_quit, $ref_weak_self);
      $menu->append ($item);
    }
  }
  {
    my $menu = Gtk::Menu->new;
    {
      my $item = Gtk::MenuItem->new_with_label (__('View'));
      my $label = $item->child;
      my $keyval = 118; # $label->parse_uline ('_View');
      ### $keyval
      $item->add_accelerator ('activate', $accel_group,
                              $keyval, 'mod1-mask', 'locked');
      $menubar->append ($item);
      $item->set_submenu ($menu);
      $item->signal_connect(activate => sub {
                              ### File activate
                            });

    }
    {
      my $item = Gtk::MenuItem->new_with_label (__('Centre'));
      $item->signal_connect (activate => sub {
                               my ($item, $ref_weak_self) = @_;
                               my $self = $$ref_weak_self || return;
                               $self->{'draw'}->centre;
                             }, $ref_weak_self);
      $tooltips->set_tip ($item,
                          __('Scroll to centre the origin 0,0 on screen (or at the left or bottom if no negatives in the path).'),
                          '');
      $menu->append ($item);
    }
  }
  {
    my $menu = Gtk::Menu->new;
    { my $item = Gtk::MenuItem->new_with_label (dgettext('gtk+','Help'));
      my $label = $item->child;
      my $keyval = 104; # $label->parse_uline ('_Help');
      ### $keyval
      $item->add_accelerator ('activate', $accel_group,
                              $keyval, 'mod1-mask', 'locked');
      $menubar->append ($item);
      $item->set_submenu ($menu);
    }
    {
      my $item = Gtk::MenuItem->new_with_label (__('About'));
      $item->signal_connect (activate => \&_do_menuitem_about, $ref_weak_self);
      $menu->append ($item);
    }
    if (Module::Util::find_installed('Browser::Open')) {
      my $item = $self->{'menuitem_oeis'}
        = Gtk::MenuItem->new_with_label (__('OEIS Web Page'));
      $item->signal_connect (activate => \&_do_menuitem_oeis, $ref_weak_self);
      $menu->append ($item);
      $self->{'accel'} = $item->child;
    }
  }

  my $draw = $self->{'draw'} = App::MathImage::Gtk1::Drawing->new;
  $draw->add_events ('pointer-motion-mask');
  $draw->signal_connect (motion_notify_event => \&_do_motion_notify);

  my $toolbar = $self->{'toolbar'} = Gtk::Toolbar->new (0, 0);
  $vbox->pack_start ($toolbar, 0,0,0);

  my $toolpos = -999;
  {
    my $hbox = $self->{'scale_hbox'} = Gtk::HBox->new;
    $toolbar->append_widget ($hbox, __('How many pixels per square.'), '');

    $hbox->pack_start (Gtk::Label->new(__('Scale')), 0,0,0);
    my $adj = Gtk::Adjustment->new ($draw->get('scale'), # initial
                                    1, 9999,  # min,max
                                    1,10,     # step,page increment
                                    0);       # page_size
    # Glib::Ex::ConnectProperties->new ([$draw,'scale'],
    #                                   [$adj,'value']);
    ### $adj
    my $spin = Gtk::SpinButton->new ($adj, 10, 0);
    App::MathImage::Gtk1::Ex::SpinButtonBits::mouse_wheel($spin);
    # $spin->set_width_chars(3);
    $hbox->pack_start ($spin, 0,0,0);
    $hbox->show_all;

    $spin->signal_connect
      (changed => sub {
         my ($spin) = @_;
         my $self = $spin->get_ancestor(__PACKAGE__) || return;
         $self->{'draw'}->set (scale => $spin->get_value_as_int);
       });

    # # hide for LinesLevel
    # Glib::Ex::ConnectProperties->new
    #     ([$values_combobox,'active-nick'],
    #      [$toolitem,'visible',
    #       write_only => 1,
    #       func_in => sub { $_[0] ne 'LinesLevel' }]);
  }

  {
    my $combo = $self->{'figure_combo'} = Gtk::Combo->new;
    App::MathImage::Gtk1::Ex::ComboBits::mouse_wheel($combo);
    $combo->set_popdown_strings (App::MathImage::Generator->figure_choices);
    $toolbar->append_widget ($combo,
                             __('The figure to draw at each position.'),
                             '');

    $combo->entry->signal_connect
      (changed => sub {
         my ($entry) = @_;
         ### figure combo changed: @_
         my $self = $entry->get_ancestor(__PACKAGE__) || return;
         $self->{'draw'}->set (figure => $entry->get_text);
       });

    # Glib::Ex::ConnectProperties->new
    #     ([$draw,'figure'],
    #      [$combobox,'active-nick']);
  }

  $vbox->pack_start ($draw, 1,1,0);

  {
    my $statusbar = $self->{'statusbar'} = Gtk::Statusbar->new;
    $vbox->pack_end ($statusbar, 0,0,0);
  }
  _update_oeis($self);

  $vbox->show_all;
  ### Main GTK_OBJECT_INIT() done ...
}

sub GTK_CLASS_INIT {
  my ($class) = @_;
  ### Main GTK_CLASS_INIT() ...
  $class->add_arg_type ('fullscreen', 'gboolean', 3); #R/W
  $class->add_arg_type ('statusbar', 'GtkWidget', 3); #R/W
}
sub GTK_OBJECT_SET_ARG {
  my ($self,$arg,$id, $value) = @_;
  ### Main GTK_OBJECT_SET_ARG(): "$arg to $value"
  # $self->{_color} = [split(' ',$value)];
  # $self->update_color;
}
sub GTK_OBJECT_GET_ARG {
  my ($self,$arg,$id) = @_;
  ### Main GTK_OBJECT_GET_ARG(): $arg
  ### is: $self->{$arg}
  return $self->{$arg};
}

sub _do_menuitem_quit {
  my ($item, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  $self->destroy;
}

sub _do_menuitem_about {
  my ($item, $ref_weak_self) = @_;
  ### _do_menuitem_about(): $item
  my $self = $$ref_weak_self || return;
  $self->popup_about;
}
sub popup_about {
  my ($self) = @_;
  ### popup_about() ...
  require App::MathImage::Gtk1::AboutDialog;
  App::MathImage::Gtk1::AboutDialog->popup;
}

sub _do_menuitem_oeis {
  my ($item, $ref_weak_self) = @_;
  ### _do_menuitem_oeis(): $item
  my $self = $$ref_weak_self || return;
  if (my $url = _oeis_url($self)) {
    require Browser::Open;
    my $cmd = Browser::Open::open_browser_cmd();
    ### $cmd
    system "$cmd $url &";
  }
}
sub _oeis_url {
  my ($self) = @_;
  my ($values_seq, $anum);
  return (($values_seq = $self->{'draw'}->gen_object->values_seq)
          && ($anum = $values_seq->oeis_anum)
          && "http://oeis.org/$anum");
}
sub _update_oeis {
  my ($self) = @_;
  my $url = _oeis_url($self);
  $self->{'menuitem_oeis'}->set (sensitive => !!$url);
  $self->{'tooltips'}->set_tip ($self->{'menuitem_oeis'},
                                __x("Open browser at Online Encyclopedia of Integer Sequences (OEIS) web page for the current values\n{url}",
                                    url => ($url||'')),
                                '');
}

sub _do_motion_notify {
  my ($draw, $event) = @_;
  ### Main _do_motion_notify()...

  my $self;
  if (($self = $draw->get_ancestor (__PACKAGE__))
      && (my $statusbar = $self->get('statusbar'))) {
    ### $statusbar
    my $id = $statusbar->get_context_id (__PACKAGE__);
    $statusbar->pop ($id);

    my $gen = $draw->gen_object;
    my $message = $gen->xy_message ($event->{'x'}, $event->{'y'});
    ### $message
    if (defined $message) {
      $statusbar->push ($id, $message);
    }
  }
  return 0; # EVENT_PROPAGATE
}

#------------------------------------------------------------------------------
# command line

sub command_line {
  my ($class, $mathimage) = @_;
  ### Main command_line() ...

  # Glib::set_application_name (__('Math Image'));
  # if (eval { require Gtk::Ex::ErrorTextDialog::Handler }) {
  #   Glib->install_exception_handler
  #     (\&Gtk::Ex::ErrorTextDialog::Handler::exception_handler);
  #   $SIG{'__WARN__'}
  #     = \&Gtk::Ex::ErrorTextDialog::Handler::exception_handler;
  # }

  my $gen_options = $mathimage->{'gen_options'};
  my $width = delete $gen_options->{'width'};
  my $height = delete $gen_options->{'height'};

  # if ($mathimage->{'gui_options'}->{'flash'}) {
  #   my $rootwin = Gtk::Gdk::Window->new_foreign(Gtk::Gdk->ROOT_WINDOW());
  #   if (! $width) {
  #     ($width, $height) = $rootwin->get_size;
  #   }
  #
  #   require Image::Base::Gtk::Gdk::Pixmap;
  #   my $image = Image::Base::Gtk::Gdk::Pixmap->new
  #     (-for_drawable => $rootwin,
  #      -width        => $width,
  #      -height       => $height);
  #   my $gen = $mathimage->make_generator;
  #   $gen->draw_Image ($image);
  #   my $pixmap = $image->get('-pixmap');
  #
  #   _flash (pixmap => $pixmap, time => .75);
  #   return 0;
  # }

  my $self = $class->new
    (fullscreen => (delete $mathimage->{'gui_options'}->{'fullscreen'})||0);
  $self->signal_connect (destroy => sub { Gtk->main_quit });

  my $draw = $self->{'draw'};
  if (defined $width) {
    App::MathImage::Gtk1::Ex::WidgetBits::set_usize_until_mapped
        ($draw, $width,$height);
  } else {
    $self->set_default_size (Gtk::Gdk->screen_width() * .8,
                             Gtk::Gdk->screen_height() * .8);
  }
  ### draw set: $gen_options

  my $rcstyle = Gtk::RcStyle->new;
  ### $rcstyle
  $rcstyle->modify_color (1,  # fg
                          'normal',
                          Gtk::Gdk::Color->parse_color
                          (delete $gen_options->{'foreground'}));
  $rcstyle->modify_color (2,  # bg
                          'normal',
                          Gtk::Gdk::Color->parse_color
                          (delete $gen_options->{'background'}));
  $draw->modify_style ($rcstyle);

  my $path_parameters = delete $gen_options->{'path_parameters'};
  my $values_parameters = delete $gen_options->{'values_parameters'};
  # ### draw set gen_options: keys %$gen_options
  # foreach my $key (keys %$gen_options) {
  #   $draw->set ($key, $gen_options->{$key});
  # }
  $draw->{'path-parameters'} = $path_parameters || {};
  $draw->{'values-parameters'} = $values_parameters || {};
  # ### draw values now: $draw->get('values')
  # ### values_parameters: $draw->get('values_parameters')
  # ### path: $draw->get('path')
  # ### path_parameters: $draw->get('path_parameters')

  $self->show;
  Gtk->main;
  return 0;
}




__END__

use Glib::Object::Subclass
  'Gtk::Window',
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
                   'Gtk::MenuBar',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->object
                  ('toolbar',
                   'Tool bar',
                   'Blurb.',
                   'Gtk::Toolbar',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->object
                  ('statusbar',
                   'Status bar',
                   'Blurb.',
                   'Gtk::Statusbar',
                   Glib::G_PARAM_READWRITE),

                ];

my $actions_array
  = [
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

     { name  => 'ViewMenu',
       label => dgettext('gtk20-properties','_View'),
     },
     { name  => 'PathMenu',
       label => dgettext('gtk20-properties','_Path'),
     },
     { name  => 'ValuesMenu',
       label => dgettext('gtk20-properties','_Values'),
     },

     { name  => 'ToolsMenu',
       label => dgettext('gtk20-properties','_Tools'),
     },
     { name     => 'RunGolly',
       label    => __('Run _Golly Program'),
       callback => \&_do_action_golly,
       tooltip  => __('Run the "golly" game-of-life program on the current display.'),
     },

     { name     => 'Random',
       label    => __('Random'),
       callback => \&_do_action_random,
       tooltip  => __('Choose a random path, values, scale, etc.
Click repeatedly to see interesting things.'),
     },
    ];

my $toggle_actions_array
  = [
     { name    => 'Toolbar',
       label   => __('_Toolbar'),
       tooltip => __('Whether to show the toolbar.'),
     },
     { name    => 'Axes',
       label   => __('A_xes'),
       tooltip => __('Whether to show axes beside the image.'),
       is_active  => 1,
     },
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
  $ui_str .= <<'HERE';
      <menuitem action='Fullscreen'/>
      <menuitem action='DrawProgressive'/>
      <menuitem action='Toolbar'/>
      <menuitem action='Axes'/>
      <menuitem action='RunGolly'/>
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
  my $actiongroup = $self->{'actiongroup'} = Gtk::ActionGroup->new ('main');
  $actiongroup->add_actions ($actions_array, $self);
  $actiongroup->add_toggle_actions ($toggle_actions_array, $self);

  {
    my $action = Gtk::ToggleAction->new (name => 'Fullscreen',
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
    my $action = Gtk::ToggleAction->new (name => 'DrawProgressive',
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

  $draw->signal_connect ('notify::values-parameters' => \&_do_values_changed);

  my $actiongroup = $self->init_actiongroup;

  {
    my $n = 0;
    my $group;
    my %hash;
    foreach my $values (App::MathImage::Generator->values_choices) {
      my $action = Gtk::RadioAction->new (name  => "Values-$values",
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
      my $action = Gtk::RadioAction->new (name  => "Path-$path",
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

  $ui->insert_action_group ($actiongroup, 0);
  $self->add_accel_group ($ui->get_accel_group);
  my $ui_str = $self->ui_string;
  $ui->add_ui_from_string ($ui_str);

  my $table = $self->{'table'} = Gtk::Table->new (3, 3);
  $vbox->pack_start ($table, 1,1,0);

  my $toolbar = $self->get('toolbar');
  $toolbar->show;
  $table->attach ($toolbar, 1,3, 0,1, ['expand','fill'],[],0,0);
  # $vbox->pack_start ($toolbar, 0,0,0);

  my $vbox2 = $self->{'vbox2'} = Gtk::VBox->new;
  $table->attach ($vbox2, 1,2, 1,2, ['expand','fill'],['expand','fill'],0,0);

  $table->attach ($draw, 1,2, 1,2, ['expand','fill'],['expand','fill'],0,0);

  {
    my $hadj = $draw->get('hadjustment');
    my $haxis = Gtk::Ex::NumAxis->new (adjustment => $hadj,
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
    my $vaxis = Gtk::Ex::NumAxis->new (adjustment => $vadj,
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
    if (Module::Util::find_installed('Gtk::Ex::QuadButton::Scroll')) {
      # quadbutton if available
      require Gtk::Ex::QuadButton::Scroll;
      $quadbutton = Gtk::Ex::QuadButton::Scroll->new
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
    my $action = $actiongroup->get_action ('Toolbar');
    Glib::Ex::ConnectProperties->new ([$toolbar,'visible'],
                                      [$action,'active']);
  }

  my $path_combobox;
  {
    my $toolitem = Gtk::Ex::ToolItem::ComboEnum->new
      (overflow_mnemonic => __('_Path'));
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
      = App::MathImage::Gtk1::Params->new (toolbar => $toolbar,
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
    my $separator = Gtk::SeparatorToolItem->new;
    $separator->show;
    $toolbar->insert ($separator, $toolpos++);
  }
  my $values_combobox;
  {
    my $toolitem = $self->{'values_toolitem'}
      = Gtk::Ex::ToolItem::ComboEnum->new
        (overflow_mnemonic => __('_Values'));
    $toolitem->show;
    $toolbar->insert ($toolitem, $toolpos++);

    $values_combobox = $self->{'values_combobox'} = $toolitem->get_child;
    set_property_maybe ($values_combobox, # tearoff-title new in 2.10
                        tearoff_title => __('Math-Image: Values'));

    $values_combobox->signal_connect
      ('notify::active-nick' => \&_do_values_changed);
    Glib::Ex::ConnectProperties->new ([$draw,'values'],
                                      [$values_combobox,'active-nick']);
    ### values combobox initial: $values_combobox->get('active-nick')


    require App::MathImage::Gtk1::Params;
    my $values_params = $self->{'values_params'}
      = App::MathImage::Gtk1::Params->new (toolbar => $toolbar,
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
    my $separator = Gtk::SeparatorToolItem->new;
    $separator->show;
    $toolbar->insert ($separator, $toolpos++);
  }
  {
    my $toolitem = Gtk::Ex::ToolItem::ComboEnum->new
      (enum_type => 'App::MathImage::Gtk::Drawing::Filters',
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
  ### _update_values_tooltip()...

  {
    my $tooltip = __('The values to display.');
    my $toolitem = $self->{'values_toolitem'};
    my $values_combobox = $self->{'values_combobox'} || return;
    my $enum_type = $values_combobox->get('enum_type');
    my $values = $values_combobox->get('active-nick');

    # my $desc = Glib::Ex::EnumBits::to_description($enum_type, $values)
    my $values_seq;
    if (($values_seq = $self->{'draw'}->gen_object->values_seq)
        && (my $desc = $values_seq->description)) {
      my $name = Glib::Ex::EnumBits::to_display ($enum_type, $values);
      $tooltip .= "\n\n"
        . __x('Current setting: {name}', name => $name)
          . "\n"
            . $desc;
    }
    ### values_seq: "$values_seq"
    ### $tooltip
    set_property_maybe ($toolitem, tooltip_text => $tooltip);
  }
}
sub _do_values_changed {
  my ($widget) = @_;
  my $self = $widget->get_ancestor(__PACKAGE__) || return;
  _update_values_tooltip($self);
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

sub popup_save_as {
  my ($self) = @_;
  require App::MathImage::Gtk1::SaveDialog;
  my $dialog = ($self->{'save_dialog'}
                ||= App::MathImage::Gtk1::SaveDialog->new
                (draw => $self->{'draw'},
                 transient_for => $self));
  $dialog->present;
}

sub _do_action_setroot {
  my ($action, $self) = @_;

  # Use X11::Protocol when possible so as to preserve colormap entries
  my $rootwin = $self->get_root_window;
  if ($rootwin->can('XID') && eval { require App::MathImage::Gtk1::X11; 1 }) {
    require App::MathImage::Gtk1::X11;
    $self->{'x11'} = App::MathImage::Gtk1::X11->new
      (gdk_window => $self->get_root_window,
       gen        => $self->{'draw'}->gen_object);
  } else {
    $self->{'draw'}->start_drawing_window ($rootwin);
  }
}

my $golly_tempfh;
sub _do_action_golly {
  my ($action, $self) = @_;

  require Gtk::Ex::WidgetCursor;
  Gtk::Ex::WidgetCursor->busy;

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
      require Gtk::Ex::Dragger;
      Gtk::Ex::Dragger->new (widget    => $axis,
                              $adjname  => $adj,
                              vinverted => 1,
                              cursor    => $orientation_to_cursorname{$orientation})
      });
    $dragger->start ($event);
  }
  return Gtk::EVENT_PROPAGATE;
}

#------------------------------------------------------------------------------
# printing

sub print_image {
  my ($self) = @_;
  my $print = Gtk::PrintOperation->new;
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
  $layout->set_width ($pwidth * Gtk::Pango::PANGO_SCALE);
  $layout->set_text ($str);
  my (undef, $str_height) = $layout->get_pixel_size;
  ### $str_height
  $c->move_to (0, 0);
  Gtk::Pango::Cairo::show_layout ($c, $layout);

  my $pixmap = $draw->pixmap;
  my $pixmap_context = Gtk::Gdk::Cairo::Context->create ($pixmap);
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


sub _flash {
  my %options = @_;
  my $time = delete $options{'time'};
  require Gtk::Ex::Splash;
  my $splash = Gtk::Ex::Splash->new (%options);
  $splash->show;
  my $timeout = Glib::Ex::SourceIds->new
    (Glib::Timeout->add (($time||.75) * 1000,
                         \&_run_timeout_handler));
  Gtk->main;
  undef $timeout;
  $splash->destroy;
}
sub _run_timeout_handler {
  Gtk->main_quit;
  return Glib::SOURCE_REMOVE();
}

1;
