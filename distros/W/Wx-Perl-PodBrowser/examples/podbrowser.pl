#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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


# Usage: podbrowser.pl modulename_or_filename
#
# This is a minimal program to open a Wx::Perl::PodBrowser window.
# See the wx-perl-podbrowser program for more options etc.
#

use 5.008;
use strict;
use warnings;
use Wx;
use Wx::Perl::PodBrowser;

my $app = Wx::SimpleApp->new;

my $browser = Wx::Perl::PodBrowser->new;
$browser->Show;
$browser->goto_pod (guess => $ARGV[0]);

$app->MainLoop;
exit 0;
