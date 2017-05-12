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
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();


eval { require Wx }
  or plan skip_all => "due to Wx display not available -- $@";

plan tests => 6;

my $app = Wx::SimpleApp->new;
my $frame = Wx::Frame->new (undef, Wx::wxID_ANY(), 'Test');
require Wx::Perl::PodRichText;


#------------------------------------------------------------------------------
# VERSION

my $want_version = 15;
{
  is ($Wx::Perl::PodRichText::VERSION, $want_version,
      'VERSION variable');
  is (Wx::Perl::PodRichText->VERSION, $want_version,
      'VERSION class method');

  ok (eval { Wx::Perl::PodRichText->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Wx::Perl::PodRichText->VERSION($check_version); 1 },
      "VERSION class check $check_version");

  # my $podtext = Wx::Perl::PodRichText->new ($frame);
  # is ($podtext->VERSION,  $want_version, 'VERSION object method');
  #
  # ok (eval { $podtext->VERSION($want_version); 1 },
  #     "VERSION object check $want_version");
  # ok (! eval { $podtext->VERSION($check_version); 1 },
  #     "VERSION object check $check_version");
}


#-----------------------------------------------------------------------------
# Scalar::Util::weaken

my $podtext = Wx::Perl::PodRichText->new ($frame);
{
  my @heading_list = $podtext->get_heading_list;
  is_deeply (\@heading_list, []);
}

diag "weakening";
require Scalar::Util;
$podtext->Destroy;
Scalar::Util::weaken ($podtext);
is ($podtext, undef, 'garbage collect when weakened');

exit 0;
