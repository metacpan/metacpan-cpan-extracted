
# The X Rotate and Resolution Extension Protocol
package X11::Protocol::Ext::RANDR;

use X11::Protocol qw(pad padding make_num_hash);
use X11::Protocol::Enhanced;
use Carp;
use strict;
use warnings;
use vars '$VERSION';
$VERSION = 0.01;

=head1 NAME

X11::Protocol::Ext::RANDR -- Perl extension module for the X Resize, Rotate and Reflect Extension

=head1 SYNOPSIS

 use X11::Protocol;
 $x = X11::Protocol->new($ENV{'DISPLAY'});
 $x->init_extension('RANDR') or die;

=head1 DESCRIPTION

This moudle is used by the L<X11::Protocol(3pm)> module to participate
in the resize, rotate and reflect extension to the X protocol, allowing
a client to participate or control these screen changes per L<The X
Resize, Rotate and Reflect Extension>, a copy of which can be obtained
from L<http://www.x.org/releases/X11R7.7/doc/randrproto/randrproto.txt>.

This manual page does not attempt to document the protocol itself, see
the specification for that.  It documents the L</CONSTANTS>,
L</REQUESTS>, L</EVENTS> and L</ERRORS> that are added to the
L<X11::Protocol(3pm)> module.

=cut

sub new
{
    my $self = bless {}, shift;
    my ($x, $request_base, $event_base, $error_base) = @_;

=head1 CONSTANTS

B<X11::Protocol::Ext::RANDR> provides the following symbolic constants:

 Rotation =>
     [ qw(Rotate_0 Rotate_90 Rotate_180 Rotate_270
          Reflect_X Refect_Y) ]

 RRSelectMask =>
     [ qw(ScreenChangeNotifyMask CrtcChangeNotifyMask
          OutputChangeNotifyMask OutputPropertyNotifyMask) ]

 RRConfigStatus =>
     [ qw(Success InvalidConfigTime InvalidTime Failed) ]

 ModeFlag =>
     [ qw(HSyncPositive HSyncNegative VSyncPositive VSyncNegative
          Interlace DoubleScan CSync CSyncPositive CSyncNegative
          HSkewPercent BCast PixelMultiplex
          DoubleClock ClockDividedBy2) ]

 Connection =>
    [ qw(Connected Disconnected UnknownConnection) ]

 SubpixelOrder =>
    [ qw(Unknown HoizontalRGB HorizontalBGR VerticalRGB VerticalBGR
	    None) ]

=cut
    $x->{ext_const}{Rotation} =
	[ qw(Rotate_0 Rotate_90 Rotate_180 Rotate_270 Reflect_X
	     Refect_Y) ];
    $x->{ext_const}{RRSelectMask} =
	 [ qw(ScreenChangeNotifyMask CrtcChangeNotifyMask
	      OutputChangeNotifyMask OutputPropertyNotifyMask) ];
    $x->{ext_const}{RRConfigStatus} =
	 [ qw(Success InvalidConfigTime InvalidTime Failed) ];
    $x->{ext_const}{ModeFlag} =
	 [ qw(HSyncPositive HSyncNegative VSyncPositive VSyncNegative
	      Interlace DoubleScan CSync CSyncPositive CSyncNegative
	      HSkewPercent BCast PixelMultiplex
	      DoubleClock ClockDividedBy2) ];
    $x->{ext_const}{Connection} =
	[ qw(Connected Disconnected UnknownConnection) ];
    $x->{ext_const}{SubpixelOrder} =
	[ qw(Unknown HorizontalRGB HorizontalBGR VerticalRGB VerticalBGR
		None) ];
    $x->{ext_const}{Mode} = [ qw(None) ];

    $x->{ext_const_num}{$_} = {make_num_hash($x->{ext_const}{$_})}
	foreach (qw(Rotation RRSelectMask RRConfigStatus ModeFlag
	            Connection SubpixelOrder Mode));

=head1 ERRORS

B<X11::Protocol::Ext::RANDR> provides the folowing bad resource errors:
C<Output>, C<Crtc>, C<Mode>.

=cut
    {
	my $i = $error_base;
	foreach (qw(Output Crtc Mode)) {
	    $x->{ext_const}{Error}[$i] = $_;
	    $x->{ext_const_num}{Error}{$_} = $i;
	    $x->{ext_error_type}[$i] = 1; # bad resource
	}
    }

=head1 REQUESTS

B<X11::Protocol::Ext::RANDR> provides the following requests:

=cut

=pod

 $X->RRQueryVersion($major, $minor)
 =>
 ($major, $minor)
=cut
    $x->{ext_request}{$request_base}[0] = [RRQueryVersion=>sub{
	    return pack('LL',@_[1..2]);
	},sub{
	    return unpack('xxxxxxxxCC', $_[1]);
	}];
=pod

 $X->RRSetScreenConfig($window, $time, $config_time, size_index,
	 rotation_reflection, refresh_rate)
 =>
 ($status, $time, $config_time, $root, $subpixel_order)
=cut
    $x->{ext_request}{$request_base}[2] = [RRSetScreenConfig=>sub{
	    return pack('LLLSSSxx', @_[1..6]);
	},sub{
	    return unpack('xCxxxxxxLLLSx[10]', $_[1]);
	}];
=pod

 $X->RRSelectInput($window, $enable)

     $enable => $RRSelectMask  # mask
=cut
    $x->{ext_request}{$request_base}[4] = [RRSelectInput=>sub{
	    my ($x,@vals) = @_;
	    $vals[1] = $x->pack_mask(RRSelectMask=>$vals[1]);
	    return pack('LSxx',@vals);
	}];
=pod

 $X->RRGetScreenInfo($window)
 =>
 ($rotations, $root, $time, $config_time, $size_index,
  $rotation_and_reflection, $rate, $screensizes, $rateinfos)

     $screensizes => [ $screensize, ... ]
     $screensize  => [ $width, $height, $width_mm, $height_mm ]

     $rateinfos   => [ $rateinfos, ... ]
     $rateinfo    => [ $rate, ... ]
=cut
    $x->{ext_request}{$request_base}[5] = [RRGetScreenInfo=>sub{
	    return pack('L',$_[1]);
	},sub{
	    my ($x,$data) = @_;
	    my $off = 0;
	    my ($nscreensize,$lrateinfo) =
		unpack('x[20]Sx[6]Sxx', substr($data,$off,32));
	    my @vals =
		unpack('xCxxxxxxLLLxxSSSxxxx', substr($data,$off,32));
	    $off += 32;
	    my $screensizes = [];
	    push @vals, $screensizes;
	    for (my $i=0;$i<$nscreensize;$i++) {
		push @$screensizes,
		     [unpack('SSSS',substr($data,$off,8))];
		$off += 8;
	    }
	    my $rateinfos = [];
	    push @vals, $rateinfos;
	    $lrateinfo <<= 1;
	    while ($lrateinfo > 0) {
		my $num = unpack('S',substr($data,$off,2));
		my $tot = 2+2*$num;
		push @$rateinfos,
		     [unpack('xxS*', substr($data,$off,$tot))];
		$off += $tot;
		$lrateinfo -= $tot;
	    }
	    return @vals;
	}];
=pod

 $X->RRGetScreenSizeRange($window)
 =>
 ($minWidth, $minHeight, $maxWidth, $maxHeight)
=cut
    $x->{ext_request}{$request_base}[6] = [RRGetScreenSizeRange=>sub{
	    return pack('L',$_[1]);
	},sub{
	    return unpack('x8SSSSx16', $_[1]);
	}];
=pod

 $X->RRSetScreenSize($window, $width, $height, $width_mm, $height_mm)
=cut
    $x->{ext_request}{$request_base}[7] = [RRSetScreenSize=>sub{
	    return pack('LSSLL', @_[1..5]);
	}];
=pod

 $X->RRGetScreenResources($window)
 =>
 ($time, $config_time, $crtcs, $outputs, $modeinfos)

     $crtcs	 => [ $crtc,     ... ]
     $outputs	 => [ $output,   ... ]
     $modeinfos	 => [ $modeinfo, ... ]

     $modeinfo   => [ $id, $width, $heigth, $dot_clock, $h_sync_start,
		     $h_sync_end, $h_total, $h_skew, $v_sync_start,
		     $v_sync_end, $v_total, $mode_flags, $name ]

     $mode_flags => $ModeFlag	# mask
=cut
    $x->{ext_request}{$request_base}[8] = [RRGetScreenResources=>sub{
	    return pack('L',$_[1]);
	},sub{
	    my ($x,$data) = @_;
	    my $off = 0;
	    my @vals = unpack('x8LLSSSx10',$data);
	    $off += 32;
	    my ($c,$o,$m) = (@vals[2..4]);
	    $vals[2] = [unpack('L*',substr($data,$off,$c<<4))];
	    $off += $c<<4;
	    $vals[3] = [unpack('L*',substr($data,$off,$o<<4))];
	    $off += $o<<4;
	    my $modeinfos = $vals[4] = [];
	    for (my $i=0;$i<$m;$i++) {
		my @modeinfo =
		     (unpack('LSSLSSSSSSSSL',substr($data,$off,32)));
		$off += 32;
		@modeinfo = (@modeinfo[0..10],$modeinfo[12],$modeinfo[11]);
		push @$modeinfos, \@modeinfo;
	    }
	    foreach (@$modeinfos) {
		my $len = $_->[-1];
		$_->[-1] = substr($data,$off,$len);
		$off += $len;
	    }
	    return @vals;
	}];
=pod

 $X->RRGetOutputInfo($output, $config_time)
 =>
 ($status, $time, $crtc, $width_mm, $height_mm, $connection,
      $subpixel_order, $preferred_modes, $crtcs, $modes, $clones, $name)
=cut
    $x->{ext_request}{$request_base}[9] = [RRGetOutputInfo=>sub{
	    my ($x,@vals) = @_;
	    $vals[0] = $x->num(Output=>$vals[0]);
	    return pack('LL',@vals);
	},sub{
	    my ($x,$data) = @_;
	    my $off = 0;
	    my ($ncrtcs,$nmodes,$nclones,$lname) =
		unpack('x[26]SSxxSS',substr($data,$off,34));
	    my @vals = unpack('xCxxxxxxLLLLCCxxxxSxxxx',substr($data,$off,36));
	    $vals[0] = $x->interp(RRConfigStatus=>$vals[0]);
	    $vals[5] = $x->interp(Connection=>$vals[5]);
	    $vals[6] = $x->interp(SubpixelOrder=>$vals[6]);
	    $off += 36;
	    push @vals, [unpack('L*',substr($data,$off,$ncrtcs<<2))];
	    $off += $ncrtcs<<2;
	    push @vals, [unpack('L*',substr($data,$off,$nmodes<<2))];
	    $off += $nmodes<<2;
	    push @vals, [unpack('L*',substr($data,$off,$nclones<<2))];
	    $off += $nclones<<2;
	    push @vals, substr($data,$off,$lname);
	    return @vals;
	}];
=pod

 $X->RRListOutputProperties($output)
 =>
 ($atom, ...)
=cut
    $x->{ext_request}{$request_base}[10] = [RRListOutputProperties=>sub{
	    return pack('L',$_[1]);
	},sub{
	    return unpack('L*',substr($_[1],32));
	}];
=pod

 $X->RRQueryOutputProperty($output,$atom)
 =>
 ($pending, $range, $immutable, @values)
=cut
    $x->{ext_request}{$request_base}[11] = [RRQueryOutputProperty=>sub{
	    return pack('LL',@_[1..2]);
	},sub{
	    my ($x,$data) = @_;
	    my @vals = unpack('xxxxxxxxCCCx[21]L*',$data);
	    $vals[0] = $x->interp(Bool=>$vals[0]);
	    $vals[1] = $x->interp(Bool=>$vals[1]);
	    $vals[2] = $x->interp(Bool=>$vals[2]);
	    return @vals;
	}];
=pod

 $X->RRConfigureOutputProperty($output,$atom,$pending,$range,@values)
=cut
    $x->{ext_request}{$request_base}[12] = [RRConfigureOutputProperty=>sub{
	    my ($x,@vals) = @_;
	    $vals[2] = $x->num(Bool=>$vals[2]);
	    $vals[3] = $x->num(Bool=>$vals[3]);
	    return pack('xxxxLLCCxxL*',@vals);
	}];
=pod

 $X->RRChangeOutputProperty($output,$property,$type,$format,$mode,@values)
=cut
    $x->{ext_request}{$request_base}[13] = [RRChangeOutputProperty=>sub{
	    my ($x,$output,$property,$type,$format,$mode,@vals) = @_;
	    $mode = $x->num(ChangePropertyMode=>$mode);
	    my $list = '';
	    $list = 'C*' if $format == 8;
	    $list = 'S*' if $format == 16;
	    $list = 'L*' if $format == 32;
	    my $data = pack('xxxxLLLCCxxL'.$list,
		    $output,$property,$type,$format,$mode,
		    scalar(@vals), @vals);
	    $data .= "\0" x ((-length($data))&3);
	    return $data;
	}];
=pod

 $X->RRDeleteOutputProperty($output, $atom)
=cut
    $x->{ext_request}{$request_base}[14] = [RRDeleteOutputProperty=>sub{
	    return pack('LL',@_[1..2]);
	}];
=pod

 $X->RRGetOutputProperty($output, $property, $type, $offset, $length,
	 $delete, $pending)
 =>
 ($format, $type, $bytes_after, @values
=cut
    $x->{ext_request}{$request_base}[15] = [RRGetOutputProperty=>sub{
	    my ($x,@vars) = @_;
	    $vars[2] = 0 if $vars[2] eq 'AnyPropertyType';
	    $vars[5] = $x->num(Bool=>$vars[5]);
	    $vars[6] = $x->num(Bool=>$vars[6]);
	    return pack('xxxxLLLLLCCxx',@vars);
	},sub{
	    my ($x,$data) = @_;
	    my @vars = unpack('xCx6LLx16', $data);
	    $vars[1] = 'None' unless $vars[1];
	    if ($vars[0] == 8) {
		push @vars, unpack('C*',substr($data,32));
	    }
	    elsif ($vars[0] == 16) {
		push @vars, unpack('S*',substr($data,32));
	    }
	    elsif ($vars[0] == 32) {
		push @vars, unpack('L*',substr($data,32));
	    }
	    return @vars;
	}];
=pod

 $X->RRCreateMode($window, $id, $width, $height, $dot_clock,
	 $h_sync_start, $h_sync_end, $h_total, $h_skew, $v_sync_start,
	 $v_sync_end, $v_total, $flags, $name)
 =>
 ($mode)

=cut
    $x->{ext_request}{$request_base}[16] = [RRCreateMode=>sub{
	    my ($x,@vars) = @_;
	    $vars[12] = $x->pack_hash(ModeFlag=>$vars[12]);
	    return pack('LLSSLSSSSSSSSL',
		    @vars[0..11],length($vars[12])) .
		$vars[12] ."\0" x ((-length($vars[12]))&3);
	},sub{
	    my ($x,$data) = @_;
	    my @vars = unpack('x8Lx20',$data);
	    $vars[0] = 'None' if $x->{interp} and $vars[0] == 0;
	    return (@vars);
	}];
=pod

 $X->RRDestroyMode($mode)
=cut
    $x->{ext_request}{$request_base}[17] = [RRDestroyMode=>sub{
	    my ($x,$mode) = @_;
	    $mode = 0 if $mode eq 'None';
	    return pack('L',$mode);
	}];
=pod

 $X->RRAddOutputMode($output, $mode)
=cut
    $x->{ext_request}{$request_base}[18] = [RRAddOutputMode=>sub{
	    my ($x,$output,$mode) = @_;
	    $mode = 0 if $mode eq 'None';
	    return pack('LL',$output,$mode);
	}];
=pod

 $X->RRDeleteOutputMode($output, $mode)
=cut
    $x->{ext_request}{$request_base}[19] = [RRDeleteOutputMode=>sub{
	    my ($x,$output,$mode) = @_;
	    $mode = 0 if $mode eq 'None';
	    return pack('LL',$output,$mode);
	}];
=pod

 $X->RRGetCrtcInfo($ctrc,$config_time)
 =>
 ($status, $timestamp, $x, $y, $width, $height, $mode, $current_randr,
  $possible_rotations, $outputs, $possible_outputs)

     $outputs           => [ $output, ... ]
     $possible_outputs  => [ $output, ... ]
=cut
    $x->{ext_request}{$request_base}[20] = [RRGetCrtcInfo=>sub{
	    return pack('LL',@_[1..2]);
	},sub{
	    my ($x,$data) = @_;
	    my ($noutputs,$npossible) =
		unpack('x28SS',$data);
	    my @vals = ( unpack('xCxxxxxxLssSSLxxxx',$data),
		[unpack('L*',substr($data,28,$noutputs<<2))],
		[unpack('L*',substr($data,28+($noutputs<<2),$npossible<<2))]);
	    return @vals;
	}];
=pod

 $X->RRSetCrtcConfig($ctrc, $time, $config_time, $x, $y, $mode, $randr,
	 @outputs)
 =>
 ($status, $new_time)
=cut
    $x->{ext_request}{$request_base}[21] = [RRSetCrtcConfig=>sub{
	    my ($x,@vals) = @_;
	    $vals[5] = 0 if $vals[5] eq 'None';
	    $vals[6] = $x->num(Rotation=>$vals[6]);
	    return pack('xxxxLLLSSLSxxL*',@vals);
	},sub{
	    my ($x,$data) = @_;
	    my @vals = unpack('xCxxxxxxLx20',$data);
	    $vals[0] = $x->interp(RRConfigStatus=>$vals[0]);
	    return @vals;
	}];
=pod

 $X->RRGetCrtcGammaSize($crtc)
 =>
 ($size)
=cut
    $x->{ext_request}{$request_base}[22] = [RRGetCrtcGammaSize=>sub{
	    return pack('L',$_[1]);
	},sub{
	    return unpack('x8Sx22',$_[1]);
	}];
=pod

 $X->RRGetCrtcGamma($crtc)
 =>
 ($crtc, $reds, $greens, $blues)
=cut
    $x->{ext_request}{$request_base}[23] = [RRGetCrtcGamma=>sub{
	    return pack('L',$_[1]);
	},sub{
	    my $off = 0;
	    my @vals = unpack('x4LSxx',substr($_[1],$off,12));
	    $off += 12;
	    my $n = $vals[1];
	    push @vals, unpack("S$n",substr($_[1],$off,$n<<1));
	    $off += $n<<1;
	    push @vals, unpack("S$n",substr($_[1],$off,$n<<1));
	    $off += $n<<1;
	    push @vals, unpack("S$n",substr($_[1],$off,$n<<1));
	    return @vals;
	}];
=pod

 $X->RRSetCrtcGamma($crtc,@reds,@greens,@blues)
=cut
    $x->{ext_request}{$request_base}[24] = [RRSetCrtcGamma=>sub{
	    my ($x,$crtc,@rgbs) = @_;
	    my $n = @rgbs/3;
	    my $data = pack('xxxxLSxxS*',$crtc,$n,@rgbs);
	    $data .= "\0" x ((-length($data))&3);
	    return $data;
	}];

=pod

 $X->RRGetScreenResourcesCurrent($window)
 =>
 ($time, $config_time, $crtcs, $outputs, $modeinfos)
     
     $crtcs      => [ $crtc,     ... ]
     $outputs    => [ $output,   ... ]
     $modeinfos  => [ $modeinfo, ... ]

     $modeinfo   => [ $id, $width, $height, $dot_clock, $h_sync_start,
		      $h_sync_end, $h_total, $h_skew, $v_sync_start,
		      $v_sync_end, $v_total, $mod_flags, $name ]
     $mode_flags => $ModeFlag  # mask
=cut
    $x->{ext_request}{$request_base}[25] = [RRGetScreenResourcesCurrent=>sub{
	    return pack('L',$_[1]);
	},sub{
	    my ($x,$data) = @_;
	    my $off = 0;
	    my @vals = unpack('x8LLSSSx10',$data);
	    $off += 32;
	    my ($c,$o,$m) = (@vals[2..4]);
	    $vals[2] = [unpack('L*',substr($data,$off,$c<<4))];
	    $off += $c<<4;
	    $vals[3] = [unpack('L*',substr($data,$off,$o<<4))];
	    $off += $o<<4;
	    my $modeinfos = $vals[4] = [];
	    for (my $i=0;$i<$m;$i++) {
		my @modeinfo =
		     [unpack('LSSLSSSSSSSSL',substr($data,$off,32))];
		$off += 32;
		@modeinfo = (@modeinfo[0..10],$modeinfo[12],$modeinfo[11]);
		push @$modeinfos, \@modeinfo;
	    }
	    foreach (@$modeinfos) {
		my $len = $_->[-1];
		$_->[-1] = substr($data,$off,$len);
		$off += $len;
	    }
	    return @vals;
	}];
=pod

 $X->RRSetCrtcTransform($ctrc,$transform,$filter,@params)
=cut
    $x->{ext_request}{$request_base}[26] = [RRSetCrtcTransform=>sub{
	    my ($x,$crtc,$transform,$filter,@params) = @_;
	    my $len = length($filter);
	    my $pad = pad($len);
	    return pack("L(a36)Sxx(a*)x${pad}L*",
		    $crtc,$transform,$len,$filter,@params);
	}];

=pod

 $X->RRGetCrtcTransform($crtc)
 =>
 ($pending, $has_transforms, $current, $pending_filter, $current_filter)

     $pending_filter => [ $filter, @params ]
     $current_filter => [ $filter, @params ]
=cut
    $x->{ext_request}{$request_base}[27] = [RRGetCrtcTransform=>sub{
	    return pack('L',$_[1]);
	},sub{
	    my ($x,$data) = @_;
	    my ($pn,$pf,$cn,$cf) = unpack('x88SSSS',$data);
	    my $pnp = padding($pn);
	    my $cnp = padding($cn);
	    my @vals = unpack('x8(a36)Cxxx(a36)x4',$data);
	    $vals[1] = $x->interp(Bool=>$vals[1]);
	    my $off = 96;
	    push @vals,
	    [unpack("(a${pn})x${pnp}L*",substr($data,$off,$pn+$pnp+($pf<<2)))];
	    $off += $pn+$pnp+($pf<<2);
	    push @vals,
	    [unpack("(a${cn})x${cnp}L*",substr($data,$off,$cn+$cnp+($cf<<2)))];
	    return @vals;
	}];

=pod

 $X->RRGetPanning($crtc)
 =>
 ($status, $time, $left, $top, $width, $height, $track_left, $track_top,
  $track_width, $track_height, $border_left, $border_top, $border_right,
  $border_bottom)
=cut
    $x->{ext_request}{$request_base}[28] = [RRGetPanning=>sub{
	    return pack('L',$_[1]);
	},sub{
	    my @vals = unpack('xCxxxxxxLSSSSSSSSssss',$_[1]);
	    $vals[0] = $x->interp(RRConfigStatus=>$vals[0]);
	    return @vals;
	}];

=pod

 $X->RRSetPanning($crtc, $time, $left, $top, $width, $height,
	 $track_left, $track_top, $track_width, $track_height,
	 $border_left, $border_top, $border_right, $border_bottom)
 =>
 ($status, $new_time)
=cut
    $x->{ext_request}{$request_base}[29] = [RRSetPanning=>sub{
	    return pack('LLSSSSSSSSssss',@_[1..14]);
	},sub{
	    my @vals = unpack('xCxxxxxxLx20',$_[1]);
	    $vals[0] = $x->interp(RRConfigStatus=>$vals[0]);
	    return @vals;
	}];

=pod

 $X->RRSetOutputPrimary($window, $output)
=cut
    $x->{ext_request}{$request_base}[30] = [RRSetOutputPrimary=>sub{
	    return pack('LL',@_[1..2]);
	}];

=pod

 $X->RRGetOutputPrimary($window)
 =>
 ($length, $output, @pads)
=cut
    $x->{ext_request}{$request_base}[31] = [RRGetOutputPrimary=>sub{
	    return pack('L',$_[1]);
	},sub{
	    return unpack('xxxxL6',$_[1]);
	}];

=head1 EVENTS

B<X11::Protocol::Ext::RANDR> provides the following events:

The following events were added in Version 1.0 of the specification.
This event uses a single event number.

 RRScreenChangeNotify => {
     name=>'RRScreenChangeNotify',
     new_rotation_and_reflection=>$rotation, # Rotation
     timestamp=>$timestamp,
     configuration_timestamp=>$timestamp,
     root_window=>$window,
     request_window=>$window,
     size_id=>$sizeid, # SizeID
     subpixel_order_defined_in_render=>$subpixelorder,
     width_in_pixels=>$width,
     height_in_pixels=>$height,
     width_in_millimeters=>$width_mm,
     height_in_millimeters=>$height_mm}

=cut
    $x->{ext_const}{Events}[$event_base+0] = 'RRScreenChangeNotify';
    $x->{ext_events}[$event_base+0] = ['xCxxLLLLSSSSSS',
	[timestamp=>['CurrentTime']],
	[configuration_timestamp=>['CurrentTime']], qw(root_window
	request_window), [size_id=>'SizeID'],
	qw(subpixel_order_defined_in_render width_in_pixels
	height_in_pixels width_in_millimeters heigth_in_millimeters)];
=pod

The following events were added in Version 1.2 of the specification.
Unfortunately they chose to multiplex the events under only one
additional event number.  Therefore, the format of these events depend
on the value of the C<sub_code> field which is of type
C<RR1dot2EventType>.

=cut
    my $RR1dot2EventTypePack = [];
=pod

 RRCrtcChangeNotify => {
     name=>'RR1dot2EventNotify',
     sub_code=>$RR1dot2EventType, # 0 or 'RRCrtcChangeNotify'
     timestamp=>$timestamp,
     request_window=>$window,
     crtc_affected=>$crtc,
     mode_in_use=>$mode,  # Mode
     new_rotation_and_reflection=>$rotation, # Rotation
     x=>$x,
     y=>$y,
     width=>$width,
     height=>$height}

=cut
    $RR1dot2EventTypePack->[0] =
	[ RRCrtcChangeNotify => sub{
	    my ($x,$data,%ret) = @_;
	    my @vals = unpack('xCxxLLLLSxxSSSS', $data);
	    foreach (qw(sub_code timestamp request_window ctrc_affected
			mode_in_use new_rotation_and_reflection x y
			width height)) {
		$ret{$_} = shift @vals;
	    }
	    $ret{sub_code} = $x->interp(RR1dot2EventType=>$ret{sub_code});
	    return (%ret);
	}, sub{
	    my ($x,%h) = @_;
	    my $do_seq = 1;
	    $h{sub_code} = $x->num(RR1dot2EventType=>$h{sub_code});
	    my @vals = ();
	    foreach (qw(sub_code timestamp request_window ctrc_affected
			mode_in_use new_rotation_and_reflection x y
			width height)) {
		push @vals, $h{$_};
	    }
	    my $data = pack('xCxxLLLLSxxSSSS', @vals);
	    return ($data, $do_seq);
	}];
=pod

 RROutputChangeNotify => {
     name=>'RR1dot2EventNotify',
     sub_code=>$RR1dot2EventType, # 1 or 'RROutputChangeNotify
     timestamp=>$time,
     configuration_timestamp=>$config_time,
     request_window=>$window,
     output_affected=>$output,
     crtc_in_use=>$crtc,
     mode_in_use=>$mode,
     rotation_in_use=>$rotation, # Rotation
     connection_status=>$status, # Connection
     subpixel_order=>$subpixel_order}

=cut
    $RR1dot2EventTypePack->[1] =
	[ RROutputChangeNotify => sub{
	    my ($x,$data,%ret) = @_;
	    my @vals = unpack('xCxxLLLLLLSCC', $data);
	    foreach (qw(sub_code timestamp configuration_timestamp
			request_window output_affected crtc_in_use
			mode_in_use rotation_in_use connection_status
			subpixel_order)) {
		$ret{$_} = shift @vals;
	    }
	    $ret{sub_code} = $x->interp(RR1dot2EventType=>$ret{sub_code});
	    return (%ret);
	}, sub{
	    my ($x,%h) = @_;
	    my $do_seq = 1;
	    $h{sub_code} = $x->num(RR1dot2EventType=>$h{sub_code});
	    my @vals = ();
	    foreach (qw(sub_code timestamp configuration_timestamp
			request_window output_affected crtc_in_use
			mode_in_use rotation_in_use connection_status
			subpixel_order)) {
		push @vals, $h{$_};
	    }
	    my $data = pack('xCxxLLLLLLSCC', @vals);
	    return ($data, $do_seq);
	}];
=pod

 RROutputPropertyNotify => {
     name=>'RR1dot2EventNotify',
     sub_code=>$RR1dot2EventType, # 2 or 'RROutputPropertyNotify
     window=>$window,
     output=>$output,
     atom=>$atom,
     timestamp=>$time}

=cut
    $RR1dot2EventTypePack->[2] =
	[ RROutputPropertyNotify => sub{
	    my ($x,$data,%ret) = @_;
	    my @vals = unpack('xCxxLLLLCx[11]', $data);
	    foreach (qw(sub_code window output atom time state)) {
		$ret{$_} = shift @vals;
	    }
	    $ret{sub_code} = $x->interp(RR1dot2EventType=>$ret{sub_code});
	    return (%ret);
	}, sub{
	    my ($x,%h) = @_;
	    my $do_seq = 1;
	    $h{sub_code} = $x->num(RR1dot2EventType=>$h{sub_code});
	    my @vals = ();
	    foreach (qw(sub_code window output atom time state)) {
		push @vals, $h{$_};
	    }
	    my $data = pack('xCxxLLLLCx[11]', @vals);
	    return ($data, $do_seq);
	}];


    $x->{ext_const}{Events}[$event_base+1] = 'RR1dot2EventNotify';
    $x->{ext_events}[$event_base+1] = [sub{
	my ($x,%ret);
    }, sub{
    }];
    $x->{ext_const}{Events}[$event_base+1] = q(RRCrtcChangeNotify);
    $x->{ext_events}[$event_base+1] = ['xxxxLLLLSxxSSSS',
	[timestamp => ['CurrentTime']], 'request_window',
	'crtc_affected', [mode => ['None']],
	[new_rotation_and_reflection => 'Rotation'],
	'x', 'y', 'width', 'height'];
    $x->{ext_const}{Events}[$event_base+1] = q(RROutputChangeNotify);
    $x->{ext_events}[$event_base+1] = ['xxxxLLLLLLSCC',
	[timestamp=>['CurrentTime']],
	[configuration_timestamp=>['CurrentTime']],
	[request_window=>['None']],
	'output_affected', 'crtc_in_use', [mode => ['None']],
	[rotation_in_use=>'Rotation'],
	[connection_status=>'Connection'], 'subpixel_order'];


    $x->{ext_const}{Events}[$event_base+1] = q(RROutputPropertyNotify);
}

1;

__END__

=head1 BUGS

Probably lots: this module has not been thoroughly tested.  At least it
loads and initializes on server supporting the correct version.

=head1 AUTHOR

Brian Bidulock <bidulock@openss7.org>

=head1 SEE ALSO

L<perl(1)>,
L<X11::Protocol(3pm)>,
L<X Synchronization Extension Protocol|http://www.x.org/releases/X11R7.7/doc/xextproto/sync.pdf>.

=cut

# vim: sw=4 tw=72
