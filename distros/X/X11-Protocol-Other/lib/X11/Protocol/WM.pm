# Copyright 2011, 2012, 2013, 2014, 2016, 2017, 2018, 2019 Kevin Ryde

# This file is part of X11-Protocol-Other.
#
# X11-Protocol-Other is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# X11-Protocol-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.


# /usr/share/doc/xorg-docs/icccm/icccm.txt.gz
# /usr/share/doc/xorg-docs/ctext/ctext.txt.gz
#
# /usr/include/X11/Xutil.h
#    Xlib structs.
#
# http://www.pps.univ-paris-diderot.fr/%7Ejch/software/UTF8_STRING/
# http://www.pps.univ-paris-diderot.fr/%7Ejch/software/UTF8_STRING/UTF8_STRING.text
# /so/netwm/UTF8_STRING.text

BEGIN { require 5 }
package X11::Protocol::WM;
use strict;
use Carp;
use X11::AtomConstants;
use X11::Protocol::Other;

use vars '$VERSION', '@ISA', '@EXPORT_OK';
$VERSION = 31;

use Exporter;
@ISA = ('Exporter');
@EXPORT_OK = qw(
                 frame_window_to_client
                 root_to_virtual_root

                 change_wm_hints
                 change_net_wm_state

                 get_wm_icon_size
                 get_wm_hints
                 get_wm_state
                 get_net_frame_extents
                 get_net_wm_state
                 set_text_property

                 set_wm_class
                 set_wm_client_machine
                 set_wm_client_machine_from_syshostname
                 set_wm_command
                 set_wm_hints
                 set_wm_name
                 set_wm_normal_hints
                 set_wm_icon_name
                 set_wm_protocols
                 set_wm_transient_for

                 set_motif_wm_hints

                 set_net_wm_pid
                 set_net_wm_state
                 set_net_wm_user_time
                 set_net_wm_window_type

                 pack_wm_hints
                 pack_wm_size_hints
                 pack_motif_wm_hints
                 unpack_wm_hints
                 unpack_wm_state
                 aspect_to_num_den

                 iconify
                 withdraw
              );

# uncomment this to run the ### lines
# use Smart::Comments;


#------------------------------------------------------------------------------
# shared bits

BEGIN {
  eval 'utf8->can("is_utf8") && *is_utf8 = \&utf8::is_utf8'   # 5.8.1
    || eval 'use Encode "is_utf8"; 1'                         # 5.8.0
      || eval 'sub is_utf8 { 0 }; 1'                          # 5.6 fallback
        || die 'Oops, cannot create is_utf8() subr: ',$@;
}
### \&is_utf8

sub set_text_property {
  my ($X, $window, $prop, $str) = @_;
  if (defined $str) {
    my $type;
    ($type, $str) = _to_TEXT ($X, $str);
    $X->ChangeProperty ($window,
                        $prop,  # prop name
                        $type,  # type
                        8,      # format
                        'Replace',
                        $str);
  } else {
    $X->DeleteProperty ($window, $prop);
  }
}

# Maybe ...
#
# =item C<$str = _to_STRING ($str)>
#
# Convert C<$str> to latin-1 bytes for use in a STRING property.  If C<$str>
# is already bytes then they're presumed to be latin-1.  If C<$str> is Perl
# 5.8 wide chars then it's converted with the Encode module, and C<croak()>
# if cannot be represented as a STRING.
#
sub _to_STRING {
  my ($str) = @_;
  if (is_utf8($str)) {
    require Encode;
    # croak in the interests of not letting bad values go through unnoticed,
    # nor letting a mangled name be stored
    return Encode::encode ('iso-8859-1', $str, Encode::FB_CROAK());
  } else {
    return $str;
  }
}

# Maybe ...
#
# =item C<($atom, $bytes) = _to_TEXT ($X, $str)>
#
# Convert C<$str> to either C<STRING> or C<COMPOUND_TEXT> per L</Text
# Properties> above.  The returned C<$atom> (an integer) is the either
# C<STRING> or C<COMPOUND_TEXT> and C<$bytes> are bytes of that type.
#
sub _to_TEXT {
  my ($X, $str) = @_;
  if (! is_utf8($str)) {
    # bytes or pre-5.8 taken to be latin-1
    return (X11::AtomConstants::STRING(), $str);
  }
  require Encode;
  {
    my $input = $str; # don't clobber $str
    my $bytes = Encode::encode ('iso-8859-1', $input, Encode::FB_QUIET());
    if (length($input) == 0) {
      # latin-1 suffices
      return (X11::AtomConstants::STRING(), $bytes);
    }
  }
  require Encode::X11;
  return ($X->atom('COMPOUND_TEXT'),
          Encode::encode ('x11-compound-text', $str, Encode::FB_WARN()));
}

# Set a property on $window (integer XID) to a single CARD32 integer value.
# $prop is the property (integer atom ID).
# $type is the property type (integer atom ID).
# $value is a 32-bit integer to store, or undef to delete the property.
#
# The ICCCM or similar specification will say what C<$type> should be in a
# property.  Often there's only one type, but in any case C<$type> indicates
# what has been stored.  This might be for example the atom for "PIXMAP" if
# $value is a pixmap XID.  Things which are counts or numbers are usually
# the atom "CARDINAL".
#
sub _set_card32_property {
  my ($X, $window, $prop, $type, $value) = @_;
  if (defined $value) {
    $X->ChangeProperty ($window,
                        $prop,  # prop name
                        $type,  # type
                        32,     # format
                        'Replace',
                        pack ('L', $value));
  } else {
    $X->DeleteProperty ($window, $prop);
  }
}

# or maybe $X->num('IDorNone',$xid)
#          $X->num('XID',$xid)
sub _num_none {
  my ($xid) = @_;
  if (defined $xid && $xid eq "None") {
    return 0;
  } else {
    return $xid;
  }
}

# or maybe $X->interp('IDorNone',$xid) or 'XIDorNone'
sub _none_interp {
  my ($X, $xid) = @_;
  if ($X->{'do_interp'} && $xid == 0) {
    return 'None';
  } else {
    return $xid;
  }
}

# return $root or if that's undef then lookup root of $window
sub _root_for_window {
  my ($X, $window, $root) = @_;
  if (! defined $root) {
    ($root) = $X->QueryTree($window);
  }
  return $root;
}

#------------------------------------------------------------------------------
# frame_window_to_client()

# /usr/share/doc/libxmu-headers/Xmu.txt.gz for XmuClientWindow()
# https://bugs.freedesktop.org/show_bug.cgi?id=7474
#     XmuClientWindow() bottom-up was hurting fluxbox and probably ion, pekwm
#
sub frame_window_to_client {
  my ($X, $frame) = @_;

  my @search = ($frame);
  my $property = $X->atom('WM_STATE');

  # ENHANCE-ME: do three reqs in parallel, better yet all reqs for an
  # @search depth level in parallel

  my $count = 0;
 OUTER: foreach (1 .. 5) {   # limit search depth for safety
    my $child;
    foreach $child (splice @search) {   # breadth-first search
      ### look at: sprintf '0x%X', $child

      if ($count++ > 50) {
        ### abandon search at count: $count
        return undef;
      }

      {
        my $ret = $X->robust_req ('GetWindowAttributes', $child);
        if (! ref $ret) {
          ### some error, skip this child
          next;
        }
        my %attr = @$ret;
        ### map_state: $attr{'map_state'}
        if ($attr{'map_state'} ne 'Viewable') {
          ### not viewable, skip
          next;
        }
      }
      {
        my $ret = $X->robust_req ('GetProperty',
                                  $child, $property, 'AnyPropertyType',
                                  0,  # offset
                                  0,  # length
                                  0); # delete;
        if (! ref $ret) {
          ### some error, skip this child
          next;
        }
        my ($value, $type, $format, $bytes_after) = @$ret;
        if ($type) {
          ### found
          return $child;
        }
      }
      {
        my $ret = $X->robust_req ('QueryTree', $child);
        if (ref $ret) {
          my ($root, $parent, @children) = @$ret;
          ### push children: @children
          # @children are in bottom up order, prefer the topmost
          push @search, reverse @children;
        }
      }
    }
  }
  ### not found
  return undef;
}


#------------------------------------------------------------------------------
# root_to_virtual_root()

# ENHANCE-ME: Could do all the GetProperty checks in parallel.
# Could intern the VROOT atom during the QueryTree too.
#
sub root_to_virtual_root {
  my ($X, $root) = @_;
  ### root_to_virtual_root(): $root

  my ($root_root, $root_parent, @toplevels) = $X->QueryTree($root);
  my $toplevel;
  foreach $toplevel (@toplevels) {
    ### $toplevel
    my @ret = $X->robust_req ('GetProperty',
                              $toplevel,
                              $X->atom('__SWM_VROOT'),
                              X11::AtomConstants::WINDOW(),  # type
                              0,  # offset
                              1,  # length x 32bits
                              0); # delete;
    ### @ret
    next unless ref $ret[0]; # ignore errors from toplevels destroyed etc

    my ($value, $type, $format, $bytes_after) = @{$ret[0]};
    if (my $vroot = unpack 'L', $value) {
      ### found: $vroot
      return $vroot;
    }
  }
  return $root;
}


#------------------------------------------------------------------------------
# WM_CLASS

sub set_wm_class {
  my ($X, $window, $instance, $class) = @_;
  if (defined $instance) {
    my $str = _to_STRING($instance)."\0"._to_STRING($class)."\0";
    $X->ChangeProperty($window,
                       X11::AtomConstants::WM_CLASS(), # prop
                       X11::AtomConstants::STRING(),   # type
                       8,                              # byte format
                       'Replace',
                       $str);
  } else {
    $X->DeleteProperty ($window, X11::AtomConstants::WM_CLASS());
  }
}


#------------------------------------------------------------------------------
# WM_CLIENT_MACHINE

sub set_wm_client_machine {
  my ($X, $window, $hostname) = @_;
  set_text_property ($X, $window,
                     X11::AtomConstants::WM_CLIENT_MACHINE(), $hostname);
}

sub set_wm_client_machine_from_syshostname {
  my ($X, $window) = @_;
  require Sys::Hostname;
  set_wm_client_machine ($X, $window, eval { Sys::Hostname::hostname() });
}


#------------------------------------------------------------------------------
# WM_COMMAND

sub set_wm_command {
  my $X = shift;
  my $window = shift;

  if (@_ && ! defined $_[0]) {
    # this not documented ...
    $X->DeleteProperty ($window, X11::AtomConstants::WM_COMMAND());
    return;
  }

  # cf join() gives a wide-char result if any parts wide, upgrading byte
  # strings as if they were latin-1
  my $value = '';
  my $type = X11::AtomConstants::STRING();
  my $str;
  foreach $str (@_) {
    my ($atom, $bytes) = _to_TEXT($X,$str);
    if ($atom != X11::AtomConstants::STRING()) {
      $type = $atom;  # COMPOUND_TEXT if any part needs COMPOUND_TEXT
    }
    $value .= "$bytes\0";
  }
  if ($value eq "\0") {
    $value = "";  # this not documented ...
    # C<$command> can be an empty string "" to mean no known command as a
    # reply to C<WM_SAVE_YOURSELF> ... maybe
  }
  $X->ChangeProperty ($window,
                      X11::AtomConstants::WM_COMMAND(), # prop name
                      $type,  # type
                      8,      # format
                      'Replace',
                      $value);
}


#------------------------------------------------------------------------------
# WM_ICON_SIZE

sub get_wm_icon_size {
  my ($X, $root) = @_;
  if (! defined $root) {
    $root = $X->root;
  }
  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($root,
                       X11::AtomConstants::WM_ICON_SIZE(),  # property
                       X11::AtomConstants::WM_ICON_SIZE(),  # type
                       0,   # offset
                       6,   # length CARD32s
                       0);  # delete;
  if ($format == 32) {
    return unpack 'L6', $value;
  } else {
    return;
  }
}


#------------------------------------------------------------------------------
# WM_HINTS

sub set_wm_hints {
  my $X = shift;
  my $window = shift;
  ### set_wm_hints(): @_
  ### set cards: map {sprintf '%#x',$_} unpack 'L*', pack_wm_hints($X,@_)
  $X->ChangeProperty($window,
                     X11::AtomConstants::WM_HINTS(), # prop name
                     X11::AtomConstants::WM_HINTS(), # type
                     32,           # format
                     'Replace',
                     pack_wm_hints($X, @_));
}

sub get_wm_hints {
  my ($X, $window) = @_;
  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window,
                       X11::AtomConstants::WM_HINTS(), # prop name
                       X11::AtomConstants::WM_HINTS(), # type
                       0,             # offset
                       9,             # length($format), of CARD32
                       0);            # no delete
  if ($format == 32) {
    ### got cards: map {sprintf '%#x',$_} unpack 'L*', $value
    return unpack_wm_hints ($X, $value);
  } else {
    return;
  }
}

sub change_wm_hints {
  my $X = shift;
  my $window = shift;
  set_wm_hints ($X, $window, get_wm_hints($X,$window), @_);
}

{
  my $format = 'LLLLLllLL';
  # The C<urgency> hint was called "visible" in X11R5.  The name "urgency"
  # is used here per X11R6.  The actual field sent and received is the same.
  #
  my %key_to_flag = (input         => 1,
                     initial_state => 2,
                     icon_pixmap   => 4,
                     icon_window   => 8,
                     icon_x        => 16,
                     icon_y        => 16,
                     icon_mask     => 32,
                     window_group  => 64,
                     # message     => 128, # in the code, obsolete
                     # urgency     => 256, # in the code
                    );

  sub pack_wm_hints {
    my ($X, %hint) = @_;
    ### pack_wm_hints(): %hint
    my $flags = 0;
    if (delete $hint{'message'}) {
      $flags = 128;
    }
    if (delete $hint{'urgency'}) {
      $flags |= 256;
    }
    my $key;
    foreach $key (keys %hint) {
      my $flag_bit = $key_to_flag{$key}
        || croak "Unknown WM_HINT field: ",$key;
      if (defined $hint{$key}) {
        $flags |= $flag_bit;
      }
    }
    return pack ($format,
                 $flags,
                 $hint{'input'} || 0,                       # CARD32 bool
                 _wmstate_num($hint{'initial_state'}) || 0, # CARD32 enum
                 _num_none($hint{'icon_pixmap'}) || 0,      # PIXMAP
                 _num_none($hint{'icon_window'}) || 0,      # WINDOW
                 $hint{'icon_x'} || 0,                      # INT32
                 $hint{'icon_y'} || 0,                      # INT32
                 _num_none($hint{'icon_mask'}) || 0,        # PIXMAP
                 _num_none($hint{'window_group'}) || 0);    # WINDOW
  }

  # X11R2 Xlib had a bug where XSetWMHints() set a WM_HINTS property to only
  # 8 CARD32s, chopping off the window_group field.  This was due to
  # Xatomtype.h NumPropWMHintsElements being 8 instead of 9.  If the length
  # of $bytes here is only 8 then ignore any window_group bit in the flags
  # and don't return a window_group field.  X11R2 source available at
  # http://ftp.x.org/pub/X11R2/X.V11R2.tar.gz
  #
  my @keys = ('input',
              'initial_state',
              'icon_pixmap',
              'icon_window',
              'icon_x',
              'icon_y',
              'icon_mask',
              'window_group',
              # 'message',      # in the code, and obsolete ...
              # 'urgency',      # in the code
             );
  my @interp = (\&_unchanged,                          # input
                \&_wmstate_interp,   # initial_state
                \&_none_interp,      # icon_pixmap
                \&_none_interp,      # icon_window
                \&_unchanged,                           # icon_x
                \&_unchanged,                           # icon_y
                \&_none_interp,      # icon_mask
                \&_none_interp,      # window_group
               );
  sub unpack_wm_hints {
    my ($X, $bytes) = @_;
    ### unpack_wm_hints(): unpack 'L*', $bytes
    my ($flags, @values) = unpack ($format, $bytes);
    my $bit = 1;
    my @ret;
    my $i;
    foreach $i (0 .. $#keys) {
      my $value = $values[$i];
      if (! defined $value) {
        # if $bytes is only 8 CARD32s as from X11R2 then omit window_group
        # from the return
        next;
      }
      if ($flags & $bit) {
        push @ret, $keys[$i], &{$interp[$i]}($X, $value);
      }
      $bit <<= ($i!=4);  # icon_x,icon_y both at $bit==16
    }
    if ($flags & 128) {
      push @ret, message => 1;
    }
    if ($flags & 256) {
      push @ret, urgency => 1;
    }
    return @ret;
  }
}

sub _unchanged {
  my ($X, $value) = @_;
  return $value;
}


#------------------------------------------------------------------------------
# WM_ICON_NAME

sub set_wm_icon_name {
  my ($X, $window, $name) = @_;
  set_text_property ($X, $window, X11::AtomConstants::WM_ICON_NAME(), $name);
}


#------------------------------------------------------------------------------
# WM_NAME

sub set_wm_name {
  my ($X, $window, $name) = @_;
  set_text_property ($X, $window, X11::AtomConstants::WM_NAME(), $name);
}

#------------------------------------------------------------------------------
# WM_PROTOCOLS

sub set_wm_protocols {
  my $X = shift;
  my $window = shift;
  my $property = $X->atom('WM_PROTOCOLS');
  if (@_) {
    X11::Protocol::Other::set_property_atoms ($X, $window, $property,
                                              _to_atom_nums($X,@_));
  } else {
    $X->DeleteProperty ($window, $property);
  }
}

# Take atom names or numbers, return atom numbers.  Convenient, but atom
# names can be numbers so this is good only where don't have such names.
sub _to_atom_nums {
  my $X = shift;
  return map { ($_ =~ /^\d+$/ ? $_ : $X->atom($_)) } @_;
}


#------------------------------------------------------------------------------
# WM_STATE enum
# For internal use yet ...

{
  my %wmstate = (WithdrawnState => 0,
                 DontCareState  => 0, # no longer in ICCCM
                 NormalState    => 1,
                 ZoomState      => 2, # no longer in ICCCM
                 IconicState    => 3,
                 InactiveState  => 4, # no longer in ICCCM
                );
  sub _wmstate_num {
    my ($wmstate) = @_;
    if (defined $wmstate && defined (my $num = $wmstate{$wmstate})) {
      return $num;
    }
    return $wmstate;
  }
}

{
  # DontCareState==0 no longer ICCCM
  my @wmstate = ('WithdrawnState', # 0
                 'NormalState',    # 1
                 'ZoomState',      # 2, no longer ICCCM
                 'IconicState',    # 3
                 'InactiveState',  # 4, no longer in ICCCM
                );
  sub _wmstate_interp {
    my ($X, $num) = @_;
    if ($X->{'do_interp'} && defined (my $str = $wmstate[$num])) {
      return $str;
    }
    return $num;
  }
}

# Maybe through $X->interp() with ...
#
# {
#   # $X->interp('WmState',$num);
#   # $X->num('WmState',$str);
#   my %const_arrays
#     = (
#        WmState => ['WithdrawnState', # 0
#                    'NormalState',    # 1
#                    'ZoomState',      # 2, no longer ICCCM
#                    'IconicState',    # 3
#                    'InactiveState',  # 4, no longer in ICCCM
#                   ],
#       );
#
#   my %const_hashes
#     = (map { $_ => { X11::Protocol::make_num_hash($const_arrays{$_}) } }
#        keys %const_arrays);
#
#
#   sub ext_const_init {
#     my ($X) = @_;
#     unless ($X->{'ext_const'}->{'WmState'}) {
#       %{$X->{'ext_const'}} = (%{$X->{'ext_const'}}, %const_arrays);
#       $X->{'ext_const_num'} ||= {};
#       %{$X->{'ext_const_num'}} = (%{$X->{'ext_const_num'}}, %const_hashes);
#     }
#   }
# }


#------------------------------------------------------------------------------
# WM_STATE

sub get_wm_state {
  my ($X, $window) = @_;
  my $xa_wm_state = $X->atom('WM_STATE');
  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window,
                       $xa_wm_state,  # property
                       $xa_wm_state,  # type
                       0,             # offset
                       2,             # length, 2 x CARD32
                       0);            # delete
  if ($format == 32) {
    return unpack_wm_state($X,$value);
  } else {
    return;
  }
}

sub unpack_wm_state {
  my ($X, $data) = @_;
  my ($state, $icon_window) = unpack 'LL', $data;
  return (_wmstate_interp($X,$state), _none_interp($X,$icon_window));
}


#------------------------------------------------------------------------------
# WM_STATE transitions

# cf /so/xorg/libX11-1.4.0/src/Iconify.c
#
sub iconify {
  my ($X, $window, $root) = @_;
  ### iconify(): $window

  # The icccm spec doesn't seem to say any particular event mask for this
  # ClientMessage, but follow Xlib Iconify.c and send
  # SubstructureRedirect+SubstructureNotify.
  #
  _send_event_to_wm ($X, _root_for_window($X,$window,$root),
                     name   => 'ClientMessage',
                     window => $window,
                     type   => $X->atom('WM_CHANGE_STATE'),
                     format => 32,
                     data   => pack('L5', 3)); # 3=IconicState
}

# cf /so/xorg/libX11-1.4.0/src/Withdraw.c
#
sub withdraw {
  my ($X, $window, $root) = @_;
  ### withdraw(): $window, $root
  $root = _root_for_window($X,$window,$root); # QueryTree before unmap
  $X->UnmapWindow ($window);
  _send_event_to_wm ($X, $root,
                     name   => 'UnmapNotify',
                     event  => $root,
                     window => $window,
                     from_configure => 0);
}

# =item C<_send_event_to_wm ($X, $root, name=E<gt>$str,...)>
#
# Send an event to the window manager by C<$X-E<gt>SendEvent()> to the given
# C<$root> (integer XID of a root window).
#
# The key/value parameters specify an event packet as per
# C<$X-E<gt>pack_event()>.  Often this is a C<ClientMessage> event, but any
# type can be sent.  (For example C<withdraw()> sends a synthetic
# C<UnmapNotify>.)
#
# But: event-mask=ColormapChange for own colormap install setups ...
# But: event-mask=StructureNotify for "manager" acquiring resource ...
#
sub _send_event_to_wm {
  my $X = shift;
  my $root = shift;
  $X->SendEvent ($root,
                 0,  # all clients
                 $X->pack_event_mask('SubstructureRedirect',
                                     'SubstructureNotify'),
                 $X->pack_event(@_));
}


#------------------------------------------------------------------------------
# WM_TRANSIENT

# $transient_for eq 'None' supported for generality, but not yet documented
# since not sure such a property value would be ICCCM compliant
#
sub set_wm_transient_for {
  my ($X, $window, $transient_for) = @_;
  _set_card32_property ($X, $window,
                        X11::AtomConstants::WM_TRANSIENT_FOR(),  # prop name
                        X11::AtomConstants::WINDOW(),            # type
                        _num_none ($transient_for));
}

# not sure about this, might be only used by window manager, not a client
# =item C<$transient_for = X11::Protocol::WM::get_wm_transient_for ($X, $window)>
# sub get_wm_transient_for {
#   my ($X, $window) = @_;
#   _get_property_card32 ($X, $window,
#                         X11::AtomConstants::WM_TRANSIENT_FOR(),
#                         X11::AtomConstants::WINDOW());
# }


#------------------------------------------------------------------------------
# _MOTIF_WM_HINTS

sub set_motif_wm_hints {
  my $X = shift;
  my $window = shift;
  $X->ChangeProperty($window,
                     $X->atom('_MOTIF_WM_HINTS'), # property
                     $X->atom('_MOTIF_WM_HINTS'), # type
                     32,                          # format
                     'Replace',
                     pack_motif_wm_hints ($X, @_));
}

{
  # per /usr/include/Xm/MwmUtil.h
  my %key_to_flag = (functions   => 1,
                     decorations => 2,
                     input_mode  => 4,
                     status      => 8,
                    );
  sub pack_motif_wm_hints {
    my ($X, %hint) = @_;

    my $flags = 0;
    my $key;
    foreach $key (keys %hint) {
      if (defined $hint{$key}) {
        $flags |= $key_to_flag{$key};
      } else {
        croak "Unrecognised _MOTIF_WM_HINTS field: ",$key;
      }
    }
    pack ('L5',
          $flags,
          $hint{'functions'} || 0,
          $hint{'decorations'} || 0,
          _motif_input_mode_num($X, $hint{'input_mode'} || 0),
          $hint{'status'} || 0);
  }
}
{
  my %input_mode_num = (modeless                  => 0,
                        primary_application_modal => 1,
                        system_modal              => 2,
                        full_application_modal    => 3,

                        # application_modal         => 1,
                       );
  sub _motif_input_mode_num {
    my ($X, $input_mode) = @_;
    if (exists $input_mode_num{$input_mode}) {
      return $input_mode_num{$input_mode};
    } else {
      return $input_mode;
    }
  }
}



#------------------------------------------------------------------------------
# _NET_FRAME_EXTENTS

sub get_net_frame_extents {
  my ($X, $window) = @_;
  my ($value, $type, $format, $bytes_after)
    = $X->GetProperty ($window,
                       $X->atom('_NET_FRAME_EXTENTS'),  # property
                       X11::AtomConstants::CARDINAL(),  # type
                       0,    # offset
                       4,    # length, 4 x CARD32
                       0);   # delete
  if ($format == 32) {
    return unpack 'L4', $value;
  } else {
    return;
  }
}

#------------------------------------------------------------------------------
# _NET_WM_PID

sub set_net_wm_pid {
  my ($X, $window, $pid) = @_;
  if (@_ < 3) { $pid = $$; }
  _set_card32_property ($X,
                        $window,
                        $X->atom('_NET_WM_PID'),
                        X11::AtomConstants::CARDINAL(),
                        $pid);
}

#------------------------------------------------------------------------------
# _NET_WM_STATE

sub get_net_wm_state {
  my ($X, $window) = @_;
  # ENHANCE-ME: maybe atom_names() for parallel name fetch
  return map {_net_wm_state_interp($X,$_)} get_net_wm_state_atoms($X,$window);
}
# $atom is an atom integer, return a string like "FULLSCREEN".
sub _net_wm_state_interp {
  my ($X, $atom) = @_;
  my $state = $X->atom_name($atom);
  $state =~ s/^_NET_WM_STATE_//;
  return $state;
}

sub get_net_wm_state_atoms {
  my ($X, $window) = @_;
  return X11::Protocol::Other::get_property_atoms
    ($X, $window, $X->atom('_NET_WM_STATE'));
}

# $state can be string like "FULLSCREEN"
#               string like "_NET_WM_STATE_FULLSCREEN"
#               integer atom number
# Integer returned unchanged.
# Otherwise get atom number of full name like "_NET_WM_STATE_FULLSCREEN".
sub _net_wm_state_num {
  my ($X, $state) = @_;
  if (! defined $state) {
    return 0;
  }
  if ($state =~ /^\d+$/) {
    return $state;  # a number already
  }
  if ($state !~ /^_NET_WM_STATE_/) {
    $state = '_NET_WM_STATE_' . $state;
  }
  return $X->atom($state);
}

sub set_net_wm_state {
  my $X = shift;
  my $window = shift;
  X11::Protocol::Other::set_property_atoms
      ($X, $window,
       $X->atom('_NET_WM_STATE'),           # property
       map {_net_wm_state_num($X,$_)} @_);  # states
}

{
  my %_net_wm_state_action_num = (remove => 0,
                                  add    => 1,
                                  toggle => 2);
  # $action is a string "add" etc, or a number 0,1,2.
  # Return a number 0,1,2.
  sub _net_wm_state_action_num {
    my ($X, $action) = @_;
    ### _net_wm_state_action_num(): $action
    if ($action =~ /^\d+$/) {
      return $action;  # a number already
    }
    my $num = $_net_wm_state_action_num{$action};
    if (defined $num) {
      return $num;
    }
    croak 'Unrecognized _NET_WM_STATE action: ',$action;
  }
}

{
  my %_net_wm_source_num = (none   => 0,
                            normal => 1,
                            user   => 2);
  # $source is a string "normal" etc, or a number 0,1,2.
  # Return a number 0,1,2.
  sub _net_wm_source_num {
    my ($X, $source) = @_;
    if (! defined $source) {
      return 1;  # default "normal"
    }
    if ($source =~ /^\d+$/) {
      return $source;  # a number already
    }
    my $num = $_net_wm_source_num{$source};
    if (defined $num) {
      return $num;
    }
    croak 'Unrecognized _NET_WM source: ',$source;
  }
}

sub change_net_wm_state {
  my ($X, $window, $action, $state, %h) = @_;
  ### change_net_wm_state() ...
  ### $state
  ### %h

  my $root = X11::Protocol::WM::_root_for_window($X,$window,
                                                 delete $h{'root'});
  my $state2 = _net_wm_state_num($X, delete $h{'state2'});
  my $source = _net_wm_source_num($X, delete $h{'source'});
  if (%h) {
    croak "change_net_wm_state() unrecognised parameter(s): ",
      join(',',keys %h);
  }
  X11::Protocol::WM::_send_event_to_wm ($X, $root,
                     name   => 'ClientMessage',
                     window => $window,
                     type   => $X->atom('_NET_WM_STATE'),
                     format => 32,
                     data   => pack('L5',
                                    _net_wm_state_action_num($X, $action),
                                    _net_wm_state_num($X, $state),
                                    $state2,
                                    $source));
}

#------------------------------------------------------------------------------
# _NET_WM_WINDOW_TYPE

sub set_net_wm_window_type {
  my ($X, $window, $window_type) = @_;
  X11::Protocol::Other::set_property_atoms
      ($X, $window, $X->atom('_NET_WM_WINDOW_TYPE'),
       _net_wm_window_type_to_atom($X, $window_type));
}

# not documented yet ...
sub _net_wm_window_type_to_atom {
  my ($X, $window_type) = @_;
  if (! defined $window_type || $window_type =~ /^\d+$/) {
    return $window_type;
  } else {
    return $X->atom ("_NET_WM_WINDOW_TYPE_$window_type");
  }
}

# unless ($window_type =~ /^_NET_WM/) {
# }
# my ($akey, $atype) = _atoms ($X,
#                              '_NET_WM_WINDOW_TYPE',
#                              "_NET_WM_WINDOW_TYPE_$window_type");
#  a type stringcan be an atom integer, a full atom name like
# "_NET_WM_WINDOW_TYPE_NORMAL", or just the type part "NORMAL".


#------------------------------------------------------------------------------
# _NET_WM_USER_TIME

sub set_net_wm_user_time {
  my ($X, $window, $time) = @_;
  _set_card32_property ($X,
                        $window,
                        $X->atom('_NET_WM_USER_TIME'),
                        X11::AtomConstants::CARDINAL(),
                        $time);
}

#------------------------------------------------------------------------------
# WM_NORMAL_HINTS

sub set_wm_normal_hints {
  my $X = shift;
  my $window = shift;
  $X->ChangeProperty($window,
                     X11::AtomConstants::WM_NORMAL_HINTS(),  # property
                     X11::AtomConstants::WM_SIZE_HINTS(),    # type
                     32,                                     # format
                     'Replace',
                     pack_wm_size_hints ($X, @_));
}

{
  my %key_to_flag =
    (user_position    => 1,   # user-specified window x,y
     user_size        => 2,   # user-specified win width,height
     program_position => 4,   # program-specified window x,y
     program_size     => 8,   # program-specified win width,height
     min_width        => 16,
     min_height       => 16,
     max_width        => 32,
     max_height       => 32,
     width_inc        => 64,
     height_inc       => 64,
     min_aspect       => 128,
     min_aspect_num   => 128,
     min_aspect_den   => 128,
     max_aspect       => 128,
     max_aspect_num   => 128,
     max_aspect_den   => 128,
     base_width       => 256,
     base_height      => 256,
     win_gravity      => 512,
    );
  sub pack_wm_size_hints {
    my ($X, %hint) = @_;
    ### pack_wm_size_hints(): %hint

    my $flags = 0;
    my $key;
    foreach $key (keys %hint) {
      if (defined $hint{$key}) {
        $flags |= $key_to_flag{$key};
      } else {
        croak "Unrecognised WM_NORMAL_HINTS field: ",$key;
      }
    }
    pack ('Lx16L13',
          $flags,
          $hint{'min_width'} || 0,        # 1
          $hint{'min_height'} || 0,       # 2
          $hint{'max_width'} || 0,        # 3
          $hint{'max_height'} || 0,       # 4
          $hint{'width_inc'} || 0,        # 5
          $hint{'height_inc'} || 0,       # 6
          _aspect (\%hint, 'min'),        # 7,8
          _aspect (\%hint, 'max'),        # 9,10
          $hint{'base_width'} || 0,       # 11
          $hint{'base_height'} || 0,      # 12
          $X->num('WinGravity',$hint{'win_gravity'} || 0),  # 13
         );
  }
}
sub _aspect {
  my ($hint, $which) = @_;
  if (defined (my $aspect = $hint->{"${which}_aspect"})) {
    return aspect_to_num_den($aspect);
  } else {
    return ($hint->{"${which}_aspect_num"} || 0,
            $hint->{"${which}_aspect_den"} || 0);
  }
}
sub aspect_to_num_den {
  my ($aspect) = @_;
  ### $aspect

  my ($num, $den);

  if ($aspect =~ /^\d+$/) {
    ### integer
    $num = $aspect;
    $den = 1;
  } elsif (($num,$den) = ($aspect =~ m{(.*)/(.*)})) {
    ### slash fraction
  } else {
    $num = $aspect;
    $den = 1;
  }

  my $den_zeros = 0;
  if ($num =~ /^0*(\d*)\.(\d*?)0*$/) {
    ### decimal
    $num = "$1$2";
    $den_zeros = length($2);
  }
  if ($den =~ /^0*(\d*)\.(\d*?)0*$/) {
    ### decimal
    $den = "$1$2";
    $den_zeros -= length($2);
  }
  if ($den_zeros > 0) {
    $den .= '0' x $den_zeros;
  }
  if ($den_zeros < 0) {
    $num .= '0' x -$den_zeros;
  }

  if ($num == $num-1) {  # infinity
    return (0x7FFF_FFFF, ($den == $den-1  # infinity too
                          ? 0x7FFF_FFFF : 1));
  }
  if ($den == $den-1) {  # infinity
    return (1, 0x7FFF_FFFF);
  }

  # cap anything bigger than 0x7FFFFFFF
  if ($num >= $den && $num > 0x7FFF_FFFF) {
    ### reduce big numerator
    ($num,$den) = _aspect_reduce($num,$den);
  }
  if ($den > 0x7FFF_FFFF) {
    ### reduce big denominator
    ($den,$num) = _aspect_reduce($den,$num);
  }

  # increase non-integers in binary
  while ((int($num) != $num || int($den) != $den)
         && $num < 0x4000_0000
         && $den < 0x4000_0000) {
    $num *= 2;
    $den *= 2;
    ### up to: $num,$den
  }

  return (_round_nz($num), _round_nz($den));
}

# Return $x rounded to the nearest integer.
# If $x is not zero then the return is not zero too, ie. $x<0.5 is rounded
# up to return 1.
sub _round_nz {
  my ($x) = @_;
  my $nz = ($x != 0);
  $x = int ($x + 0.5);
  if ($nz && $x == 0) {
    return 1;
  } else {
    return $x;
  }
}

# $x is > 0x7FFF_FFFF.  Reduce it to 0x7FFF_FFFF and reduce $y in proportion.
# If $y!=0 then it's reduced to a minimum 1, not to 0.
sub _aspect_reduce {
  my ($x,$y) = @_;
  my $nz = ($y != 0);
  $y = int (0.5 + $y / $x * 0x7FFF_FFFF);
  if ($nz && $y == 0) { $y = 1; }
  elsif ($y > 0x7FFF_FFFF) { $y = 0x7FFF_FFFF; }
  return (0x7FFF_FFFF, $y);
}
# printf "%d %d", _aspect_frac('.123456789');



1;
__END__

# Maybe:

# =item C<$window_type = X11::Protocol::WM::get_net_wm_window_type_atom ($X, $window)>
#
# C<get_net_wm_window_type_atom> returns C<$window_type> as an atom (integer).
#
# not documented ...
# sub _get_net_wm_window_type_atom {
#   my ($X, $window) = @_;
#   _get_property_card32 ($X, $window,
#                         $X->atom('_NET_WM_WINDOW_TYPE'),
#                         X11::AtomConstants::ATOM());
# }

# not documented ...
# sub _get_property_card32 {
#   my ($X, $window, $prop, $type) = @_;
#   my ($value, $got_type, $format, $bytes_after)
#     = $X->GetProperty ($window,
#                        $prop,
#                        $type,
#                        0,  # offset
#                        1,  # length, 1 x CARD32
#                        0); # delete
#   if ($format == 32) {
#     $ret = scalar(unpack 'L', $value);
#     if ($type == X11::AtomConstants::WINDOW()
#         || $type == X11::AtomConstants::PIXMAP()) {
#       if ($ret == 0 && $X->{'do_interp'}) {
#         $ret = 'None';
#       }
#     }
#     return $ret;
#   } else {
#     return undef;
#   }
# }



=for stopwords Ryde XID NETWM enum NormalState IconicState ICCCM ClientMessage iconify EWMH multi-colour ie pixmap iconified toplevel WithdrawnState keypress KeyRelease ButtonRelease popup Xlib OOP OOPery encodings lookup XTerm hostname localhost filename latin-1 POSIX EBCDIC ebcdic resizing scrollbar 0x7FFFFFFF de-iconified recognises recognised unrecognised unmapped there'll reparented bitwise tearoff Tearoff tearoffs programmatically PID KDE

=head1 NAME

X11::Protocol::WM -- window manager things for client programs

=head1 SYNOPSIS

 use X11::Protocol::WM;

=head1 DESCRIPTION

This is some window manager related functions for use by client programs, as
per the "Inter-Client Communication Conventions Manual" and some of the
Net-WM "Extended Window Manager Hints".

=over

F</usr/share/doc/xorg-docs/icccm/icccm.txt.gz>

L<http://www.freedesktop.org/wiki/Specifications/wm-spec>

=back

=head2 Usual Properties

Every toplevel client window should usually

=over

=item *

C<set_wm_class()> to identify itself to other programs (see L</WM_CLASS>
below).

=item *

C<set_wm_name()> and C<set_wm_icon_name()> for user-visible window name (see
L</WM_NAME, WM_ICON_NAME> below).

=item *

C<set_wm_client_machine_from_syshostname()> and C<set_net_wm_pid()> for the
running process (see L</WM_CLIENT_MACHINE> and L</_NET_WM_PID> below).

=back

Then optionally,

=over

=item *

If you have an icon then C<set_wm_hints()> with a bitmap or a window (see
L</WM_HINTS> below).

=item *

If the user gave an initial size or position on the command line then
C<set_wm_normal_hints()>.  The same if the program has min/max sizes or
aspect ratio desired (see L</WM_NORMAL_HINTS> below).

=item *

If a command to re-run the program can be constructed then
C<set_wm_command()>, and preferably keep that up-to-date with changes such
as currently open file etc (see L</WM_COMMAND> below).

=back

=head1 FUNCTIONS

=head2 Text Properties

Property functions taking text strings such as C<set_wm_name()> accept
either byte strings or wide char strings (Perl 5.8 up).  Byte strings are
presumed to be Latin-1 and set as C<STRING> type in properties.  Wide char
strings are stored as C<STRING> if entirely Latin-1, or encoded to
C<COMPOUND_TEXT> for other chars (see L<Encode::X11>).

In the future perhaps the string functions could accept some sort of
compound text object to represent segments of various encodings to become
C<COMPOUND_TEXT>, together with manipulations for such content etc.  If text
is bytes in one of the ICCCM encodings then it might save work to represent
it directly as C<COMPOUND_TEXT> segments rather than going to wide chars and
back again.

=over

=item C<set_text_property ($X, $window, $prop, $str)>

Set the given C<$prop> (integer atom) property on C<$window> (integer XID)
using either C<STRING> or C<COMPOUND_TEXT> as described above.  If C<$str> is
C<undef> then C<$prop> is deleted.

C<$str> is limited to C<$X-E<gt>maximum_request_length()>.  In theory longer
strings can be stored by piecewise, but there's no attempt to do that here.
The maximum request limit is at least 16384 bytes and the server may allow
more, possibly much more.

=back

=head2 WM_CLASS

=over 4

=item C<X11::Protocol::WM::set_wm_class ($X, $window, $instance, $class)>

Set the C<WM_CLASS> property on C<$window> (an XID).

This property may be used by the window manager to lookup settings and
preferences for the program through the X Resource system (see "RESOURCES"
in L<X(7)>) or similar.

Usually the instance name is the program command such as "xterm" and the
class name something like "XTerm".  Some programs have command line options
to set the class and/or instance so the user can have different window
manager settings applied to a particular running copy of a program.

    X11::Protocol::WM::set_wm_class ($X, $window,
                                     "myprog", "MyProg");

C<$instance> and C<$class> must be ASCII or Latin-1 only.  Wide-char strings
which are Latin-1 are converted as necessary.

=back

=head2 WM_CLIENT_MACHINE

=over 4

=item C<X11::Protocol::WM::set_wm_client_machine ($X, $window, $hostname)>

Set the C<WM_CLIENT_MACHINE> property on C<$window> to C<$hostname> (a
string).

C<$hostname> should be the name of the client machine as seen from the
server.  If C<$hostname> is C<undef> then the property is deleted.

Usually a machine name is ASCII-only, but anything per L</Text Properties>
above is accepted.

=item C<X11::Protocol::WM::set_wm_client_machine_from_syshostname ($X, $window)>

Set the C<WM_CLIENT_MACHINE> property on C<$window> using the
L<Sys::Hostname> module.

If C<Sys::Hostname> can't determine a hostname by its various gambits then
currently the property is deleted.  Would it be better to leave it
unchanged, or return a flag to say if set?

Some of the C<Sys::Hostname> cases might return "localhost".  That's put
through unchanged, on the assumption that it would be when there's no
networking beyond the local host so client and server are on the same
machine and name "localhost" suffices.

=back

=head2 WM_COMMAND

=over 4

=item C<X11::Protocol::WM::set_wm_command ($X, $window, $command, $arg...)>

Set the C<WM_COMMAND> property on C<$window> (an XID).

This should be a program name and argument strings which will restart the
client.  C<$command> is the program name, followed by any argument strings.

    X11::Protocol::WM::set_wm_command ($X, $window,
                                       'myprog',
                                       '--option',
                                       'filename.txt');

The command should start the client in its current state, so the command
might include a filename, command line options for current settings, etc.

Non-ASCII is allowed per L</Text Properties> above.  The ICCCM spec is for
Latin-1 to work on a POSIX Latin-1 system, but how well anything else
survives a session manager etc is another matter.

A client can set this at any time, or if participating in the
C<WM_SAVE_YOURSELF> session manager protocol then it should set in response
to a C<ClientMessage> of C<WM_SAVE_YOURSELF> .

For reference, under C<mwm> circa 2017, a client with C<WM_SAVE_YOURSELF>
receives that message for the C<mwm> Close button (C<f.kill>) and is
expected to respond within a timeout (default 1 second), whereupon C<mwm>
closes the client connection (C<KillClient>).  Unfortunately if both
C<WM_SAVE_YOURSELF> and C<WM_DELETE_WINDOW> then C<mwm> still does the
C<WM_SAVE_YOURSELF> and close, defeating the aim of letting
C<WM_DELETE_WINDOW> query the user and perhaps not close.

The easiest workaround would be use only C<WM_DELETE_WINDOW>, keep
C<WM_COMMAND> always up-to-date, and be prepared to save state on connection
loss.  This is quite reasonable anyway actually, since a C<WM_SAVE_YOURSELF>
message is fairly limited use, given that connection loss or other
termination could happen at any time so if state is important that it'd be
prudent to keep it saved.

=back

=head2 WM_ICON_SIZE

=over

=item C<($min_width,$min_height, $max_width,$max_height, $width_inc,$height_inc) = X11::Protocol::WM::get_wm_icon_size($X,$root)>

Return the window manager's C<WM_ICON_SIZE> recommended icon sizes (in
pixels) as a range, and increment above the minimum.  If there's no
C<WM_ICON_SIZE> property then return an empty list.

C<$root> is the root window to read.  If omitted then read the
C<$X-E<gt>root> default.

An icon pixmap or window in C<WM_HINTS> should be a size in this range.
Many window managers don't set a preferred icon size.  32x32 might be
typical on a small screen or 48x48 on a bigger screen.

=back

=head2 WM_HINTS

=over 4

=item C<X11::Protocol::WM::set_wm_hints ($X, $window, key=E<gt>value, ...)>

Set the C<WM_HINTS> property on C<$window> (an XID).  For example,

    X11::Protocol::WM::set_wm_hints
        ($X, $my_window,
         input         => 1,
         initial_state => 'NormalState',
         icon_pixmap   => $my_pixmap);

The key/value parameters are as follows.

    input             integer 0 or 1
    initial_state     enum string or number
    icon_pixmap       pixmap (XID integer), depth 1
    icon_window       window (XID integer)
    icon_x            \ integer coordinate
    icon_y            / integer coordinate
    icon_mask         pixmap (XID integer)
    window_group      window (XID integer)
    urgency           boolean

C<input> is 1 if the client wants the window manager to give C<$window> the
keyboard input focus.  This will be with C<$X-E<gt>SetInputFocus()>, or if
C<WM_TAKE_FOCUS> is in C<WM_PROTOCOLS> then instead by a C<ClientMessage>.

C<input> is 0 if the window manager should not give the client the focus.
This is either because C<$window> is output-only, or if C<WM_TAKE_FOCUS> is
in C<WM_PROTOCOLS> then because the client will do a C<SetInputFocus()> to
itself on an appropriate button press etc.

C<initial_state> is a string or number.  The ICCCM allows "NormalState" or
"IconicState" as initial states.

    "NormalState"       1
    "IconicState"       3

C<icon_pixmap> should be a bitmap, ie. a pixmap (XID) with depth 1.  The
window manager will draw it in suitable contrasting colours.  "1" pixels are
foreground and "0" is background.  C<icon_mask> bitmap is applied to the
displayed icon.  It can be used to make a non-rectangular icon.

C<icon_window> is a window which the window manager may show when C<$window>
is iconified.  This can be used for a multi-colour icon, done either by a
background or by client drawing (in response to C<Expose> events, or updated
periodically for a clock, etc).  The C<icon_window> should be a child of the
root and should use the default visual and colormap of the screen.  The
window manager might resize the window and/or border.

The window manager might set a C<WM_ICON_SIZE> property on the root window
for good icon sizes.  See L</WM_ICON_SIZE> above.

C<window_group> is the XID of a window which is the group leader of a group
of top-level windows being used by the client.  The window manager might
provide a way to manipulate the group as a whole, for example to iconify it
all.  If iconified then the icon hints of the leader are used for the icon.
The group leader can be an unmapped window.  It can be convenient to use a
never-mapped window as the leader for all subsequent windows.

C<urgency> true means the window is important and the window manager should
draw the user's attention to it in some way.  The client can change this
hint at any time to change the current importance.

=item C<(key =E<gt> $value, ...) = X11::Protocol::WM::get_wm_hints ($X, $window)>

Return the C<WM_HINTS> property from C<$window>.  The return is a list of
key/value pairs as per C<set_wm_hints()> above

    input => 1,
    icon_pixmap => 1234,
    ...

Only fields with their flag bits set in the hints are included in the
return.  If there's no C<WM_HINTS> at all or or its flags field is zero then
the return is an empty list.

The return can be put into a hash to get fields by name,

    my %hints = X11::Protocol::WM::get_wm_hints ($X, $window);
    if (exists $hints{'icon_pixmap'}) {
      print "icon_pixmap is ", $hints{'icon_pixmap'}, "\n";
    }

C<initial_state> is a string such as "NormalState".  The pixmaps and windows
are string "None" if set but zero (which is probably unusual).  If
C<$X-E<gt>{'do_interp'}> is disabled then all are numbers.

X11R2 Xlib had a bug in its C<XSetWMHints()> which chopped off the
C<window_group> value from the hints stored.  The C<window_group> field is
omitted from the return if the data read is missing that field.

=item C<(key =E<gt> $value, ...) = X11::Protocol::WM::change_wm_hints ($X, $window, key=E<gt>value, ...)>

Change some fields of the C<WM_HINTS> property on C<$window>.  The given
key/value fields are changed.  Other fields are left alone.  For example,

    X11::Protocol::WM::set_wm_hints ($X, $window,
                                     urgency => 1);

A value C<undef> means delete a field,

    X11::Protocol::WM::set_wm_hints ($X, $window,
                                     icon_pixmap => undef,
                                     icon_mask   => undef);

The change requires a server round-trip to fetch the current values from
C<$window>.  An application might prefer to remember its desired hints and
send a full C<set_wm_hints()> each time.

=item C<$bytes = X11::Protocol::WM::pack_wm_hints ($X, key=E<gt>value...)>

Pack a set of values into a byte string of C<WM_HINTS> format.  The
key/value arguments are per C<set_wm_hints()> above and the result is the
raw bytes stored in a C<WM_HINTS> property.

The C<$X> argument is not actually used currently, but is present in case
C<initial_state> or other values might use an C<$X-E<gt>num()> lookup in the
future.

=item C<(key =E<gt> $value, ...) = X11::Protocol::WM::unpack_wm_hints ($X, $bytes)>

Unpack a byte string as a C<WM_HINTS> structure.  The return is key/value
pairs as per C<get_wm_hints()> above.  The C<$X> parameter is used for
C<do_interp>.  There's no communication with the server.

=back

=head2 WM_NAME, WM_ICON_NAME

=over

=item C<X11::Protocol::WM::set_wm_name ($X, $window, $name)>

Set the C<WM_NAME> property on C<$window> (an integer XID) to C<$name> (a
string).

The window manager might display this as a title above the window, or in a
menu of windows, etc.  It can be a Perl 5.8 wide-char string per L</Text
Properties> above.  A good window manager ought to support non-ASCII or
non-Latin-1 titles, but how well it displays might depend on fonts etc.

=item C<X11::Protocol::WM::set_wm_icon_name ($X, $window, $name)>

Set the C<WM_ICON_NAME> property on C<$window> (an integer XID) to C<$name>
(a string).

The window manager might display this when C<$window> is iconified.  If
C<$window> doesn't have an icon (in C<WM_HINTS> or from the window manager
itself) then this text might be all that's shown.  Either way it should be
something short.  It can be a Perl 5.8 wide-char string per L</Text
Properties> above.

=back

=head2 WM_NORMAL_HINTS

=over

=item C<X11::Protocol::WM::set_wm_normal_hints ($X, $window, key=E<gt>value,...)>

Set the C<WM_NORMAL_HINTS> property on C<$window> (an integer XID).  This is
a C<WM_SIZE_HINTS> structure which tells the window manager what sizes the
client would like.  For example,

    set_wm_normal_hints ($X, $window,
                         min_width => 200,
                         min_height => 100);

Generally the window manager restricts user resizing to the hint limits.
Most window managers use these hints, but of course they're only hints and a
good program should be prepared for other sizes even if it won't look good
or can't do much useful when too big or too small etc.

The key/value parameters are

    user_position      boolean, window x,y is user specified
    user_size          boolean, window width,height is user specified
    program_position   boolean, window x,y is program specified
    program_size       boolean, window width,height is program specified
    min_width          \ integers, min size in pixels
    min_height         /
    max_width          \ integers, max size in pixels
    max_height         /
    base_width         \ integers, size base in pixels
    base_height        /
    width_inc          \ integers, size increment in pixels
    height_inc         /
    min_aspect         \  fraction 2/3 or decimal 2 or 1.5
    min_aspect_num      | or integer num/den up to 0x7FFFFFFF
    min_aspect_den      |
    max_aspect          |
    max_aspect_num      |
    max_aspect_den     /
    win_gravity        WinGravity enum "NorthEast" etc

C<user_position> and C<user_size> are flags meaning that the window's x,y or
width,height (in the usual core C<$X-E<gt>SetWindowAttributes()>) were given
by the user, for example from a C<-geometry> command line option.  The
window manager will generally obey these values and skip any auto-placement
or interactive placement it might otherwise do.

C<program_position> and C<program_size> are flags meaning the window x,y or
width,height were calculated by the program.  The window manager might
override with its own positioning or sizing policy.  There's generally no
need to set these fields unless the program has a definite idea of where and
how big it should be.  For a size it's enough to set the core window
width,height and let the window manager (if there's one running) go from
there.

Items shown grouped above must be given together, so for instance if a
C<min_width> is given then C<min_height> should be given too.

C<base_width>,C<base_height> and C<width_inc>,C<height_inc> ask that the
window be a certain base size in pixels then a multiple of "inc" pixels
above that.  This can be used by things like C<xterm> which want a fixed
size for border or scrollbar and then a multiple of the character size above
that.  If C<base_width>,C<base_height> are not given then
C<min_width>,C<min_height> is the base size.

C<base_width>,C<base_height> can be smaller than C<min_width>,C<min_height>.
This means the size should still be a base+inc multiple, but the first such
which is at least the min size.  The window manager generally presents the
"inc" multiple to the user, so that for example on an xterm the user sees a
count of characters.  A min size can then demand for example a minimum 1x1
or 2x2 character size.

C<min_aspect>,C<max_aspect> ask that the window have a certain minimum or
maximum width/height ratio.  For example aspect 2/1 means it should be twice
as wide as it is high.  This is applied to the size above
C<base_width>,C<base_height>, or if base not given then to the whole window
size.

C<min_aspect_num>,C<min_aspect_den> and C<max_aspect_num>,C<max_aspect_den>
set numerator and denominator values directly (INT32, so maximum
0x7FFF_FFFF).  Or C<min_aspect> and C<max_aspect> accept a single value in
various forms which are turned into num/den values.

    2         integer
    1.125     decimal, meaning 1125/1000
    2/3       fraction
    1.5/4.5   fraction with decimals

Values bigger than 0x7FFFFFFF in these forms are reduced proportionally as
necessary.  A Perl floating point value will usually have more bits of
precision than 0x7FFFFFFF and is truncated to something that fits.

C<win_gravity> is how the client would like to be shifted to make room for
any surrounding frame the window manager might add.  For example if the
program calculated the window size and position to ensure the north-east
corner is at a desired position, then give C<win_gravity =E<gt> "NorthEast">
so that the window manager keeps the north-east corner the same when it
applies its frame.

C<win_gravity =E<gt> "Static"> means the frame is put around the window and
the window not moved at all.  Of course that might mean some of the frame
ends up off-screen.

=item C<$bytes = X11::Protocol::WM::pack_size_hints ($X, key=E<gt>value,...)>

Return a bytes string which is a C<WM_SIZE_HINTS> structure made from the
given key/value parameters.  C<WM_SIZE_HINTS> is structure type for
C<WM_NORMAL_HINTS> described above and the key/value parameters are as
described above.

The C<$X> parameter is used to interpret C<win_gravity> enum values.
There's no communication with the server.

=item C<($num,$den) = X11::Protocol::WM::aspect_to_num_den ($aspect)>

Return a pair of INT32 integers 0 to 0x7FFF_FFFF for the given aspect ratio
C<$aspect>.  This is the conversion applied to C<min_aspect> and
C<max_aspect> above.  C<$aspect> can be any of the integer, decimal or
fraction described.

=back

=head2 WM_PROTOCOLS

=over

=item C<X11::Protocol::WM::set_wm_protocols ($X, $window, $protocol,...)>

Set the C<WM_PROTOCOLS> property on C<$window> (an XID).  Each argument is a
string protocol name or an integer atom ID.

    X11::Protocol::WM::set_wm_protocols
      ($X, $window, 'WM_DELETE_WINDOW', '_NET_WM_PING')

For example C<WM_DELETE_WINDOW> means that when the user clicks the close
button the window manager sends a C<ClientMessage> event rather than doing a
C<KillClient()>.  The C<ClientMessage> event allows a program to clean-up or
ask the user about saving a document before exiting, etc.

=back

=head2 WM_STATE

The window manager maintains a state for each client window it manages,

    WithdrawnState
    NormalState
    IconicState

C<WithdrawnState> means the window is not mapped and the window manager is
not managing it.  A newly created window (C<$X-E<gt>CreateWindow()>) is
initially C<WithdrawnState> and on first C<$X-E<gt>MapWindow()> goes to
C<NormalState> (or to C<IconicState> if that's the initial state asked for
in C<WM_HINTS>).

C<iconify()> and C<withdraw()> below can change the state to iconic or
withdrawn.  A window can be restored from iconic to normal by a
C<MapWindow()>.

=over

=item C<($state, $icon_window) = X11::Protocol::WM::get_wm_state ($X, $window)>

Return the C<WM_STATE> property from C<$window>.  This is set by the window
manager on top-level application windows.  If there's no such property then
the return is an empty list.

C<$state> returned is an enum string, or an integer value if
C<$X-E<gt>{'do_interp'}> is disabled or the value unrecognised.

    "WithdrawnState"    0      not displayed
    "NormalState"       1      window displayed
    "IconicState"       3      iconified in some way

    "ZoomState"         2      \ no longer in ICCCM
    "InactiveState"     4      /   (zoom meant maximized)

C<$icon_window> returned is the window (integer XID) used by the window
manager to display an icon of C<$window>.  If there's no such window then
C<$icon_window> is "None" (or 0 if C<$X-E<gt>{'do_interp'}> is disabled).

C<$icon_window> might be the icon window from the client's C<WM_HINTS> or it
might be a window created by the window manager.  The client can draw into
it for animations etc, perhaps selecting C<Expose> events on it to know when
to redraw.

C<WM_STATE> is set by the window manager when a toplevel window is first
mapped (or perhaps earlier), and then kept up-to-date.  Generally no
C<WM_STATE> property or a C<WM_STATE> set to WithdrawnState means the window
manager is not managing the window, or not yet doing so.  A client can
select C<PropertyChange> event mask in the usual way to listen for
C<WM_STATE> changes.

=item C<($state, $icon_window) = X11::Protocol::WM::unpack_wm_state ($X, $bytes)>

Unpack the bytes of a C<WM_STATE> property to a C<$state> and
C<$icon_window> as per C<get_wm_state()> above.

C<$X> is used for C<$X-E<gt>{'do_interp'}> but there's no communication with
the server.

=item C<X11::Protocol::WM::iconify ($X, $window)>

=item C<X11::Protocol::WM::iconify ($X, $window, $root)>

Change C<$window> to "IconicState" by sending a C<ClientMessage> to the
window manager.

If the window manager does not have any iconification then it might do
nothing (eg. some tiling window managers).  If there's no window manager
running then iconification is not possible and this message will do nothing.

C<$root> should be the root window of C<$window>.  If not given or C<undef>
then it's obtained by a C<QueryTree()> here.  Any client can iconify any top
level window.

If C<$window> has other windows which are C<WM_TRANSIENT_FOR> for it then
generally the window manager will iconify or hide those windows too (see
L</WM_TRANSIENT_FOR> below).

=item C<X11::Protocol::WM::withdraw ($X, $window)>

=item C<X11::Protocol::WM::withdraw ($X, $window, $root)>

Change C<$window> to "WithdrawnState" by an C<$X-E<gt>UnmapWindow()> and a
synthetic C<UnmapNotify> message to the window manager.

If there's no window manager running then the C<UnmapWindow()> unmaps and
the C<UnmapNotify> message does nothing.

C<$root> should be the root window of C<$window>.  If not given or
C<undef> then it's obtained by a C<QueryTree()> here.

If other windows are C<WM_TRANSIENT_FOR> this C<$window> (eg. open dialog
windows) then generally the client should withdraw them too.  The window
manager might make such other windows inaccessible anyway.

The ICCCM specifies an C<UnmapNotify> message so the window manager is
notified of the desired state change even if C<$window> is already unmapped,
such as in "IconicState" or perhaps during some window manager reparenting,
etc.

C<$window> can be changed back to NormalState or IconicState later with
C<$X-E<gt>MapWindow()> the same as for a newly created window.  (And
C<WM_HINTS> C<initial_state> can give a desired initial iconic/normal
state).  But before doing so be sure the window manager has recognised the
C<withdraw()>.  This will be when the window manager changes the C<WM_STATE>
property to "WithdrawnState", or deletes that property.

Any client can withdraw any toplevel window, but it's unusual for a client
to withdraw windows which are not its own.

=back

=head2 WM_TRANSIENT_FOR

=over

=item C<X11::Protocol::WM::set_wm_transient_for ($X, $window, $transient_for)>

Set the C<WM_TRANSIENT_FOR> property on C<$window> (an XID).

C<$transient_for> is another window XID, or C<undef> if C<$window> is not
transient for anything so C<WM_TRANSIENT_FOR> should be deleted.

"Transient for" means C<$window> is some sort of dialog or menu related to
the given C<$transient_for> window.  The window manager will generally
iconify C<$window> together with its C<$transient_for>, etc.  See
C<set_motif_wm_hints()> below for "modal" transients.

=back

=head2 _MOTIF_WM_HINTS

=over

=item C<X11::Protocol::WM::set_motif_wm_hints ($X, $window, key=E<gt>value...)>

Set the C<MOTIF_WM_HINTS> property on C<$window> (an XID).

These hints control window decorations and "modal" state.  It originated in
the Motif C<mwm> window manager but is recognised by most other window
managers.  It should be set on a toplevel window before mapping.  Changes
made later might not affect what the window manager does.

    X11::Protocol::WM::set_motif_wm_hints
      ($X, $dialog_window,
       input_mode => "full_application_modal");
    $X->MapWindow ($dialog_window);

Ordinary windows generally don't need to restrict their decorations etc, but
something special like a clock or gadget might benefit.

    X11::Protocol::WM::set_motif_wm_hints
      ($X, $my_gadget_window,
       functions   => 4+32,   # move+close
       decorations => 1+4+8); # border+title+menu

The key/value arguments are

    functions   => integer bits
    decorations => integer bits
    input_mode  => enum string or integer
    status      => integer bits

C<functions> is what actions the window manager should offer to the user in
a drop-down menu or similar.  It's an integer bitwise OR of the following
values.  If not given then the default is normally all functions.

    bit    actions offered
    ---    ---------------
     1     all functions
     2     resize window
     4     move window
     8     minimize, to iconify
    16     maximize, to full-screen (with a frame still)
    32     close window

C<decorations> is what visual decorations the window manager should show
around the window.  It's an integer bitwise OR of the following values.  If
not given then the default is normally all decorations.

    bit       decorations displayed
    ---       ---------------------
     1        all decorations
     2        border around the window
     4        resizeh, handles to resize by dragging
     8        title bar, showing WM_NAME
    16        menu, drop-down menu of the "functions" above
    32        minimize button, to iconify
    64        maximize button, to full-screen

C<input_mode> allows a window to be "modal", meaning the user should
interact only with C<$window>.  The window manager will generally keep it on
top, not move the focus to other windows, etc.  The value is one of the
following strings or corresponding integer,

      string                   integer
    "modeless"                    0    not modal (the default)
    "primary_application_modal"   1    modal to its "transient for"
    "system_modal"                2    modal to the whole display
    "full_application_modal"      3    modal to the current client

"primary_application_modal" means C<$window> is modal for the
C<WM_TRANSIENT_FOR> set on C<$window> (see L</WM_TRANSIENT_FOR> above), but
other windows on the display can be used normally.  "full_application_modal"
means modal for all windows of the same client, but other clients can be
used normally.

Modal behaviour is important for good user interaction and therefore ought
to be implemented by a window manager, but a good program should be prepared
to do something with input on other windows.

C<status> field is a bitwise OR of the following bits (only one currently).

    bit
     1    tearoff menu window

Tearoff menu flag is intended for tearoff menus, as the name suggests.

    X11::Protocol::WM::set_motif_wm_hints
      ($X, $my_tearoff_window, status => 1);

Motif C<mwm> will expand the window to make it wide enough for the
C<WM_NAME> in the frame title bar.  Otherwise a title is generally truncated
to as much as fits the window's current width.  Expanding can be good for
tearoffs where the title bar is some originating item name etc which the
user should see.  But don't be surprised if this flag is ignored by other
window managers.

Perhaps in the future the individual bits above will have some symbolic
names.  Either constants or string values interpreted.  What would a
possible C<get_hints()> return, and what might be convenient to add/subtract
bits?

See F</usr/include/Xm/MwmUtil.h> on the hints bits, and see C<mwm>
sources F<WmWinInfo.c> C<ProcessWmWindowTitle()> for the C<status>
tearoff window flag.

=back

=head2 _NET_FRAME_EXTENTS

=over

=item C<my ($left,$right, $top,$bottom) = X11::Protocol::WM::get_net_frame_extents ($X, $window)>

Get the C<_NET_FRAME_EXTENTS> property from C<$window>.

This is set on top-level windows by the window manager to report how many
pixels of frame or decoration it has added around C<$window>.

If there's no such property set then the return is an empty list.  So for
example

    my ($left,$right,$top,$bottom)
          = get_net_frame_extents ($X, $window)
      or print "no frame extents";

    my ($left,$right,$top,$bottom)
      = get_net_frame_extents ($X, $window);
    if (! defined $left) {
      print "no frame extents";
    }

A client might look at the frame size if moving a window programmatically so
as not to put the title bar etc off-screen.  Oldish window managers might
not provide this information though.

=back

=head2 _NET_WM_PID

=over

=item C<X11::Protocol::WM::set_net_wm_pid ($X, $window)>

=item C<X11::Protocol::WM::set_net_wm_pid ($X, $window, $pid)>

=item C<X11::Protocol::WM::set_net_wm_pid ($X, $window, undef)>

Set the C<_NET_WM_PID> property on C<$window> to the given C<$pid> process
ID, or to the C<$$> current process ID if omitted.  (See L<perlvar> for
C<$$>.)  If C<$pid> is C<undef> then the property is deleted.

A window manager or similar might use the PID to forcibly kill an
unresponsive client.  It's only useful if C<WM_CLIENT_MACHINE> (above) is
set too, to know where the client is running.

=back

=head2 _NET_WM_STATE

An EWMH compliant window manager maintains a set of state flags for each
client window.  A state is an atom such as C<_NET_WM_STATE_FULLSCREEN> and
each such state can be present or absent.  The supported states are listed
in property C<_NET_SUPPORTED> on the root (together with other features).
For example,

    my @net_supported = X11::Protocol::Other::get_property_atoms
                         ($X, $X->root, $X->atom('_NET_SUPPORTED'));
    if (grep {$_ == $X->atom('_NET_WM_STATE_FULLSCREEN')}
             @net_supported) { 
      print "Have _NET_WM_STATE_FULLSCREEN\n";
    }

Any client can ask the window manager to change states of any window.
A client might set initial states on a new window with C<set_net_wm_state()>
below.  Possible states include

=over

=item _NET_WM_STATE_MODAL

The window is modal to its C<WM_TRANSIENT_FOR> parent, or if
C<WM_TRANSIENT_FOR> not set then modal to its window group.

See L</_MOTIF_WM_HINTS> to set modal with the Motif style hints.

=item _NET_WM_STATE_STICKY

The window is kept in a fixed position on screen when the desktop scrolls.

=item _NET_WM_STATE_MAXIMIZED_VERT

=item _NET_WM_STATE_MAXIMIZED_HORZ

The window is maximum size vertically or horizontally or both.  The window
still has its surrounding decoration and the size should obey size
increments specified in L</WM_NORMAL_HINTS>.

=item _NET_WM_STATE_FULLSCREEN

The window is the full screen with no decoration around it, thus being the
full screen.

The window manager remembers the "normal" size of the window so that when
maximize or fullscreen states are removed the previous size is restored.

=item _NET_WM_STATE_SHADED

The window is "shaded" which generally means its title bar is displayed but
none of the client window.  This is an alternative to iconifying a window.

=item _NET_WM_STATE_SKIP_TASKBAR

=item _NET_WM_STATE_SKIP_PAGER

Don't show the window on a task bar or in a pager, respectively.

=item _NET_WM_STATE_HIDDEN (read-only)

This state is set by the window manger when the window is iconified or
similar and so does not appear on screen.  Clients cannot change this.

=item _NET_WM_STATE_ABOVE

=item _NET_WM_STATE_BELOW

The window is kept above or below other client windows.  The stacking order
maintained is roughly

     top
    +-----------------------------+
    |  _NET_WM_WINDOW_TYPE_DOCK   |   "DOCK" panels (etc) on top,
    +-----------------------------+   except perhaps FULLSCREEN
    |     _NET_WM_STATE_ABOVE     |   windows above those panels
    +-----------------------------+   when focused
    |            normal           |
    +-----------------------------+
    |     _NET_WM_STATE_BELOW     |
    +-----------------------------+
    | _NET_WM_WINDOW_TYPE_DESKTOP |
    +-----------------------------+
     bottom

=item _NET_WM_STATE_DEMANDS_ATTENTION

The window should be brought to the attention of the user in some way.
A client sets this and the window manager clears it after the window has
received user attention (which might mean keyboard focus or similar).

=back

The following functions get or set the states.

=over

=item C<change_net_wm_state($X, $window, $action, $state, key=E<gt>value,...)>

Change one of the C<_NET_WM_STATE> state flags on C<$window> by sending a
message to the window manager.  For example,

    change_net_wm_state ($X, $window, "toggle", "FULLSCREEN");

C<$window> must be a managed window, ie. must have had its initial
C<MapWindow()> and not be an override-redirect.  If that's not so or if
there's no window manager or it doesn't have EWMH then this change message
will have no effect.

C<$action> is a string or integer how to change the state,

    "remove"       0
    "add"          1
    "toggle"       2

C<$state> is a string such as "FULLSCREEN" or an atom integer such as
C<$X-E<gt>atom("_NET_WM_STATE_FULLSCREEN")>.

The further optional key/value parameters are

    state2   => string or atom
    source   => "none", "normal", "user", 0,1,2
    root     => integer XID, or undef

A change message can act on one or two states.  For two states, the second
is C<state2>.  For example to maximize vertically and horizontally in one
operation,

    change_net_wm_state ($X, $window, "add", "MAXIMIZED_VERT",
                         state2 => "MAXIMIZED_HORZ");

C<source> is where the change request came from.  The default is "normal"
which means a normal application.  "user" is for a user-interface control
program such as a pager.  ("none"=0 is what clients prior to EWMH 1.2 gave.)

C<root> is the root window (integer XID) of C<$window>.  If C<undef> or not
given then it's found by C<$X-E<gt>QueryTree()>.  If you already know the
root then giving it avoids that round-trip query.

=item C<@strings = get_net_wm_state ($X, $window)>

=item C<@atoms = get_net_wm_state_atoms ($X, $window)>

Get the C<_NET_WM_STATE> property from C<$window>.  C<get_net_wm_state()>
returns a list of strings such as "FULLSCREEN".  C<get_net_wm_state_atoms()>
returns a list of atom integers such as
C<$X-E<gt>atom('_NET_WM_STATE_FULLSCREEN')>.  In both cases, if there's no
such property or if it's empty then return an empty list.

=item C<set_net_wm_state ($X, $window, $state,...)>

Set the C<_NET_WM_STATE> property on C<$window>.  Each C<$state> can be

   string like "FULLSCREEN"
   string like "_NET_WM_STATE_FULLSCREEN"
   integer atom of a name like _NET_WM_STATE_FULLSCREEN

A client can set C<_NET_WM_STATE> on a new window to tell the window manager
of desired initial states.  This is only a "should" in the EWMH spec so it
might not be obeyed.

    # initial desired state
    set_net_wm_state ($X, $window,
                      "MAXIMIZED_HORZ", "MAXIMIZED_VERT");

After the window is managed by the window manager (once mapped), clients
should not set C<_NET_WM_STATE> but instead ask the window manager with
C<change_net_wm_state()> message above.

=back

=head2 _NET_WM_USER_TIME

=over

=item C<set_net_wm_user_time ($X, $window, $time)>

Set the C<_NET_WM_USER_TIME> property on C<$window>.

C<$time> should be a server time value (an integer) from the last user
keypress etc event in C<$window>.  Or when C<$window> is created then the
time from the event which caused it to be opened.

On a newly created window, a special C<$time> value 0 means the window
should not receive the focus when mapped -- assuming the window manager
recognises C<_NET_WM_USER_TIME> of course.

If the client has the active window it should update C<_NET_WM_USER_TIME>
for every user input.  Generally KeyPress and ButtonPress events are user
input, but normally KeyRelease and ButtonRelease are not since it's the
Press events which are the user actively doing something.

The window manager might use C<_NET_WM_USER_TIME> to control focus and/or
stacking order so that for example a slow popup doesn't steal the focus if
you've gone to another window to do other work in the interim.

=back

=head2 _NET_WM_WINDOW_TYPE

=over

=item C<X11::Protocol::WM::set_net_wm_window_type ($X, $window, $window_type)>

Set the C<_NET_WM_WINDOW_TYPE> property on C<$window> (an XID).
C<$window_type> can be

    string like "NORMAL"
    integer atom of a name like _NET_WM_WINDOW_TYPE_NORMAL

The window types from from the EWMH are as follows.

    "NORMAL"
    "DIALOG"
    "DESKTOP"
    "DOCK"
    "TOOLBAR"
    "MENU"
    "UTILITY"
    "SPLASH"

=back

=head2 Frame to Client

=over

=item C<$window = X11::Protocol::WM::frame_window_to_client ($X, $frame)>

Return the client window (an XID) contained within window manager C<$frame>
window (an XID).  C<$frame> is usually an immediate child of the root
window.

If no client window can be found in C<$frame> then return C<undef>.  This
might happen if C<$frame> is an icon window or similar created by the window
manager itself, or an override-redirect client without a frame, or if
there's no window manager running at all.  In the latter two cases C<$frame>
would be the client already.

The strategy is to look at C<$frame> and down the window tree seeking a
C<WM_STATE> property which the window manager puts on a client's toplevel
when mapped.  The search depth and total windows are limited in case the
window manager does its decoration in some ridiculous way or the client uses
excessive windows (which would be traversed if there's no window manager).

    +-rootwin--------------------------+
    |                                  |
    |                                  |
    |    +-frame-win--------+          |
    |    | +-client-win---+ |          |
    |    | | WM_STATE ... | |          |
    |    | |              | |          |
    |    | +--------------+ |          |
    |    +------------------+          |
    |                                  |
    +----------------------------------+

Care is taken not to error out if some windows are destroyed during the
search.  When a window belongs to other clients it could be destroyed at any
time.  If C<$frame> itself doesn't exist then the return is C<undef>.

This function is similar to what C<xwininfo> and similar programs do to go
from a toplevel root window child down to the client window, per
F<dmsimple.c> C<Select_Window()> or Xlib C<XmuClientWindow()>.  (See also
L<X11::Protocol::ChooseWindow>.)

=back

=head2 Virtual Root

Some window managers use a "virtual root" window covering the entire screen.
Application windows or frame windows are then children of that virtual root.
This can help the window manager implement a large desktop or multiple
desktops, though it tends to fail in subtle ways with various root oriented
programs, including for example L<xsetroot(1)> or the click-to-select in
L<xwininfo(1)> and L<xprop(1)>.

=over

=item C<$window = X11::Protocol::WM::root_to_virtual_root ($X, $root)>

If the window manager is using a virtual root then return that window XID.
If not then return C<undef>.

The current implementation searches for a window with an C<__SWM_VROOT>
property, as per the C<swm>, C<tvtwm> and C<amiwm> window managers, and as
used by the C<xscreensaver> program and perhaps some versions of KDE.

There's nothing yet for EWMH C<_NET_VIRTUAL_ROOTS>.  Do any window managers
use it?  Is C<_NET_CURRENT_DESKTOP> an index into that virtual roots list?

(See L<X11::Protocol::XSetRoot> for changing the background of a root or
virtual root.)

=back

=head1 EXPORTS

Nothing is exported by default, but the functions can be requested in usual
C<Exporter> style,

    use X11::Protocol::WM 'set_wm_hints';
    set_wm_hints ($X, $window, input => 1, ...);

Or just call with full package name

    use X11::Protocol::WM;
    X11::Protocol::WM::set_wm_hints ($X, $window, input => 1, ...);

There's no C<:all> tag since this module is meant as a grab-bag of functions
and to import as-yet unknown things would be asking for name clashes.

=head1 BUGS

Not much attention is paid to text on an EBCDIC system.  Wide char strings
probably work, but byte strings may go straight through whereas they ought
to be re-coded to Latin-1.  But the same probably applies to parts of the
core C<X11::Protocol> such as C<$X-E<gt>atom_name()> where you'd want to
convert Latin-1 from the server to native EBCDIC.

=head1 SEE ALSO

L<X11::Protocol>,
L<X11::Protocol::Other>,
L<X11::Protocol::ChooseWindow>,
L<X11::Protocol::XSetRoot>

"Inter-Client Communication Conventions Manual",
F</usr/share/doc/xorg-docs/icccm/icccm.txt.gz>,
L<http://www.x.org/docs/ICCCM/>

"Compound Text Encoding" specification.
F</usr/share/doc/xorg-docs/ctext/ctext.txt.gz>,
L<http://www.x.org/docs/CTEXT/>

"Extended Window Manager Hints" which is the C<_NET_WM> things.
L<http://www.freedesktop.org/wiki/Specifications/wm-spec>,
L<http://mail.gnome.org/archives/wm-spec-list/>

L<wmctrl(1)>, L<xwit(1)>, L<X(7)>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/x11-protocol-other/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2016, 2017, 2018, 2019 Kevin Ryde

X11-Protocol-Other is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

X11-Protocol-Other is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.

=cut
