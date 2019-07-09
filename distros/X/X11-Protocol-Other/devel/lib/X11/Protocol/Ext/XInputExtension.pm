# in progress



# Copyright 2011, 2012, 2013, 2014, 2017 Kevin Ryde

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

BEGIN { require 5 }
package X11::Protocol::Ext::XInputExtension;
use strict;
use Carp;
use X11::Protocol;

use vars '$VERSION', '@CARP_NOT';
$VERSION = 31;
@CARP_NOT = ('X11::Protocol');

# uncomment this to run the ### lines
use Smart::Comments;

# /usr/share/doc/x11proto-input-dev/XIproto.txt.gz
# /usr/share/doc/x11proto-input-dev/XI2proto.txt.gz
#
# /usr/include/X11/extensions/XIproto.h
# /usr/include/X11/extensions/XI2proto.h
#
# /usr/include/X11/extensions/XInput2.h
#
# /usr/share/doc/x11proto-core-dev/x11protocol.txt.gz
#
# xinput dumper programs
#

# these not documented yet ...
use constant CLIENT_MAJOR_VERSION => 2;
use constant CLIENT_MINOR_VERSION => 0;

#------------------------------------------------------------------------------
# symbolic constants

my %const_arrays
  = (
     XIDeviceUse => ['MasterPointer', 'MasterKeyboard',
                     'SlavePointer', 'SlaveKeyboard',
                     'FloatingSlave' ],
     XIClass => ['Key', 'Button', 'Valuator'],
     XIDeviceMode => ['Relative', 'Absolute'],
     XIFeedbackClass => ['Kbd',     # 0
                         'Ptr',     # 1
                         'String',  # 2
                         'Integer', # 3
                         'Led',     # 4
                         'Bell',    # 5
                        ],
     XIUse => ['Pointer',           # 0
               'Keyboard',          # 1
               'ExtensionDevice',   # 2
               'ExtensionKeyboard', # 3
               'ExtensionPointer',  # 4
              ],
     XIEventMode => [ 'AsyncThisDevice',    # 0  per XI.h
                      'SyncThisDevice',     # 1
                      'ReplayThisdevice',   # 2
                      'AsyncOtherDevices',  # 3
                      'AsyncAll',           # 4
                      'SyncAll',            # 5
                    ]
    );

my %const_hashes
  = (map { $_ => { X11::Protocol::make_num_hash($const_arrays{$_}) } }
     keys %const_arrays);

#------------------------------------------------------------------------------
# requests

my $reqs =
  [
   undef,  # 0

   ['XIGetExtensionVersion',  # 1
    sub {
      my ($X, $name) = @_;
      ### XIGetExtensionVersion() ...
      if (! defined $name) { $name = "XInputExtension"; }
      # my $ret = pack ('Sxx' . X11::Protocol::padded($name),
      #              length($name), $name);
      # ### $ret
      # ### len: length($ret)
      return pack ('Sxx' . X11::Protocol::padded($name),
                   length($name), $name);
    },
    sub {
      my ($X, $data) = @_;
      return unpack 'x8SS', $data;

      # Any interest in holding onto the version?
      #  my ($server_major, $server_minor) = unpack 'x8SS', $data;
      # ### $server_major
      # ### $server_minor
      # my $self;
      # if ($self = $self->{'ext'}{'XInputExtension'}->[3]) {
      #   $self->{'major'} = $server_major;
      #   $self->{'minor'} = $server_minor;
      # }
      # return ($server_major, $server_minor);
    }],

   ['XIListInputDevices',  # 2
    \&_request_empty,
    sub {
      my ($X, $data) = @_;

      # use Data::HexDump::XXD;
      # print scalar(Data::HexDump::XXD::xxd($data));
      # print "\n";

      my ($num_devices) = unpack 'x8C', $data;
      my $pos = 32;
      ### $num_devices

      my @ret;
      my @infos;
      foreach (1 .. $num_devices) {
        ### device: $_
        ### pos: sprintf '%d %#X', $pos, $pos

        my ($type_atom, $deviceid, $num_classes, $use, $attached_deviceid)
          = unpack 'LCCCC', substr ($data, $pos, 8);
        $pos += 8;
        my $info = { type => $type_atom,
                     use  => $X->interp('XIUse',$use),
                     attached_deviceid => $attached_deviceid,
                     num_classes => $num_classes,
                   };
        push @infos, $info;
        push @ret, $deviceid => $info;
      }

      my $info;
      foreach $info (@infos) {
        my $num_classes = $info->{'num_classes'};

        my @classes;
        $info->{'classes'} = \@classes;

        foreach (1 .. $num_classes) {
          ### pos: sprintf '%d %#X', $pos, $pos

          my ($class, $class_len) = unpack 'CC', substr ($data, $pos, 2);
          my %class_info = (class => $X->interp('XIClass',$class));
          push @classes, \%class_info;

          ### $class
          ### class interp: $X->interp('XIClass',$class)
          ### $class_len
          ### assert: $class_len >= 2

          if ($class == 0) { # Key
            ($class_info{'min_keycode'},
             $class_info{'max_keycode'},
             $class_info{'num_keys'})
              = unpack 'xxCCS', substr ($data, $pos, 6);
          } elsif ($class == 1) { # Button
            ($class_info{'num_buttons'})
              = unpack 'xxS', substr ($data, $pos, 4);
          } elsif ($class == 2) { # Valuator
            my ($num_axes, $mode, $motion_buffer_size)
              = unpack 'xxCCL', substr ($data, $pos, 8);
            $class_info{'num_axes'} = $num_axes;
            $class_info{'mode'} = $X->interp('XIDeviceMode',$mode);
            $class_info{'motion_buffer_size'} = $motion_buffer_size;
            $class_info{'axes'}
              = [ map {
                # FIXME: min/max signed or unsigned? Xlib is signed ...
                my ($resolution, $min_value, $max_value)
                  = unpack 'Lll', substr ($data, $pos+12*$_-4, 12);
                { resolution => $resolution,
                    min_value => $min_value,
                      max_value => $max_value
                    }
              } 1 .. $num_axes ];
          }
          $pos += $class_len;
        }
      }

      ### names pos: sprintf '%d %#X', $pos, $pos
      foreach my $i (1 .. $num_devices) {
        my ($name_len) = unpack 'C', substr($data,$pos++,1);
        ### $name_len
        $ret[2*$i-1]->{'name'} = substr($data,$pos,$name_len);
        $pos += $name_len;
      }
      return @ret;
    }],

   undef,  # OpenDevice			3

   ['XICloseDevice',  # 4
    sub {
      my ($X, $deviceid) = @_;
      return pack 'Cxxx', $deviceid;
    }],

   ['XISetDeviceMode',  # 5
    sub {
      my ($X, $deviceid, $mode) = @_;
      return pack 'CCxx',
        $deviceid, $X->num('XIDeviceMode',$mode);
    },
    sub {
      my ($X, $data) = @_;
      # FIXME: decode status value ...
      return unpack 'x8C', $data;
    }],

   undef,  # SelectExtensionEvent		6
   undef,  # GetSelectedExtensionEvents	7
   undef,  # ChangeDeviceDontPropagateList 8
   undef,  # GetDeviceDontPropagateList	9
   undef,  # GetDeviceMotionEvents		10
   undef,  # ChangeKeyboardDevice		11
   undef,  # ChangePointerDevice		12

   ['XIGrabDevice',  # 13
    sub {
      my ($X, $window, $deviceid, $owner_events, $event_class_list,
          $this_device_mode, $other_device_mode, $time) = @_;
      return pack('LLSCCCCxxC*',
                  $window,
                  _num_time($time),
                  scalar(@$event_class_list), # event_count
                  $X->num('SyncMode',$this_device_mode),
                  $X->num('SyncMode',$other_device_mode),
                  $owner_events,
                  $deviceid,
                  map {$X->num('XIEventClass',$_)}
                  @$event_class_list
                 )
    },
    sub {
      my ($X, $data) = @_;
      my ($status) = unpack 'x8C', $data;
      return $X->interp('GrabStatus',$status);
    } ],

   ['XIUngrabDevice',  # 14
    sub {
      my ($X, $deviceid, $time) = @_;
      return pack 'LCxxx', _num_time($time), $deviceid;
    } ],

   undef,  # GrabDeviceKey			15
   undef,  # UngrabDeviceKey		16
   undef,  # GrabDeviceButton		17
   undef,  # UngrabDeviceButton		18

   ['XIAllowDeviceEvents',  # 19
    sub {
      my ($X, $deviceid, $event_mode, $time) = @_;
      return pack 'LCCxx',
        _num_time($time),
          $X->num('XIEventMode',$event_mode),
            $deviceid;
    } ],

   undef,  # GetDeviceFocus		20
   undef,  # SetDeviceFocus		21
   undef,  # GetFeedbackControl		22
   undef,  # ChangeFeedbackControl		23
   undef,  # GetDeviceKeyMapping		24
   undef,  # ChangeDeviceKeyMapping	25
   undef,  # GetDeviceModifierMapping	26
   undef,  # SetDeviceModifierMapping	27
   undef,  # GetDeviceButtonMapping	28
   undef,  # SetDeviceButtonMapping	29
   undef,  # QueryDeviceState		30
   undef,  # SendExtensionEvent		31

   ['XIDeviceBell',  # 32
    sub {
      my ($X, $deviceid, $feedbackclass, $feedbackid, $percent) = @_;
      return pack 'CCCc', $deviceid, $feedbackclass, $feedbackid, $percent;
    } ],  #

   undef,  # SetDeviceValuators		33
   undef,  # GetDeviceControl		34
   undef,  # ChangeDeviceControl		35

   # -------------------------------------------------------------------------
   # XInputExtension version 1.5
   undef,  # ListDeviceProperties          36
   undef,  # ChangeDeviceProperty          37
   undef,  # DeleteDeviceProperty          38
   undef,  # GetDeviceProperty             39

   # -------------------------------------------------------------------------
   # XInputExtension version 2.0

   undef,  # XIQueryPointer                40
   undef,  # XIWarpPointer                 41
   undef,  # XIChangeCursor                42
   undef,  # XIChangeHierarchy             43
   undef,  # XISetClientPointer            44
   undef,  # XIGetClientPointer            45
   undef,  # XISelectEvents                46

   ['XIQueryVersion',  # 47
    sub {
      shift; # ($X, $client_major, $client_minor)
      ### XIQueryVersion() ...
      return pack 'SS', @_;
    },
    sub {
      my ($X, $data) = @_;
      return unpack 'x8SS', $data;

      # Any interest in holding onto the version?
      #  my ($server_major, $server_minor) = unpack 'x8SS', $data;
      # ### $server_major
      # ### $server_minor
      # my $self;
      # if ($self = $self->{'ext'}{'XI'}->[3]) {
      #   $self->{'major'} = $server_major;
      #   $self->{'minor'} = $server_minor;
      # }
      # return ($server_major, $server_minor);
    }],

   ['XIQueryDevice',  # 48
    sub {
      my ($X, $deviceid) = @_;
      ### XIQueryDevice() ...
      return pack 'Sxx', $deviceid;
    },
    sub {
      my ($X, $data) = @_;
      ### XIQueryDevice reply ...

      my ($num_devices) = unpack 'x8S', $data;
      ### $num_devices

      my $pos = 32;
      my @ret;
      foreach (1 .. $num_devices) {
        ### $pos
        ### data: substr($data,$pos)

        my ($deviceid, $use, $attachment, $num_classes, $name_len, $enabled)
          = unpack 'SSSSSC', substr ($data, $pos);
        $pos += 12;

        ### $deviceid
        ### $use
        ### $attachment
        ### $num_classes
        ### $name_len
        ### $enabled

        my $name = substr ($data, $pos, $name_len);
        $pos += $name_len + X11::Protocol::padding($name_len);
        ### $name

        my @classes;
        foreach (1 .. $num_classes) {
          my ($type, $class_len, $sourceid, $num_whatever)
            = unpack 'SSSS', substr($data,$pos);
          $pos += $class_len*4;
          ### $type
          ### $class_len
          ### $sourceid
          ### $num_whatever

          push @classes, [ $X->interp('XIClass', $type),
                           $sourceid ];
        }

        push @ret, [ $deviceid,
                     $X->interp('XIDeviceUse',$use),
                     $attachment,
                     $enabled,
                     $name,
                     \@classes ];
      }
      return @ret;
    }],

   ['XISetFocus',  # 49
    sub {
      my ($X, $window, $deviceid, $time) = @_;
      return pack 'LLSxx', _num_none($window), _num_time($time), $deviceid;
    } ],

   ['XIGetFocus',  # 50
    sub {
      my ($X, $deviceid) = @_;
      return pack 'Sxx', $deviceid;
    },
    sub {
      my ($X, $data) = @_;
      return unpack 'L', $data;
    } ],

   undef,  # XIGrabDevice                  51
   undef,  # XIUngrabDevice                52

   ['XIAllowEvents',  # 53
    sub {
      my ($X, $deviceid, $mode, $time) = @_;  # per $X->AllowEvents() arg order
      return pack 'LSCx',
        _num_time($time),
          $deviceid,
            $X->num('AllowEventsMode',$mode);
    } ],

   undef,  # XIPassiveGrabDevice           54
   undef,  # XIPassiveUngrabDevice         55
   undef,  # XIListProperties              56
   undef,  # XIChangeProperty              57
   undef,  # XIDeleteProperty              58
   undef,  # XIGetProperty                 59

   ['XIGetSelectedEvents',  # 60
    \&_request_xids,
    sub {
      my ($X, $data) = @_;
      # pairs of
      # uint16_t    deviceid;       /**< Device id to select for        */
      # uint16_t    mask_len;       /**< Length of mask in 4 byte units */

      my ($num_masks) = unpack 'x8S', $data;
      my @ret;
      my $pos = 12;
      foreach (1 .. $num_masks) {
        my ($deviceid, $mask_len) = unpack 'SS', substr ($data, $pos);
        $pos += 4;
        my $mask = substr ($data, $pos, $mask_len); # FIXME ... numize bytes
        $pos += $mask_len;
        push @ret, $deviceid, $mask;
      }
      return @ret;
    }],

  ];

sub _num_none {
  my ($xid) = @_;
  if (defined $xid && $xid eq "None") {
    return 0;
  } else {
    return $xid;
  }
}
sub _num_time {
  my ($time) = @_;
  if (defined $time && $time eq "CurrentTime") {
    return 0;
  } else {
    return $time;
  }
}

sub _request_empty {
  # ($X)
  if (@_ > 1) {
    croak "No parameters in this request";
  }
  return '';
}
sub _request_xids {
  my $X = shift;
  ### _request_xids(): @_
  return _request_card32s ($X, map {_num_none($_)} @_);
}
sub _request_card32s {
  shift;
  ### _request_card32s(): @_
  return pack 'L*', @_;
}

sub new {
  my ($class, $X, $request_num, $event_num, $error_num) = @_;
  ### XInputExtension new() ...

  # Constants
  %{$X->{'ext_const'}}     = (%{$X->{'ext_const'}     ||= {}}, %const_arrays);
  %{$X->{'ext_const_num'}} = (%{$X->{'ext_const_num'} ||= {}}, %const_hashes);

  # Errors
  _ext_const_error_install ($X, $error_num,
                            'Device',       # 0
                            'Event',        # 1
                            'XIMode',       # 2
                            'DeviceBusy',   # 3
                            'XIClass');     # 4

  # Requests
  _ext_requests_install ($X, $request_num, $reqs);

  return bless { }, $class;
}

sub _ext_requests_install {
  my ($X, $request_num, $reqs) = @_;

  $X->{'ext_request'}->{$request_num} = $reqs;
  my $href = $X->{'ext_request_num'};
  my $i;
  foreach $i (0 .. $#$reqs) {
    if (defined $reqs->[$i]) {
      $href->{$reqs->[$i]->[0]} = [$request_num, $i];
    }
  }
}
sub _ext_const_error_install {
  my $X = shift;  # ($X, $errname1,$errname2,...)
  ### _ext_const_error_install: @_
  my $error_num = shift;
  my $aref = $X->{'ext_const'}{'Error'}  # copy
    = [ @{$X->{'ext_const'}{'Error'} || []} ];
  my $href = $X->{'ext_const_num'}{'Error'}  # copy
    = { %{$X->{'ext_const_num'}{'Error'} || {}} };
  my $i;
  foreach $i (0 .. $#_) {
    $aref->[$error_num + $i] = $_[$i];
    $href->{$_[$i]} = $error_num + $i;
  }
}

### XInputExtension loaded ...

1;
__END__

=for stopwords XID Ryde

=head1 NAME

X11::Protocol::Ext::XInputExtension - input devices beyond keyboard and pointer

=head1 SYNOPSIS

 use X11::Protocol;
 my $X = X11::Protocol->new;
 $X->init_extension('XInputExtension')
   or print "XInputExtension not available";

=head1 DESCRIPTION

The XInputExtension extension ...

=head1 REQUESTS

The following requests are made available with an C<init_extension()>, as
per L<X11::Protocol/EXTENSIONS>.

    my $is_available = $X->init_extension('XInputExtension');

=head1 XInputExtension 1.5

=over

=item C<$X-E<gt>XIAllowDeviceEvents ($deviceid, $event_mode, $time)>

Release some events frozen by a grab on C<$deviceid>.  C<$event_mode> can be

     "AsyncThisDevice"         0
     "SyncThisDevice"          1
     "ReplayThisdevice"        2
     "AsyncOtherDevices"       3
     "AsyncAll"                4
     "SyncAll"                 5

C<$time> is a server timestamp, or "CurrentTime".  If C<$time> is before the
last grab then C<XIAllowDeviceEvents()> is ignored.

=item C<$X-E<gt>XIDeviceBell ($deviceid, $feedback_class, $feedback_id, $percent)>

Sound the device bell, in a style similar to the core C<Bell()>.
C<$feedback_class> and C<$feedback_id> identify which bell to ring.

C<$percent> is -100 to +100 relative to the base volume of the bell.

    -100            0    +100   $percent
      |-----------base----|
      0                  100    volume used

Percent 0 means the base volume.  Positive percent 0 to 100 means a volume
proportionally from base up to 100% volume.  Negative percent -100 to 0
means a volume proportionally from 0% (silent) up to the base volume.

    percent <= 0     volume = base * (percent+100)/100
                    so percent=-100 to 0 is volume=0 to base

    percent >= 0     volume = base + percent*(100 - base)/100
                    so percent=0 to +100 is volume=base to 100

=cut

# when percent>=0
# volume = base - [(base * percent) / 100] + percent
#        = base + percent - (base*percent)/100
#        = base + percent*(1 - base/100)
#        = base + percent*(100 - base)/100

=pod

=back

=head1 XInputExtension 2.0

=over

=item C<($server_major, $server_minor) = $X-E<gt>XIQueryVersion ($client_major, $client_minor)>

Negotiate a protocol version with the server.  C<$client_major> and
C<$client_minor> is what the client would like.  The returned
C<$server_major> and C<$server_minor> is what the server will do.

C<$client_major> must be 2 or more or a C<BadValue> error results.

=back

=head1 SEE ALSO

L<X11::Protocol>

F</usr/share/doc/x11proto-input-dev/XIproto.txt.gz>,
F</usr/share/doc/x11proto-input-dev/XI2proto.txt.gz>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/x11-protocol-other/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2017 Kevin Ryde

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
