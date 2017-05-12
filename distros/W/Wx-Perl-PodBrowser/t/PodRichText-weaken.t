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

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

# uncomment this to run the ### lines
#use Smart::Comments;


eval { require Wx }
  or plan skip_all => "due to Wx display not available -- $@";

# Test::Weaken 3 for "contents"
eval "use Test::Weaken 3; 1"
  or plan skip_all => "due to Test::Weaken 3 not available -- $@";

plan tests => 2;

require Wx::Perl::PodRichText;

my $app = Wx::SimpleApp->new;
my $frame = Wx::Frame->new (undef, Wx::wxID_ANY(), 'Test');
require Wx::Perl::PodRichText;


sub main_iterations {
  my ($app) = @_;
  if (! $app) { $app = Wx::App::GetInstance(); }
  my $count = 0;
  Wx::Yield();
  while ($app->Pending) {
    $count++;
    $app->Dispatch;
  }
  diag "main_iterations: $count dispatches";
}

sub destructor_destroy {
  my ($window) = @_;
  $window->Destroy;
  main_iterations();
}
sub contents_children {
  my ($ref) = @_;
  if (Scalar::Util::blessed($ref)
      && ($ref->isa('Wx::Window') || $ref->isa('Wx::Sizer'))) {
    return $ref->GetChildren;
  }
  return;
}

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         return Wx::Perl::PodRichText->new($frame);
       },
       destructor => \&destructor_destroy,
       # contents   => \&contents_children,
       # ignore     => \&my_ignore,
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $podtext = Wx::Perl::PodRichText->new($frame);
         $podtext->goto_pod (string => "=head1 NAME\n");
         while ($podtext->{'fh'}) {
           $podtext->parse_some;
         }
         return $podtext;
       },
       destructor => \&destructor_destroy,
       contents   => \&contents_children,
       # ignore     => \&my_ignore,
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

exit 0;
