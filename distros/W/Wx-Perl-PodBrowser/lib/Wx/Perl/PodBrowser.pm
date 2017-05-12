# Copyright 2011, 2012, 2013, 2014, 2017 Kevin Ryde

# This file is part of Wx-Perl-PodBrowser.
#
# Wx-Perl-PodBrowser is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Wx-Perl-PodBrowser is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Wx-Perl-PodBrowser.  If not, see <http://www.gnu.org/licenses/>.


# Maybe $browser = Wx::Perl::PodBrowser->goto_pod (module => $module)
# for combined new(), Show(), goto_pod().
#
# Maybe:
# $podrichtext->goto_pod (forward => $n)
# $podrichtext->goto_pod (backward => $n)
# $podrichtext->goto_pod (source => $bool)   # show pod source
#                         source_linenum => 
#
# Option to close pod window when main win destroyed.


package Wx::Perl::PodBrowser;
use 5.008;
use strict;
use warnings;
use Carp;
use Wx;
use Wx::Event 'EVT_MENU';
use Wx::Perl::PodRichText;

use base 'Wx::Frame';
our $VERSION = 15;

# uncomment this to run the ### lines
# use Smart::Comments;


sub new {
  my ($class, $parent, $id, $title, @rest) = @_;
  if (! defined $id) { $id = Wx::wxID_ANY(); }
  if (! defined $title) { $title = Wx::GetTranslation('POD Browser'); }

  my $self = $class->SUPER::new ($parent, $id, $title, @rest);
  $self->SetIcon (Wx::GetWxPerlIcon());
  $self->{'url_message'} = '';
  Wx::Event::EVT_CLOSE ($self, \&_do_close_event);

  my $menubar = Wx::MenuBar->new;
  $self->SetMenuBar ($menubar);

  {
    my $menu = Wx::Menu->new;
    $menubar->Append ($menu, Wx::GetTranslation('&File'));

    {
      my $item = $menu->Append (Wx::wxID_ANY(),
                                Wx::GetTranslation('Open &Module'),
                                Wx::GetTranslation('Open a Perl module POD.'));
      EVT_MENU ($self, $item, 'popup_module_dialog');
    }

    $menu->Append (Wx::wxID_OPEN(),
                   '',
                   Wx::GetTranslation('Open a POD file.'));
    EVT_MENU ($self, Wx::wxID_OPEN(), 'popup_file_dialog');

    {
      my $item
        = $self->{'go_back_menuitem'}
          = $menu->Append (Wx::wxID_ANY(),
                           Wx::GetTranslation("&Back\tCtrl-B"),
                           Wx::GetTranslation('Go back to the previous POD.'));
      EVT_MENU ($self, $item, 'go_back');
      Wx::Event::EVT_UPDATE_UI ($self, $item, \&_update_history_menuitems);
    }
    {
      my $item
        = $self->{'go_forward_menuitem'}
          = $menu->Append (Wx::wxID_ANY(),
                           Wx::GetTranslation("&Forward\tCtrl-F"),
                           Wx::GetTranslation('Go forward again.'));
      EVT_MENU ($self, $item, 'go_forward');
    }
    {
      my $item
        = $self->{'reload_menuitem'}
          = $menu->Append (Wx::wxID_ANY(),
                           Wx::GetTranslation('&Reload'),
                           Wx::GetTranslation('Re-read the POD file.'));
      EVT_MENU ($self, $item, 'reload');
    }

    $menu->AppendSeparator;
    $menu->Append (Wx::wxID_PRINT(),
                   '',
                   Wx::GetTranslation('Print the document.'));
    EVT_MENU ($self, Wx::wxID_PRINT(), 'popup_print');

    $menu->Append (Wx::wxID_PREVIEW(),
                   '',
                   Wx::GetTranslation('Preview document print.'));
    EVT_MENU ($self, Wx::wxID_PREVIEW(), 'popup_print_preview');

    $menu->Append (Wx::wxID_PRINT_SETUP(),
                   Wx::GetTranslation('Page &Setup'),
                   Wx::GetTranslation('Printer setups.'));
    EVT_MENU ($self, Wx::wxID_PRINT_SETUP(), 'popup_print_setup');

    $menu->AppendSeparator;
    $menu->Append(Wx::wxID_EXIT(),
                  '',
                  Wx::GetTranslation('Close this window'));
    EVT_MENU ($self, Wx::wxID_EXIT(), 'quit');
  }

  # {
  #   my $menu = Wx::Menu->new;
  #   $menubar->Append ($menu, Wx::GetTranslation('&Edit'));
  #
  #   {
  #     my $item
  #       = $self->{'edit_copy_menuitem'}
  #         = $menu->Append (Wx::wxID_COPY(),
  #                          '',
  #                          Wx::GetTranslation('Copy selected text to the clipboard.'));
  #     EVT_MENU ($self, $item, 'edit_copy');
  #     Wx::Event::EVT_UPDATE_UI ($self, $item, \&_update_can_copy);
  #   }
  #   {
  #     my $item = $menu->Append (Wx::wxID_SELECTALL(),
  #                               '',
  #                               Wx::GetTranslation('Select all text for cut and paste.'));
  #     EVT_MENU ($self, $item, 'edit_select_all');
  #   }
  # }

  {
    my $menu = $self->{'section_menu'} = Wx::Menu->new;
    my $label = $self->{'section_menu_label'} = Wx::GetTranslation('&Section');
    $menubar->Append ($menu, $label);

    # Wx::UpdateUIEvent::SetMode(Wx::wxUPDATE_UI_PROCESS_SPECIFIED());
    # Wx::UpdateUIEvent::SetMode(Wx::wxUPDATE_UI_PROCESS_ALL());
    # No ExtraStyle on menu?
    # $menu->SetExtraStyle ($menu->GetExtraStyle
    #                       | Wx::wxWS_EX_PROCESS_UPDATE_EVENTS());
    # Wx::Event::EVT_UPDATE_UI ($self, $self, \&_update_sections);
  }
  {
    my $menu = $self->{'index_menu'} = Wx::Menu->new;
    my $label = $self->{'index_menu_label'} = Wx::GetTranslation('&Index');
    $menubar->Append ($menu, $label);
  }
  {
    my $menu = Wx::Menu->new;
    $menubar->Append ($menu, Wx::GetTranslation('&Help'));
    {
      $menu->Append (Wx::wxID_ABOUT(),
                     '',
                     Wx::GetTranslation('Show about dialog'));
      EVT_MENU ($self, Wx::wxID_ABOUT(), 'popup_about');
    }
    {
      my $item = $menu->Append (Wx::wxID_ANY(),
                                Wx::GetTranslation('&Pod Browser POD'),
                                Wx::GetTranslation('Go to the POD documentation for this browser itself'));
      EVT_MENU ($self, $item, 'goto_own_pod');
    }
  }

  $self->CreateStatusBar;

  my $podtext
    = $self->{'podtext'}
      = Wx::Perl::PodRichText->new ($self);
  $podtext->SetFocus;
  Wx::Event::EVT_MOTION ($podtext, \&_do_podtext_mouse_motion);
  Wx::Event::EVT_ENTER_WINDOW ($podtext, \&_do_podtext_mouse_motion);
  Wx::Event::EVT_LEAVE_WINDOW ($podtext, \&_do_podtext_mouse_leave);
  Wx::Perl::PodRichText::EVT_PERL_PODRICHTEXT_CHANGED
    ($self, $podtext, \&_do_pod_changed);

  $self->SetSize ($self->GetBestSize);
  # _update_history_menuitems($self);  # initial insensitive
  _update_sections($self);  # initial insensitive

  return $self;
}

# sub Destroy {
#   my ($self) = @_;
#   ### PodBrowser Destroy() ...
#   # $self->{'podtext'}->abort_and_clear;
#   $self->SUPER::Destroy();
# }
# sub DESTROY {
#   my ($self) = @_;
#   ### PodBrowser DESTROY() ...
#   $self->{'podtext'}->abort_and_clear;
# }

#------------------------------------------------------------------------------

sub popup_module_dialog {
  my ($self) = @_;
  # ENHANCE-ME: non-modal
  my $module = Wx::GetTextFromUser(Wx::GetTranslation('Enter POD module name'),
                                   Wx::GetTranslation('POD module'),
                                   '',     # default
                                   $self); # parent
  if (defined $module) {
    $module =~ s/^\s+//; # whitespace
    $module =~ s/\s+$//;
    if ($module ne '') {
      $self->goto_pod (module => $module);
    }
  }
}

sub popup_file_dialog {
  my ($self) = @_;
  require Cwd;

  # ENHANCE-ME: non-modal
  my $filename = Wx::FileSelector
    (Wx::GetTranslation('Choose a POD file'),
     Cwd::getcwd(), # default dir
     '',            # default filename
     '',            # default extension
     Wx::GetTranslation('Perl files (pod,pm,pl)|*.pod;*.pm;*.pl|All files|*'),
     (Wx::wxFD_OPEN()
      | Wx::wxFD_FILE_MUST_EXIST()
      | Wx::wxSTAY_ON_TOP()),
     $self,
    );
  ### $filename
  $self->goto_pod (filename => $filename);


  # my $dialog = ($self->{'file_dialog'} ||= Wx::FileDialog->new
  #               ($self,
  #                Wx::GetTranslation('Choose a POD file'),
  #                Cwd::getcwd(), # default dir
  #                '',            # default file
  #                'Perl files (pod,pm,pl)|*.pod;*.pm;*.pl|All files|*',
  #                (Wx::wxFD_OPEN()
  #                 | Wx::wxFD_FILE_MUST_EXIST()
  #                 | Wx::wxSTAY_ON_TOP())
  #               ));
  # Wx::Event::EVT_COMMAND ($dialog, $self, sub {
  #                           ### EVT_COMMAND() ...
  #                           my $filename = $dialog->GetPath;
  #                           $self->goto_pod (filename => $filename);
  #                         });
  # Wx::Event::EVT_ACTIVATE ($dialog, sub {
  #                            ### EVT_ACTIVATE() ...
  #                            my $filename = $dialog->GetPath;
  #                            $self->goto_pod (filename => $filename);
  #                          });
  # $dialog->Show;

  # if( $dialog->ShowModal == Wx::wxID_CANCEL() ) {
  #   ### user cancel ...
  #   return;
  # }
  # my $filename = $dialog->GetPath;
  # $self->goto_pod (filename => $filename);
  # $dialog->Destroy;
}

sub reload {
  my ($self) = @_;
  $self->{'podtext'}->reload;
}
sub go_back {
  my ($self) = @_;
  $self->{'podtext'}->go_back;
}
sub go_forward {
  my ($self) = @_;
  $self->{'podtext'}->go_forward;
}

sub _update_history_menuitems {
  my ($self) = @_;
  ### PodBrowser _update_history_menuitems() ...

  my $podtext = $self->{'podtext'};
  $self->{'go_back_menuitem'}   ->Enable ($podtext->can_go_back);
  $self->{'go_forward_menuitem'}->Enable ($podtext->can_go_forward);
  $self->{'reload_menuitem'}    ->Enable ($podtext->can_reload);
}

sub _update_sections {
  my ($self) = @_;
  ### PodBrowser _update_sections() ...
  my $podtext = $self->{'podtext'};

  {
    my @heading_list = $podtext->get_heading_list;
    ### @heading_list

    # limit how many shown in menu
    if ($#heading_list > 50) {
      $#heading_list = 50;
    }

    {
      my $menubar = $self->GetMenuBar;
      my $pos = $menubar->FindMenu ($self->{'section_menu_label'});
      if ($pos != Wx::wxNOT_FOUND()) {
        # top-level "Sections" sensitive if there's any headings
        $menubar->EnableTop ($pos, @heading_list > 0);
      }
    }
    {
      my $menu = $self->{'section_menu'};
      my $i;
      for ($i = 0; $i <= $#heading_list; $i++) {
        my $heading = $heading_list[$i];

        my $label = $heading;
        $label = $self->section_menu_ellipsize($label);
        $label = _double_ampersands($label);
        $label =~ s/([[:alnum:]])/&$1/;   # first letter as mnemonic
        ### $label

        my $help = Wx::GetTranslation('Go to section:').' '.$heading;
        ### $help

        if (my $item = $menu->FindItemByPosition($i)) {
          # cf SetItemLabel() in Wx 2.9 up
          $menu->SetLabel($item->GetId, $label);
          $item->SetHelp ($help);
        } else {
          $item = $menu->Append (Wx::wxID_ANY(), $label, $help);
          my $num = $i;
          EVT_MENU ($self, $item, sub {
                      my ($self) = @_;
                      $self->goto_pod (heading_num => $num);
                    });
        }
      }
      for ( ; my $item = $menu->FindItemByPosition($i); $i++) {
        $menu->Remove($item);   # hide further items
      }
    }
  }

  {
    my @index_list = @{$podtext->{'index_list'} || []};
    ### @index_list

    @index_list = map {my (undef, $y) = $podtext->PositionToXY($podtext->{'index_pos_list'}->[$_]);
                       [$index_list[$_], $y]} 0 .. $#index_list;

    foreach my $elem (@index_list) {
      my $str = $elem->[0];
      $elem->[2] = lc($str);
      $elem->[3] = $str;
    }
    if (eval { require Sort::Key::Natural }) {
      foreach my $elem (@index_list) {
        $elem->[2] = Sort::Key::Natural::mkkey_natural($elem->[2]);
        $elem->[3] = Sort::Key::Natural::mkkey_natural($elem->[3]);
      }
    }
    @index_list = sort {$a->[2] cmp $b->[2]
                          || $a->[3] cmp $b->[3]
                            || $a->[0] cmp $b->[0]} @index_list;

    # limit how many shown in menu
    if ($#index_list > 50) {
      $#index_list = 50;
    }

    {
      my $menubar = $self->GetMenuBar;
      my $pos = $menubar->FindMenu ($self->{'index_menu_label'});
      if ($pos != Wx::wxNOT_FOUND()) {
        # top-level "Index" sensitive if there's any indexs
        $menubar->EnableTop ($pos, @index_list > 0);
      }
    }
    {
      my $menu = $self->{'index_menu'};
      my $i;
      for ($i = 0; $i <= $#index_list; $i++) {
        my $elem = $index_list[$i];
        ### $elem
        my $index = $elem->[0];
        $self->{'index_menu_list'}->[$i] = $elem->[1];

        my $label = $index;
        $label = $self->section_menu_ellipsize($label);
        $label = _double_ampersands($label);
        $label =~ s/([[:alnum:]])/&$1/;   # first letter as mnemonic
        ### $label

        my $help = Wx::GetTranslation('Go to index:').' '.$index;
        ### $help

        if (my $item = $menu->FindItemByPosition($i)) {
          # cf SetItemLabel() in Wx 2.9 up
          $menu->SetLabel($item->GetId, $label);
          $item->SetHelp ($help);
        } else {
          $item = $menu->Append (Wx::wxID_ANY(), $label, $help);
          my $num = $i;
          EVT_MENU ($self, $item, sub {
                      my ($self) = @_;
                      $self->goto_pod (line => $self->{'index_menu_list'}->[$num]);
                    });
        }
      }
      for ( ; my $item = $menu->FindItemByPosition($i); $i++) {
        $menu->Remove($item);   # hide further items
      }
    }
  }
}
sub _section_menuitem_activate {
}

# not documented ...
# cf Text::Truncate
sub section_menu_ellipsize {
  my ($self, $str) = @_;
  if (length($str) > 30) {
    $str = substr($str,0,30) . Wx::GetTranslation('...');
  }
  return $str;
}

sub goto_own_pod {
  my ($self) = @_;
  $self->goto_pod (module => ref $self);
}

sub goto_pod {
  my ($self, @args) = @_;
  my $podtext = $self->{'podtext'};
  $podtext->goto_pod (@args);
}
sub _do_pod_changed {
  my ($self, $event) = @_;
  my $what = $event->GetWhat;

  # done in UPDATE_UI
  # if ($what eq 'history') {
  #    _update_history_menuitems($self);
  # }

  if ($what eq 'heading_list') {
    _update_sections($self);
  }
}

sub quit {
  my ($self, $event) = @_;
  ### quit() ...
  $self->Close;
}
# wxCloseEvent says to Destroy()
sub _do_close_event {
  my ($self, $event) = @_;
  $self->Destroy;
}

#------------------------------------------------------------------------------

# sub edit_select_all {
#   my ($self) = @_;
#   $self->{'podtext'}->SelectAll;
# }
# sub edit_copy {
#   my ($self) = @_;
#   $self->{'podtext'}->Copy;
# }
# sub _update_can_copy {
#   my ($self) = @_;
#   $self->{'edit_copy_menuitem'}->Enable($self->{'podtext'}->CanCopy);
# }

#------------------------------------------------------------------------------

sub popup_print {
  my ($self) = @_;
  my $printing = $self->rich_text_printing;
  ### buffer: $self->{'podtext'}->GetBuffer
  $printing->PrintBuffer ($self->{'podtext'}->GetBuffer);
}
sub popup_print_preview {
  my ($self) = @_;
  my $printing = $self->rich_text_printing;
  $printing->PreviewBuffer ($self->{'podtext'}->GetBuffer);
}
sub popup_print_setup {
  my ($self) = @_;
  $self->rich_text_printing->PageSetup;
}
sub rich_text_printing {
  my ($self) = @_;
  return $self->{'podtext'}->rich_text_printing;
}

#------------------------------------------------------------------------------
# Help/About

sub popup_about {
  my ($self, $event) = @_;
  Wx::AboutBox($self->about_dialog_info);
}

sub about_dialog_info {
  my ($self) = @_;
  my $info = Wx::AboutDialogInfo->new;
  $info->SetName(ref $self);
  $info->SetVersion($self->VERSION);
  $info->SetWebSite('http://user42.tuxfamily.org/wx-pod-browser/index.html');
  # $info->SetIcon('...');

  $info->SetDescription
    (sprintf
     Wx::GetTranslation("%s\nYou are running under: Perl %s, wxPerl %s, %s"),
     $self->GetTitle,
     sprintf('%vd', $^V),
     Wx->VERSION,
     Wx::wxVERSION_STRING());

  $info->SetCopyright(Wx::GetTranslation('Copyright (C) 2012 Kevin Ryde

Wx-Pod-Browser is Free Software, distributed under the terms of the GNU General
Public License as published by the Free Software Foundation, either version
3 of the License, or (at your option) any later version.  Click on the
License button below for the full text.

Wx-Pod-Browser is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the license for more.
'));

  # the same as COPYING in the sources
  my $class = 'Software::License::GPL_3';
  if (eval "require $class") {
    # believe "holder" doesn't show up anywhere just from $sl->license()
    my $sl = $class->new({ holder => 'Kevin Ryde' });
    $info->SetLicense ($sl->license);
  } else {
    $info->SetLicense (sprintf(Wx::GetTranslation("GPL version 3 or higher.
Install %s to see the full text."),
                               $class));
  }
  return $info;
}

#------------------------------------------------------------------------------

# $event is a wxMouseEvent, either from EVT_MOTION or EVT_ENTER_WINDOW
sub _do_podtext_mouse_motion {
  my ($podtext, $event) = @_;
  #  ### Wx-PodBrowser _do_podtext_mouse_motion(): $event->GetX,$event->GetY

  my $url = _podtext_url_at_point($podtext,$event->GetPosition);
  my $self = $podtext->GetParent;
  $self->show_url_message ($url || '');
  $event->Skip(1); # propagate to other processing
}

# $point is a Wx::Point
sub _podtext_url_at_point {
  my ($podtext, $point) = @_;

  my ($result, $x,$y) = $podtext->HitTest($point);
  # ### $x
  # ### $y
  # $result==0 if x,y found in text
  # $result!=0 various kinds of outside, such as Wx::wxRICHTEXT_HITTEST_NONE()

  if ($result == 0) {
    if (defined (my $pos = $podtext->XYToPosition($x,$y))) {
      # ### $pos
      if (my $attrs = $podtext->GetRichTextAttrStyle($pos)) {
        # ### url: $attrs->GetURL
        return $attrs->GetURL;
      }
    }
  }
  return undef;
}

sub _do_podtext_mouse_leave {
  my ($podtext, $event) = @_;
  my $self = $podtext->GetParent;
  $self->show_url_message ('');
  $event->Skip(1); # propagate to other processing
}
sub show_url_message {
  my ($self, $message) = @_;
  if ($self->{'url_message'} ne $message) {
    $self->{'url_message'} = $message;
    $self->SetStatusText ($message);
  }
}

#------------------------------------------------------------------------------
# Maybe ...
#
# =item C<< $str = Wx::Perl::ControlBits::double_ampersands($str) >>
#
# Double any "&" characters in C<$str> "&&" so as to show them literally in
# a C<Wx::Control> C<SetLabel()> and similar labels (such as
# C<Wx::MenuItem> C<SetItemLabel()>).
#
sub _double_ampersands {
  my ($str) = @_;
  $str =~ s/&/&&/g;
  return $str;
}

1;
__END__

=for stopwords Wx-Perl-PodBrowser Ryde PodRichText menubar multi-window PodBrowser Wx toolkits toplevel

=head1 NAME

Wx::Perl::PodBrowser -- toplevel POD browser window

=head1 SYNOPSIS

 use Wx::Perl::PodBrowser;
 my $browser = Wx::Perl::PodBrowser->new;
 $browser->Show;
 $browser->goto_pod (module => 'Foo::Bar');

=head1 CLASS HIERARCHY

C<Wx::Perl::PodBrowser> is a C<Wx::Frame> toplevel window.

    Wx::Object
      Wx::EvtHandler
        Wx::Window
          Wx::TopLevelWindow
            Wx::Frame
              Wx::Perl::PodBrowser

=head1 DESCRIPTION

This is a POD documentation browser frame.  The POD is displayed using
C<Wx::Perl::PodRichText> which is a C<RichTextCtrl>.  There's menus for
various features and the links in the text can be followed to other
documents.

    +-------------------------------------------+
    | File  Section  Help                       |
    +-------------------------------------------+
    | NAME                                      |
    |   Foo - some thing                        |
    | DESCRIPTION                               |
    |   Blah blah.                              |
    | SEE ALSO                                  |
    |   Bar                                     |
    +-------------------------------------------+
    | (statusbar)                               |
    +-------------------------------------------+

=head2 Programming

The initial window size follows the 80x30 initial size of the
C<Wx::Perl::PodRichText> display widget.  Program code or the user can make
the window bigger or smaller as desired.

The menubar is available from the usual C<Wx::Frame> method
C<< $browser->GetMenuBar() >> to make additions or modifications.  The quit
menu item (C<Wx::wxID_EXIT>) closes the window with C<< $browser->quit() >>
described below.  In a multi-window program this only closes the
C<PodBrowser> window, it doesn't exit the whole program.

See L<wx-perl-podbrowser> for a standalone program running a PodBrowser
window.  Or see F<examples/podbrowser.pl> for a minimal program.

=head1 FUNCTIONS

=head2 Creation

=over 4

=item C<< $browser = Wx::Perl::PodBrowser->new () >>

=item C<< $browser = Wx::Perl::PodBrowser->new ($parent, $id, $title) >>

Create and return a new browser window widget.

The optional C<$parent>, C<$id> and C<$title> arguments are per
C<< Wx::Frame->new() >>.

The default C<$title> is "POD Browser".  An application could set something
more specific if displaying its own help pages, either when creating the
browser or later with the usual C<Wx::TopLevelWindow> method
C<< $browser->SetTitle($title) >>.

=back

=head2 Methods

=over 4

=item C<< $browser->go_back() >>

=item C<< $browser->go_forward() >>

Go back or forward to the next or previous POD module or file.  These are
the "File/Back" and "File/Forward" menu entries.

=item C<< $browser->goto_own_pod() >>

Go to the POD of the PodBrowser module itself.  This is the "Help/POD
Browser POD" menu entry.

=item C<< $browser->reload() >>

Re-read the current POD module or file.  This is the "File/Reload" menu
entry.

=item C<< $browser->quit() >>

Close the PodBrowser window.  This is the "File/Quit" menu entry (which is
C<wxID_EXIT>).  It closes the window with the usual C<Wx::Frame> method
C<< $browser->Close() >>.

The C<EVT_CLOSE()> handler does a C<< $browser->Destroy() >> to destroy the
browser.  Perhaps there should be an option to only C<Hide()>, so an
application could keep a single browser window.  Is there a conventional way
to choose that?

=back

=head2 Printing

=over 4

=item C<< $browser->popup_print() >>

Open a print dialog for the POD document.  This is the "File/Print" menu
entry (which is C<wxID_PRINT>).

=item C<< $browser->popup_print_preview() >>

Open a print-preview dialog for the POD document.  This is the "File/Print
Preview" menu entry (which is C<wxID_PREVIEW>).

=item C<< $browser->popup_print_setup() >>

Open a printer page setup dialog.  This is the "File/Page Setup" menu entry
(which is C<wxID_PRINT_SETUP>).

=back

=head2 About Dialog

=over 4

=item C<< $browser->popup_about_dialog() >>

Open the "about" dialog for C<$browser>.  This is the Help/About menu entry
(the usual C<wxID_ABOUT>).  It displays a C<Wx::AboutBox()> containing the
C<< $browser->about_dialog_info() >> below.

=item C<< $info = $browser->about_dialog_info() >>

Return a C<Wx::AboutDialogInfo> object with information about C<$browser>.

=back

=head1 SEE ALSO

L<wx-perl-podbrowser>,
L<Wx>

=head2 Other Ways to Do It

L<Wx::Perl::PodEditor> does a similar thing, and in a C<Wx::RichTextCtrl>
too, but designed for editing the POD.

L<Padre::Wx::Frame::POD> displays POD in a C<Wx::HtmlWindow>, converted to
HTML with a special C<Pod::Simple::XHTML>.

L<CPANPLUS::Shell::Wx::PODReader> also displays POD in a C<Wx::HtmlWindow>,
converted to HTML with C<perldoc -o html>, which in recent C<perldoc> means
C<Pod::Simple::Html>.

POD browsers in other toolkits include L<Tk::Pod>, L<Prima::HelpViewer> and
L<Gtk2::Ex::PodViewer>.

=head1 HOME PAGE

L<http://user42.tuxfamily.org/wx-perl-podbrowser/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2017 Kevin Ryde

Wx-Perl-PodBrowser is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Wx-Perl-PodBrowser is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Wx-Perl-PodBrowser.  If not, see L<http://www.gnu.org/licenses/>.

=cut
