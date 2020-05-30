#!/usr/bin/perl -w
#
#  VBI proxy test client
#
#  Copyright (C) 2003,2004,2006,2007,2020 Tom Zoerner
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License version 2 as
#  published by the Free Software Foundation.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#
#  Description:
#
#   Example for the use of class Video::ZVBI::proxy. The script can
#   capture either from a proxy daemon or a local device. Continuously
#   shows summary of captured data on the terminal. Also allows changing
#   services and channels during capturing (e.g.  by entering "+ttx" or
#   "-ttx" via terminal at STDIN.) Run the script with option -help for a
#   list of supported command line options.
#
#   (This is a direct translation of test/proxy-test.c in libzvbi.)
#

use blib;
use strict;
use Socket;
use POSIX;
use Fcntl;
use Video::ZVBI qw(/^VBI_/);

# constants from linux/videodev2.h
use constant VIDIOC_ENUMINPUT => 0xC050561A;
use constant VIDIOC_G_INPUT => 0x80045626;
use constant VIDIOC_S_INPUT => 0xC0045627;
use constant VIDIOC_G_FREQUENCY => 0xC02C5638;
use constant VIDIOC_S_FREQUENCY => 0x402C5639;

my $opt_device = "/dev/vbi0";
my $opt_buf_count = 5;
my $opt_api = "proxy";
my $opt_scanning = 0;
my $opt_services = 0;
my $opt_strict = 0;
my $opt_debug_level = 0;
my $opt_vinput = -1;
my $opt_freq = -1;
my $opt_chnprio = VBI_CHN_PRIO_INTERACTIVE;
my $opt_subprio = 0;

my $all_services_625 =   ( VBI_SLICED_TELETEXT_B |
                           VBI_SLICED_VPS |
                           VBI_SLICED_CAPTION_625 |
                           VBI_SLICED_WSS_625 |
                           VBI_SLICED_VBI_625 );
my $all_services_525 =   ( VBI_SLICED_CAPTION_525 |
                           VBI_SLICED_2xCAPTION_525 |
                           VBI_SLICED_TELETEXT_BD_525 |
                           VBI_SLICED_VBI_525 );

my $update_services = 0;
my $proxy; # for callback

# ---------------------------------------------------------------------------
# Switch channel and frequency (Video 4 Linux #2 API)
#
sub SwitchTvChannel {
   my ($proxy, $input_idx, $freq) = @_;
   my $result = 1;

   if ($input_idx != -1) {
      $result = 0;

      # get current config of the selected chanel
      my $vinp = pack("i", 0);
      if ($proxy->device_ioctl(VIDIOC_G_INPUT, $vinp) == 0) {
         my $prev_inp_idx = unpack("i", $vinp);

         # insert requested channel and norm into the struct
         $vinp = pack("i", $input_idx);

         # send channel change request
         if ($proxy->device_ioctl(VIDIOC_S_INPUT, $vinp) == 0) {
            print STDERR "Successfully switched video input from $prev_inp_idx to $input_idx\n";
            $result = 1;
         } else {
            print STDERR "ioctl VIDIOC_S_INPUT: $!\n";
         }
      } else {
         print STDERR "ioctl VIDIOC_G_INPUT: $!\n";
      }
   }

   if ($freq != -1) {
      $result = 0;

      # query current tuner parameters (including frequency)
      my $vfreq = pack("LLLx32", 0, 0, 0);
      if ($proxy->device_ioctl(VIDIOC_G_FREQUENCY, $vfreq) == 0) {
         my ($vtuner, $vtype, $prev_freq) = unpack("LLLx32", $vfreq);

         # send frequency change request
         my $vfreq = pack("LLLx32", $vtuner, $vtype, $freq);
         if ($proxy->device_ioctl(VIDIOC_S_FREQUENCY, $vfreq) == 0)
         {
            print STDERR "Successfully switched frequency: from $prev_freq to $freq ".
                         "(tuner:$vtuner type:$vtype)\n";
            $result = 1;
         } else {
            print STDERR "ioctl VIDIOC_S_FREQUENCY: $!\n";
         }
      } else {
         print STDERR "ioctl VIDIOC_G_FREQUENCY: $!\n";
      }
   }
   return $result;
}

# ----------------------------------------------------------------------------
# Callback for proxy events
#
sub ProxyEventCallback {
   my ($ev_mask) = @_;
   my $flags;
   #my $proxy; # XS doesn't pass data through

   if (defined($proxy)) {
      if ($ev_mask & VBI_PROXY_EV_CHN_RECLAIMED) {
         print STDERR "ProxyEventCallback: token was reclaimed\n";

         $proxy->channel_notify(VBI_PROXY_CHN_TOKEN, 0);

      } elsif ($ev_mask & VBI_PROXY_EV_CHN_GRANTED) {
         print STDERR "ProxyEventCallback: token granted\n";

         if (($opt_vinput != -1) || ($opt_freq != -1)) {
            if (SwitchTvChannel($proxy, $opt_vinput, $opt_freq)) {
               $flags = VBI_PROXY_CHN_TOKEN |
                        VBI_PROXY_CHN_FLUSH;
            } else {
               $flags = VBI_PROXY_CHN_RELEASE |
                        VBI_PROXY_CHN_FAIL |
                        VBI_PROXY_CHN_FLUSH;
            }

            if ($opt_scanning != 0) {
               $flags |= VBI_PROXY_CHN_NORM;
            }
         }
         else {
            $flags = VBI_PROXY_CHN_RELEASE;
         }

         $proxy->channel_notify($flags, $opt_scanning);
      }
      if ($ev_mask & VBI_PROXY_EV_CHN_CHANGED) {
         my $lfreq = 0;
         my $vfreq = pack("LLLx32", 0, 0, 0);
         if ($proxy->device_ioctl(VIDIOC_G_FREQUENCY, $vfreq) == 0) {
            $lfreq = (unpack("LLLx32", $vfreq))[2];
         }
         print STDERR "ProxyEventCallback: TV channel changed: $lfreq\n";
      }
      if ($ev_mask & VBI_PROXY_EV_NORM_CHANGED) {
         print STDERR "ProxyEventCallback: TV norm changed\n";
         $update_services = 1;
      }
   }
}

# ---------------------------------------------------------------------------
# Decode a teletext data line
#
sub PrintTeletextData {
   my ($data, $line, $id) = @_;
   my ($tmp1, $tmp2, $tmp3);

   my $mag    =    0xF;
   my $pkgno  =   0xFF;
   $tmp1 = Video::ZVBI::unham16p($data);
   if ($tmp1 >= 0) {
      $pkgno = ($tmp1 >> 3) & 0x1f;
      $mag   = $tmp1 & 7;
      $mag = 8 if ($mag == 0);
   }

   if ($pkgno != 0) {
      Video::ZVBI::unpar_str($data);
      $data =~ s#[\x00-\x1F]# #g;
      printf("line %3d id=%d pkg %X.%03X: '%s'\n", $line, $id, $mag, $pkgno, substr($data, 2, 40));
   } else {
      # it's a page header: decode page number and sub-page code
      $tmp1 = Video::ZVBI::unham16p($data, 2);
      $tmp2 = Video::ZVBI::unham16p($data, 4);
      $tmp3 = Video::ZVBI::unham16p($data, 6);
      my $pageNo = $tmp1 | ($mag << 8);
      my $sub    = ($tmp2 | ($tmp3 << 8)) & 0x3f7f;

      Video::ZVBI::unpar_str($data);
      $data =~ s#[\x00-\x1F]# #g;
      printf("line %3d id=%d page %03X.%04X: '%s'\n", $line, $id, $pageNo, $sub, substr($data, 2+8, 40-8));
   }
}

# ---------------------------------------------------------------------------
# Decode a VPS data line
# - bit fields are defined in "VPS Richtlinie 8R2" from August 1995
# - called by the VBI decoder for every received VPS line
#
sub PrintVpsData {
   my ($indata) = @_;
   my ($mday, $month, $hour, $minute);
   my (@data);
   my ($cni);

   my $VPSOFF = -3;

   foreach (split(//, $indata)) {
      push @data, ord($_);
   }

   #$cni = (($data[$VPSOFF+13] & 0x3) << 10) | (($data[$VPSOFF+14] & 0xc0) << 2) |
   #       (($data[$VPSOFF+11] & 0xc0)) | ($data[$VPSOFF+14] & 0x3f);
   #if ($cni == 0xDC3) {
   #   # special case: "ARD/ZDF Gemeinsames Vormittagsprogramm"
   #   $cni = ($data[$VPSOFF+5] & 0x20) ? 0xDC1 : 0xDC2;
   #}
   $cni = Video::ZVBI::decode_vps_cni($indata);

   if (($cni != 0) && ($cni != 0xfff)) {

      # decode VPS PIL
      $mday   =  ($data[$VPSOFF+11] & 0x3e) >> 1;
      $month  = (($data[$VPSOFF+12] & 0xe0) >> 5) | (($data[$VPSOFF+11] & 1) << 3);
      $hour   =  ($data[$VPSOFF+12] & 0x1f);
      $minute =  ($data[$VPSOFF+13] >> 2);

      printf("VPS %d.%d. %02d:%02d CNI 0x%04X\n", $mday, $month, $hour, $minute, $cni);
   }
}

# ---------------------------------------------------------------------------
# Check stdin for services change requests
# - syntax: ["+"|"-"|"="]keyword, e.g. "+vps-ttx" or "=wss"
#
sub read_service_string {
   my $buf;
   my $ret;

   my $services = $opt_services;

   my $rd = '';
   vec($rd, 0, 1) = 1;
   $ret = select($rd, undef, undef, 0);
   if ($ret == 1)
   {
      $ret = sysread(STDIN, $buf, 100);
      if ($ret > 0) {
         while ($buf =~ / *([\=\+\-]) *(\S+)/g) {
            my $tmp_services;
            my $substract = 0;
            if ($1 eq "=") {
               $services = 0;
            } elsif ($1 eq "-") {
               $substract = 1;
            } elsif ($1 eq "+") {
            }

            if ( ($2 eq "ttx") || ($2 eq "teletext") ) {
               $tmp_services = VBI_SLICED_TELETEXT_B | VBI_SLICED_TELETEXT_BD_525;
            } elsif ($2 eq "vps") {
               $tmp_services = VBI_SLICED_VPS;
            } elsif ($2 eq "wss") {
               $tmp_services = VBI_SLICED_WSS_625 | VBI_SLICED_WSS_CPR1204;
            } elsif ( ($2 eq "cc") || ($2 eq "caption") ) {
               $tmp_services = VBI_SLICED_CAPTION_625 | VBI_SLICED_CAPTION_525;
            } elsif ($2 eq "raw") {
               $tmp_services = VBI_SLICED_VBI_625 | VBI_SLICED_VBI_525;
            } else {
               $tmp_services = 0;
            }

            if ($substract == 0) {
               $services |= $tmp_services;
            } else {
               $services &= ~ $tmp_services;
            }
         }
      } elsif (($ret < 0) && ($! != EINTR) && ($! != EAGAIN)) {
         print STDERR "read_service_string: read: $!\n";
      }
   } elsif (($ret < 0) && ($! != EINTR) && ($! != EAGAIN)) {
      print STDERR "read_service_string: select: $!\n";
   }
   return $services;
}

# ---------------------------------------------------------------------------
# Print usage and exit
#
my $usage =
                   "Usage: $0 [ Options ] service ...\n".
                   "Supported services         : ttx | vps | wss | cc | raw | null\n".
                   "Supported options:\n".
                   "       -dev <path>         : device path\n".
                   "       -api <type>         : v4l API: proxy|v4l2|v4l\n".
                   "       -strict <level>     : service strictness level: 0..2\n".
                   "       -vinput <index>     : switch video input source\n".
                   "       -freq <kHz * 16>    : switch TV tuner frequency\n".
                   "       -chnprio <1..3>     : channel switch priority\n".
                   "       -subprio <0..4>     : background scheduling priority\n".
                   "       -debug <level>      : enable debug output: 1=warnings, 2=all\n".
                   "       -help               : this message\n".
                   "You can also type service requests to stdin at runtime:\n".
                   "Format: [\"+\"|\"-\"|\"=\"]<service>, e.g. \"+vps -ttx\" or \"=wss\"\n";

# ---------------------------------------------------------------------------
# Parse command line options
#
sub parse_argv {
   my $have_service = 0;

   while ($_ = shift @ARGV) {
      if (/^(ttx|teletext)/) {
         $opt_services |= VBI_SLICED_TELETEXT_B | VBI_SLICED_TELETEXT_BD_525;
         $have_service = 1;
      } elsif (/^vps/) {
         $opt_services |= VBI_SLICED_VPS;
         $have_service = 1;
      } elsif (/^wss/) {
         $opt_services |= VBI_SLICED_WSS_625 | VBI_SLICED_WSS_CPR1204;
         $have_service = 1;
      } elsif (/^(cc|caption)/) {
         $opt_services |= VBI_SLICED_CAPTION_625 | VBI_SLICED_CAPTION_525;
         $have_service = 1;
      } elsif (/^raw/) {
         $opt_services |= VBI_SLICED_VBI_625 | VBI_SLICED_VBI_525;
         $have_service = 1;
      } elsif (/^null/) {
         $have_service = 1;
      } elsif (/^-dev/) {
         die "Missing argument for $_\n$usage" unless $#ARGV>=0;
         $opt_device = shift @ARGV;
         die "-dev $opt_device: doesn't exist\n" unless -e $opt_device;
         die "-dev $opt_device: not a character device\n" unless -c $opt_device;
         warn "WARNING: DVB devices are not supported by the proxy\n" if $opt_device =~ /dvb/;
      } elsif (/^-api/) {
         die "Missing argument for $_\n$usage" unless $#ARGV>=0;
         $opt_api = shift @ARGV;
         die "Unknown API $opt_api\n" unless $opt_api =~ /^(proxy|v4l|v4l2)$/;
      } elsif (/^-norm/) {
         die "Missing argument for $_\n$usage" unless $#ARGV>=0;
         my $tmp_norm = shift @ARGV;
         if (($tmp_norm eq "PAL") || ($tmp_norm eq "SECAM")) {
            $opt_scanning = 625;
         } elsif ($tmp_norm eq "NTSC") {
            $opt_scanning = 525;
         } else {
            die "-norm $tmp_norm: unknwon norm\n";
         }
      } elsif (/^-trace/) {
         $opt_debug_level = 1;
      } elsif (/^-debug/) {
         die "Missing argument for $_\n$usage" unless $#ARGV>=0;
         $opt_debug_level = shift @ARGV;
         die "$_ $opt_debug_level: expect numeric argument\n" unless $opt_debug_level =~ /^\d+$/;
      } elsif (/^-strict/) {
         die "Missing argument for $_\n$usage" unless $#ARGV>=0;
         $opt_strict = shift @ARGV;
         die "$_ $opt_strict: expect numeric argument\n" unless $opt_strict =~ /^\d+$/;
      } elsif (/^-vinput/) {
         die "Missing argument for $_\n$usage" unless $#ARGV>=0;
         $opt_vinput = shift @ARGV;
         die "$_ $opt_vinput: expect numeric argument\n" unless $opt_vinput =~ /^\d+$/;
      } elsif (/^-freq/) {
         die "Missing argument for $_\n$usage" unless $#ARGV>=0;
         $opt_freq = shift @ARGV;
         die "$_ $opt_freq: expect numeric argument\n" unless $opt_freq =~ /^\d+$/;
      } elsif (/^-chnprio/) {
         die "Missing argument for $_\n$usage" unless $#ARGV>=0;
         $opt_chnprio = shift @ARGV;
         die "$_ $opt_chnprio: expect numeric argument\n" unless $opt_chnprio =~ /^\d+$/;
      } elsif (/^-subprio/) {
         die "Missing argument for $_\n$usage" unless $#ARGV>=0;
         $opt_subprio = shift @ARGV;
         die "$_ $opt_subprio: expect numeric argument\n" unless $opt_subprio =~ /^\d+$/;
      } elsif (/^-help/) {
         print $usage;
         exit;
      } else {
         die "unknown option or argument\n$usage";
      }
   }

   if ($have_service == 0) {
      die "no service given - Must specify at least one service\n$usage";
   }

   if ($opt_scanning == 625) {
      $opt_services &= $all_services_625;
   } elsif ($opt_scanning == 525) {
      $opt_services &= $all_services_525;
   }
}


# ----------------------------------------------------------------------------
# Main entry point
#
sub main {
   #my $proxy;
   my $cap;
   my $raw;
   my $err;
   my $cur_services;
   my $lineCount;
   my $lastLineCount;

   fcntl(STDIN, F_SETFL, O_NONBLOCK);

   if (($opt_services != 0) && ($opt_scanning == 0)) {
      $cur_services = $opt_services;
   } else {
      $cur_services = undef;
   }

   $proxy = undef;
   $cap = undef;
   if ($opt_api eq "v4l2") {
      $cap = Video::ZVBI::capture::v4l2_new($opt_device, $opt_buf_count, $cur_services, $opt_strict, $err, $opt_debug_level);
   }
   if ($opt_api eq "v4l") {
      $cap = Video::ZVBI::capture::v4l_new($opt_device, 0, $cur_services, $opt_strict, $err, $opt_debug_level);
   }
   if ($opt_api eq "proxy") {
      $proxy = Video::ZVBI::proxy::create($opt_device, "proxy-test", 0, $err, $opt_debug_level);
      if ($proxy) {
         $cap = Video::ZVBI::capture::proxy_new($proxy, $opt_buf_count, 0, $cur_services, $opt_strict, $err);
         $proxy->set_callback(\&ProxyEventCallback);
      } else {
         undef $proxy;
      }
   }

   if (defined($cap)) {
      $lastLineCount = -1;

      # switch to the requested channel
      if ( ($opt_vinput != -1) || ($opt_freq != -1) ||
           ($opt_chnprio != VBI_CHN_PRIO_INTERACTIVE) ) {
         my $chn_profile = {};

         $chn_profile->{is_valid}      = ($opt_vinput != -1) || ($opt_freq != -1);
         $chn_profile->{sub_prio}      = $opt_subprio;
         $chn_profile->{min_duration}  = 10;

         $proxy->channel_request($opt_chnprio, $chn_profile);

         if ($opt_chnprio != VBI_CHN_PRIO_BACKGROUND) {
            SwitchTvChannel($proxy, $opt_vinput, $opt_freq);
         }
      }

      # initialize services for raw capture
      if (($opt_services & (VBI_SLICED_VBI_625 | VBI_SLICED_VBI_525)) != 0) {
         #my $par = $cap->parameters();
         #$raw = Video::ZVBI::rawdec::new($par);
         $raw = Video::ZVBI::rawdec::new($cap);
         $raw->add_services($all_services_525 | $all_services_625, 0);
      }

      $update_services = ($opt_scanning != 0);

      while (1) {
         my $rd = '';
         my $vbi_fd = $cap->fd();
         last if $vbi_fd == -1;

         vec($rd, $vbi_fd, 1) = 1;
         vec($rd, 0, 1) = 1;
         select($rd, undef, undef, undef);

         if (vec($rd, 0, 1) == 1) {
            my $new_services = read_service_string();
            if ($opt_scanning == 625) {
               $new_services &= $all_services_625;
            } elsif ($opt_scanning == 525) {
               $new_services &= $all_services_525;
            }
            if ($new_services != $opt_services) {
               printf STDERR "switching service from 0x%X to 0x%X...\n", $opt_services, $new_services;
               $opt_services = $new_services;
               $update_services = 1;
            }
         }
         if ($update_services) {
            $cur_services = $cap->update_services(1, 1, $opt_services, $opt_strict, $err);
            if (($cur_services != 0) || ($opt_services == 0)) {
               printf STDERR "...got granted services 0x%X.\n", $cur_services;
            } else {
               print STDERR "...failed: $err\n";
            }
            $lastLineCount = 0;
            $update_services = 0;
         }

         if (vec($rd, $vbi_fd, 1) == 1) {
            if (($opt_services & (VBI_SLICED_VBI_625 | VBI_SLICED_VBI_525)) == 0) {
               my $sliced;
               my $line_count;
               my $timestamp;
               my $res = $cap->pull_sliced($sliced, $line_count, $timestamp, 1000);
               if ($res < 0) {
                  print STDERR "VBI read error: $!\n";
                  last;
               } elsif (($res > 0) && (defined($sliced))) {
                  my $ttx_lines = 0;
                  for (my $idx = 0; $idx < $line_count; $idx++) {
                     my @a = Video::ZVBI::get_sliced_line($sliced, $idx);
                     if ($a[1] & VBI_SLICED_TELETEXT_B) {
                        PrintTeletextData($a[0], $a[2], $a[1]);
                        $ttx_lines++;
                     } elsif ($a[1] & VBI_SLICED_VPS) {
                        PrintVpsData($a[0]);
                     } elsif ($a[1] & VBI_SLICED_WSS_625) {
                        my ($w0, $w1, $w2) = unpack("ccc", $a[0]);
                        printf("WSS 0x%02X%02X%02X\n", $w0, $w1, $w2);
                     }
                  }

                  if ($lastLineCount != $ttx_lines + 1) {
                     $lastLineCount = $ttx_lines + 1;
                     print STDERR "$lastLineCount lines\n";
                  }
               } else {
                  print STDERR "proxy-test: timeout in VBI read\n";
               }
            } else {
               my $ts;
               my $raw_buf;
               my $timestamp;
               #my $res = $cap->pull_raw($raw_buf, $timestamp, 1000);
               my $res = $cap->read_raw($raw_buf, $ts, 1000);
               if (($res < 0) && ($! != EAGAIN)) {
                  print STDERR "VBI read error: $!\n";
                  last;
               } elsif (($res > 0) && defined($raw_buf)) {
                  my $sliced;
                  my $line_count;

                  $line_count = $raw->decode($raw_buf, $sliced);

                  if ($lastLineCount != $line_count) {
                     print STDERR "$line_count lines\n";
                     $lastLineCount = $line_count;
                  }

                  for (my $idx = 0; $idx < $line_count; $idx++) {
                     my @a = Video::ZVBI::get_sliced_line($sliced, $idx);
                     if ($a[1] & VBI_SLICED_TELETEXT_B) {
                        PrintTeletextData($a[0], $a[2], $a[1]);
                     } elsif ($a[1] & VBI_SLICED_VPS) {
                        PrintVpsData($a[0]);
                     } elsif ($a[1] & VBI_SLICED_WSS_625) {
                        my ($w0, $w1, $w2) = unpack("ccc", $a[0]);
                        printf("WSS 0x%02X%02X%02X\n", $w0, $w1, $w2);
                     }
                  }

               } elsif ($opt_debug_level > 0) {
                  print STDERR "VBI read timeout\n";
               }
            }
         }
      }

      undef $cap;
   } else {
      if ($err ne "") {
         print STDERR "libzvbi error: $err\n";
      } else {
         printf STDERR "error starting acquisition\n";
      }
   }
   if (defined($proxy)) {
      undef $proxy;
   }
}

parse_argv();
main();
