#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

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


# cf wxperl_demo.pl -s wxSearchCtrl

use 5.008;
use strict;
use Wx;
use Wx::Perl::PodRichText;

# uncomment this to run the ### lines
use Devel::Comments;


{
  my $app = Wx::SimpleApp->new;
  my $self = Wx::Frame->new(undef, Wx::wxID_ANY(), 'Pod');
  ### $self

  my $linebreak = (eval { Wx::wxRichTextLineBreakChar() }
                   || chr(29)); # per src/richtext/richtextbuffer.cpp

  my $vertsizer = Wx::BoxSizer->new (Wx::wxVERTICAL());


  my $search_panel = Wx::Panel->new ($self);
  $vertsizer->Add ($search_panel, 0, 0, 0);

  my $search_sizer = Wx::BoxSizer->new (Wx::wxHORIZONTAL());
  {
    my $search = $self->{'search'}
      = Wx::SearchCtrl->new ($search_panel,
                             Wx::wxID_ANY(),
                             '', # initial value
                             Wx::wxDefaultPosition(),
                             Wx::wxDefaultSize(),
                             Wx::wxTE_PROCESS_ENTER());
    $search->ShowCancelButton(1);
    $search->SetValue('Pod');

    Wx::Event::EVT_SEARCHCTRL_SEARCH_BTN
        ($self, $search, \&search_next);
    Wx::Event::EVT_SEARCHCTRL_CANCEL_BTN ($self, $search, sub {
                                            my ($self, $event) = @_;
                                            print "cancel\n";
                                            $vertsizer->Hide($search_panel);
                                            $vertsizer->Layout;
                                          });
    Wx::Event::EVT_TEXT_ENTER( $self, $search, sub {
                                 my ($self, $event) = @_;
                                 print "enter\n";
                                 search_next($self,$event);
                               } );
    $search->SetFocus;
    $search_sizer->Add ($search, 1, Wx::wxGROW()|Wx::wxRIGHT(), 15);
  }

  {
    my $next_button
      = Wx::Button->new ($search_panel, Wx::wxID_ANY(),
                         Wx::GetTranslation('Next'));
    Wx::Event::EVT_BUTTON ($self, $next_button, \&search_next);
    $search_sizer->Add ($next_button, 0, Wx::wxGROW(), 0);
  }
  {
    my $prev_button
      = Wx::Button->new ($search_panel, Wx::wxID_ANY(),
                         Wx::GetTranslation('Prev'));
    Wx::Event::EVT_BUTTON ($self, $prev_button, sub {
                             my ($self,$event) = @_;
                             ### Prev: $event
                             \&search_next($self,$event,1);
                           });
    $search_sizer->Add ($prev_button, 0, Wx::wxGROW(), 0);
  }
  {
    my $case_checkbox
      = $self->{'case_checkbox'}
        = Wx::CheckBox->new ($search_panel, Wx::wxID_ANY(), Wx::GetTranslation('Case'));
    Wx::Event::EVT_CHECKBOX ($self, $case_checkbox, sub {});
    $search_sizer->Add ($case_checkbox, 0, Wx::wxGROW(), 0);
  }
  {
    my $wrap_checkbox
      = $self->{'wrap_checkbox'}
        = Wx::CheckBox->new ($search_panel, Wx::wxID_ANY(), Wx::GetTranslation('Wrap'));
    $wrap_checkbox->SetValue(1);
    Wx::Event::EVT_CHECKBOX ($self, $wrap_checkbox, sub {});
    $search_sizer->Add ($wrap_checkbox, 0, Wx::wxGROW(), 0);
  }
  $search_panel->SetSizerAndFit($search_sizer);

  {
    # my $podtext = Wx::RichTextCtrl->new ($self);
    my $podtext
      = $self->{'podtext'}
        = Wx::Perl::PodRichText->new ($self);
    $podtext->goto_pod (module => 'Wx::Perl::PodRichText');
    $podtext->GetValue;
    $podtext->_set_size_chars(60,30);
    $vertsizer->Add ($podtext, 1, Wx::wxGROW(), 0);
  }

  my $bestsize = $self->GetBestSize;
  ### best height: $bestsize->GetHeight
  $self->SetSizerAndFit($vertsizer);
  $self->SetSize ($bestsize);
  $self->Show;

  $app->MainLoop;
  exit 0;

  sub search_next {
    my ($self, $event, $prev) = @_;
    print "search\n";
    my $podtext = $self->{'podtext'};
    my ($from, $to) = $podtext->GetSelection;
    ### $from
    if ($from == $to) {
      $from = $to = 0;
    }
    my $search = $self->{'search'};
    my $search_str = $search->GetValue;

    my $str = $podtext->GetValue;
    my $case_checkbox = $self->{'case_checkbox'};
    unless ($case_checkbox->GetValue) {
      $str = lc($str);
      $search_str = lc($search_str);
    }
    # $str =~ s/$linebreak/\n/g;
    ### $search_str
    ### $to

    if ($prev) {
      $from = rindex($str, $search_str, $from-1);
      if ($from < 0 && $self->{'wrap_checkbox'}->GetValue) {
        ### try wrap ...
        $from = rindex($str, $search_str);
      }
    } else {
      $from = index($str, $search_str, $from+1);
      if ($from < 0 && $self->{'wrap_checkbox'}->GetValue) {
        ### try wrap ...
        $from = index($str, $search_str);
      }
    }
    if ($from < 0) {
      ### not found ...
      return;
    }
    ### found ...
    $to = $from + length($search_str);
    ### $from
    ### $to
    $podtext->SetSelection ($from, $to);
    # Have sometimes seen the selected text not all on screen if only
    # ShowPosition($from).  Seems better if ShowPosition($to) first.
    $podtext->ShowPosition($to);
    $podtext->ShowPosition($from);
  }
}
