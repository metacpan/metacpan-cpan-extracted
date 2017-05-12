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


package App::MathImage::Tk::Main;
use 5.008;
use strict;
use warnings;
use FindBin;
use List::Util 'max';
use Tk;
use Tk::Balloon;
use Locale::TextDomain 1.19 ('App-MathImage');

use App::MathImage::Generator;
use App::MathImage::Tk::Drawing;
use App::MathImage::Tk::Perl::WidgetBits 'with_underline';

# uncomment this to run the ### lines
# use Smart::Comments;

use base 'Tk::Derived', 'Tk::MainWindow';
Tk::Widget->Construct('AppMathImageTkMain');

our $VERSION = 110;

sub Populate {
  my ($self, $args) = @_;

  # read-only
  $self->ConfigSpecs(-menubar => [ 'PASSIVE',
                                   'AppMathImageTkMain',
                                   'AppMathImageTkMain',
                                   undef ]);
  $self->ConfigSpecs(-toolbar => [ 'PASSIVE',
                                   'AppMathImageTkMain',
                                   'AppMathImageTkMain',
                                   undef ]);
  $self->ConfigSpecs(-drawing => [ 'PASSIVE',
                                   'AppMathImageTkMain',
                                   'AppMathImageTkMain',
                                   undef ]);

  my $balloon = $self->Balloon;

  # cf add-on Tk::ToolBar
  my $toolbar
    = $self->{'Configure'}->{'-toolbar'}
      = $self->Component('Frame','toolbar');

  my $menubar
    = $self->{'Configure'}->{'-menubar'}
      = $self->Component('Frame','menubar',
                         -relief => 'raised', -bd => 2);

  my $gui_options = delete $args->{'-gui_options'};
  my $gen_options = delete $args->{'-gen_options'} || {};
  {
    my %gen_options = %{App::MathImage::Generator->default_options};
    delete $gen_options{'width'};
    delete $gen_options{'height'};
    $gen_options = { %gen_options,
                     %$gen_options };
  }
  ### Main gen_options: $gen_options

  my $drawing
    = $self->{'Configure'}->{'-drawing'}
      = $self->Component
        ('AppMathImageTkDrawing','drawing',
         -background => 'black',
         -foreground => 'white',
         -activebackground => 'black',
         -activeforeground => 'white',
         -disabledforeground => 'white',
         (defined $gen_options->{'width'}
          ? (-width  => $gen_options->{'width'},
             -height => $gen_options->{'height'} || $gen_options->{'width'})
          : ()),
        );
  $drawing->bind('<Enter>',  [\&_do_drawing_motion, Ev('x'), Ev('y')]);
  $drawing->bind('<Motion>', [\&_do_drawing_motion, Ev('x'), Ev('y')]);
  $drawing->bind('<Leave>',  [\&_do_drawing_leave]);

  $self->SUPER::Populate($args);

  $menubar->pack(-side => 'top', -fill => 'x');
  $toolbar->pack(-side => 'top', -fill => 'x');

  {
    my $menu = $menubar->Menubutton(-text => with_underline(__('_File')),
                                    -tearoff => 0);
    $menu->pack(-side => 'left');

    $menu->cascade (-label     => with_underline(__('_Path')),
                    -tearoff   => 1,
                    -menuitems => [ map {
                      ['Button', _path_to_mnemonic($_),
                       -command => [ \&_path_menu_action, $self, $_ ]],
                     } App::MathImage::Generator->path_choices ]);

    $menu->cascade (-label     => with_underline(__('_Values')),
                    -tearoff   => 1,
                    -menuitems => [ map {
                      ['Button', _values_to_mnemonic($_),
                       -command => [ \&_values_menu_action, $self, $_ ]]
                    } App::MathImage::Generator->values_choices ]);

    $menu->command (-label   => with_underline(__('Save _As ...')),
                    -command => [ $self, 'popup_save_as' ]);

    $menu->command (-label   => with_underline(__('_Quit')),
                    -command => [ $self, 'destroy' ]);
  }

  {
    my $menu = $menubar->Menubutton(-text => with_underline(__('_Tools')));
    $menu->pack(-side => 'left');

    $menu->command (-label     => with_underline(__('_Fullscreen')),
                    -command   => [$self, 'toggle_fullscreen']);
    # $item->uncheck('fullscreen'); # initially unchecked

    {
      my $accelerator = __p('Main-accelerator-key','C');
      $menu->command (-label       => with_underline(__('_Centre')),
                      -accelerator => $accelerator,
                      -command => [$self, 'centre']);
      # upper and lower case
      $self->bind("<$accelerator>", ['centre']);
      $self->bind("<\L$accelerator>", ['centre']);
    }
    {
      my $item = $menu->cascade (-label => with_underline(__('_Toolbar')));
      my $submenu = $item->cget('-menu');
      $submenu->command (-label     => with_underline(__('_Horizontal')),
                         -command   => [$self, 'toolbar_state', 'horizontal']);
      $submenu->command (-label     => with_underline(__('_Vertical')),
                         -command   => [$self, 'toolbar_state', 'vertical']);
      $submenu->command (-label     => with_underline(__('Hi_de')),
                         -command   => [$self, 'toolbar_state', 'hide']);
    }
  }
  {
    my $menu = $menubar->Menubutton(-text => with_underline(__('_Help')));
    $menu->pack(-side => 'right');
    $menu->command (-label => with_underline(__('_About')),
                    -command => [ \&popup_about, $self ]);
    $menu->command (-label => with_underline(__('_Program POD')),
                    -command => [$self, 'popup_program_pod']);
    $menu->command (-label => with_underline(__('Pa_th POD')),
                    -command => [$self, 'popup_path_pod']);
    $menu->command (-label => with_underline(__('_Values POD')),
                    -command => [$self, 'popup_values_pod']);
    $menu->command (-label => with_underline(__('Dia_gnostics')),
                    -command => [ $self, 'popup_diagnostics' ]);
    $menu->command (-label => with_underline(__('_Widget Dump')),
                    -command => [ $self, 'popup_widgetdump' ]);
  }

  $drawing->{'gen_options'} = $gen_options;
  $drawing->pack(-side   => 'top',
                 -fill   => 'both',
                 -expand => 1,
                 -after  => $toolbar);

  {
    my $button = $toolbar->Button
      (-text    => __('Randomize'),
       -command => [ $self, 'randomize' ]);
    $button->pack (-side => 'left');
    $balloon->attach($button, -balloonmsg => __('Choose a random path, values, scale, etc.  Click repeatedly to see interesting things.'));
  }
  {
    my @values = App::MathImage::Generator->path_choices;
    my $spinbox = $self->{'path_spinbox'} = $toolbar->Spinbox
      (-values       => \@values,
       -width        => max(map{length} @values),
       -state        => 'readonly',
       -textvariable => \$gen_options->{'path'},
       -command => sub {
         my ($value, $direction) = @_;
         if ($gen_options->{'path'} ne $value) {
           $gen_options->{'path'} = $value;
         }
         $drawing->queue_reimage;
       })->pack(-side => 'left');
    $balloon->attach($spinbox, -balloonmsg => __('The path for where to place values in the plane.'));
  }
  {
    my @values = App::MathImage::Generator->values_choices;
    my $spinbox = $toolbar->Component
      ('Spinbox','values_spinbox',
       -values       => \@values,
       -width        => max(map{length} @values),
       -state        => 'readonly',
       -textvariable => \$gen_options->{'values'},
       -command => sub {
         my ($value, $direction) = @_;
         # if ($gen_options->{'values'} ne $value) {
         #   $gen_options->{'values'} = $value;
         # }
         $drawing->queue_reimage;
       })->pack(-side => 'left');
    $balloon->attach($spinbox, -balloonmsg => __('The values to show.'));
  }
  {
    my $frame = $toolbar->Frame;
    $frame->pack (-side => 'left');
    $frame->Label(-text => __('Scale'))->pack(-side => 'left');
    $self->{'scale_spinbox'} = $frame->Spinbox
      (-from  => 1,
       -to    => 9999,
       -width => 2,
       -text  => 3,
       -textvariable => \$gen_options->{'scale'},
       -command => sub {
         my ($value, $direction) = @_;
         # if ($gen_options->{'scale'} != $value) {
         #   $gen_options->{'scale'} = $value;
         # }
         $drawing->queue_reimage;
       })->pack(-side => 'left');
    $balloon->attach($frame, -balloonmsg => __('How many pixels per square.'));
  }
  {
    my @values = map { $_ eq 'default' ? 'figure' : $_ }
      App::MathImage::Generator->figure_choices;
    my $spinbox = $self->{'figure_spinbox'} = $toolbar->Spinbox
      (-values  => \@values,
       -width   => max(map{length} @values),
       -state   => 'readonly',
       -textvariable => \$self->{'figure'},
       -command => sub {
         my ($value, $direction) = @_;
         if ($value eq 'figure') { $value = 'default' }
         if ($gen_options->{'figure'} ne $value) {
           $gen_options->{'figure'} = $value;
           $drawing->queue_reimage;
         }
       })->pack(-side => 'left');
    $balloon->attach ($spinbox,
                      -balloonmsg => __('The figure to draw at each position.'));
  }

  $self->Component ('Label','statusbar',
                    -justify => 'left')
    ->pack(-side => 'bottom', -fill => 'x');


  # ### ismapped: $self->ismapped
  # $self->update;
  ### reqheight: $self->reqheight, $drawing->reqheight
  ### ismapped: $self->ismapped

  if (! $gen_options->{'width'}) {
    ### geometry: int($self->screenwidth * .8).'x'.int($self->screenheight * .8)
    $self->geometry(int($self->screenwidth * .8)
                    .'x'
                    .int($self->screenheight * .8));
  }
}

my %_values_to_mnemonic =
  (primes          => __('_Primes'),
   TwinPrimes      => __('_Twin Primes'),
   Squares         => __('S_quares'),
   Pronic          => __('Pro_nic'),
   triangular      => __('Trian_gular'),
   cubes           => __('_Cubes'),
   Tetrahedral     => __('_Tetrahedral'),
   Perrin          => __('Perr_in'),
   Padovan         => __('Pado_van'),
   Fibonacci       => __('_Fibonacci'),
   FractionDigits  => __('F_raction Digits'),
   Polygonal       => __('Pol_ygonal Numbers'),
   PiBits          => __('_Pi Bits'),
   odd             => __('_Odd Integers'),
   even            => __('_Even Integers'),
   all             => __('_All Integers'),
  );
sub _values_to_mnemonic {
  my ($str) = @_;
  $str = ($_values_to_mnemonic{$str} || nick_to_display($str));
  $str =~ tr/_/~/;
  return $str;
}
sub _values_menu_action {
  my ($self, $itemname) = @_;
  ### _values_menu_action(): $itemname
  my $drawing = $self->Subwidget('drawing');
  $drawing->{'gen_options'}->{'values'} = $itemname;
  $drawing->queue_reimage;
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
  return ($_values_to_mnemonic{$str} || nick_to_display($str));
}
sub _path_menu_action {
  my ($self, $path) = @_;
  ### _path_menu_action(): $path
  my $drawing = $self->Subwidget('drawing');
  $drawing->{'gen_options'}->{'path'} = $path;
  $drawing->queue_reimage;
}

sub nick_to_display {
  my ($nick) = @_;
  return join (' ',
               map {ucfirst}
               split(/[-_ ]+
                    |(?<=\D)(?=\d)
                    |(?<=\d)(?=\D)
                    |(?<=[[:lower:]])(?=[[:upper:]])
                     /x,
                     $nick));
}

# centre the display
sub centre {
  my ($self) = @_;  # also $itemname when called from menu
  ### Main centre() ...
  $self->Subwidget('drawing')->centre;
}

sub toolbar_state {
  my ($self, $state) = @_;
  my $toolbar = $self->cget('-toolbar');
  ### toolbar_state(): $toolbar

  $toolbar->packForget;
  if ($state eq 'hide') {
    return;
  }
  if ($state eq 'vertical') {
    $toolbar->pack(-side => 'left',
                   -before => $self->Subwidget('drawing'),
                   -fill => 'y');
    foreach my $child ($toolbar->children) {
      $child->packForget;
      $child->pack (-side => 'top',
                   -anchor => 'w');
    }
  } else { # Horizontal
    $toolbar->pack(-side => 'top',
                   -after => $self->cget('-menubar'),
                   -fill => 'x');
    foreach my $child ($toolbar->children) {
      $child->packForget;
      $child->pack (-side => 'left');
    }
  }
}

sub toggle_fullscreen {
  my ($self, $itemname) = @_;
  ### toggle_fullscreen(): "@_"

  ### wm attributes: $self->attributes

  my %attributes = $self->attributes;
  if (exists $attributes{'-fullscreen'}) {
    # FIXME: this probably only works for netwm, though might prefer Tk not
    # to advertise it if it doesn't work
    $self->attributes (-fullscreen => ! $attributes{'-fullscreen'});
  } else {
    # FIXME: save the current size to toggle back to
    $self->FullScreen;
  }
  ### wm attributes: $self->attributes
}
sub randomize {
  my ($self) = @_;
  my $drawing = $self->Subwidget('drawing');
  my %new_options = App::MathImage::Generator->random_options;
  my $gen_options = $drawing->{'gen_options'};
  @{$gen_options}{keys %new_options} = values %new_options; # hash slice
  ### randomize to: $gen_options
  $drawing->queue_reimage;
  _controls_from_draw ($self);
}
sub _controls_from_draw {
  my ($self) = @_;
  my $drawing = $self->Subwidget('drawing');
  my $gen_options = $drawing->{'gen_options'};

  # $self->{'scale_spinbox'}->configure(-text => $gen_options->{'scale'});
  {
    $self->{'figure'} = my $figure = $gen_options->{'figure'};
    if ($figure eq 'default') { $figure = 'figure' }
    $self->{'figure_spinbox'}->configure(-text => $figure);
  }
}

sub popup_about {
  my ($self) = @_;
  require App::MathImage::Tk::About;
  $self->AppMathImageTkAbout->Popup;
}

sub _do_drawing_motion {
  my ($drawing, $x, $y) = @_;
  ### _do_motion(): "@_"

  my $message = $drawing->gen_object->xy_message ($x, $y);
  ### $message

  my $self = $drawing->parent;
  my $statusbar = $self->Subwidget('statusbar');
  $statusbar->configure(-text => $message);
}
sub _do_drawing_leave {
  my ($drawing, $x, $y) = @_;
  my $self = $drawing->parent;
  my $statusbar = $self->Subwidget('statusbar');
  $statusbar->configure(-text => '');
}

sub popup_save_as {
  my ($self) = @_;
  require App::MathImage::Tk::SaveDialog;
  my $dialog = ($self->{'save_dialog'}
                ||= $self->AppMathImageTkSaveDialog
                (-drawing => $self->Subwidget('drawing')));
  $dialog->Popup;
}

sub popup_program_pod {
  my ($self) = @_;
  _tk_pod($self) or return;
  $self->Pod(-file => "$FindBin::Bin/$FindBin::Script");
}
sub popup_path_pod {
  my ($self) = @_;
  _tk_pod($self) or return;
  if (my $path = $self->Subwidget('drawing')->{'gen_options'}->{'path'}) {
    if (my $module = App::MathImage::Generator->path_choice_to_class ($path)) {
      $self->Pod(-file => $module);
    }
  }
}
sub popup_values_pod {
  my ($self) = @_;
  _tk_pod($self) or return;
  if (my $values = $self->Subwidget('drawing')->{'gen_options'}->{'values'}) {
    if ((my $module = App::MathImage::Generator->values_choice_to_class($values))) {
      $self->Pod(-file => $module);
    }
  }
}

# Load the Tk::Pod module if available.
# Return 1 if available, return 0 and open an error dialog if not.
sub _tk_pod {
  my ($self) = @_;
  if (eval { require Tk::Pod; 1}) {
    return 1;
  } else {
    my $err = $@;
    $self->popup_module_not_available ('Tk::Pod', $err);
    return 0;
  }
}

sub popup_diagnostics {
  my ($self) = @_;
  require App::MathImage::Tk::Diagnostics;
  $self->AppMathImageTkDiagonostics->Popup;
}
sub popup_widgetdump {
  my ($self) = @_;
  if (! eval { require Tk::WixdgetDump; 1}) {
    my $err = $@;
    $self->popup_module_not_available ('Tk::WidgetDump', $err);
    return;
  }
  $self->WidgetDump;
}

# ENHANCE-ME: MessageBox isn't very good on long $error messages
sub popup_module_not_available {
  my ($self, $module, $error) = @_;
  $self->messageBox (-type => 'Ok',
                     -icon => 'error',
                     -message => (__x('{module} not available',
                                      module => $module,
                                      error  => $error)
                                  . "\n" . $error));
}

sub command_line {
  my ($class, $mathimage) = @_;
  ### command_line(): $mathimage

  # require Tk::ErrorDialog;
  # {
  #   *Tk::Error = sub {
  #     require Devel::StackTrace;
  #     my $trace = Devel::StackTrace->new;
  #     my $str = $trace->as_string;
  #     print "--------------\n$str\n---------------\n";
  #   };
  # }

  my $gui_options = $mathimage->{'gui_options'};
  my $gen_options = $mathimage->{'gen_options'};
  my $self = $class->new
    (-gui_options => $gui_options,
     -gen_options => $gen_options);

  # ### ConfigSpecs: $self->ConfigSpecs

  if ($gui_options->{'fullscreen'}) {
    $self->toggle_fullscreen;
  }
  MainLoop;
  return 0;
}

1;
__END__
