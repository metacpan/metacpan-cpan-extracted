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


package App::MathImage::Wx::Main;
use strict;
use Wx;
use Wx::Event 'EVT_MENU';
use Locale::TextDomain ('App-MathImage');

use App::MathImage::Generator;
use App::MathImage::Wx::Drawing;
use App::MathImage::Wx::Params;

use base qw(Wx::Frame);

# uncomment this to run the ### lines
# use Smart::Comments;


our $VERSION = 110;

sub new {
  my ($class, $parent, $id, $title) = @_;
  if (! defined $title) { $title = __('Math-Image'); }
  my $self = $class->SUPER::new ($parent,
                                 $id || Wx::wxID_ANY(),
                                 $title);
  $self->{'position_status'} = '';

  # load an icon and set it as frame icon
  $self->SetIcon (Wx::GetWxPerlIcon());

  my $menubar = Wx::MenuBar->new;
  $self->SetMenuBar ($menubar);

  {
    my $menu = Wx::Menu->new;
    $menubar->Append ($menu, __('&File'));

    $menu->Append (Wx::wxID_PRINT(),
                   '',
                   Wx::GetTranslation('Print the image.'));
    EVT_MENU ($self, Wx::wxID_PRINT(), 'print_image');

    $menu->Append (Wx::wxID_PREVIEW(),
                   '',
                   Wx::GetTranslation('Preview image print.'));
    EVT_MENU ($self, Wx::wxID_PREVIEW(), 'print_preview');

    $menu->Append (Wx::wxID_PRINT_SETUP(),
                   Wx::GetTranslation('Print &Setup'),
                   Wx::GetTranslation('Setup page print.'));
    EVT_MENU ($self, Wx::wxID_PRINT_SETUP(), 'print_setup');

    $menu->Append(Wx::wxID_EXIT(),
                  '',
                  __('Exit the program'));
    EVT_MENU ($self, Wx::wxID_EXIT(), 'quit');
  }
  {
    my $menu = Wx::Menu->new;
    $menubar->Append ($menu, __('&Tools'));
    {
      my $item = $self->{'fullscreen_menuitem'} =
        $menu->Append (Wx::wxID_ANY(),
                       __("&Fullscreen\tCtrl-F"),
                       __("Toggle full screen or normal window (use accelerator Ctrl-F to return from fullscreen)."),
                       Wx::wxITEM_CHECK());
      EVT_MENU ($self, $item, 'toggle_fullscreen');
      Wx::Event::EVT_UPDATE_UI ($self, $item, \&_update_ui_fullscreen_menuitem);
    }
    {
      my $item = $menu->Append(Wx::wxID_ANY(),
                               __("&Centre\tCtrl-C"),
                               __('Scroll to centre the origin 0,0 on screen (or at the left or bottom if no negatives in the path).'));
      EVT_MENU ($self, $item, '_menu_centre');
    }
    {
      my $submenu = Wx::Menu->new;
      $menu->AppendSubMenu ($submenu, __('&Toolbar'));
      {
        my $item = $submenu->AppendRadioItem
          (Wx::wxID_ANY(),
           __("&Horizontal"),
           __('Toolbar horizontal across the top of the window.'));
        EVT_MENU ($self, $item, '_toolbar_horizontal');
      }
      {
        my $item = $submenu->AppendRadioItem
          (Wx::wxID_ANY(),
           __("&Vertical"),
           __('Toolbar vertically at the left of the window.'));
        EVT_MENU ($self, $item, '_toolbar_vertical');
      }
      {
        my $item = $submenu->AppendRadioItem
          (Wx::wxID_ANY(),
           __("Hi&de"),
           __('Hide the toolbar.'));
        EVT_MENU ($self, $item, '_toolbar_hide');
      }
    }
  }
  {
    my $menu = $self->{'help_menu'} = Wx::Menu->new;
    $menubar->Append ($menu, __('&Help'));

    $menu->Append (Wx::wxID_ABOUT(),
                   '',
                   __('Show about dialog'));
    EVT_MENU ($self, Wx::wxID_ABOUT(), 'popup_about');

    {
      my $item = $menu->Append (Wx::wxID_ANY(),
                                __('&Program POD'),
                                __('Show the values POD'));
      EVT_MENU ($self, $item, 'popup_program_pod');
    }
    {
      my $item = $menu->Append (Wx::wxID_ANY(),
                                __('Pa&th POD'),
                                __('Show the program POD'));
      EVT_MENU ($self, $item, 'popup_path_pod');
    }
    {
      my $item = $menu->Append (Wx::wxID_ANY(),
                                __('&Values POD'),
                                __('Show the path POD'));
      EVT_MENU ($self, $item, 'popup_values_pod');
    }
    {
      my $item
        = $self->{'help_oeis_menuitem'}
          = $menu->Append (Wx::wxID_ANY(),
                           __('&OEIS Web Page'),
                           ''); # tooltip set by _oeis_browse_update()
      EVT_MENU ($self, $item, 'oeis_browse');
    }
    {
      my $item = $menu->Append (Wx::wxID_ANY(),
                                __('Dia&gnostics'),
                               __('Show some diagnostic sizes and statistics.'));
      EVT_MENU ($self, $item, 'popup_diagnostics');
    }
  }

  {
    my $toolbar = $self->{'toolbar'} = $self->CreateToolBar;
    # (Wx::wxTB_VERTICAL());

    # my $bitmap = Wx::Bitmap->new (10,10);
    # $toolbar->AddTool(Wx::wxID_ANY(),
    #                   __('&Randomize'),
    #                   $bitmap, # Wx::wxNullBitmap(),
    #                   "Random path, values, etc",
    #                   Wx::wxITEM_NORMAL());
    # EVT_MENU ($self, $item, 'randomize');

    {
      my $button = Wx::Button->new ($toolbar, Wx::wxID_ANY(), __('Randomize'));
      $toolbar->AddControl($button);
      $toolbar->SetToolShortHelp ($button->GetId,
                                  __("Random path, values, etc"));
      Wx::Event::EVT_BUTTON ($self, $button, 'randomize');
    }

    {
      my $choice = $self->{'path_choice'}
        = Wx::Choice->new ($toolbar,
                           Wx::wxID_ANY(),
                           Wx::wxDefaultPosition(),
                           Wx::wxDefaultSize(),
                           [App::MathImage::Generator->path_choices]);
      # 0,  # style
      # Wx::wxDefaultValidator(),
      $toolbar->AddControl($choice);
      $toolbar->SetToolShortHelp
        ($choice->GetId,
         __('The path for where to place values in the plane.'));
      Wx::Event::EVT_CHOICE ($self, $choice, 'path_update');

      my $path_params = $self->{'path_params'}
        = App::MathImage::Wx::Params->new
          (toolbar    => $toolbar,
           after_item => $choice,
           callback   => sub { path_params_update($self) });
    }

    {
      my $choice = $self->{'values_choice'}
        = Wx::Choice->new ($toolbar,
                           Wx::wxID_ANY(),
                           Wx::wxDefaultPosition(),
                           Wx::wxDefaultSize(),
                           [App::MathImage::Generator->values_choices]);
      $toolbar->AddControl($choice);
      $toolbar->SetToolShortHelp
        ($choice->GetId,
         __('The values to show.'));
      Wx::Event::EVT_CHOICE ($self, $choice, 'values_update');

      my $values_params = $self->{'values_params'}
        = App::MathImage::Wx::Params->new
          (toolbar => $toolbar,
           after_item => $choice,
           callback => sub { values_params_update($self) });
    }

    #    $toolbar->AddSeparator;

    {
      my $choice = $self->{'filter_choice'}
        = Wx::Choice->new ($toolbar,
                           Wx::wxID_ANY(),
                           Wx::wxDefaultPosition(),
                           Wx::wxDefaultSize(),
                           [ App::MathImage::Generator->filter_choices_display ]);
      $toolbar->AddControl($choice);
      $toolbar->SetToolShortHelp
        ($choice->GetId,
         __('Filter the values to only odd, or even, or primes, etc.'));
      Wx::Event::EVT_CHOICE ($self, $choice, 'filter_update');
    }
    {
      my $spin = $self->{'scale_spin'}
        = Wx::SpinCtrl->new ($toolbar,
                             Wx::wxID_ANY(),
                             3,  # initial value
                             Wx::wxDefaultPosition(),
                             Wx::Size->new(40,-1),
                             Wx::wxSP_ARROW_KEYS(),
                             1,                  # min
                             POSIX::INT_MAX(),   # max
                             3);                 # initial
      $toolbar->AddControl($spin);
      $toolbar->SetToolShortHelp ($spin->GetId,
                                  __('How many pixels per square.'));
      Wx::Event::EVT_SPINCTRL ($self, $spin, 'scale_update');
    }
    {
      my @figure_display = map {ucfirst}
        App::MathImage::Generator->figure_choices;
      $figure_display[0] = __('Figure');
      my $choice = $self->{'figure_choice'}
        = Wx::Choice->new ($toolbar,
                           Wx::wxID_ANY(),
                           Wx::wxDefaultPosition(),
                           Wx::wxDefaultSize(),
                           \@figure_display);
      $toolbar->AddControl($choice);
      $toolbar->SetToolShortHelp
        ($choice->GetId,
         __('The figure to draw at each position.'));
      Wx::Event::EVT_CHOICE ($self, $choice, 'figure_update');
    }
  }

  $self->CreateStatusBar;

  my $draw = $self->{'draw'} = App::MathImage::Wx::Drawing->new ($self);
  _controls_from_draw ($self);
  # $self->values_update_tooltip;
  # _oeis_browse_update($self);

  ### Wx-Main new() done ...
  return $self;
}

use constant FULLSCREEN_HIDE_BITS => Wx::wxFULLSCREEN_ALL();
# & ~ Wx::wxFULLSCREEN_NOMENUBAR();
sub toggle_fullscreen {
  my ($self, $event) = @_;
  ### Wx-Main toggle_fullscreen() ...
  $self->ShowFullScreen (! $self->IsFullScreen, FULLSCREEN_HIDE_BITS);
}
sub _update_ui_fullscreen_menuitem {
  my ($self, $event) = @_;
  ### Wx-Main _update_ui_fullscreen_menuitem: "@_"
  # though if FULLSCREEN_HIDE_BITS hides the menubar then the item won't be
  # seen when checked ...
  $self->{'fullscreen_menuitem'}->Check ($self->IsFullScreen);
}
sub _menu_centre {
  my ($self, $event) = @_;
  ### Main _menu_fullscreen() ...

  my $draw = $self->{'draw'};
  if ($draw->{'x_offset'} != 0 || $draw->{'y_offset'} != 0) {
    $draw->{'x_offset'} = 0;
    $draw->{'y_offset'} = 0;
    $draw->redraw;
  }
}

sub _toolbar_horizontal {
  my ($self, $event) = @_;
  ### _toolbar_horizontal() ...
  my $toolbar = $self->{'toolbar'};
  $self->SetToolBar(undef);

  my $style = $toolbar->GetWindowStyleFlag;
  $style &= ~ Wx::wxTB_VERTICAL();
  $style |= Wx::wxTB_HORIZONTAL();
  $toolbar->SetWindowStyleFlag($style);
  $toolbar->SetSize (Wx::wxDefaultSize());

  $toolbar->Show;  # if previously hidden
  $self->SetToolBar($toolbar);
  # $toolbar->SetSize ($toolbar->GetBestSize);
  ### toolbar horizontal GetBestSize: $toolbar->GetBestSize->GetWidth, $toolbar->GetBestSize->GetHeight
  ### toolbar sizer: $toolbar->GetSizer
}
sub _toolbar_vertical {
  my ($self, $event) = @_;
  my $toolbar = $self->{'toolbar'};
  $self->SetToolBar(undef);

  my $style = $toolbar->GetWindowStyleFlag;
  $style &= ~ Wx::wxTB_HORIZONTAL();
  $style |= Wx::wxTB_VERTICAL();
  $toolbar->SetWindowStyleFlag($style);
  $toolbar->SetSize (Wx::wxDefaultSize());

  $toolbar->Show;  # if previously hidden
  $self->SetToolBar($toolbar);
  # $toolbar->SetSize ($toolbar->GetBestSize);
  ### toolbar vertical GetBestSize: $toolbar->GetBestSize->GetWidth, $toolbar->GetBestSize->GetHeight
  ### toolbar sizer: $toolbar->GetSizer
}
sub _toolbar_hide {
  my ($self, $event) = @_;
  my $toolbar = $self->{'toolbar'};
  $toolbar->Hide;
  $self->SetToolBar(undef);
  $self->SetToolBar($toolbar);
}

sub oeis_browse {
  my ($self, $event) = @_;
  if (my $url = $self->oeis_url) {
    Wx::LaunchDefaultBrowser($url);
  }
}
sub oeis_url {
  my ($self) = @_;
  if (my $anum = $self->oeis_anum) {
    return "http://oeis.org/$anum";
  }
  return undef;
}
sub oeis_anum {
  my ($self) = @_;
  if (my $gen_object = $self->{'draw'}->gen_object_maybe) {
    return $gen_object->oeis_anum;
  }
  return undef;
}

sub randomize {
  my ($self, $event) = @_;
  ### Main randomize() ...

  my $draw = $self->{'draw'};
  my %options = App::MathImage::Generator->random_options;
  @{$draw}{keys %options} = values %options;
  _controls_from_draw ($self);
  $draw->redraw;
  $self->values_update_tooltip;
  _oeis_browse_update($self);
}
sub scale_update {
  my ($self, $event) = @_;
  ### Main scale_update() ...
  my $draw = $self->{'draw'};
  $draw->{'scale'} = $self->{'scale_spin'}->GetValue;
  $draw->redraw;
}
sub filter_update {
  my ($self, $event) = @_;
  ### Main filter_update() ...
  my $draw = $self->{'draw'};
  my @filter_choices = App::MathImage::Generator->filter_choices;
  $draw->{'filter'} = $filter_choices[$self->{'filter_choice'}->GetSelection];
  $draw->redraw;
}
sub figure_update {
  my ($self, $event) = @_;
  ### Main figure_update() ...
  my $draw = $self->{'draw'};
  my @figure_choices = App::MathImage::Generator->figure_choices;
  $draw->{'figure'} = $figure_choices[$self->{'figure_choice'}->GetSelection];
  $draw->redraw;
}
sub path_update {
  my ($self) = @_;  # ($self, $event)
  ### Wx-Main path_update(): "$self"
  my $draw = $self->{'draw'};
  my $path = $draw->{'path'} = $self->{'path_choice'}->GetStringSelection;
  $self->{'path_params'}->SetParameterInfoArray
    (App::MathImage::Generator->path_class($path)->parameter_info_array);
  $draw->redraw;
}
sub path_params_update {
  my ($self) = @_;
  ### Wx-Main path_parameters_update(): "$self"
  my $draw = $self->{'draw'};
  my $path_params = $self->{'path_params'};
  $draw->{'path_parameters'} = $path_params->GetParameterValues;
  $draw->redraw;
}
sub values_update {
  my ($self, $event) = @_;
  ### Wx-Main values_update() ...
  my $draw = $self->{'draw'};
  my $values = $draw->{'values'} = $self->{'values_choice'}->GetStringSelection;
  $self->{'values_params'}->SetParameterInfoArray
    ($self->values_parameter_info_array);
  $draw->redraw;
  $self->values_update_tooltip;
  _oeis_browse_update($self);
}
sub values_parameter_info_array {
  my ($self) = @_;
  my $values = $self->{'values_choice'}->GetStringSelection;
  my $aref = App::MathImage::Generator->values_class($values)->parameter_info_array;
  foreach my $i (0 .. $#$aref) {
    if ($aref->[$i]->{'name'} eq 'planepath') {
      require Clone::PP;
      $aref = Clone::PP::clone($aref);
      $aref->[$i]->{'default'} = 'ThisPath';
      unshift @{$aref->[$i]->{'choices'}}, 'ThisPath';
      if ($aref->[$i]->{'choices_display'}) {
        unshift @{$aref->[$i]->{'choices_display'}}, 'This Path';
      }
      last;
    }
  }
  ### $aref
  return $aref;
}
sub values_params_update {
  my ($self) = @_;
  ### Wx-Main values_parameters_update(): "$self"
  my $draw = $self->{'draw'};
  my $values_params = $self->{'values_params'};
  $draw->{'values_parameters'} = $values_params->GetParameterValues;
  ### values_parameters: $draw->{'values_parameters'}
  $draw->redraw;
  $self->values_update_tooltip;
  _oeis_browse_update($self);
}
sub values_update_tooltip {
  my ($self) = @_;
  ### Wx-Main values_update_tooltip() ...

  my $tooltip = __('The values to display.');
  my $values_choice = $self->{'values_choice'};

  if (my $gen_object = $self->{'draw'}->gen_object_maybe) {
    if (my $values_seq = $gen_object->values_seq_maybe) {
      {
        my $name = $values_choice->GetStringSelection;
        $tooltip .= "\n\n" . __x('Current setting: {name}', name => $name);
      }
      if (my $desc = $values_seq->description) {
        $tooltip .= "\n" . $desc;
      }
      if (my $anum = $values_seq->oeis_anum) {
        $tooltip .= "\n" . __x('OEIS {anum}', anum => $anum);
      }
    }
  }

  my $toolbar = $self->{'toolbar'};
  $toolbar->SetToolShortHelp ($values_choice->GetId, $tooltip);
}
sub _oeis_browse_update {
  my ($self) = @_;
  my $item = $self->{'help_oeis_menuitem'};
  my $menu = $self->{'help_menu'};
  my $url = $self->oeis_url;
  $menu->Enable ($item, defined($url));
  $menu->SetHelpString ($item->GetId,
                        __x("Open browser at Online Encyclopedia of Integer Sequences (OEIS) web page for the current values\n{url}",
                            url => ($url||'')));
}



sub _controls_from_draw {
  my ($self) = @_;
  ### _controls_from_draw() ...
  ### path: $self->{'draw'}->{'path'}
  ### path_parameters: $self->{'draw'}->{'path_parameters'}
  ### values: $self->{'draw'}->{'values'}
  ### draw seq: ($self->{'draw'}->gen_object->values_seq || '').''

  my $draw = $self->{'draw'};
  my $path = $draw->{'path'};
  $self->{'path_choice'}->SetStringSelection ($path);
  $self->{'path_params'}->SetParameterInfoArray
    (App::MathImage::Generator->path_class($path)->parameter_info_array);
  $self->{'path_params'}->SetParameterValues ($draw->{'path_parameters'} || {});

  my $values = $draw->{'values'};
  $self->{'values_choice'}->SetStringSelection ($values);
  $self->{'values_params'}->SetParameterInfoArray
    ($self->values_parameter_info_array);
  $self->{'values_params'}->SetParameterValues ($draw->{'values_parameters'} || {});

  $self->{'scale_spin'}->SetValue ($draw->{'scale'});
  $self->{'figure_choice'}->SetStringSelection ($draw->{'figure'});

  $self->values_update_tooltip;
  _oeis_browse_update($self);
}

sub quit {
  my ($self, $event) = @_;
  $self->Close;
}

#------------------------------------------------------------------------------
# help

sub popup_about {
  my ($self) = @_;
  Wx::AboutBox($self->about_dialog_info);
}
sub about_dialog_info {
  my ($self) = @_;

  my $info = Wx::AboutDialogInfo->new;
  $info->SetName(__("Math-Image"));
  # $info->SetIcon('...');
  $info->SetVersion($self->VERSION);
  $info->SetWebSite('http://user42.tuxfamily.org/math-image/index.html');

  $info->SetDescription(__x("Display some mathematical images.

You are running under: Perl {perlver}, wxPerl {wxperlver}, Wx {wxver}",
                            perlver    => sprintf('%vd', $^V),
                            wxver      => Wx::wxVERSION_STRING(),
                            wxperlver  => Wx->VERSION));

  $info->SetCopyright(__x("Copyright 2010, 2011, 2012 Kevin Ryde

Math-Image is Free Software, distributed under the terms of the GNU General
Public License as published by the Free Software Foundation, either version
3 of the License, or (at your option) any later version.  Click on the
License button below for the full text.

Math-Image is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the license for more.
"));

  # the same as COPYING in the sources
  require Software::License::GPL_3;
  my $sl = Software::License::GPL_3->new({ holder => 'Kevin Ryde' });
  $info->SetLicense ($sl->license);

  return $info;
}

sub popup_program_pod {
  my ($self) = @_;
  $self->popup_pod('math-image');
}
sub popup_path_pod {
  my ($self) = @_;
  my $draw = $self->{'draw'};
  if (my $path = $draw->{'path'}) {
    if (my $module = App::MathImage::Generator->path_choice_to_class ($path)) {
      $self->popup_pod($module);
    }
  }
}
sub popup_values_pod {
  my ($self) = @_;
  my $draw = $self->{'draw'};
  if (my $values = $draw->{'values'}) {
    if ((my $module = App::MathImage::Generator->values_choice_to_class($values))) {
      $self->popup_pod($module);
    }
  }
}
sub popup_pod {
  my ($self, $module) = @_;
  ### popup_pod(): $module
  if (eval { require Wx::Perl::PodBrowser }) {
    my $browser = Wx::Perl::PodBrowser->new;
    $browser->Show;
    $browser->goto_pod (module => $module);
  } else {
    Wx::MessageBox (__('Wx::Perl::PodBrowser not available')."\n\n$@",
                    __('Math-Image: Error'),
                    Wx::wxICON_ERROR(),
                    $self);
  }
}
sub popup_diagnostics {
  my ($self) = @_;
  require App::MathImage::Wx::Diagnostics;
  my $dialog = App::MathImage::Wx::Diagnostics->new ($self);
  $dialog->Show;
}

#------------------------------------------------------------------------------
# status

sub mouse_motion {
  my ($self, $event) = @_;
  ### Wx-Main mouse_motion() ...
  my $message = '';
  if ($event) {
    if (my $gen_object = $self->{'draw'}->gen_object_maybe) {
      ### xy: $event->GetX.','.$event->GetY
      $message = $gen_object->xy_message ($event->GetX, $event->GetY);
      ### $message
    }
  }
  $self->set_position_status ($message);
}
sub set_position_status {
  my ($self, $message) = @_;
  if ($self->{'position_status'} ne $message) {
    $self->SetStatusText ($message);
    $self->{'position_status'} = $message;
  }
}

#------------------------------------------------------------------------------
# cf Wx::DemoModules::wxPrinting
#    /usr/share/doc/wx2.8-examples/examples/samples/printing/printing.cpp.gz

use constant::defer page_setup_dialog_data => sub {
  require Wx::Print;
  my $page_setup_dialog_data = Wx::PageSetupDialogData->new;
  $page_setup_dialog_data->SetDefaultMinMargins(1);
  $page_setup_dialog_data->SetMarginTopLeft (Wx::Point->new(25,25));
  $page_setup_dialog_data->SetMarginBottomRight (Wx::Point->new(25,25));
  return $page_setup_dialog_data;
};

sub print_image {
  my ($self) = @_;
  require Wx::Print;
  my $printer = Wx::Printer->new;
  $printer->Print ($self,
                   $self->printout_object,
                   1); # popup the print dialog
}
sub print_preview {
  my ($self) = @_;
  require Wx::Print;
  my $previewout = $self->printout_object;
  my $printout = $self->printout_object;
  my $preview = Wx::PrintPreview->new ($previewout, $printout);
  my $frame = Wx::PreviewFrame->new ($preview,
                                       $self,  # parent
                                       __('Math-Image: Print Preview'));
  $frame->Initialize;
  $frame->Show(1);
}
sub print_setup {
  my ($self) = @_;
  require Wx::Print;
  my $dialog = Wx::PageSetupDialog->new ($self, $self->page_setup_dialog_data);
  $dialog->ShowModal;
}
sub printout_object {
  my ($self) = @_;
  return App::MathImage::Wx::Printout->new ($self);
}

{
  package App::MathImage::Wx::Printout;
  use strict;
  use Wx;
  use List::Util 'min';
  use Locale::TextDomain ('App-MathImage');

  our @ISA = ('Wx::Printout');
  sub new {
    my ($class, $main) = @_;
    ### Printout new() ...

    my $self = $class->SUPER::new (__('Math-Image'));
    $self->{'main'} = $main;
    return $self;
  }

  sub GetPageInfo {
    my ($self) = @_;
    ### Printout GetPageInfo() ...
    return (0,  # minpage
            1,  # maxpage
            1,  # pagefrom
            1); # pageto
  }
  sub HasPage {
    my ($self, $pagenum) = @_;
    ### Printout HasPage(): $pagenum
    return ($pagenum <= 1);
  }
  sub OnPrintPage {
    my ($self, $pagenum) = @_;
    ### Printout OnPrintPage(): $pagenum

    my $main = $self->{'main'};
    my $draw = $main->{'draw'};
    my $gen = $draw->gen_object;

    my $dc = $self->GetDC;
    ### $dc
    # something fishy in wx 2.8.12 that it needs a SetFont or there's no
    # scale command emitted in the postscript, or some such
    if (my $font = $dc->GetFont) { $dc->SetFont($font); }
    #
    # Or could force a particular font instead of the default.
    # $dc->SetFont (Wx::Font->new (12,
    #                              Wx::wxFONTFAMILY_ROMAN(),
    #                              Wx::wxFONTSTYLE_NORMAL(),
    #                              Wx::wxFONTWEIGHT_NORMAL()));

    my $bitmap = $draw->bitmap
      || return 0;  # no bitmap, cancel print
    my $bitmap_width = $bitmap->GetWidth;
    my $bitmap_height = $bitmap->GetHeight;

    my $page_setup_dialog_data = $main->page_setup_dialog_data;
    ### $page_setup_dialog_data

    # FIXME: take into account the height of the description text
    $self->FitThisSizeToPageMargins
      (Wx::Size->new($bitmap_width,$bitmap_height),
       $page_setup_dialog_data);

    my $y = 0;
    {
      my ($dc_width, $dc_height) = $dc->GetSizeWH;
      ### $dc_width
      ### $dc_height

      my $str = $gen->description;

      # $y = _dc_draw_text_word_wrap($dc,$str,$dc_width-2*$border_width);
      # $dc->SetDeviceOrigin ($border_width, $border_height + $y);
      # return;
      # $str = _dc_word_wrap_str($dc,$str,$dc_width-$border_width);

      $str .= "\n\n";  # followed by blank line
      ### $str
      ### extents: $dc->GetTextExtent($str)

      my $boundrect = $dc->DrawLabel ($str,
                                      Wx::wxNullBitmap(),
                                      Wx::Rect->new(0,0,$dc_width,$dc_height));
      $y = $boundrect->GetHeight;
    }
    {
      # my $xscale = $dc_width / $bitmap_width;
      # my $yscale = ($dc_height-$y) / $bitmap_height;
      # my $scale = min ($xscale, $yscale);
      # $dc->SetUserScale($scale, $scale);
      # ### $scale

      my $x = 0; # ($dc_width - $bitmap_width) / 2;
      ### $x
      ### $y

      $dc->DrawBitmap ($bitmap,
                       $x,$y,
                       0);     # not transparent
    }
    return 1; # good, don't cancel the job
  }

  sub _dc_draw_text_word_wrap {
    my ($dc, $str, $max_width) = @_;
    ### $max_width
    ### scale: $dc->GetUserScale
    my $fmt = Wx::wxC2S_HTML_SYNTAX();
    ### text foreground: $dc->GetTextForeground->GetAsString($fmt)
    ### text background: $dc->GetTextBackground->GetAsString($fmt)

    my $line = '';
    my $y = 0;
    while ($str =~ /\G(\s*(\S+))/g) {
      my $more = $1;
      my $moreword = $2;
      my ($width,$height,$descent,$leading) = $dc->GetTextExtent($line.$more);
      ### $more
      ### $width
      ### $height
      if ($line eq '' || $width <= $max_width) {
        $line .= $more;
      } else {
        ### $line
        ### $y
        $dc->DrawText ($line, 0, $y);
        $y += $height + $descent + $leading;
        $line = $moreword;
      }
    }

    if ($line ne '') {
      ### final line: $line
      my ($width,$height,$descent,$leading) = $dc->GetTextExtent($line);
      $dc->DrawText ($line, 0, $y);
      $y += $height + $descent + $leading;
    }

    ### final y: $y
    return $y;
  }

  sub _dc_word_wrap_str {
    my ($dc, $str, $max_width) = @_;
    ### $max_width

    my $ret = '';
    my $line = '';
    while ($str =~ /\G(\s*(\S+))/g) {
      my $more = $1;
      my $moreword = $2;
      my ($width,$height,$descent,$leading) = $dc->GetTextExtent($line.$more);
      ### $more
      ### $width
      ### $height
      if ($line eq '' || $width <= $max_width) {
        $line .= $more;
      } else {
        $ret .= "$line\n";
        $line = $moreword;
      }
    }
    return $ret . $line;
  }
}

#------------------------------------------------------------------------------
# command line

sub command_line {
  my ($class, $mathimage) = @_;
  ### Wx-Main command_line() ...

  my $app = Wx::SimpleApp->new;
  $app->SetAppName(__('Math Image'));

  my $gen_options = $mathimage->{'gen_options'};
  my $width = delete $gen_options->{'width'};
  my $height = delete $gen_options->{'height'};

  my $self = $class->new();

  my $draw = $self->{'draw'};
  {
    ### foreground: $gen_options->{'foreground'}
    my $wxc = Wx::Colour->new (delete $gen_options->{'foreground'});
    $draw->SetForegroundColour($wxc);
  }
  { my $wxc = Wx::Colour->new (delete $gen_options->{'background'});
    $draw->SetBackgroundColour($wxc);
  }

  ### command_line draw: $gen_options
  %$draw = (%$draw,
            %$gen_options);
  $draw->redraw;
  _controls_from_draw ($self);

  if (defined $width) {
    #   require Wx::Perl::Units;
    #   Wx::Perl::Units::SetInitialSizeWithSubsizes
    #       ($self, [ $draw, $width, $height ]);

    $draw->SetSize ($width, $height);
    my $size = $self->GetBestSize;
    $draw->SetSize (-1,-1);

    ### $width
    ### $height
    ### best width: $size->GetWidth
    ### best height: $size->GetHeight
    $self->SetSize ($size);

  } else {
    my $screen_size = Wx::GetDisplaySize();
    $self->SetSize (Wx::Size->new ($screen_size->GetWidth * 0.8,
                                   $screen_size->GetHeight * 0.8));
  }

  if (delete $mathimage->{'gui_options'}->{'fullscreen'}) {
    $self->ShowFullScreen(1, FULLSCREEN_HIDE_BITS)
  } else {
    $self->Show;
  }
  $app->MainLoop;
  return 0;

  # my $path_parameters = delete $gen_options->{'path_parameters'};
  # my $values_parameters = delete $gen_options->{'values_parameters'};
  # ### draw set gen_options: keys %$gen_options
  # foreach my $key (keys %$gen_options) {
  #   $draw->set ($key, $gen_options->{$key});
  # }
  # $draw->set (path_parameters => $path_parameters);
  # $draw->set (values_parameters => $values_parameters);
  # ### draw values now: $draw->get('values')
  # ### values_parameters: $draw->get('values_parameters')
  # ### path: $draw->get('path')
  # ### path_parameters: $draw->get('path_parameters')
}

1;
__END__

=for stopwords Ryde menubar multi Wx

=head1 NAME

App::MathImage::Wx::Main -- math-image wxWidgets main window

=head1 SYNOPSIS

 use App::MathImage::Wx::Main;
 my $main = App::MathImage::Wx::Main->new;
 $main->Show;

=head1 CLASS HIERARCHY

C<App::MathImage::Wx::Main> is a C<Wx::Frame> toplevel window.

    Wx::Object
      Wx::EvtHandler
        Wx::Window
          Wx::TopLevelWindow
            Wx::Frame
              App::MathImage::Wx::Main

=head1 DESCRIPTION

This is the main toplevel window for the math-image program wxWidgets
interface.

=cut

# math-image --text --size 43x10

=pod

    +-------------------------------------------+
    | File  Tools  Help                         |
    +-------------------------------------------+
    | Randomize   Square Spiral   Primes ...    |
    +-------------------------------------------+
    |  *   *   *   * *   *       *   * *        |
    |                     * *   *               |
    |*   *       *   * *     * * *     * * *    |
    | *   * * * * * * * *   *       *         * |
    |                    * * *           *      |
    | *             *   *  ** * * *   * * *     |
    |*       *       * * *                      |
    |                 *   *                     |
    |*     *   * *   * *   *   * *   *   * *   *|
    |   *     *   *   *     *     * *   *       |
    +-------------------------------------------+
    | x=9, y=4  N=302                           |
    +-------------------------------------------+

=head1 FUNCTIONS

=over 4

=item C<< $main = App::MathImage::Wx::Main->new () >>

=item C<< $main = App::MathImage::Wx::Main->new ($parent, $id, $title) >>

Create and return a new main window.

The optional C<$parent>, C<$id> and C<$title> arguments are per
C<< Wx::Frame->new() >>.  Usually they can be omitted for a standalone
window.

=back

=head2 Methods

=over

=item C<< $main->randomize () >>

Display a random combination of path, values, figure, etc.  This is the
toolbar randomize button.

=item C<< $main->toggle_fullscreen () >>

Toggle the window between fullscreen and normal.  This is the
Tools/Fullscreen menu entry.

=back

=head2 Help

=over 4

=item C<< $main->popup_program_pod() >>

=item C<< $main->popup_path_pod() >>

=item C<< $main->popup_values_pod() >>

Open a C<Wx::Perl::PodBrowser> window showing the POD documentation for
either the C<math-image> program, the currently selected path module, or
currently selected values module.  These are the "Help/Program POD" etc menu
entries.

=item C<< $main->oeis_browse() >>

Open a web browser on the OEIS page for the currently selected sequence.
This is the Help/OEIS menu entry.

=back

=head2 About

=over 4

=item C<< $main->popup_about_dialog() >>

Open the "about" dialog for C<$main>.  This is the Help/About menu entry.
It displays a C<Wx::AboutBox()> with the C<< $main->about_dialog_info() >>
below.

=item C<< $info = $main->about_dialog_info() >>

Return a C<Wx::AboutDialogInfo> object with information about C<$main>.

=back

=head1 SEE ALSO

L<Wx>,
L<math-image>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-image/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013 Kevin Ryde

Math-Image is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-Image is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-Image.  If not, see L<http://www.gnu.org/licenses/>.

=cut
