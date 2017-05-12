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

use 5.008;
use strict;
use Wx;
use Wx::RichText;

# uncomment this to run the ### lines
use Devel::Comments;

my $str;


{
  # RichText word wrapping

  my $app = Wx::SimpleApp->new;
  my $frame = Wx::Frame->new(undef, Wx::wxID_ANY(), 'Pod');

  my $textctrl = Wx::RichTextCtrl->new ($frame);
  $textctrl->WriteText ('abc ' x 100);
  $textctrl->Newline;

  $textctrl->BeginRightIndent(-100);
  $textctrl->WriteText ('abc ' x 100);
  $textctrl->Newline;
  $textctrl->EndRightIndent;

  $frame->SetSize (800, 800);
  $frame->Show;
  $app->MainLoop;
  exit 0;
}

{
  my $app = Wx::SimpleApp->new;

  my $main = Wx::Frame->new (undef, Wx::wxID_ANY(), 'Main');
  $main->SetSize(100,100);
  $main->Show;

  my $m2 = Wx::Frame->new (undef, Wx::wxID_ANY(), 'Main');
  $m2->SetSize(100,100);
  $m2->Show;

  my $timer = Wx::Timer->new ($m2);
  Wx::Event::EVT_TIMER ($m2,
                        0, # id, through to $event->GetId
                        sub {
                          ### timer fires ...
                        });
  $timer->Start(1000, # milliseconds
                Wx::wxTIMER_CONTINUOUS());
  # undef $timer;
  #  $m2->Destroy;
  ### $timer

  $app->MainLoop;
  exit 0;
}

{
  # indent cumulative
  my $app = Wx::SimpleApp->new;
  my $frame = Wx::Frame->new(undef, Wx::wxID_ANY(), 'Pod');

  my $textctrl = Wx::RichTextCtrl->new ($frame);
  $textctrl->BeginLeftIndent(100);
  $textctrl->BeginLeftIndent(100);
  $textctrl->WriteText ('abc');
  $textctrl->Newline;
  $textctrl->EndLeftIndent;
  $textctrl->WriteText ('def');
  $textctrl->Newline;
  $textctrl->EndLeftIndent;

  $frame->SetSize (800, 800);
  $frame->Show;
  $app->MainLoop;
  exit 0;
}

{
  my $attrs = Wx::RichTextAttr->new;
  my $url = $attrs->GetURL;
  ### $attrs
  ### $url
  exit 0;
}

{
  my $app = Wx::SimpleApp->new;
  my $frame = Wx::Frame->new(undef, Wx::wxID_ANY(), 'Pod');

  my $textctrl = Wx::RichTextCtrl->new ($frame);
  $textctrl->BeginLeftIndent(100);
  $textctrl->WriteText ('abc');
  $textctrl->Newline;

  $textctrl->EndAllStyles;
  $textctrl->Clear;
  $textctrl->WriteText ('def');
  $textctrl->Newline;

  $frame->SetSize (800, 800);
  $frame->Show;
  $app->MainLoop;
  exit 0;
}

{
  # bold inherited
  my $app = Wx::SimpleApp->new;
  my $frame = Wx::Frame->new(undef, Wx::wxID_ANY(), 'Pod');

  my $textctrl = my $self = Wx::RichTextCtrl->new ($frame);
  $textctrl->BeginBold;
  $textctrl->WriteText ('abc');
  $textctrl->EndBold;
  $textctrl->Newline;
  $textctrl->WriteText ('jfd');
  $textctrl->Newline;

  $textctrl->EndAllStyles;
  $textctrl->SetInsertionPoint(0);
  {
    my $style = $self->GetBasicStyle;
    $self->SetDefaultStyle ($style);
    ### $style
    ### flags: $style->GetFlags
  }
  # {
  #   my $style = Wx::TextAttrEx->new;
  #   $self->SetDefaultStyle ($style);
  # }
  $textctrl->Clear;

  $textctrl->WriteText ('def');
  $textctrl->Newline;

  $frame->SetSize (800, 800);
  $frame->Show;
  $app->MainLoop;
  exit 0;
}

