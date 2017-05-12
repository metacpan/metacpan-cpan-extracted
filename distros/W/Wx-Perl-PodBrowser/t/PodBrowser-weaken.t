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
#use Smart::Comments;


eval { require Wx }
  or plan skip_all => "due to Wx display not available -- $@";

# Test::Weaken 3 for "contents"
eval "use Test::Weaken 3; 1"
  or plan skip_all => "due to Test::Weaken 3 not available -- $@";

plan tests => 3;

require Wx::Perl::PodBrowser;

my $app = Wx::SimpleApp->new;
my $frame = Wx::Frame->new (undef, Wx::wxID_ANY(), 'Test');
require Wx::Perl::PodBrowser;


sub app_mainloop_timer {
  my $timer = Wx::Timer->new($app);
  Wx::Event::EVT_TIMER ($app, -1, sub { $app->ExitMainLoop });
  $timer->Start(1000, # milliseconds
                Wx::wxTIMER_ONE_SHOT())
    or die "Oops, cannot start timer";
  $app->MainLoop;
}

# sub main_iterations {
#   my ($app) = @_;
#   if (! $app) { $app = Wx::App::GetInstance(); }
#   my $count = 0;
#   Wx::Yield();
#   while ($app->Pending) {
#     $count++;
#     $app->Dispatch;
#   }
#   diag "main_iterations: $count dispatches";
# }

sub destructor_destroy {
  my ($window) = @_;
  $window->Destroy;
  app_mainloop_timer($app);  # to run queued destroys
}

# If $ref is a Wx::Window then return a list of its GetChildren(), and some
# other content widgets such as menubar, menu items, etc.
# If $ref is not a Wx::Window then return an empty list.
sub contents_children {
  my ($ref) = @_;
  my @ret;
  if (Scalar::Util::blessed($ref)) {
    if ($ref->isa('Wx::Window') || $ref->isa('Wx::Sizer')) {
      ### window children: ref $ref, $ref->GetChildren
      push @ret, $ref->GetChildren;
    }
    if ($ref->isa('Wx::Frame')) {
      ### frame menubar: $ref->GetMenuBar
      push @ret, ($ref->GetMenuBar,
                  $ref->GetToolBar,
                  $ref->GetStatusBarPane,
                  $ref->GetStatusBar);
    }
    if ($ref->isa('Wx::MenuBar')) {
      push @ret, map {$ref->GetMenu($_)} 0 .. $ref->GetMenuCount - 1;
    }
    if ($ref->isa('Wx::Menu')) {
      ### menu items: $ref->GetMenuItems
      push @ret, $ref->GetMenuItems;
    }
  }
  return @ret;
}
sub contents_frame_parts {
  my ($ref) = @_;
  return;
}
sub my_contents {
  my ($ref) = @_;
  return (contents_children($ref),
          contents_frame_parts($ref));
}

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         return Wx::Perl::PodBrowser->new;
       },
       destructor => \&destructor_destroy,
       contents   => \&my_contents,
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection empty and Destroy()');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $browser = Wx::Perl::PodBrowser->new;
         $browser->goto_pod(string => "=head1 NAME\n");
         $browser->Show;
         is (join(',',$browser->{'podtext'}->get_heading_list),
             'NAME');
         return $browser;
       },
       destructor => \&destructor_destroy,
       contents   => \&my_contents,
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection with content and Destroy()');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

exit 0;
