#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

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

use 5.004;
use strict;
use Wx;

# uncomment this to run the ### lines
use Devel::Comments;

{
  my $app = Wx::SimpleApp->new;
  require App::MathImage::Wx::Diagnostics;
  my $dialog = App::MathImage::Wx::Diagnostics->new;
  $dialog->Show;
  $app->MainLoop;
  exit 0;
}

{
  require Package::Stash;
  my $stash = Package::Stash->new('Wx::Window');
  ### syms: $stash->list_all_symbols('CODE')
  exit 0;
}
{
  my @size = Wx::GetDisplaySize();
  ### @size
  exit 0;
}
{
  my $app = Wx::SimpleApp->new;
  my $info = Wx::AboutDialogInfo->new;

  $app->MainLoop;
  exit 0;
}
