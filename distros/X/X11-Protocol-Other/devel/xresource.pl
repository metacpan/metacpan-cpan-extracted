#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013 Kevin Ryde

# This file is part of X11-Protocol-Other.
#
# X11-Protocol-Other is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# X11-Protocol-Other is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use X11::Protocol;
use vars '%Keysyms';
use X11::Keysyms '%Keysyms', 'MISCELLANY';

use lib 'devel', '.';
use X11::Protocol::Ext::X_Resource;

# uncomment this to run the ### lines
use Smart::Comments;


{
  # various prints

  my $display = $ENV{'DISPLAY'} || ':0';
  $display = ':1';
  my $X0 = X11::Protocol->new ($display);
  ### resource_id_base: sprintf '%X', $X0->resource_id_base

  my $X = X11::Protocol->new ($display);
  ### resource_id_base: sprintf '%X', $X->resource_id_base

  { my @query = $X->QueryExtension('X-Resource');
    ### @query
  }
  $X->QueryPointer($X->root); # sync

  $X->init_extension('X-Resource') or die $@;
  $X->QueryPointer($X->root); # sync

  { my @version = $X->XResourceQueryVersion (99,99);
    ### @version
  }
  $X->QueryPointer($X->root); # sync

  my @clients = $X->XResourceQueryClients;
  ### @clients
  foreach (@clients) {
    printf "%X %X\n", @$_;
  }
  $X->QueryPointer($X->root); # sync

  {
    # = $Keysyms{'Zenkaku'};
    my $keycode = $X->max_keycode - 2;
    my $modifiers = 0;
    $X->GrabKey ($keycode, $modifiers, $X->root,
                 0, # owner
                 'Asynchronous', 'Asynchronous');
  }
  {
    # = $Keysyms{'Hankaku'};
    my $keycode = $X->max_keycode - 1;
    my $modifiers = 0;
    $X->GrabKey ($keycode, $modifiers, $X->root,
                 0, # owner
                 'Asynchronous', 'Asynchronous');
  }

  my $pixmap;
  foreach (1 .. 1) {
    $pixmap = $X->new_rsrc;
    $X->CreatePixmap ($pixmap,
                      $X->root,
                      $X->{'root_depth'},
                      1000,1000);  # width,height
    # 32767,32767);  # width,height
  }
  $X->QueryPointer($X->root); # sync

  { my @res = $X->XResourceQueryClientResources ($X->resource_id_base);
    ### @res
    { my %res = @res;
      atom_names ($X, values(%res)); }
    while (@res) {
      my $atom = shift @res;
      my $count = shift @res;
      printf "%s (atom %d)   %d\n", atom_name_maybe($X,$atom), $atom, $count;
    }
  }

  require Number::Format;
  my $nf = Number::Format->new;

  foreach my $client (@clients) {
    printf "\nclient %X %X\n", $client->[0], $client->[1];
    my $xid =  $client->[0] + $client->[1];
    my @res = $X->XResourceQueryClientResources ($xid);
    while (@res) {
      my $atom = shift @res;
      my $count = shift @res;
      printf "%s (atom %d)   %d\n", atom_name_maybe($X,$atom), $atom, $count;
    }
    my $bytes = $X->XResourceQueryClientPixmapBytes ($xid);
    my $nbytes = $nf->format_number($bytes);
    print "PixmapBytes $nbytes   $bytes\n";
  }

  exit 0;
}

{
  my $display = $ENV{'DISPLAY'} || ':0';
  my $X = X11::Protocol->new ($display);
  $X->init_extension('X-Resource') or die $@;

  my $pixmap;
  foreach (1 .. 1) {
    $pixmap = $X->new_rsrc;
    $X->CreatePixmap ($pixmap,
                      $X->root,
                      8,
                      1000,1000);  # width,height
  }

  my $bytes = $X->XResourceQueryClientPixmapBytes ($pixmap);
  print "PixmapBytes $bytes\n";
  exit 0;
}

{
  $ENV{'DISPLAY'} ||= ':0';
  my $X = X11::Protocol->new;
  $X->init_extension('X-Resource') or die $@;
  my $clients = [ $X->XResourceQueryClients ];
  ### $clients
  my $xid = $clients->[2]->[0] + 123;
  my $base = clients_xid_to_base ($clients, $xid);
  ### $xid
  ### $base

  sub clients_xid_to_base {
    my ($clients, $xid) = @_;
    my $elem;
    foreach $elem (@$clients) {
      if (($xid & ~ $elem->[1]) == $elem->[0]) {
        return $elem->[0];
      }
    }
    return undef;
  }
  exit 0;
}

{
  my $X = X11::Protocol->new (':0');
  require X11::AtomConstants;
  my @names = atom_names ($X,
                          X11::AtomConstants::WINDOW(),
                          X11::AtomConstants::PIXMAP(),
                         );
  ### @names

  @names = atom_names ($X,
                       X11::AtomConstants::WINDOW(),
                       X11::AtomConstants::COLORMAP(),
                       X11::AtomConstants::PIXMAP(),
                       X11::AtomConstants::FONT(),
                      );
  ### @names

  exit 0;
}

{
  my $data;
  my $result = unpack 'xL', $data;
  ### $data
  exit 0;
}

{
  my $X = X11::Protocol->new (':0');
  $X->{'error_handler'}  = sub {
    my ($X, $data) = @_;
    ### error handler: $data
    return;
  };
  $X->QueryPointer(999999);
  ### exit
  exit 0;
}

{
  my $v = ((0xFFFFFFFF * (2.0**32)) + 0xFFFFFFFF);
  require Devel::Peek;
  Devel::Peek::Dump ($v);
  ### sp: sprintf "%u", $v
  my $bit = ($v & 1);
  ### $bit
  my $test = ($v & 1) == 1;
  ### $test
  exit 0;
}

sub atom_names {
  my $X = shift;
  my @ret;
  my @atom;
  my @seq;
  my @data;
  for (;;) {
    while (@_ && @seq < 100) {  # max 100 sliding window
      my $atom = shift;
      push @atom, $atom;
      my $seq;
      my $name = $X->{'atom_names'}->[$atom];
      if (defined $name) {
        push @data, $name;
      } else {
        $seq = $X->send('GetAtomName',$atom);
        ### send: $seq
        push @data, undef;
        $X->add_reply ($seq, \($data[-1]));
      }
      push @seq, $seq;
    }

    @seq || last;
    my $seq = shift @seq;
    my $atom = shift @atom;
    my $name;
    if (defined $seq) {
      ### handle_input_for: $seq
      $X->handle_input_for ($seq);
      $X->delete_reply($seq);
      $name = $X->unpack_reply ('GetAtomName', shift @data);
      ### $name
      $X->{'atom_names'}->[$atom] = $name;
    } else {
      $name = shift @data;
    }
    push @ret, $name;
  }
  return @ret;
}

sub atom_name_maybe {
  my ($X, $atom) = @_;
  my $ret = $X->robust_req ('GetAtomName', $atom);
  if (ref $ret) {
    return @$ret;
  }
  return '[not-atom]';
}

