#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use Tk;
use App::MathImage::Tk::Drawing;
use App::MathImage::Tk::SaveDialog;

use FindBin;
my $progname = $FindBin::Script;

my $mw = MainWindow->new;
my $drawing = $mw->AppMathImageTkDrawing;
my $dialog = $mw->AppMathImageTkSaveDialog (-drawing => $drawing);
### $dialog
$dialog->Popup;
MainLoop;
exit 0;
