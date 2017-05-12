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


package App::MathImage::Prima::Main;
use 5.004;
use strict;
use warnings;
use FindBin;
use List::Util 'max';
use Locale::TextDomain 1.19 ('App-MathImage');

use Prima;
use Prima::Application name => __('Math-Image');
use Prima::Buttons;
use Prima::ComboBox;
use Prima::Label;
use Prima::Sliders; # SpinEdit
use App::MathImage::Prima::Drawing;
use App::MathImage::Generator;

# uncomment this to run the ### lines
# use Smart::Comments;


use vars '$VERSION', '@ISA';
$VERSION = 110;
@ISA = ('Prima::MainWindow');

sub profile_default {
  my ($class) = @_;
  ### Prima-Drawing profile_default() ...
  return { %{$class->SUPER::profile_default},
           name        => __('Math-Image'),
           transparent => 1, # no clear background

           # color            => cl::White(),
           # backColor        => cl::Black(),

           menuItems =>
           [ [ "~File" =>
               [
                #       <menuitem action='SaveAs'/>
                #       <menuitem action='SetRoot'/>
                [ __('~Print') => 'print_image' ],
                [ __('E~xit')  => 'destroy' ],
               ] ],
             [ ef => "~View" =>
               [ [ ef => "~Path"   => [ _menu_for_path() ]],
                 [ ef => "~Values" => [ _menu_for_values() ]],
                 [ 'centre', __('~Centre'), 'draw_centre' ],
                 [ 'fullscreen', __('~Fullscreen'), 'toggle_fullscreen' ],
               ]],
             # [],  # separator to put Help at the right
             [ "~Help" =>
               [ [ __('~About'), 'help_about' ],
                 [ __('~Program POD'), 'help_program' ],
                 [ __('Pa~th POD'), 'help_path' ],
                 [ __('~Values POD'), 'help_values' ],
                 (defined (Module::Util::find_installed('Browser::Open'))
                  ? [ 'help-oeis', __('~OEIS Web Page'), 'help_oeis' ]
                  : ()),
               ],
             ],
           ],
         };
}

# together with transparent=>1 for no clear background underneath draw widget
sub on_paint {
}


sub init {
  my ($self, %profile) = @_;
  ### Prima Main init() ...

  my $visible = (exists $profile{'visible'} ? $profile{'visible'} : 1);
  $profile{'visible'} = 0;
  %profile = $self-> SUPER::init(%profile);

  my $gui_options = delete $profile{'gui_options'};
  my $gen_options = delete $profile{'gen_options'} || {};
  {
    my %default_gen_options = %{App::MathImage::Generator->default_options};
    delete @default_gen_options{'width','height'}; # hash slice
    $gen_options = { %default_gen_options,
                     %$gen_options };
  }
  ### $gen_options

  my $toolbar = $self->{'toolbar'}
    = $self->insert ('Widget',
                     pack => { in => $self,
                               side => 'top',
                               fill => 'x',
                               expand => 0,
                               anchor => 'n',
                             },
                    );

  $toolbar->insert ('Button',
                    text => __('Randomize'),
                    pack => { side => 'left' },
                    hint  => __('Choose a random path, values, scale, etc.
Click repeatedly to see interesting things.'),
                    onClick  => sub {
                      my ($button) = @_;
                      $self->{'draw'}->gen_options (App::MathImage::Generator->random_options);
                      _update($self);
                    },
                   );

  my $combobox_height = do {
    my $combo = Prima::ComboBox->create;
    my $height = $combo->editHeight;
    $combo->destroy;
    $height
  };

  my $path_combo = $self->{'path_combo'}
    = $toolbar->insert ('ComboBox',
                        pack   => { side => 'left',
                                    fill => 'none',
                                    expand => 0 },
                        hint  => __('The path for where to place values in the plane.'),
                        style => cs::DropDown,
                        # override dodgy height when style set
                        height => $combobox_height,
                        items => [ map { $_ } App::MathImage::Generator->path_choices ],
                        onChange  => sub {
                          my ($combo) = @_;
                          ### Main path_combo onChange
                          my $path = $combo->text;
                          $self->{'draw'}->gen_options (path => $path);
                          _update ($self);
                        },
                       );

  $self->{'values_combo'}
    = $toolbar->insert ('ComboBox',
                        pack  => { side => 'left',
                                   fill => 'none',
                                   expand => 0 },
                        style  => cs::DropDown,
                        # override dodgy height when style set
                        height => $combobox_height,
                        hint   => __('The values to display.'),
                        items => [ map { $_ } App::MathImage::Generator->values_choices ],
                        onChange  => sub {
                          my ($combo) = @_;
                          ### Main values combo onChange
                          my $values = $combo->text;
                          $self->{'draw'}->gen_options (values => $values);
                          _update ($self);
                        },
                       );

  # {
  #   my $max = 0;
  #   foreach (0 .. $self->{'values_combo'}->{list}->count() - 1) {
  #     ### wid: $self->{'values_combo'}->{list}->get_item_width($_)
  #     $max = max ($max, $self->{'values_combo'}->{list}->get_item_width($_));
  #   }
  #   ### $max
  #   $self->{'values_combo'}->width($max+10);
  # }

  {
    $toolbar->insert ('Label',
                      text => __('Scale'),
                      pack => { side => 'left' },);
    $self->{'scale_spin'}
      = $toolbar->insert ('SpinEdit',
                          pack => { side => 'left' },
                          min => 1,
                          step => 1,
                          pageStep => 10,
                          onChange  => sub {
                            my ($spin) = @_;
                            ### Prima-Main scale onChange: $spin->value
                            my $scale = $spin->value;
                            $self->{'draw'}->gen_options (scale => $scale);
                          },
                         );
  }

  $self->{'draw'} = $self->insert
    ('App::MathImage::Prima::Drawing',
     name   => 'Drawing',
     width  => (defined $gen_options->{'width'} ? $gen_options->{'width'} :-1),
     height => (defined $gen_options->{'height'}? $gen_options->{'height'}:-1),
     pack   => { expand => 1, fill => 'both' },
     delegations  => ['MouseMove'],
     gen_options  => $gen_options,
    );

  my $statusbar = $self->{'statusbar'} = $self->insert
    ('Label',
     text => '',
     pack => { in => $self,
               side => 'top',
               fill => 'x',
               expand => 0,
               anchor => 'n',
             });

  _update ($self);

  {
    my @size = $self->size;
    ### @size
    my ($screen_width, $screen_height) = $::application->size;
    if (! defined $gen_options->{'width'}) {
      ### $screen_width
      $size[0] = $screen_width * .8;
    }
    if (! defined $gen_options->{'height'}) {
      ### $screen_height
      $size[1] = $screen_height * .8;
    }
    $self->set (size => \@size);
    ### @size
  }

  # don't resize toplevel window for changes in children
  $self->packPropagate(0);

  $self->visible ($visible);
  return $self;
}

sub _update {
  my ($self) = @_;
  ### Prima-Main _update() ...

  my $gen_options = $self->{'draw'}->gen_options;

  my $menu = $self->menu;
  foreach my $path (App::MathImage::Generator->path_choices) {
    $menu->uncheck("path-$path");
  }
  $menu->check("path-$gen_options->{'path'}");

  foreach my $values (App::MathImage::Generator->values_choices) {
    $menu->uncheck("values-$values");
  }
  $menu->check("values-$gen_options->{'values'}");

  my $path = $gen_options->{'path'};
  if ($self->{'path_combo'}->text ne $path) {
    ### path_combo set text() ...
    $self->{'path_combo'}->text ($path);
  }

  if ($path eq 'SquareSpiral') {
    $self->{'path_wider_spin'}
      ||= $self->{'toolbar'}->insert ('SpinEdit',
                                      pack => { side => 'left',
                                                after => $self->{'path_combo'},
                                              },
                                      min => 0,
                                      step => 1,
                                      pageStep => 1,
                                      hint => __('Wider path.'),
                                      onChange  => sub {
                                        my ($spin) = @_;
                                        ### Main wider onChange ...
                                        my $wider = $spin->value;
                                        $self->{'draw'}->path_parameters (wider => $wider);
                                      },
                                     );
    $self->{'path_wider_spin'}->value ($self->{'draw'}->path_parameters->{'wider'});
  } else {
    if (my $spin = delete $self->{'path_wider_spin'}) {
      ### path_wider_spin destroy ...
      $spin->destroy;
    }
  }

  my $values = $gen_options->{'values'};
  if ($self->{'values_combo'}->text ne $values) {
    ### values_combo set text() ...
    $self->{'values_combo'}->text ($values);
  }

  {
    my $url = _oeis_url($self);
    ### $url
    $menu->enabled('help-oeis', defined($url));
  }

  $self->{'scale_spin'}->value ($gen_options->{'scale'});
  ### Prima-Main _update() done ...
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
   Ln2Bits         => __x('_Log Natural {logarg} Bits', logarg => 2),
   Ln3Bits         => __x('_Log Natural {logarg} Bits', logarg => 3),
   Ln10Bits        => __x('_Log Natural {logarg} Bits', logarg => 10),
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
sub _menu_for_values {
  my ($self) = @_;

  return map {
    my $values = $_;
    [ "*values-$_",
      _values_to_mnemonic($_),
      \&_values_menu_action,
    ]
  } App::MathImage::Generator->values_choices;
}
sub _values_menu_action {
  my ($self, $itemname) = @_;
  ### Values menu item name: $itemname
  $itemname =~ s/^values-//;
  $self->{'draw'}->gen_options (values => $itemname);
  _update($self);
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
sub _menu_for_path {
  my ($self) = @_;

  return map {
    my $path = $_;
    [ "*path-$_", _path_to_mnemonic($_), \&_path_menu_action,
    ]
  } App::MathImage::Generator->path_choices;
}
sub _path_menu_action {
  my ($self, $itemname) = @_;
  ### _path_menu_action(): "@_"
  $itemname =~ s/^path-//;
  $self->{'draw'}->gen_options (path => $itemname);
  _update($self);
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



#------------------------------------------------------------------------------
# fullscreen

sub toggle_fullscreen {
  my ($self, $itemname) = @_;
  ### toggle_fullscreen(), current: $self->menu->checked($itemname)
  $self->windowState ($self->menu->checked($itemname)
                      ? ws::Normal() : ws::Maximized()); # opposite
}
sub on_windowstate {
  my ($self, $windowstate) = @_;
  ### on_windowstate(): $windowstate
  $self->menu->checked('fullscreen', $windowstate == ws::Maximized());
}

#------------------------------------------------------------------------------
sub help_about {
  my ($self) = @_;
  require App::MathImage::Prima::About;
  App::MathImage::Prima::About->popup;
}
sub help_program {
  my ($self) = @_;
  $::application->open_help (File::Spec->catfile ($FindBin::Bin,
                                                  $FindBin::Script));
}
sub help_path {
  my ($self) = @_;
  my $path = $self->{'draw'}->gen_options->{'path'};
  if (my $module = App::MathImage::Generator->path_choice_to_class ($path)) {
    $::application->open_help ($module);
  }
}
sub help_values {
  my ($self) = @_;
  my $values = $self->{'draw'}->gen_options->{'values'};
  if (my $module = App::MathImage::Generator->values_choice_to_class($values)){
    $::application->open_help ($module);
  }
}
sub help_oeis {
  my ($self) = @_;
  if (my $url = _oeis_url($self)) {
    require Browser::Open;
    Browser::Open::open_browser ($url);
  }
}
sub _oeis_url {
  my ($self) = @_;
  my ($values_seq, $anum);
  return (($values_seq = $self->{'draw'}->gen_object->values_seq)
          && ($anum = $values_seq->oeis_anum)
          && "http://oeis.org/$anum");
}

sub draw_centre {
  my ($self) = @_;
  my $draw = $self->{'draw'};
  my $gen_options = $draw->gen_options;
  if ($gen_options->{'x_offset'} || $gen_options->{'y_offset'}) {
    $draw->gen_options->{'x_offset'} = 0;
    $draw->gen_options->{'y_offset'} = 0;
    $draw->redraw;
  }
}

sub Drawing_MouseMove {
  my ($self, $modifiers, $x, $y) = @_;
  ### Draw_Mousemove() ...
  my $draw = $self->{'draw'};
  # Generator based on 0 at top, so reverse $y
  my $message = $draw->gen_object->xy_message ($x,
                                               $draw->height-1 - $y);
  ### $message
  my $statusbar = $self->{'statusbar'};
  $statusbar->text ($message);
}

# sub save_as {
#   my ($action, $self) = @_;
#   require App::MathImage::Prima::SaveDialog;
#   my $dialog = ($self->{'save_dialog'}
#                 ||= App::MathImage::Prima::SaveDialog->new
#                 (draw => $self->{'draw'},
#                  transient_for => $self));
#   $dialog->present;
# }
# sub setroot {
#   my ($action, $self) = @_;
#   Prima::Ex::WidgetCursor->busy;
# 
#   my $draw = $self->{'draw'};
#   my $rootwin = Prima::Gdk->get_default_root_window;
#   my ($width, $height) = $rootwin->get_size;
# 
#   require App::MathImage::Generator;
#   my $gen = App::MathImage::Generator->new
#     (values     => $draw->get('values'),
#      path       => $draw->get('path'),
#      scale      => $draw->get('scale'),
#      fraction   => $draw->get('fraction'),
#      width      => $width,
#      height     => $height,
#      foreground => $draw->style->fg($self->state),
#      background => $draw->style->bg($self->state));
# 
#   require Image::Base::Prima::Drawable;
#   my $image = Image::Base::Prima::Drawable->new
#     (-for_window => $rootwin,
#      -width      => $width,
#      -height     => $height);
#   $gen->draw_Image ($image);
# 
#   $rootwin->set_back_pixmap ($image->get('-pixmap'));
#   $rootwin->clear;
# }


#------------------------------------------------------------------------------
# printer

sub print_image {
  my ($self) = @_;
  require Prima::PrintDialog;
  my $dialog = Prima::PrintSetupDialog->create;
  if ($dialog->execute) {
    _draw_to_printer($self);
  }
}

sub _draw_to_printer {
  my ($self) = @_;
  my $printer = $::application->get_printer;
  if (! $printer->begin_doc(__('Math-Image'))) {
    warn "Print begin_doc() failed: $@\n";
    return;
  }

  my $draw = $self->{'draw'};
  my $gen_options = $draw->gen_options;
  my $gen = App::MathImage::Generator->new
    (step_time       => 0.25,
     step_figures    => 1000,
     %$gen_options,
     #      foreground => $self->style->fg($self->state)->to_string,
     #      background => $background_colorobj->to_string,
    );

  my $printer_width = $printer->width;
  my $printer_height = $printer->height;

  $printer->font->size(12);  # in points
  # ### fonts: $printer->fonts

  my $str = $gen->description . "\n\n";
  my $str_height = $printer->draw_text
    ($str, 0,10, $printer_width,$printer_height-10,
     dt::Left | dt::NewLineBreak | tw::WordBreak | dt::UseExternalLeading
     | dt::QueryHeight);
  ### $str
  ### $str_height
  ### font height: $printer->font->height

  ### clipRect is: $printer->clipRect
  # $printer->clipRect (0, 0, $printer_width, $printer_height);
  # $printer->translate (0, 20);  # up from bottom of page
  my $factor = max ($printer_width / $draw->width,
                    ($printer_height-10-5) / $draw->height);
  $gen->{'scale'} *= $factor,

  ### draw width: $draw->width
  ### draw height: $draw->height
  ### printer width: $printer->width
  ### printer height: $printer->height
  ### $factor
  ### $gen_options

  require Image::Base::Prima::Drawable;
  my $image = Image::Base::Prima::Drawable->new (-drawable => $printer);
  ### printer width:  $image->get('-width')
  ### printer height: $image->get('-height')

  $gen->draw_Image ($image);
  ### printer end_doc() ...


  $printer->translate (0, 0);  # up from bottom of page
  $printer->color (cl::White);
  $printer->bar (0, $printer_height-10-$str_height-5,
                  $printer_width, $printer_height);

  $printer->color (cl::Black);
  $printer->draw_text
    ($str, 0,10, $printer_width,$printer_height-10,
     dt::Left | dt::NewLineBreak | tw::WordBreak | dt::UseExternalLeading
     | dt::QueryHeight);

  $printer->end_doc;
  ### printer done ...
}


#------------------------------------------------------------------------------
# command line

sub command_line {
  my ($class, $mathimage) = @_;
  ### Prima command_line(): $mathimage

  my $gen_options = $mathimage->{'gen_options'};
  my $mainwin = $class->new
    (gui_options => $mathimage->{'gui_options'},
     gen_options => $gen_options);
  Prima->run;
  return 0;
}

1;
__END__
