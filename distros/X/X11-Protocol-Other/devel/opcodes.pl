#!/usr/bin/perl -w
use strict;
use X11::Protocol;
$ENV{DISPLAY}=":0";

# uncomment this to run the ### lines
use Smart::Comments;

my $X = X11::Protocol->new;
my $depth = $X->root_depth;

my ($major_opcode, $first_event, $first_error) = $X->QueryExtension('RENDER');
### $major_opcode
### $first_event
### $first_error

{
  local $^W = 0;
  if (! $X->init_extension('RENDER')) {
    print "RENDER extension not available on the server\n";
    exit 1;
  }
}

         

