#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Image is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use Test::More;

if (! eval { require Tk; 1 }) {
  diag ('Tk not available -- ',$@);
  plan skip_all => 'due to no Tk';
}
diag ("Tk version ", Tk->VERSION);

plan tests => 11;

require App::MathImage::Tk::Perl::WeakAfter;


# uncomment this to run the ### lines
#use Smart::Comments;


#------------------------------------------------------------------------------
# VERSION

my $want_version = 99;
is ($App::MathImage::Tk::Perl::WeakAfter::VERSION, $want_version,
    'VERSION variable');
is (App::MathImage::Tk::Perl::WeakAfter->VERSION, $want_version,
    'VERSION class method');

ok (eval { App::MathImage::Tk::Perl::WeakAfter->VERSION($want_version); 1 },
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { App::MathImage::Tk::Perl::WeakAfter->VERSION($check_version); 1 },
    "VERSION class check $check_version");

#------------------------------------------------------------------------------

my $mw = MainWindow->new;
{
  my $called = 0;
  my $af = App::MathImage::Tk::Perl::WeakAfter->new;
  is ($af->type, '');
  $af->idle($mw, sub { $called++ });
  is ($af->type, 'idle');
  $mw->update;
  is($called, 1);
  is ($af->type, '');
}
{
  my $called = 0;
  my $af = App::MathImage::Tk::Perl::WeakAfter->new;
  $af->idle($mw, sub { $called++; });
  undef $af;
  $mw->update;
  is($called, 0);
}
# {
#   my $label = $mw->Label;
#   $label->destroy;
#   Scalar::Util::weaken($label);
#   is($label, undef);
# }
# {
#   my $label = $mw->Label;
#   my $called = 0;
#   my $af = App::MathImage::Tk::Perl::WeakAfter->new($label, sub {
#                                                   $called++;
#                                                 });
#   $label->destroy;
#   Scalar::Util::weaken($label);
#   $mw->update;
#   ### $af
#   is($label, undef);
#   is($called, 0);
# }

{
  my $af = App::MathImage::Tk::Perl::WeakAfter->new;
  { my @info = $af->info;
    is_deeply(\@info,[]);
  }
  $af->idle($mw, sub { });
  { my @info = $af->info;
    is (scalar(@info),3);
  }
}
# {
#
#   my $called = 0;
#   my $id = $mw->after(100, sub { $called++; });
#   my @info = $mw->afterInfo($id);
#   ### @info
#   my $called = 0;
#   my $af = App::MathImage::Tk::Perl::WeakAfter->new($mw, sub {
#                                                   $called++;
#                                                 });
#   my @info = $af->info;
#   ### @info
# }

exit 0;
