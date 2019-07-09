#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2017 Kevin Ryde

# This file is part of X11-Protocol-Other.
#
# X11-Protocol-Other is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# X11-Protocol-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.

BEGIN { require 5 }
use strict;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }
END { MyTestHelpers::diag ("END"); }

# uncomment this to run the ### lines
#use Smart::Comments;

my $test_count = (tests => 12)[1];
plan tests => $test_count;

require X11::Protocol;
MyTestHelpers::diag ("X11::Protocol version ", X11::Protocol->VERSION);

my $display = $ENV{'DISPLAY'};
if (! defined $display) {
  foreach (1 .. $test_count) {
    skip ('No DISPLAY set', 1, 1);
  }
  exit 0;
}

# pass display arg so as not to get a "guess" warning
my $X;
if (! eval { $X = X11::Protocol->new ($display); }) {
  MyTestHelpers::diag ('Cannot connect to X server -- ',$@);
  foreach (1 .. $test_count) {
    skip ('Cannot connect to X server', 1, 1);
  }
  exit 0;
}
$X->QueryPointer($X->{'root'});  # sync

require X11::Protocol::GrabServer;

#------------------------------------------------------------------------------
# VERSION

my $want_version = 31;
ok ($X11::Protocol::GrabServer::VERSION,
    $want_version,
    'VERSION variable');
ok (X11::Protocol::GrabServer->VERSION,
    $want_version,
    'VERSION class method');

ok (eval { X11::Protocol::GrabServer->VERSION($want_version); 1 },
    1,
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { X11::Protocol::GrabServer->VERSION($check_version); 1 },
    1,
    "VERSION class check $check_version");

#------------------------------------------------------------------------------
# is_grabbed()

{
  my $grab = X11::Protocol::GrabServer->new ($X);
  ok (1, $grab->is_grabbed);

  $grab->ungrab;
  ok (1, ! $grab->is_grabbed);
  $grab->ungrab;
  ok (1, ! $grab->is_grabbed);

  $grab->grab;
  ok (1, $grab->is_grabbed);
  $grab->grab;
  ok (1, $grab->is_grabbed);
}

#------------------------------------------------------------------------------
# fields left in $X

{
  my $fields_before = join (',', sort keys %$X);
  my $grab = X11::Protocol::GrabServer->new ($X);
  ok (!! $grab->isa('X11::Protocol::GrabServer'),
      1,
      "new() isa X11::Protocol::GrabServer");
  {
    my $fields_during = join (',', sort keys %$X);
    ok ($fields_before ne $fields_during, 1);
  }
  undef $grab;
  {
    my $fields_after = join (',', sort keys %$X);
    ok ($fields_before, $fields_after);
  }
}

#------------------------------------------------------------------------------
# DESTROY() preserve $@

# Only relevant if playing around with evals in DESTROY.
# {
#   $@ = 'my initial message';
#   eval {
#     my $grab = X11::Protocol::GrabServer->new ($X);
#     die "my test error message";
#   };
#   my $err = $@;
#   MyTestHelpers::diag ("eval err is: $err");
#   ok ($err, "/^my test error message/");
# }

#------------------------------------------------------------------------------
# DESTROY() no error

# Nothing for this as yet, probably not worth the complication.
# {
#   my $X2 = X11::Protocol->new ($display);
#   my $pixmap2 = $X2->new_rsrc;
#   $X2->CreatePixmap ($pixmap2,
#                      $X2->{'root'},
#                      $X2->{'root_depth'},
#                      1,1);  # width,height
#   $X2->QueryPointer($X2->{'root'});  # sync
# 
#   MyTestHelpers::diag ("KillClient");
#   $X->KillClient($pixmap2);
#   $X->QueryPointer($X->{'root'});  # sync
#   $X->flush;
# 
#   alarm (10);
#   $SIG{'ALRM'} = sub {
#     MyTestHelpers::diag ('alarm timeout!');
#     exit 99;
#   };
#   local $SIG{'PIPE'} = 'IGNORE';  # return EPIPE
# 
#   my $grab = X11::Protocol::GrabServer->new ($X2);
# 
#   MyTestHelpers::diag ("wait for EPIPE");
#   require POSIX;
#   for (1 .. 5) {
#     sleep 1;
#     MyTestHelpers::diag ("try NoOperation");
#     if (! eval { $X2->NoOperation; $X2->flush; 1 }) {
#       my $e = $@;
#       $e =~ s/\n+$//;
#       my $errno = $! + 0;
#       my $errno_str = "$!";
#       if ($errno != POSIX::EPIPE()) {
#         MyTestHelpers::diag ('Unexpected write error:');
#       }
#       MyTestHelpers::diag ("eval: $e");
#       MyTestHelpers::diag ("errno: $errno $errno_str");
#       last;
#     }
#   }
#   MyTestHelpers::diag ("now DESTROY");
#   undef $grab;
#   ok (1, 1, "DESTROY when connection lost");
# }

#------------------------------------------------------------------------------
$X->QueryPointer($X->{'root'});  # sync

exit 0;
