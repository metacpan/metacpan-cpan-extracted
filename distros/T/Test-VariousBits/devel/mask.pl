#!/usr/bin/perl -w

# Copyright 2011, 2012, 2015, 2017 Kevin Ryde

# This file is part of Test-VariousBits.
#
# Test-VariousBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Test-VariousBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Test-VariousBits.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Module::Util::Masked;

# uncomment this to run the ### lines
use Smart::Comments;

{
  unshift @INC, 't/lib';
  require Module::Util;
  { my @filenames = Module::Util::find_in_namespace('Module_Util_Masked_test');
    ### find_in_namespace initial: @filenames
  }

  eval 'use Test::Without::Module q{Module_Util_Masked_test::Two}; 1' or die;

  my $module = 'Module_Util_Masked_test';
  { my $forbidden_list = Test::Without::Module::get_forbidden_list();
    ### $forbidden_list
  }
  #    if (exists (Test::Without::Module::get_forbidden_list()->{$module})) {

  { my @filenames = Module::Util::find_in_namespace($module);
    ### find_in_namespace now: @filenames
  }
  exit 0;
}
{
  print Module::Util::module_path('Module_Util_Masked_test::Two'),"\n";
  exit 0;
}

{
  # { my $path = Module::Util::find_installed('SelectSaver');
  #   ### $path
  # }
  eval "use Test::Without::Module 'SelectSaver'";
  my @forbidden = Test::Without::Module::get_forbidden_list();
  ### @forbidden
  ### @INC

  my $refaddr = Scalar::Util::refaddr({});
  print "refaddr $refaddr\n";

  { my @filenames = Module::Util::find_in_namespace('constant');
    ### @filenames
  }
  # { my $path = Module::Util::find_installed('SelectSaver');
  #   ### $path
  # }

  exit 0;
}

{
  push @INC, sub { return; };

  { my @filenames = Module::Util::find_in_namespace('constant');
    print @filenames,"\n";
  }

  exit 0;
}

{
  system (q(strace perl -MModule::Mask=Blah -MModule::Util -e 'Module::Util::find_installed(q(FindBin))'));
  exit 0;
}

{
  sub foo {
    use Devel::TraceLoad::Hook;
    require Devel::Unplug;
    Devel::Unplug::unplug ('Acme::Magic8Ball');
    require Acme::Magic8Ball;
  }
  # eval 'require constant::defer' or die;

  require B::Concise;
  my $walker = B::Concise::compile('-terse','foo', \&foo);
B::Concise::walk_output(\my $buf);
  &$walker();
  print $buf;

  require B::Deparse;
  my $deparse = B::Deparse->new("-p", "-sC");
  my $body = $deparse->coderef2text(\&foo);
  print $body;

  foo();

  # my @filenames = Module::Util::find_in_namespace('constant');
  # ### @filenames

  exit 0;
}

{
  require App::MathImage::Generator;
  my @choices = App::MathImage::Generator->values_choices;
  ### @choices


  require Module::Util::Masked;
  eval 'use Test::Without::Module q{Math::Aronson}, q{Math::NumSeq::Aronson}; 1'
    or die;
  my @filenames = Module::Util::find_in_namespace('Math::NumSeq');
  ### @filenames

  @filenames = Module::Util::find_in_namespace('App::MathImage::NumSeq');
  ### @filenames

  exit 0;
}



my $path = Module::Util::find_installed('FindBin');
### $path
eval "use Module::Mask 'FindBin'";
$path = Module::Util::find_installed('FindBin');
### $path



$path = Module::Util::find_installed('SelectSaver');
### $path
require Module::Mask;
my $mask = Module::Mask->new ('SelectSaver');

$path = Module::Util::find_installed('SelectSaver');
### $path

push @INC, shift @INC;
### @INC

$path = Module::Util::find_installed('SelectSaver');
### $path


