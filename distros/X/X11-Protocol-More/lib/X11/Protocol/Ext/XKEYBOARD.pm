
# The X Keyboard Extension
package X11::Protocol::Ext::XKEYBOARD;

# Note: this is not a complete implementation of the XKEYBOARD extension, but
#	is sufficient for getting and setting controls and requesting
#	and receiving events.

use X11::Protocol qw(pad padding padded make_num_hash);
use X11::Protocol::Enhanced;
use Carp;
use strict;
use warnings;
use vars '$VERSION';
$VERSION = 0.02;

=head1 NAME

X11::Protocol::Ext::XKEYBOARD -- Perl extension module for X Keyboard Extension Protocol

=head1 SYNOPSIS

 use X11::Protocol;
 $x = X11::Protocol->new($ENV{DISPLAY});
 $x->init_extension('XKEYBOARD') or die;

=head1 DESCRIPTION

This module is used by the L<X11::Protocol(3pm)> module to participat in
the keboard extension to the X protocol, allowing the client to control
the keyboard and other input devices, per the L<X Keyboard Extension
Protocol Specification>, a copy of which can be obtained from
L<http://www.x.org/releases/X11R7.7/doc/kbproto/xkbproto.pdf>.

This manual page does not attempt to document the protocol itself, see
the specification for that.  It documents the L</CONSTANTS>, L</EVENTS>
and L</ERRORS> that are added to the L<X11::Protocol(3pm)> module.

=cut

=head1 EVENTS

B<XKEYBOARD> multiplexes one base event number with the C<xkb-code>
field.  Therefore, B<X11::Protocol::Ext::XKEYBOARD> provides the
following single event type: C<XkbNotify>, the fields of which depend on
the value of the C<xkb_code> field (which is of type C<XkbEventType>).
This field can have the value:

  XkbEventType => XkbNewKeyboardNotify XkbMapNotify XkbStateNotify
      XkbControlsNotify XkbIndicatorStateNotify XkbIndicatorMapNotify
      XkbNamesNotify XkbCompatMapNotify XkbBellNotify XkbActionNotify
      XkbAccessXNotify XkbExtensionDeviceNotify
=cut

our $XkbEventTypePack = [];

=head2 XkbNewKeyboardNotify

The unpacked C<XkbNewKeyboardNotify> event
contains the following fields in the event hash:

 XkbNewKeyboardNotify => {
     xkb_code           => $code,
     time               => $time,
     deviceID           => $deviceid,
     oldDeviceID        => $deviceid,
     minKeyCode         => $keycode,
     maxKeyCode         => $keycode,
     oldMinKeyCode      => $keycode,
     oldMaxKeyCode      => $keycode,
     requestMajor       => $major,
     requestMinor       => $minor,
     changed            => $XkbNKNDetail} # mask
=cut
$XkbEventTypePack->[0] =
    [ 'XkbNewKeyboardNotify', sub{ # 0
        my ($x,$data,%ret) = @_;
        my @vals = unpack('xCxxLCCCCCCCCSxxxxxxxxxxxxxx', $data);
        foreach (qw(xkb_code time deviceId oldDeviceId minKeyCode
                    maxKeyCode oldMinKeyCode oldMaxKeyCode requestMajor
                    requestMinor changed)) {
            $ret{$_} = shift @vals;
        }
        $ret{xkb_code} = $x->interp(XkbEventType=>$ret{xkb_code});
        return (%ret);
    }, sub{
        my ($x,%h) = @_;
        my $do_seq = 1;
        $h{xkb_code} = $x->num(XkbEventType=>$h{xkb_code});
        my @vals = ();
        foreach (qw(xkb_code time deviceId oldDeviceId minKeyCode
                    maxKeyCode oldMinKeyCode oldMaxKeyCode requestMajor
                    requestMinor changed)) {
            push @vals, $h{$_};
        }
        my $data = pack('xCxxLCCCCCCCCSxxxxxxxxxxxxxx',@vals);
        return ($data, $do_seq);
    }];
=head2 XkbMapNotify

The unpacked C<XkbMapNotify> event
contains the following fields in the event hash:

 XkbMapNotify => {
     xkb_code           => $code,
     time               => $time,
     deviceId           => $deviceid,
     ptrBtnActions      => $XkbButMask, # 8-bit bit mask
     changed            => $XkbMapPart, # mask
     minKeyCode         => $keycode,
     maxKeyCode         => $keycode,
     firstType          => $type,
     nTypes             => $ntypes,
     firstKeySym        => $keysym,
     nKeySyms           => $nkeysyms,
     firstKeyAct        => $keyact,
     nKeyActs           => $nkeyacts,
     firstKeyBehavior   => $behave,
     nKeyBehavior       => $nbehave,
     firstKeyExplicit   => $keyexp,
     nKeyExplicit       => $nkeyexp,
     firstModMapKey     => $modmapkey,
     nModMapKeys        => $nmodmapkey,
     firstVModMapKey    => $vmodmapkey,
     nVModMapKeys       => $nvmodmapkey,
     virtualMods        => $XkbVMod}    # mask
=cut
$XkbEventTypePack->[1] =
    [ 'XkbMapNotify', sub{ # 1
        my ($x,$data,%ret) = @_;
        my @vals = unpack('xCxxLCCSCCCCCCCCCCCCCCCCSxx', $data);
        foreach (qw(xkb_code time deviceId ptrBtnActions changed
                    minKeyCode maxKeyCode firstType nTypes firstKeySym
                    nKeySyms firstKeyAct nKeyActs firstKeyBehavior
                    nKeyBehavior firstKeyExplicit nKeyExplicit
                    firstModMapKey nModMapKeys firstVModMapKey
                    nVModMapKeys virtualMods)) {
            $ret{$_} = shift @vals;
        }
        $ret{xkb_code} = $x->interp(XkbEventType=>$ret{xkb_code});
        return (%ret);
    }, sub{
        my ($x,%h) = @_;
        my $do_seq = 1;
        $h{xkb_code} = $x->num(XkbEventType=>$h{xkb_code});
        my @vals = ();
        foreach (qw(xkb_code time deviceId ptrBtnActions changed
                    minKeyCode maxKeyCode firstType nTypes firstKeySym
                    nKeySyms firstKeyAct nKeyActs firstKeyBehavior
                    nKeyBehavior firstKeyExplicit nKeyExplicit
                    firstModMapKey nModMapKeys firstVModMapKey
                    nVModMapKeys virtualMods)) {
            push @vals, $h{$_};
        }
        my $data = pack('xCxxLCCSCCCCCCCCCCCCCCCCSxx', @vals);
        return ($data, $do_seq);
    }];
=head2 XkbStateNotify 

The unpacked C<XkbStateNotify> event
contains the following fields in the event hash:

 XkbStateNotify => {
     xkb_code           => $code,
     time               => $time,
     deviceID           => $deviceid,
     mods               => $XkbKeyMask,     # mask
     baseMods           => $XkbKeyMask,     # mask
     latchedMods        => $XkbKeyMask,     # mask
     lockedMods         => $XkbKeyMask,     # mask
     group              => $XkbGroup,
     baseGroup          => $group,
     latchedGroup       => $group,
     lockedGroup        => $XkbGroup,
     compatState        => $XkbKeyMask,     # mask
     grabMods           => $XkbKeyMask,     # mask
     compatGrabMods     => $XkbKeyMask,     # mask
     lookupMods         => $XkbKeyMask,     # mask
     compatLookupMods   => $XkbKeyMask,     # mask
     ptrBtnState        => $butmask,
     changed            => $XkbStatePart,   # mask
     keycode            => $keycode,
     eventType          => $eventtype,
     requestMajor       => $major,
     requestMinor       => $minor}
=cut
$XkbEventTypePack->[2] =
    [ 'XkbStateNotify', sub{ # 2
        my ($x,$data,%ret) = @_;
        my @vals = unpack('xCxxLCCCCCCSSCCCCCCSSCCCC', $data);
        foreach (qw(xkb_code time deviceID mods baseMods latchedMods
                    lockedMods group baseGroup latchedGroup lockedGroup
                    compatState grabMods compatGrabMods lookupMods
                    compatLookupMods ptrBtnState changed keycode
                    eventType requestMajor requestMinor)) {
            $ret{$_} = shift @vals;
        }
        $ret{xkb_code} = $x->interp(XkbEventType=>$ret{xkb_code});
        return (%ret);
    }, sub{
        my ($x,%h) = @_;
        my $do_seq = 1;
        $h{xkb_code} = $x->num(XkbEventType=>$h{xkb_code});
        my @vals = ();
        foreach (qw(xkb_code time deviceID mods baseMods latchedMods
                    lockedMods group baseGroup latchedGroup lockedGroup
                    compatState grabMods compatGrabMods lookupMods
                    compatLookupMods ptrBtnState changed keycode
                    eventType requestMajor requestMinor)) {
            push @vals, $h{$_};
        }
        my $data = pack('xCxxLCCCCCCSSCCCCCCSSCCCC',@vals);
        return ($data, $do_seq);
    }];
=head2 XkbControlsNotify 

The unpacked C<XkbControlsNotify> event
contains the following fields in the event hash:

 XkbControlsNotify => {
     xkb_code           => $code,
     time               => $time,
     deviceID           => $deviceid,
     numGroups          => $numgroups,
     changedControls    => $XkbControl,     # mask
     enabledControls    => $XkbBoolCtrl,    # mask
     enabledControlChanges => $XkbBoolCtrl, # mask
     keycode            => $keycode,
     eventType          => $eventttype,
     requestMajor       => $major,
     requestMinor       => $minor}
=cut
$XkbEventTypePack->[3] =
    [ 'XkbControlsNotify', sub{ # 3
        my ($x,$data,%ret) = @_;
        my @vals = unpack('xCxxLCCxxLLLCCCCxxxx', $data);
        foreach (qw(xkb_code time deviceID numGroups changedControls
                    enabledControls enabledControlChanges keycode
                    eventType requestMajor requestMinor)) {
            $ret{$_} = shift @vals;
        }
        $ret{xkb_code} = $x->interp(XkbEventType=>$ret{xkb_code});
        return (%ret);
    }, sub{
        my ($x,%h) = @_;
        my $do_seq = 1;
        $h{xkb_code} = $x->num(XkbEventType=>$h{xkb_code});
        my @vals = ();
        foreach (qw(xkb_code time deviceID numGroups changedControls
                    enabledControls enabledControlChanges keycode
                    eventType requestMajor requestMinor)) {
            push @vals, $h{$_};
        }
        my $data = pack('xCxxLCCxxLLLCCCCxxxx',@vals);
        return ($data, $do_seq);
    }];
=head2 XkbIndicatorStateNotify 

The unpacked C<XkbIndicatorStateNotify> event
contains the following fields in the event hash:

 XkbIndicatorStateNotify => {
     xkb_code           => $code,
     time               => $time,
     deviceID           => $deviceid,
     state              => $XkbIndicator, # 32-bit bit mask
     stateChanged       => $XkbIndicator} # 32-bit bit mask
=cut
$XkbEventTypePack->[4] =
    [ 'XkbIndicatorStateNotify', sub{ # 4
        my ($x,$data,%ret) = @_;
        my @vals = unpack('xCxxLCxxxLLxxxxxxxxxxxx', $data);
        foreach (qw(xkb_code time deviceID state stateChanged)) {
            $ret{$_} = shift @vals;
        }
        $ret{xkb_code} = $x->interp(XkbEventType=>$ret{xkb_code});
        return (%ret);
    }, sub{
        my ($x,%h) = @_;
        my $do_seq = 1;
        $h{xkb_code} = $x->num(XkbEventType=>$h{xkb_code});
        my @vals = ();
        foreach (qw(xkb_code time deviceID state stateChanged)) {
            push @vals, $h{$_};
        }
        my $data = pack('xCxxLCxxxLLxxxxxxxxxxxx', @vals);
        return ($data, $do_seq);
    }];
=head2 XkbIndicatorMapNotify 

The unpacked C<XkbIndicatorMapNotify> event
contains the following fields in the event hash:

 XkbIndicatorMapNotify => {
     xkb_code           => $code,
     time               => $time,
     deviceID           => $deviceid,
     state              => $XkbIndicator, # 32-bit bit mask
     mapChanged         => $XkbIndicator} # 32-bit bit mask
=cut
$XkbEventTypePack->[5] =
    [ 'XkbIndicatorMapNotify', sub{ # 5
        my ($x,$data,%ret) = @_;
        my @vals = unpack('xCxxLCxxxLLxxxxxxxxxxxx', $data);
        foreach (qw(xkb_code time deviceID state mapChanged)) {
            $ret{$_} = shift @vals;
        }
        $ret{xkb_code} = $x->interp(XkbEventType=>$ret{xkb_code});
        return (%ret);
    }, sub{
        my ($x,%h) = @_;
        my $do_seq = 1;
        $h{xkb_code} = $x->num(XkbEventType=>$h{xkb_code});
        my @vals = ();
        foreach (qw(xkb_code time deviceID state mapChanged)) {
            push @vals, $h{$_};
        }
        my $data = pack('xCxxLCxxxLLxxxxxxxxxxxx', @vals);
        return ($data, $do_seq);
    }];
=head2 XkbNamesNotify 

The unpacked C<XkbNamesNotify> event
contains the following fields in the event hash:

 XkbNamesNotify => {
     xkb_code           => $code,
     time               => $time,
     deviceID           => $deviceid,
     changed            => $XkbNameDetail,  # mask
     firstType          => $type,
     nTypes             => $ntypes,
     firstLevelName     => $level,
     nLevelNames        => $nlevels,
     nRadioGroups       => $ngroups,
     nKeyAliases        => $naliases,
     changedGroupNames  => $XkbKbGroup,     # mask
     changedVirtualMods => $XkbVMod,        # mask
     firstKey           => $keycode,
     nKeys              => $nkeys,
     changedIndicators  => $XkbIndicator}   # 32-bit bit mask
=cut
$XkbEventTypePack->[6] =
    [ 'XkbNamesNotify', sub{ # 6
        my ($x,$data,%ret) = @_;
        my @vals = unpack('xCxxLCxSCCCCxCCCSCCLxxxx', $data);
        foreach (qw(xkb_code time deviceID changed firstType nTypes
                    firstLevelName nLevelNames nRadioGroups nKeyAliases
                    changedGroupNames changedVirtualMods firstKey nKeys
                    changedIndicators)) {
            $ret{$_} = shift @vals;
        }
        $ret{xkb_code} = $x->interp(XkbEventType=>$ret{xkb_code});
        return (%ret);
    }, sub{
        my ($x,%h) = @_;
        my $do_seq = 1;
        $h{xkb_code} = $x->num(XkbEventType=>$h{xkb_code});
        my @vals = ();
        foreach (qw(xkb_code time deviceID changed firstType nTypes
                    firstLevelName nLevelNames nRadioGroups nKeyAliases
                    changedGroupNames changedVirtualMods firstKey nKeys
                    changedIndicators)) {
            push @vals, $h{$_};
        }
        my $data = pack('xCxxLCxSCCCCxCCCSCCLxxxx', @vals);
        return ($data, $do_seq);
    }];
=head2 XkbCompatMapNotify 

The unpacked C<XkbCompatMapNotify> event
contains the following fields in the event hash:

 XkbCompatMapNotify => {
     xkb_code           => $code,
     time               => $time,
     deviceID           => $deviceid,
     changedGroups      => $XkbKbGroup,     # mask
     firstSI            => $firstsi,
     nSI                => $nsi,
     nTotalSI           => $ntotalsi}

=cut
$XkbEventTypePack->[7] =
    [ 'XkbCompatMapNotify', sub{ # 7
        my ($x,$data,%ret) = @_;
        my @vals = unpack('xCxxLCCSSSxxxxxxxxxxxxxxxx', $data);
        foreach (qw(xkb_code time deviceID changedGroups firstSI nSI
                    nTotalSI)) {
            $ret{$_} = shift @vals;
        }
        $ret{xkb_code} = $x->interp(XkbEventType=>$ret{xkb_code});
        return (%ret);
    }, sub{
        my ($x,%h) = @_;
        my $do_seq = 1;
        $h{xkb_code} = $x->num(XkbEventType=>$h{xkb_code});
        my @vals = ();
        foreach (qw(xkb_code time deviceID changedGroups firstSI nSI
                    nTotalSI)) {
            push @vals, $h{$_};
        }
        my $data = pack('xCxxLCCSSSxxxxxxxxxxxxxxxx', @vals);
        return ($data, $do_seq);
    }];
=head2 XkbBellNotify 

The unpacked C<XkbBellNotify> event
contains the following fields in the event hash:

 XkbBellNotify => {
     xkb_code           => $code,
     time               => $time,
     deviceID           => $deviceid,
     bellClass          => $XkbBellClassResult,
     bellID             => $bellid,
     percent            => $percent,
     pitch              => $pitch,
     duration           => $duration,
     bell_name          => $atom,  # 'name' would conflict
     window             => $window,
     eventOnly          => $Bool}
=cut
$XkbEventTypePack->[8] =
    [ 'XkbBellNotify', sub{ # 8
        my ($x,$data,%ret) = @_;
        my @vals = unpack('xCxxLCCCCSSLLCxxxxxxx', $data);
        foreach (qw(xkb_code time deviceID bellClass bellID percent
                    pitch duration bell_name window eventOnly)) {
            $ret{$_} = shift @vals;
        }
        $ret{xkb_code} = $x->interp(XkbEventType=>$ret{xkb_code});
        $ret{bellClass} = $x->interp(XkbBellClassResult=>$ret{bellClass});
        $ret{eventOnly} = $x->interp(Bool=>$ret{eventOnly});
        return (%ret);
    }, sub{
        my ($x,%h) = @_;
        my $do_seq = 1;
        $h{xkb_code} = $x->num(XkbEventType=>$h{xkb_code});
        $h{bellClass} = $x->num(XkbBellClassResult=>$h{bellClass});
        $h{eventOnly} = $x->num(Bool=>$h{eventOnly});
        my @vals = ();
        foreach (qw(xkb_code time deviceID bellClass bellID percent
                    pitch duration bell_name window eventOnly)) {
            push @vals, $h{$_};
        }
        my $data = pack('xCxxLCCCCSSLLCxxxxxxx', @vals);
        return ($data, $do_seq);
    }];
=head2 XkbActionMessage 

The unpacked C<XkbActionMessage> event
contains the following fields in the event hash:

 XkbActionMessage => {
     xkb_code           => $code,
     time               => $time,
     deviceID           => $deviceid,
     keycode            => $keycode,
     press              => $Bool,
     keyEventFollows    => $Bool,
     mods               => $XkbKeyMask,     # mask
     group              => $XkbGroup,
     message            => $message}
=cut
$XkbEventTypePack->[9] =
    [ 'XkbActionMessage', sub{ # 9
        my ($x,$data,%ret) = @_;
        my @vals = unpack('xCxxLCCCCCCa[8]x[10]', $data);
        foreach (qw(xkb_code time deviceID keycode press keyEventFollows
                    mods group message)) {
            $ret{$_} = shift @vals;
        }
        $ret{xkb_code} = $x->interp(XkbEventType=>$ret{xkb_code});
        $ret{press} = $x->interp(Bool=>$ret{press});
        $ret{keyEventFollows} = $x->interp(Bool=>$ret{keyEventFollows});
        $ret{group} = $x->interp(XkbGroup=>$ret{group});
        return (%ret);
    }, sub{
        my ($x,%h) = @_;
        my $do_seq = 1;
        $h{xkb_code} = $x->num(XkbEventType=>$h{xkb_code});
        $h{press} = $x->num(Bool=>$h{press});
        $h{keyEventFollows} = $x->num(Bool=>$h{keyEventFollows});
        $h{group} = $x->num(XkbGroup=>$h{group});
        my @vals = ();
        foreach (qw(xkb_code time deviceID keycode press keyEventFollows
                    mods group message)) {
            push @vals, $h{$_};
        }
        my $data = pack('xCxxLCCCCCCa[8]x[10]', @vals);
        return ($data, $do_seq);
    }];
=head2 XkbAcessXNotify 

The unpacked C<XkbAcessXNotify> event contains the following fields in
the event hash:

 XkbAcessXNotify => {
     xkb_code           => $code,
     time               => $time,
     deviceID           => $deviceid,
     keycode            => $keycode,
     detail             => $XkbAXNDetail,   # mask
     slowKeysDelay      => $delay,
     debounceDelay      => $delay}
=cut
$XkbEventTypePack->[10] =
    [ 'XkbAccessXNotify', sub{ # 10
        my ($x,$data,%ret) = @_;
        my @vals = unpack('xCxxLCCSSSxxxxxxxxxxxxxxxx', $data);
        foreach (qw(xkb_code time deviceID keycode detail slowKeysDelay
                    debounceDelay)) {
            $ret{$_} = shift @vals;
        }
        $ret{xkb_code} = $x->interp(XkbEventType=>$ret{xkb_code});
        return (%ret);
    }, sub{
        my ($x,%h) = @_;
        my $do_seq = 1;
        $h{xkb_code} = $x->num(XkbEventType=>$h{xkb_code});
        my @vals = ();
        foreach (qw(xkb_code time deviceID keycode detail slowKeysDelay
                    debounceDelay)) {
            push @vals, $h{$_};
        }
        my $data = pack('xCxxLCCSSSxxxxxxxxxxxxxxxx', @vals);
        return ($data, $do_seq);
    }];
=head2 XkbExtensionDeviceNotify 

The unpacked C<XkbExtensionDeviceNotify> event contains the following
fields in the event hash:

 XkbExtensionDeviceNotify => {
     xkb_code           => $code,
     time               => $time,
     deviceID           => $deviceid,
     reason             => $XkbXIDetail,    # mask
     ledClass           => $XkbLEDClassResult,
     ledID              => $ledid,
     ledsDefined        => $XkbIndicator,   # 32-bit bit mask
     ledState           => $XkbIndicator,   # 32-bit bit mask
     firstButton        => $button,
     nButtons           => $nbuttons,
     supported          => $XkbXIFeature,   # mask
     unsupported        => $XkbXIFeature}   # mask
=cut
$XkbEventTypePack->[11] =
    [ 'XkbExtensionDeviceNotify', sub{ # 11
        my ($x,$data,%ret) = @_;
        my @vals = unpack('xCxxLCxSSSLLCCSSxx', $data);
        foreach (qw(xkb_code time deviceID reason ledClass ledID
                    ledsDefined ledState firstButton nButtons supported
                    unsupported)) {
            $ret{$_} = shift @vals;
        }
        $ret{xkb_code} = $x->interp(XkbEventType=>$ret{xkb_code});
        return (%ret);
    }, sub{
        my ($x,%h) = @_;
        my $do_seq = 1;
        $h{xkb_code} = $x->num(XkbEventType=>$h{xkb_code});
        my @vals = ();
        foreach (qw(xkb_code time deviceID reason ledClass ledID
                    ledsDefined ledState firstButton nButtons supported
                    unsupported)) {
            push @vals, $h{$_};
        }
        my $data = pack('xCxxLCxSSSLLCCSSxx', @vals);
        return ($data, $do_seq);
    }];

sub new
{
    my $self = bless {}, shift;
    my($x, $request_base, $event_base, $error_base) = @_;

    $x->{ext_const}{Events}[$event_base] = 'XkbEventNotify';
    $x->{ext_events}[$event_base] = [sub{
        my ($x,$data,%ret) = @_;
        my ($code) = unpack('xCxx',$data);
        return (%ret) unless 0 <= $code and $code <= 11;
        return &{$XkbEventTypePack->[$code][1]}(@_);
    },sub{
        my ($x,%h) = @_;
        my $code = $x->num(XkbEventType=>$h{xkb_code});
        return ('',0) unless 0 <= $code and $code <= 11;
        return &{$XkbEventTypePack->[$code][2]}(@_);
    }];

=head1 CONSTANTS

B<X11::Protocol::Ext::XKEYBOARD> provides the following constants: (some
are enums, some are masks, some are both)

 XkbEventType => XkbNewKeyboardNotify XkbMapNotify
     XkbStateNotify XkbControlsNotify XkbIndicatorStateNotify
     XkbIndicatorMapNotify XkbNamesNotify XkbCompatMapNotify
     XkbBellNotify XkbActionMessage XkbAcessXNotify
     XkbExtensionDeviceNotify
=cut
    my $XkbEventType =
	[qw(XkbNewKeyboardNotify XkbMapNotify XkbStateNotify
	    XkbControlsNotify XkbIndicatorStateNotify
	    XkbIndicatorMapNotify XkbNamesNotify XkbCompatMapNotify
	    XkbBellNotify XkbActionMessage XkbAcessXNotify
	    XkbExtensionDeviceNotify)];
    my $XkbEventTypeHash = {make_num_hash($XkbEventType)};
    $x->{ext_const}{XkbEventType} = $XkbEventType;
    $x->{ext_const_num}{XkbEventType} = $XkbEventTypeHash;
    my @XkbEventTypePack = (
            ['SS',4,'XkbNKNDetail'],
            ['SS',4,'XkbMapDetail'],
            ['SS',4,'XkbStatePart'],
            ['LL',8,'XkbControl'],
            ['LL',8,'XkbIndicator'],
            ['LL',8,'XkbIndicator'],
            ['SS',4,'XkbNameDetail'],
            ['CC',2,'XkbCMDetail'],
            ['CC',2,'XkbBellDetail'],
            ['CC',2,'XkbMsgDetail'],
            ['SS',4,'XkbAXNDetail'],
            ['SS',4,'XkbXIDetail'],
    );
=pod

 XkbKeyMask => Shift Lock Control Mod1 Mod2 Mod3 Mod4 Mod5
=cut
    my $XkbKeyMask =
        [qw(Shift Lock Control Mod1 Mod2 Mod3 Mod4 Mod5)];
    my $XkbKeyMaskHash = {make_num_hash($XkbKeyMask)};
    $x->{ext_const}{XkbKeyMask} = $XkbKeyMask;
    $x->{ext_const_num}{XkbKeyMask} = $XkbKeyMaskHash;
=pod

 XkbButMask => Button0 Button1 Button2 Button3
               Button4 Button5 Button6 Button7
=cut
    my $XkbButMask =
        [qw(Button0 Button1 Button2 Button3
            Button4 Button5 Button6 Button7)];
    my $XkbButMaskHash = {make_num_hash($XkbButMask)};
    $x->{ext_const}{XkbButMask} = $XkbButMask;
    $x->{ext_const_num}{XkbButMask} = $XkbButMaskHash;
=pod

 XkbNKNDetail => Keycodes Geometry DeviceID
=cut
    my $XkbNKNDetail =
	[qw(Keycodes Geometry DeviceID)];
    my $XkbNKNDetailHash = {make_num_hash($XkbNKNDetail)};
    $x->{ext_const}{XkbNKNDetail} = $XkbNKNDetail;
    $x->{ext_const_num}{XkbNKNDetail} = $XkbNKNDetailHash;
=pod

 XkbAXNDetail => SKPress SKAccept SKReject SKRelease BKAccept
     BKReject AXKWarning
=cut
    my $XkbAXNDetail =
	[qw(SKPress SKAccept SKReject SKRelease BKAccept BKReject
	    AXKWarning)];
    my $XkbAXNDetailHash = {make_num_hash($XkbAXNDetail)};
    $x->{ext_const}{XkbAXNDetail} = $XkbAXNDetail;
    $x->{ext_const_num}{XkbAXNDetail} = $XkbAXNDetailHash;
=pod

 XkbMapPart => KeyTypes KeySyms ModifierMap ExplicitComponents
     KeyActions KeyBehaviors VirtualMods VirtualModMap
=cut
    my $XkbMapPart =
	[qw(KeyTypes KeySyms ModifierMap ExplicitComponents KeyActions
	    KeyBehaviors VirtualMods VirtualModMap)];
    my $XkbMapPartHash = {make_num_hash($XkbMapPart)};
    $x->{ext_const}{XkbMapPart} = $XkbMapPart;
    $x->{ext_const_num}{XkbMapPart} = $XkbMapPartHash;
=pod

 XkbStatePart => ModifierState ModifierBase ModifierLatch
     ModifierLock GroupState GroupBase GroupLatch GroupLock
     CompatState GrabModes CompatGrabMods LookupMods
     CompatLookupMods PointerButtons
=cut
    my $XkbStatePart =
	[qw(ModifierState ModifierBase ModifierLatch ModifierLock
	    GroupState GroupBase GroupLatch GroupLock CompatState
	    GrabModes CompatGrabMods LookupMods CompatLookupMods
	    PointerButtons)];
    my $XkbStatePartHash = {make_num_hash($XkbStatePart)};
    $x->{ext_const}{XkbStatePart} = $XkbStatePart;
    $x->{ext_const_num}{XkbStatePart} = $XkbStatePartHash;
=pod

 XkbBoolCtrl => RepeatKeys SlowKeys BounceKeys StickyKeys
     MouseKeys MouseKeysAccel AccessXKeys AccessXTimeoutMask
     AccessXFeedbackMask AudibleBellMask Overlay1Mask
     Overlay2Mask IgnoreGroupLockMask
=cut
    my $XkbBoolCtrl =
	[qw(RepeatKeys SlowKeys BounceKeys StickyKeys MouseKeys
	    MouseKeysAccel AccessXKeys AccessXTimeoutMask
	    AccessXFeedbackMask AudibleBellMask Overlay1Mask
	    Overlay2Mask IgnoreGroupLockMask)];
    my $XkbBoolCtrlHash = {make_num_hash($XkbBoolCtrl)};
    $x->{ext_const}{XkbBoolCtrl} = $XkbBoolCtrl;
    $x->{ext_const_num}{XkbBoolCtrl} = $XkbBoolCtrlHash;
=pod

  XkbControl => RepeatKeys SlowKeys BounceKeys StickyKeys
      MouseKeys MouseKeysAccel AccessXKeys AccessXTimeoutMask
      AccessXFeedbackMask AudibleBellMask Overlay1Mask
      Overlay2Mask IgnoreGroupLockMask GroupsWrap InternalMods
      IgnoreLockMods PerKeyRepeat ControlsEnabled
=cut
    my $XkbControl =
	[qw(RepeatKeys SlowKeys BounceKeys StickyKeys MouseKeys
	    MouseKeysAccel AccessXKeys AccessXTimeoutMask
	    AccessXFeedbackMask AudibleBellMask Overlay1Mask
	    Overlay2Mask IgnoreGroupLockMask), undef, undef, undef,
	    undef, undef, undef, undef, undef, undef, undef, undef,
	    undef, undef, qw(GroupsWrap InternalMods IgnoreLockMods
	    PerKeyRepeat ControlsEnabled)];
    my $XkbControlHash = {make_num_hash($XkbControl)};
    $x->{ext_const}{XkbControl} = $XkbControl;
    $x->{ext_const_num}{XkbControl} = $XkbControlHash;
=pod

  XkbAXFBOpt => SKPress SKAccept Feature SlowWarn Indicator
      StickyKeys SKRelease SKReject BKReject DumbBell
=cut
    my $XkbAXFBOpt =
	[qw(SKPress SKAccept Feature SlowWarn Indicator StickyKeys),
	    undef, undef, qw(SKRelease SKReject BKReject DumbBell)];
    my $XkbAXFBOptHash = {make_num_hash($XkbAXFBOpt)};
    $x->{ext_const}{XkbAXFBOpt} = $XkbAXFBOpt;
    $x->{ext_const_num}{XkbAXFBOpt} = $XkbAXFBOptHash;
=pod

  XkbAXSKOpt => TwoKeys LatchToLock
=cut
    my $XkbAXSKOpt =
	[undef, undef, undef, undef, undef, undef, qw(TwoKeys
	    LatchToLock)];
    my $XkbAXSKOptHash = {make_num_hash($XkbAXSKOpt)};
    $x->{ext_const}{XkbAXSKOpt} = $XkbAXSKOpt;
    $x->{ext_const_num}{XkbAXSKOpt} = $XkbAXSKOptHash;
=pod

  XkbAXOption => SKPress SKAccept Feature SlowWarn Indicator
      StickKeys TwoKeys LatchToLock SKRelease SKReject BKReject
      DumbBell
=cut
    my $XkbAXOption =
	[qw(SKPress SKAccept Feature SlowWarn Indicator StickKeys
	    TwoKeys LatchToLock SKRelease SKReject BKReject DumbBell)];
    my $XkbAXOptionHash = {make_num_hash($XkbAXOption)};
    $x->{ext_const}{XkbAXOption} = $XkbAXOption;
    $x->{ext_const_num}{XkbAXOption} = $XkbAXOptionHash;
=pod

  XkbDeviceSpec => UseCoreKbd UseCorePtr
=cut
    my $XkbDeviceSpec = [];
    $XkbDeviceSpec->[256] = 'UseCoreKbd';
    $XkbDeviceSpec->[257] = 'UseCorePtr';
    my $XkbDeviceSpecHash = {make_num_hash($XkbDeviceSpec)};
    $x->{ext_const}{XkbDeviceSpec} = $XkbDeviceSpec;
    $x->{ext_const_num}{XkbDeviceSpec} = $XkbDeviceSpecHash;
=pod

  XkbLEDClassResult => KbdFeedbackClass LedFeedbackClass
=cut
    my $XkbLEDClassResult = [q(KbdFeedbackClass), undef, undef, undef,
       q(LedFeedbackClass)];
    my $XkbLEDClassResultHash = {make_num_hash($XkbLEDClassResult)};
    $x->{ext_const}{XkbLEDClassResult} = $XkbLEDClassResult;
    $x->{ext_const_num}{XkbLEDClassResult} = $XkbLEDClassResultHash;
=pod

  XkbLEDClassSpec => KbdFeedbackClass LedFeedbackClass
      DfltXIClass AllXIClasses
=cut
    my $XkbLEDClassSpec = [ @{$XkbLEDClassResult} ];
    $XkbLEDClassSpec->[0x0300] = 'DfltXIClass';
    $XkbLEDClassSpec->[0x0500] = 'AllXIClasses';
    my $XkbLEDClassSpecHash = {make_num_hash($XkbLEDClassSpec)};
    $x->{ext_const}{XkbLEDClassSpec} = $XkbLEDClassSpec;
    $x->{ext_const_num}{XkbLEDClassSpec} = $XkbLEDClassSpecHash;
=pod

  XkbBellClassResult => KbdFeedbackClass BellFeedbackClass
=cut
    my $XkbBellClassResult = [q(KbdFeedbackClass), undef, undef, undef,
       undef, q(BellFeedbackClass)];
    my $XkbBellClassResultHash = {make_num_hash($XkbBellClassResult)};
    $x->{ext_const}{XkbBellClassResult} = $XkbBellClassResult;
    $x->{ext_const_num}{XkbBellClassResult} = $XkbBellClassResultHash;
=pod

  XkbBellClassSpec => KbdFeedbackClass BellFeedbackClass
      DfltXIClass
=cut
    my $XkbBellClassSpec = [ @{$XkbBellClassResult} ];
    $XkbBellClassSpec->[0x0300] = 'DfltXIClass';
    $x->{ext_const}{XkbBellClassSpec} = $XkbBellClassSpec;
=pod

  XkbIDSpec => DfltXIId
=cut
    my $XkbIDSpec = [];
    $XkbIDSpec->[0x0400] = 'DfltXIId';
    my $XkbIDSpecHash = {make_num_hash($XkbIDSpec)};
    $x->{ext_const}{XkbIDSpec} = $XkbIDSpec;
    $x->{ext_const_num}{XkbIDSpec} = $XkbIDSpecHash;
=pod

  XkbIDResult => DfltXIId XINone
=cut
    my $XkbIDResult = [ @{$XkbIDSpec} ];
    $XkbIDResult->[0xff00] = 'XINone';
    my $XkbIDResultHash = {make_num_hash($XkbIDResult)};
    $x->{ext_const}{XkbIDResult} = $XkbIDResult;
    $x->{ext_const_num}{XkbIDResult} = $XkbIDResultHash;
=pod

  XkbMultiIDSpec => DfltXIId AllXIIds
=cut
    my $XkbMultiIDSpec = [ @{$XkbIDSpec} ];
    $XkbMultiIDSpec->[0x0500] = 'AllXIIds';
    my $XkbMultiIDSpecHash = {make_num_hash($XkbMultiIDSpec)};
    $x->{ext_const}{XkbMultiIDSpec} = $XkbMultiIDSpec;
    $x->{ext_const_num}{XkbMultiIDSpec} = $XkbMultiIDSpecHash;
=pod

  XkbGroup => Group1 Group2 Group3 Group4
=cut
    my $XkbGroup = [qw(Group1 Group2 Group3 Group4)];
    my $XkbGroupHash = {make_num_hash($XkbGroup)};
    $x->{ext_const}{XkbGroup} = $XkbGroup;
    $x->{ext_const_num}{XkbGroup} = $XkbGroupHash;
=pod

  XkbGroups => Group1 Group2 Group3 Group4 AnyGroup AllGroups
=cut
    my $XkbGroups = [ @{$XkbGroup} ];
    $XkbGroups->[254] = 'AnyGroup';
    $XkbGroups->[255] = 'AllGroups';
    my $XkbGroupsHash = {make_num_hash($XkbGroups)};
    $x->{ext_const}{XkbGroups} = $XkbGroups;
    $x->{ext_const_num}{XkbGroups} = $XkbGroupsHash;
=pod

  XkbKbGroup => Group1 Group2 Group3 Group4
=cut
    my $XkbKbGroup = [qw(Group1 Group2 Group3 Group4)];
    $x->{ext_const}{XkbKbGroup} = $XkbKbGroup;
=pod

  XkbKbGroups => Group1 Group2 Group3 Group4 AnyGroup
=cut
    my $XkbKbGroups = [ @{$XkbKbGroup} ];
    $XkbKbGroups->[7] = 'AnyGroup';
    my $XkbKbGroupsHash = {make_num_hash($XkbKbGroups)};
    $x->{ext_const}{XkbKbGroups} = $XkbKbGroups;
    $x->{ext_const_num}{XkbKbGroups} = $XkbKbGroupsHash;
=pod

  XkbGroupsWrap => ClampIntoRange RedirectIntoRange
=cut
    my $XkbGroupsWrap = [undef, undef, undef, undef, undef, undef,
       qw(ClampIntoRange RedirectIntoRange)];
    my $XkbGroupsWrapHash = {make_num_hash($XkbGroupsWrap)};
    $x->{ext_const}{XkbGroupsWrap} = $XkbGroupsWrap;
    $x->{ext_const_num}{XkbGroupsWrap} = $XkbGroupsWrapHash;
=pod

  XkbVModsHigh => vmod8 vmod9 vmod10 vmod11 vmod12 vmod13
      vmod14 vmod15
=cut
    my $XkbVModsHigh = [qw(vmod8 vmod9 vmod10 vmod11 vmod12 vmod13
	    vmod14 vmod15)];
    my $XkbVModsHighHash = {make_num_hash($XkbVModsHigh)};
    $x->{ext_const}{XkbVModsHigh} = $XkbVModsHigh;
    $x->{ext_const_num}{XkbVModsHigh} = $XkbVModsHighHash;
=pod

  XkbVModsLow => vmod0 vmod1 vmod2 vmod3 vmod4 vmod5 vmod6 vmod7
=cut
    my $XkbVModsLow = [qw(vmod0 vmod1 vmod2 vmod3 vmod4 vmod5 vmod6
	    vmod7)];
    my $XkbVModsLowHash = {make_num_hash($XkbVModsLow)};
    $x->{ext_const}{XkbVModsLow} = $XkbVModsLow;
    $x->{ext_const_num}{XkbVModsLow} = $XkbVModsLowHash;
=pod

  XkbVMod => vmod0 vmod1 vmod2 vmod3 vmod4 vmod5 vmod6 vmod7
      vmod8 vmod9 vmod10 vmod11 vmod12 vmod13 vmod14 vmod15
      vmod16
=cut
    my $XkbVMod = [qw(vmod0 vmod1 vmod2 vmod3 vmod4 vmod5 vmod6 vmod7
	    vmod8 vmod9 vmod10 vmod11 vmod12 vmod13 vmod14 vmod15
	    vmod16)];
    my $XkbVModHash = {make_num_hash($XkbVMod)};
    $x->{ext_const}{XkbVMod} = $XkbVMod;
    $x->{ext_const_num}{XkbVMod} = $XkbVModHash;
=pod

  XkbExplicit => KeyType1 KeyType2 KeyType3 KeyType4 Interpret
      AutoRepeat Behavior VModMap
=cut
    my $XkbExplicit = [qw(KeyType1 KeyType2 KeyType3 KeyType4 Interpret
	    AutoRepeat Behavior VModMap)];
    my $XkbExplicitHash = {make_num_hash($XkbExplicit)};
    $x->{ext_const}{XkbExplicit} = $XkbExplicit;
    $x->{ext_const_num}{XkbExplicit} = $XkbExplicitHash;
=pod

  XkbSymInterpMatch => LevelOneOnly Operation
=cut
    my $XkbSymInterpMatch = [];
    $XkbSymInterpMatch->[0x80] = 'LevelOneOnly';
    $XkbSymInterpMatch->[0x7f] = 'Operation';
    my $XkbSymInterpMatchHash = {make_num_hash($XkbSymInterpMatch)};
    $x->{ext_const}{XkbSymInterpMatch} = $XkbSymInterpMatch;
    $x->{ext_const_num}{XkbSymInterpMatch} = $XkbSymInterpMatchHash;
=pod

  XkbIMFlag => LEDDrivesKB NoAutomatic NoExplicit
=cut
    my $XkbIMFlag = [undef, undef, undef, undef, undef, qw(LEDDrivesKB
	    NoAutomatic NoExplicit)];
    my $XkbIMFlagHash = {make_num_hash($XkbIMFlag)};
    $x->{ext_const}{XkbIMFlag} = $XkbIMFlag;
    $x->{ext_const_num}{XkbIMFlag} = $XkbIMFlagHash;
=pod

  XkbIMModsWhich => UseBase UseLatched UseLocked UseEffective
      UseCompat
=cut
    my $XkbIMModsWhich = [qw(UseBase UseLatched UseLocked UseEffective
	    UseCompat)];
    my $XkbIMModsWhichHash = {make_num_hash($XkbIMModsWhich)};
    $x->{ext_const}{XkbIMModsWhich} = $XkbIMModsWhich;
    $x->{ext_const_num}{XkbIMModsWhich} = $XkbIMModsWhichHash;
=pod

  XkbIMGroupsWhich => UseBase UseLatched UseLocked UseEffective
      UseCompat
=cut
    my $XkbIMGroupsWhich = [qw(UseBase UseLatched UseLocked UseEffective
	    UseCompat)];
    my $XkbIMGroupsWhichHash = {make_num_hash($XkbIMGroupsWhich)};
    $x->{ext_const}{XkbIMGroupsWhich} = $XkbIMGroupsWhich;
    $x->{ext_const_num}{XkbIMGroupsWhich} = $XkbIMGroupsWhichHash;
=pod

  XkbCMDetail => SymInterp GroupCompat
=cut
    my $XkbCMDetail = [qw(SymInterp GroupCompat)];
    my $XkbCMDetailHash = {make_num_hash($XkbCMDetail)};
    $x->{ext_const}{XkbCMDetail} = $XkbCMDetail;
    $x->{ext_const_num}{XkbCMDetail} = $XkbCMDetailHash;
=pod

  XkbNamesDetail => KeycodesName GeometryName SymbolsName
      PhysSymbolsName TypesName CompatName KeyTypeNames
      KTLevelNames IndicatorNames KeyNames KeyAliases
      VirtualModNames GroupNames RGNames
=cut
    my $XkbNameDetail = [qw(KeycodesName GeometryName SymbolsName
	    PhysSymbolsName TypesName CompatName KeyTypeNames
	    KTLevelNames IndicatorNames KeyNames KeyAliases
	    VirtualModNames GroupNames RGNames)];
    my $XkbNameDetailHash = {make_num_hash($XkbNameDetail)};
    $x->{ext_const}{XkbNameDetail} = $XkbNameDetail;
    $x->{ext_const_num}{XkbNameDetail} = $XkbNameDetailHash;
=pod

  XkbGBNDetail => Types CompatMap ClientSymbols ServerSymbols
      IndicatorMaps KeyNames Geometry OtherNames
=cut
    my $XkbGBNDetail = [qw(Types CompatMap ClientSymbols ServerSymbols
	    IndicatorMaps KeyNames Geometry OtherNames)];
    my $XkbGBNDetailHash = {make_num_hash($XkbGBNDetail)};
    $x->{ext_const}{XkbGBNDetail} = $XkbGBNDetail;
    $x->{ext_const_num}{XkbGBNDetail} = $XkbGBNDetailHash;
=pod

  XkbXIExtDevFeature => ButtonActions IndicatorNames
      IndicatorMaps IndicatorState
=cut
    my $XkbXIExtDevFeature = [undef, qw(ButtonActions IndicatorNames
	    IndicatorMaps IndicatorState)];
    my $XkbXIExtDevFeatureHash = {make_num_hash($XkbXIExtDevFeature)};
    $x->{ext_const}{XkbXIExtDevFeature} = $XkbXIExtDevFeature;
    $x->{ext_const_num}{XkbXIExtDevFeature} = $XkbXIExtDevFeatureHash;
=pod

  XkbXIFeature => Keyboards ButtonActions IndicatorNames
      IndicatorMaps IndicatorState
=cut
    my $XkbXIFeature = [ @{$XkbXIExtDevFeature} ];
    $XkbXIFeature->[0] = 'Keyboards';
    my $XkbXIFeatureHash = {make_num_hash($XkbXIFeature)};
    $x->{ext_const}{XkbXIFeature} = $XkbXIFeature;
    $x->{ext_const_num}{XkbXIFeature} = $XkbXIFeatureHash;
=pod

  XkbXIDetail => Keyboards ButtonActions IndicatorNames
      IndicatorMaps IndicatorState UnsupportedFeature
=cut
    my $XkbXIDetail = [ @{$XkbXIFeature} ];
    $XkbXIDetail->[15] = 'UnsupportedFeature';
    my $XkbXIDetailHash = {make_num_hash($XkbXIDetail)};
    $x->{ext_const}{XkbXIDetail} = $XkbXIDetail;
    $x->{ext_const_num}{XkbXIDetail} = $XkbXIDetailHash;
=pod

  XkbPerClientFlag => DetectableAutorepeat GrabsUseXKBState
      AutoResetControls LookupStateWhenGrabbed
      SendEventUsesXKBState
=cut
    my $XkbPerClientFlag = [qw(DetectableAutorepeat GrabsUseXKBState
	    AutoResetControls LookupStateWhenGrabbed
	    SendEventUsesXKBState)];
    my $XkbPerClientFlagHash = {make_num_hash($XkbPerClientFlag)};
    $x->{ext_const}{XkbPerClientFlag} = $XkbPerClientFlag;
    $x->{ext_const_num}{XkbPerClientFlag} = $XkbPerClientFlagHash;

=head1 ERRORS

B<X11::Protocol::Ext::XKEYBOARD> provides the following bad resource
errors: C<Keyboard>

=cut
    $x->{ext_const}{Error}[$error_base] = 'Keyboard';
    $x->{ext_const_num}{Error}{Keyboard} = $error_base;

=head1 REQUESTS

B<X11::Protocol::Ext::KEYBOARD> provides the folloing requests:

=cut

=pod

 $X->XkbUseExtension($major,$minor)
 =>
 ($supported,$major,$minor)
=cut
    $x->{ext_request}{$request_base}[0] =
	[XkbUseExtension => sub{
	    return pack('SS',@_[1..2]);
	}, sub{
            my ($x,$data) = @_;
	    my @vals = unpack('xCxxxxxxSSxxxxxxxxxxxxxxxxxxxx',$data);
	    $vals[0] = $x->interp(Bool=>$vals[0]);
	    return @vals;
	}];
=pod

 $X->XkbSelectEvents($deviceSpec,
         $XkbEventType=>'clear',            # to clear events
         $XkbEventType=>'selectAll,         # to select all events
	 $XkbEventType=>[$affect,$details], # filtered events
         ... )

     $deviceSpec => $XkbDeviceSpec
     $affects    => $bitmask # see spec for type
     $details    => $bitmask # see spec for type

     $bit is event type bit name or bit number
=cut
    $x->{ext_request}{$request_base}[1] =
	[XkbSelectEvents => sub{
            my($x, $deviceSpec, %ad) = @_;
	    %ad = () unless %ad;

	    $deviceSpec  = $x->num(XkbDeviceSpec=>$deviceSpec);
            $ad{XkbMapNotify} = [ [], [] ] unless $ad{XkbMapNotify};
            my ($affectWhich,$clear,$selectAll) = (0,0,0);
            my @topack = ();
            my $pack = 'SSSS';
            my $vlen = 0;
            for my $i (1, 0, 2 .. $#{$XkbEventType}) {
                my $mask = (1<<$i);
                if (my $val = $ad{$XkbEventType->[$i]}) {
                    $mask = (1<<$i);
                    if ($val eq 'clear') {
                        $clear |= $mask;
                        $affectWhich |= $mask;
                    }
                    elsif ($val eq 'selectAll') {
                        $selectAll |= $mask;
                        $affectWhich |= $mask;
                    }
                    elsif (ref $val eq 'ARRAY') {
                        $affectWhich |= $mask;
                        my @p = @{$XkbEventTypePack[$i]};
                        $pack .= $p[0];
                        $vlen += $p[1];
                        push @topack, $x->pack_mask($p[2],
                                $ad{$XkbEventType->[$i]});
                    }
                }
            }
            $pack .= 'x' x padding($vlen);
            return pack($pack, $deviceSpec, $affectWhich, $clear,
                    $selectAll, @topack);
	}];
=pod

 $X->XkbBell($deviceSpec, $bellClass, $bellID, $percent, $forceSound,
         $eventOnly, $pitch, $duration, $name, $window)
=cut
    $x->{ext_request}{$request_base}[3] =
	[XkbBell => sub{
	    my ($x,@vals) = @_;
	    $vals[0] = $x->num(XkbDeviceSpec=>$vals[0]);
	    $vals[1] = $x->num(XkbBellClassSpec=>$vals[1]);
	    $vals[2] = $x->num(XkbIDSpec=>$vals[2]);
	    $vals[4] = $x->num(Bool=>$vals[4]);
	    $vals[5] = $x->num(Bool=>$vals[5]);
	    return pack('SSSCCCxSSxxLL',@vals);
	}];
=pod

 $X->XkbGetState($deviceSpec)
 =>
 ($deviceID, $mods, $baseMods, $latchedMods, $lockedMods, $group,
         $lockedGroup, $baseGroup, $latchedGroup, $compatState,
         $grabMods, $compatGrabMods, $lookupMods, $compatLookupMods,
         $ptrBtnState)
=cut
    $x->{ext_request}{$request_base}[4] =
	[XkbGetState => sub{
	    my ($x,@vals) = @_;
	    $vals[0] = $x->num(XkbDeviceSpec=>$vals[0]);
	    return pack('Sxx',$vals[0]);
	}, sub{
	    return unpack('xCxxxxxxCCCCCCssCCCCCxSxxxxxx',$_[1]);
	}];
=pod

 $X->XkbLatchLockState($deviceSpec, $affectModLocks, $modLocks,
         $lockGroup, $groupLock, $affectModLatches, $modLatches,
         $latchGroup, $groupLatch)
    
     $affectModLocks    => $XkbKeyMask  # mask
     $modLock           => $XkbKeyMask  # mask
     $lockGroup         => $Bool
     $groupLock         => $XkbGroup
     $affectModLatches  => $XkbKeyMask  # mask
     $modLatches        => $XkbKeyMask  # mask
     $latchGroup        => $Bool
     $groupLatch        => $bitmask     # 16-bit bit mask

=cut
    $x->{ext_request}{$request_base}[5] =
	[XkbLatchLockState => sub{
            my ($x,@vals) = @_;
            $vals[0] = $x->num(XkbDeviceSpec=>$vals[0]);
            $vals[1] = $x->pack_mask(XkbKeyMask=>$vals[1]);
            $vals[2] = $x->pack_mask(XkbKeyMask=>$vals[2]);
            $vals[3] = $x->num(Bool=>$vals[3]);
            $vals[4] = $x->num(XkbGroup=>$vals[4]);
            $vals[5] = $x->pack_mask(XkbKeyMask=>$vals[5]);
            $vals[6] = $x->pack_mask(XkbKeyMask=>$vals[6]);
            $vals[7] = $x->num(Bool=>$vals[7]);
            return pack('SCCCCCCCxS',@vals);
	}];
=pod

 $X->XkbGetControls($deviceSpec)
 =>
 ($deviceID, $mouseKeysDfltBtn, $numGroups, $groupsWrap,
         $internalMods_mask, $ignoreLockMods_mask,
         $interalMods_realMods, $ignoreLockMods_realMods,
         $internalMods_vmods, $ignoreLockMods_vmods, $repeatDelay,
         $repeatInterval, $slowKeysDelay, $debounceDelay,
         $mouseKeysDelay, $mouseKeysInterval, $mouseKeysTimeToMax,
         $mouseKeysMaxSpeed, $mouseKeysCurve, $accessXOptions,
         $accessXTimeout, $accessXTimeoutOptionsMask,
         $accessXTimeoutOptionValues, $accessXTimeoutMask,
         $accessXTimeoutValues, $enabledControls, $perKeyRepeat)

     $deviceSpec                    => $XkbDeviceSpec
     $internalMods_mask             => $XkbKeyMask  # mask
     $ignoreLockMods_mask           => $XkbKeyMask  # mask
     $internalMods_realMods         => $XkbKeyMask  # mask
     $ignoreLockMods_realMods       => $XkbKeyMask  # mask
     $internalMods_vmods            => $XkbVMod     # mask
     $ignoreLockMods_vmods          => $XkbVMod     # mask
     $accessXOptions                => #XkbAXOption # mask
     $accessXTimeoutOptionsMask     => $XkbAXOption # mask
     $accessXTimeoutOptionsValues   => $XkbAXOption # mask
     $accessXTimeoutMask            => $XkbBoolCtrl # mask
     $accessXTimeoutValues          => $XkbBoolCtrl # mask
     $enabledControls               => $XkbBoolCtrl # mask
=cut
    $x->{ext_request}{$request_base}[6] =
	[XkbGetControls => sub{
            my ($x,$deviceSpec) = @_;
            $deviceSpec = $x->num(XkbDeviceSpec=>$deviceSpec);
            return pack('Sxx',$deviceSpec);
	}, sub{
            return unpack('xCxxxxxxCCCCCCCxSSSSSSSSSSsSSSSxxLLLa[32]',$_[1]);
	}];
=pod

 $X->XkbSetControls($deviceSpec, $affectInternalRealMods,
        $internalRealMods, $affectIgnoreLockRealMods,
        $ignoreLockRealMods, $affectInternalVirtualMods,
        $internalVirtualMods, $affectIgnoreLockVirtualMods,
        $ignoreLockVirtualMods, $mouseKeysDfltBtn, $groupsWrap,
        $accessXOptions, $affectEnabledControls, $enabledControls,
        $changeControls, $repeatDelay, $repeatInterval, $slowKeysDelay,
        $debounceDelay, $mouseKeysDelay, $mouseKeysInterval,
        $mouseKeysTimeToMax, $mouseKeysMaxSpeed, $mouseKeysCurve
        $accessXTimeout, $accessXTimeoutMask, $accessXTimeoutValues,
        $accessXTimeoutOptionsMask, $accessXTimeoutOptionsValues,
        $perKeyRepeat)

    $deviceSpec                     => $XkbDeviceSpec
    $affectInternalRealMods         => $XkbKeyMask  # mask
    $internalRealMods               => $XkbKeyMask  # mask
    $affectIgnoreLockRealMods       => $XkbKeyMask  # mask
    $ignoreLockRealMods             => $XkbKeyMask  # mask
    $affectInternalVirualMods       => $XkbVMod     # mask
    $internalVirualMods             => $XkbVMod     # mask
    $affectIgnoreLockVirtualMods    => $XkbVMod     # mask
    $ignoreLockVirtualMods          => $XkbVMod     # mask
    $accessXOptions                 => $XkbAXOption # mask
    $enabledControls                => $XkbBoolCtrl # mask
    $changeControls                 => $XkbControl  # mask
    $accessXTimeoutMask             => $XkbBoolCtrl # mask
    $accessXTimeoutValues           => $XkbBoolCtrl # mask
    $accessXTimeoutOptionsMask      => $XkbAXOption # mask
    $accessXTimeoutOptionsValues    => $XkbAXOption # mask
=cut
    $x->{ext_request}{$request_base}[7] =
	[XkbSetControls => sub{
            my ($x,@vals) = @_;
            $vals[ 0] = $x->num(XkbDeviceSpec       =>$vals[ 0]);
            $vals[ 1] = $x->pack_mask(XkbKeyMask    =>$vals[ 1]);
            $vals[ 2] = $x->pack_mask(XkbKeyMask    =>$vals[ 2]);
            $vals[ 3] = $x->pack_mask(XkbKeyMask    =>$vals[ 3]);
            $vals[ 4] = $x->pack_mask(XkbKeyMask    =>$vals[ 4]);
            $vals[ 5] = $x->pack_mask(XkbVMod       =>$vals[ 5]);
            $vals[ 6] = $x->pack_mask(XkbVMod       =>$vals[ 6]);
            $vals[ 7] = $x->pack_mask(XkbVMod       =>$vals[ 7]);
            $vals[ 8] = $x->pack_mask(XkbVMod       =>$vals[ 8]);
            $vals[11] = $x->pack_mask(XkbAXOption   =>$vals[11]);
            $vals[12] = $x->pack_mask(XkbBoolCtrl   =>$vals[12]);
            $vals[13] = $x->pack_mask(XkbBoolCtrl   =>$vals[13]);
            $vals[14] = $x->pack_mask(XkbControl    =>$vals[14]);
            $vals[25] = $x->pack_mask(XkbBoolCtrl   =>$vals[25]);
            $vals[26] = $x->pack_mask(XkbBoolCtrl   =>$vals[26]);
            $vals[27] = $x->pack_mask(XkbAXOption   =>$vals[27]);
            $vals[28] = $x->pack_mask(XkbAXOption   =>$vals[28]);
            return pack('SCCCCSSSSCCSxxLLLSSSSSSSSsSLLSSa[32]', @vals);
	}];
=pod

 $X->XkbGetMap($deviceSpec, $full, $partial, $firstType, $nTypes,
         $firstKeySym, $nKeySyms, $firstKeyAction, $nKeyActions,
         $firstKeyBehavior, $nKeyBehaviours, $virtualMods,
         $firstKeyExplicit, $nKeyExplicit, $firstModMapKey,
         $nModMapKeys, $firstVModMapKey, $nVModMapKeys)
 =>
 ($deviceID, $minKeyCode, $maxKeyCode, $present, $firstType, $nTypes,
         $totalTypes, $firstKeySym, $nKeySyms, $firstKeyAction,
         $totalActions, $nKeyActions, $firstKeyBehavior, $nKeyBehaviors,
         $totalKeyBehaviors, $firstKeyExplicit, $nKeyExplicit,
         $totalKeyExplicit, $firstModMapKey, $nModMapKeys,
         $totalModMapKeys, $firstVModMapKey, $nVModMapKeys,
         $totalVModMapKeys, $virtualMods, XkbKeyTypes=>$typesRtrn,
         XkbKeySyms=>$symsRtrn, XkbKeyActions=>[$actsRtrn,...],
         XkbKeyBehaviors=>$behaviorsRtrn, XkbVirtualMods=>$vmodsRtrn,
         XkbExplicitComponents=>$explicitRtrn,
         XkbModifierMap=>$modmapRtrn, XkbVirtualModMap=>$vmodMapRtrn)

     $typesRtrn     => [ $keytype, ... ]
     $keytype       => [ $mods_mask, $mods_mods, $mods_vmods,
                         $numLevels, $hasPreserve, [$map,...],
                         [$preserve,...] ]
     $map           => [ $active, $mods_mask, $level, $mods_mods,
                         $mods_vmods ]
     $preserve      => [ $moddef, ... ]

     $symsRtrn      => [ $keysym, ... ]
     $keysym        => [ [ @ktIndex[0..3] ], $groupInfo, $width,
                         [ $sym, ... ] ]

     $actsRtrn      => [ $act, ... ]

     $behaviorsRtrn => [ $behavior, ... ]
     $behavior      => [ $keycode, $behaviors ]

     $vmodsRtrn     => [ $vmod, ... ]

     $explicitRtrn  => [ $explicit, ... ]
     $explicit      => [ $keycode, $explicits ]

     $modmapRtrn    => [ $modmap, ... ]
     $modmap        => [ $keycode, $mods ]

     $vmodmapRtrn   => [ $vmodmap, ... ]
     $vmodmap       => [ $keycode, $vmods ]
=cut
    $x->{ext_request}{$request_base}[8] =
	[XkbGetMap => sub{
            my ($x,@vals) = @_;
            $vals[0] = $x->num(XkbDeviceSpec=>$vals[0]);
            $vals[1] = $x->pack_mask(XkbMapPart=>$vals[1]);
            $vals[2] = $x->pack_mask(XkbMapPart=>$vals[2]);
            $vals[11] = $x->pack_mask(XkbVMod=>$vals[11]);
            return pack('SSSCCCCCCCCSCCCCCCxx',@vals);
	}, sub{
            my ($x,$data) = @_;
            my $off = 0;
            my @v = unpack('xCxxxxxxxxCCSCCCCSCCSCCCCCCCCCCCCCxS',$data);
            $off += 40;
            my %h = ();
            my %mask = $x->unpack_mask(XkbMapPart=>$v[4]);
            if ($mask{XkbKeyTypes}) {
                my $n = $v[6]; # nKeyTypes
                $h{XkbKeyTypes} = [];
                for (my $i=0;$i<$n;$i++) {
                    my $map = [];
                    my $preserve = [];
                    my @keytype =
                        (unpack('CCSCCCx',substr($data,$off,8)),
                        $map, $preserve);
                    $off += 8;
                    my $m = $keytype[4];
                    for (my $j=0;$j<$m;$j++) {
                        push @$map,
                             [ unpack('CCCCSxx', substr($data,$off,8)) ];
                        $off += 8;
                        $map->[-1][0] = $x->interp(Bool=>$map->[-1][0]);
                    }
                    if ($keytype[5]) {
                        push @$preserve,
                             unpack('L' x $m,
                                     substr($data,$off,$m<<2));
                        $off += $m<<2;
                    }
                    $keytype[5] = $x->interp(Bool=>$keytype[5]);
                    push @{$h{XkbKeyTypes}}, \@keytype;
                }
            }
            if ($mask{XkbKeySyms}) {
                my $n = $v[10]; # nKeySyms
                $h{XkbKeySyms} = [];
                for (my $i=0;$i<$n;$i++) {
                    my @keysym =
                        ([ unpack('CCCC',substr($data,$off,4)) ],
                        unpack('CCS',substr($data,$off+4,4)));
                    $off += 8;
                    if (my $m = $keysym[-1]) {
                        push @keysym,
                             [ unpack('L' x $m, substr($data,$off,$m<<2)) ];
                        $off += $m<<2; 
                    }
                    push @{$h{XkbKeySyms}}, \@keysym;
                }
            }
            if ($mask{XkbKeyActions}) {
                my $n = $v[13]; # nKeyActions
                $h{XkbKeyActions} =
                    [ unpack('C' x $n, substr($data,$off,$n)) ];
                $off += $n + pad($n);
            }
            if ($mask{XkbKeyBehaviors}) {
                my $n = $v[15]; # nKeyBehaviors
                $h{XkbKeyBehaviors} = [];
                for (my $i=0;$i<$n;$i++) {
                    push @{$h{XkbKeyBehaviors}},
                        [ unpack('CSx', substr($data,$off,4)) ];
                    $off += 4;
                }
            }
            if ($mask{XkbVirtualMods}) {
                my $n = 0;
                my $bits = $v[26]; # virtualMods
                while ($bits) {
                    $n += 1 if $bits & 0x1;
                    $bits >>= 1;
                }
                if ($n) {
                    $h{XkbVirtualMods} =
                        [ unpack('C' x $n, substr($data,$off,$n)) ];
                    $off += $n;
                }
            }
            if ($mask{XkbExplicitComponents}) {
                my $n = $v[18]; # nKeyExplicit
                for (my $i=0;$i<$n;$i++) {
                    push @{$h{XkbExplicitComponents}},
                         [ unpack('CC',substr($data,$off,2)) ];
                    $off += 2;
                }
            }
            if ($mask{XkbModifierMap}) {
                my $n = $v[21]; # nModMapKeys
                for (my $i=0;$i<$n;$i++) {
                    push @{$h{XkbModifierMap}},
                         [ unpack('CC',substr($data,$off,2)) ];
                    $off += 2;
                }
            }
            if ($mask{XkbVirtualModMap}) {
                my $n = $v[24]; # nVModMapKeys
                for (my $i=0;$i<$n;$i++) {
                    push @{$h{XkbVirtualModMap}},
                         [ unpack('CxS',substr($data,$off,4)) ];
                    $off += 4;
                }
            }
            return (@v, %h);
	}];
=pod

 $X->XkbSetMap(...)
         too complex (not implemented yet)
=cut
    $x->{ext_request}{$request_base}[9] =
        undef; # XkbSetMap too complex
=pod

 $X->XkbGetCompatMap(...)
         too complex (not implemented yet)
=cut
    $x->{ext_request}{$request_base}[10] =
        undef; # XkbGetCompatMap too complex
=pod

 $X->XkbSetCompatMap(...)
         too complex (not implemented yet)
=cut
    $x->{ext_request}{$request_base}[11] =
        undef; # XkbSetCompatMap too complex
=pod

 $X->GetIndicatorState($deviceSpec)
 => 
 ($deviceID, $state)

     $deviceSpec => $XkbDeviceSpec
=cut
    $x->{ext_request}{$request_base}[12] =
	[XkbGetIndicatorState => sub{
            my ($x,$deviceSpec) = @_;
            $deviceSpec = $x->num(XkbDeviceSpec=>$deviceSpec);
            return pack('Sxx',$deviceSpec);
	}, sub{
            return unpack('xCxxxxxxLxxxxxxxxxxxxxxxxxxxx',$_[1]);
	}];
=pod

 $X->GetIndicatorMap($deviceSpec, $which)
 => 
 ($deviceID, $which, $realIndicators, $maps)

     $deviceSpec => $XkbDeviceSpec

     $maps => [ $map, ... ]
     $map  => [ $flags, $whichGroups, $groups, $whichMods,
                $mods, $realMods, $vmods, $ctrls ]
=cut
    $x->{ext_request}{$request_base}[13] =
	[XkbGetIndicatorMap => sub{
            my ($x,$deviceSpec,$which) = @_;
            $deviceSpec = $x->num(XkbDeviceSpec=>$deviceSpec);
            $which = $x->unpack_mask(XkbIndicator=>$which);
            return pack('SxxL',$deviceSpec,$which);
	}, sub{
            my ($x,$data) = @_;
            my $off = 0;
            my ($deviceID,$which,$realIndicators,$n) =
                unpack('xCxxxxxxLLCxxxxxxxxxxxxxxx',
                        substr($data,$off,32));
            $off += 32;
            my @maps = ();
            for (my $i=0;$i<$n;$i++) {
                push @maps,
                     [ unpack('CCCCCCSL',substr($data,$off,12)) ];
                $off += 12;
            }
            return ($deviceID,$which,$realIndicators,\@maps);
	}];
=pod

 $X->SetIndicatorMap($deviceSpec,$which, $maps)

     $deviceSpec => $XkbDeviceSpec

     $maps => [ $map, ... ]
     $map  => [ $flags, $whichGroups, $groups, $whichMods,
                $mods, $realMods, $vmods, $ctrls ]
=cut
    $x->{ext_request}{$request_base}[14] =
	[XkbSetIndicatorMap => sub{
            my ($x,$deviceSpec,$which,$maps) = @_;
            $deviceSpec = $x->num(XkbDeviceSpec=>$deviceSpec);
            my $data = pack('SxxL', $deviceSpec, $which);
            while(my $map = shift @$maps) {
                $data .= pack('CCCCCCSL',@$map);
            }
            return $data;
	}];
=pod

 $X->GetNamedIndicator($deviceSpec, $ledClass, $ledID, $indicator)
 =>
 ($deviceID, $indicator, $found, $on, $realIndicator, $ndx,
         $map, $supported)

     $deviceSpec => $XkbDeviceSpec

     $map => [ $flags, $whichGroups, $groups, $whichMods,
               $mods, $realMods, $vmods, $ctrls ]

=cut
    $x->{ext_request}{$request_base}[15] =
	[XkbGetNamedIndicator => sub{
            my ($x,$deviceSpec,$ledClass,$ledID,$indicator) = @_;
            $deviceSpec = $x->num(XkbDeviceSpec=>$deviceSpec);
            $ledClass = $x->num(XkbLEDClassSpec=>$ledClass);
            $ledID = $x->num(XkbIDSpec=>$ledID);
            return pack('SSSxxL',$deviceSpec,$ledClass,$ledID,$indicator);
	}, sub{
            my ($x,$data) = @_;
            my @vals = ( unpack('xCxxxxxxLCCCCxxxxxxxxxxxxxxxx',$data),
                       [ unpack('xxxxxxxxxxxxxxxxCCCCCCSLxxxx',$data) ],
                         unpack('xxxxxxxxxxxxxxxxxxxxxxxxxxxxCxxx',$data));
            $vals[2] = $x->interp(Bool=>$vals[2]);
            $vals[3] = $x->interp(Bool=>$vals[3]);
            $vals[4] = $x->interp(Bool=>$vals[4]);
            $vals[7] = $x->interp(Bool=>$vals[7]);
            return @vals;
	}];
=pod

 $X->XkbSetNamedIndicator->($deviceSpec, $ledClass, $ledID,
         $indicator, $setState, $on, $setMap, $createMap, $map)

     $deviceSpec => $XkbDeviceSpec

     $map => [ $flags, $whichGroups, $groups, $whichMods,
               $mods, $realMods, $vmods, $ctrls ]
=cut
    $x->{ext_request}{$request_base}[16] =
	[XkbSetNamedIndicator => sub{
            my ($x,@vals) = @_;
            $vals[0] = $x->num(XkbDeviceSpec=>$vals[0]);
            $vals[1] = $x->num(XkbLEDClassSpec=>$vals[1]);
            $vals[2] = $x->num(XkbIDSpec=>$vals[2]);
            $vals[4] = $x->num(Bool=>$vals[4]);
            $vals[5] = $x->num(Bool=>$vals[5]);
            $vals[6] = $x->num(Bool=>$vals[6]);
            $vals[7] = $x->num(Bool=>$vals[7]);
            my $map = $_[9];
            $map->[0] = $x->pack_mask(XkbIMFlags=>$map->[0]);
            $map->[1] = $x->pack_mask(XkbIMGroupsWhich=>$map->[1]);
            $map->[2] = $x->pack_mask(XkbGroup=>$map->[2]);
            $map->[3] = $x->pack_mask(XkbIMModsWhich=>$map->[3]);
            $map->[4] = $x->pack_mask(XkbKeyMask=>$map->[4]);
            $map->[5] = $x->pack_mask(XkbVMod=>$map->[5]);
            $map->[6] = $x->pack_mask(XkbBoolCtrl=>$map->[6]);
            return pack('SSSxxLCCCCxCCCCCCSL',@vals[0..7],@$map);
	}];
=pod

 $X->XkbGetNames(...)
         too complex (not implemented yet)
=cut
    $x->{ext_request}{$request_base}[17] =
        undef; # XkbGetNames is too complex
=pod

 $X->XkbSetNames(...)
         too complex (not implemented yet)
=cut
    $x->{ext_request}{$request_base}[18] =
        undef; # XkbSetNames is too complex
=pod

 $X->XkbGetGeometry(...)
         too complex (not implemented yet)
=cut
    $x->{ext_request}{$request_base}[19] =
        undef; # XkbGetGeometry is too complex
=pod

 $X->XkbSetGeometry(...)
         too complex (not implemented yet)
=cut
    $x->{ext_request}{$request_base}[20] =
        undef; # XkbSetGeometry is too complex
=pod

 $X->XkbPerClientFlags($deviceSpec, $change, $value, $ctrlsToChange,
         $autoCtrls, $autoCtrlValues)
 =>
 ($deviceID, $supported, $value, $autoCtrls, $autoCtrlValues)

     $deviceSpec     => $XkbDeviceSpec
     $change         => $XkbPerClientFlag    # mask
     $value          => $XkbPerClientFlag    # mask
     $ctrlsToChange  => $XkbBoolCtrl         # mask
     $autoCtrls      => $XkbBoolCtrl         # mask
     $autoCtrlValues => $XkbBoolCtrl         # mask
=cut
    $x->{ext_request}{$request_base}[21] =
	[XkbPerClientFlags => sub{
            my ($x,@vals) = @_;
            $vals[0] = $x->num(XkbDeviceSpec=>$vals[0]);
            $vals[1] = $x->pack_mask(XkbPerClientFlag=>$vals[1]);
            $vals[2] = $x->pack_mask(XkbPerClientFlag=>$vals[2]);
            $vals[3] = $x->pack_mask(XkbBoolCtrl=>$vals[3]);
            $vals[4] = $x->pack_mask(XkbBoolCtrl=>$vals[4]);
            $vals[5] = $x->pack_mask(XkbBoolCtrl=>$vals[5]);
            return pack('SxxLLLLL',@vals);
	}, sub{
            return unpack('xCxxxxxxLLLLxxxxxxxx',$_[1]);
	}];
=pod

 $X->XkbListComponents($deviceSpec, $maxNames, $keymaps, $keycodes,
	 $types, $compatMap, $symbols, $geometry)
 =>
 ($deviceID, $keymaps, $keycodes, $types, $compatMaps, $symbols,
  $geometries, $extra)

     $keymaps	 => [ $kblisting, ... ]
     $keycodes	 => [ $kblisting, ... ]
     $types	 => [ $kblisting, ... ]
     $compatMaps => [ $kblisting, ... ]
     $symbols	 => [ $kblisting, ... ]

     $kblisting => [ $flags, $string ]
=cut
    $x->{ext_request}{$request_base}[22] = [XkbListComponents=>sub{
	    my ($x,$deviceSpec,$maxNames,@vals) = @_;
	    $deviceSpec = $x->num(XkbDeviceSpe=>$deviceSpec);
	    my $data = pack('SSC(a*)C(a*)C(a*)C(a*)C(a*)C(a*)',
		    $deviceSpec,$maxNames, map{(length($_),$_)} @vals);
	    $data .= "\0" x ((-length($data))&3);
	    return $data;
	}, sub {
	    my ($x,$data) = @_;
	    my @vals = unpack('xCxxxxxxSSSSSSSx10',$data);
	    my $off = 32;
	    for (my $i=0;$i<6;$i++) {
		my $cnt = $vals[3+$i];
		my $list = $vals[3+$i] = [];
		for (my $j=0;$j<$cnt;$j++) {
		    my ($flags,$n) = unpack('SS',substr($data,$off,4));
		    $off += 4;
		    my $string = substr($data,$off,$n);
		    $off += $n + (-$n&3);
		    push @$list, [ $flags, $string ];
		}
	    }
	    return @vals;
	}];
=pod

 $X->XkbGetKbdByName(...)
         too complex (not implemented yet)
=cut
    $x->{ext_request}{$request_base}[23] =
        undef; # XkbGetKbdByName too complex
=pod

 $X->XkbGetDeviceInfo(...)
         too complex (not implemented yet)
=cut
    $x->{ext_request}{$request_base}[24] =
        undef; # XkbGetDeviceInfo too complex
=pod

 $X->XkbSetDeviceInfo(...)
         too complex (not implemented yet)
=cut
    $x->{ext_request}{$request_base}[25] =
        undef; # XkbSetDeviceInfo too complex
=pod

 $X->XkbSetDebuggingFlags(...)
         not useful (not implemented)
=cut
    $x->{ext_request}{$request_base}[101] =
        undef; # XkbSetDebuggingFlags too complex

    for my $i (0 .. $#{$x->{ext_request}{$request_base}}) {
	$x->{ext_request_num}{$x->{ext_request}{$request_base}[$i][0]}
	= [$request_base, $i]
	if $x->{ext_request}{$request_base}[$i];
    }

    ($self->{supported},$self->{major},$self->{minor}) =
        $x->req('XkbUseExtension',1,0);
    unless ($self->{supported} eq 'True') {
	warn "XKEYBOARD version is not supported";
        warn "XKEYBOARD supports $self->{major}.$self->{minor}";
    }
    if ($self->{major} != 1) {
	warn "Wrong XKEYBOARD version ($self->{major} != 1)";
	return undef;
    }

    return $self;
}

1;

=head1 BUGS

This modue has not been tested exhaustively and will likely fail when
anything special is attempted.

Many requests are not implemented yet due to their high complexity.  (I
really only needed XkbGetControls and XkbSetControls.)

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>.

=head1 SEE ALSO

L<perl(1)>,
L<X11::Protocol(3pm)>,
I<The X Keyboard Extension: Protocol Specification, Protocol Version
1.0/Document Revision 1.0 (X Consortium Standard)>

=cut

# vim: sw=4 tw=72
