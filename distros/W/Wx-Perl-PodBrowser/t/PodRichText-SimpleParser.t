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

# uncomment this to run the ### lines
# use Smart::Comments;


eval { require Wx }
  or plan skip_all => "due to Wx display not available -- $@";

plan tests => 8;
require Wx::Perl::PodRichText::SimpleParser;


#------------------------------------------------------------------------------
# VERSION

my $want_version = 15;
{
  is ($Wx::Perl::PodRichText::SimpleParser::VERSION, $want_version,
      'VERSION variable');
  is (Wx::Perl::PodRichText::SimpleParser->VERSION, $want_version,
      'VERSION class method');

  ok (eval { Wx::Perl::PodRichText::SimpleParser->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Wx::Perl::PodRichText::SimpleParser->VERSION($check_version); 1 },
      "VERSION class check $check_version");

  my $parser = Wx::Perl::PodRichText::SimpleParser->new;
  is ($parser->VERSION,  $want_version, 'VERSION object method');
  ok (eval { $parser->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $parser->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}


#-----------------------------------------------------------------------------
# =encoding utf-8 not through to output

my $app = Wx::SimpleApp->new;
my $frame = Wx::Frame->new (undef, Wx::wxID_ANY(), 'Test');
require Wx::Perl::PodRichText;
{
  my $podtext = Wx::Perl::PodRichText->new ($frame);
  $podtext->goto_pod (string => "=encoding utf-8\n\n\nThis is some text.\n");
  my $str = $podtext->GetValue;
  ### $str
  unlike ($str, qr/utf/i,
          '=encoding charset name not shown in text');
}

#-------------------------------------------------------------------------------
exit 0;
