#!/usr/bin/perl -w
#
#  zvbi-decode -- decode sliced VBI data using low-level
#                  libzvbi functions
#
#  Copyright (C) 2004, 2006 Michael H. Schimek
#  Perl Port: Copyright (C) 2007 Tom Zoerner
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#/

# Perl $Id: decode.pl,v 1.1 2007/11/18 18:48:35 tom Exp tom $
# libzvbi #Id: decode.c,v 1.19 2006/10/06 19:23:15 mschimek Exp #

use blib;
use strict;
use Getopt::Long;
use Switch;
use POSIX;
use IO::Handle;
use Encode;
use Video::ZVBI qw(/^VBI_/);

my $source_is_pes       = 0; # ATSC/DVB

my $option_pfc_pgno     = 0;
my $option_pfc_stream   = 0;

my $option_decode_ttx   = 0;
my $option_decode_8301  = 0;
my $option_decode_8302  = 0;
my $option_decode_caption = 0;
my $option_decode_xds   = 0;
my $option_decode_idl   = 0;
my $option_decode_vps   = 0;
my $option_decode_vps_other = 0;
my $option_decode_wss   = 0;

my $option_dump_network = 0;
my $option_dump_hex     = 0;
my $option_dump_bin     = 0;
my $option_dump_time    = 0;
my $option_all          = 0;

my $option_idl_channel  = 0;
my $option_idl_address  = 0;

# Demultiplexers.

my $pfc;
my $dvb;
my $idl;
my $xds;


# Reader for old test/capture --sliced output.

my $infile;
my $outfile;
my $read_elapsed = 0;

sub read_sliced {
        my $buf;

	#die "stream error: $!\n" if ($infile->ferror ());

	if ($infile->eof () || !($buf = $infile->gets ())) {
		return undef;
        }

	# Time in seconds since last frame.
        die "invalid timestamp in input\n" unless $buf =~ /^(-?\d+|(-?\d*\.\d+))$/;
	my $dt = $buf + 0.0;
	if ($dt < 0.0) {
		$dt = -$dt;
	}

	my $timestamp = $read_elapsed;
	$read_elapsed += $dt;

	my $n_lines = unpack "C", $infile->getc ();
	die "invalid line count in input: $n_lines\n" if ($n_lines < 0);

        my @sliced = ();

	for (my $n = 0; $n < $n_lines; $n++) {

		my $index = unpack "C", $infile->getc ();
		die "invalid index: $index\n" if ($index < 0);

		my $line = (unpack("C", $infile->getc())
			   + 256 * unpack("C", $infile->getc())) & 0xFFF;

		die "IO: $!\n" if ($infile->eof () || $infile->error ());

                my $id;
                my $data;

		switch ($index) {
		case 0 {
			$id = VBI_SLICED_TELETEXT_B;
			$infile->read ($data, 42);
		}
		case 1 {
			$id = VBI_SLICED_CAPTION_625; 
			$infile->read ($data, 2);
		}
		case 2 {
			$id = VBI_SLICED_VPS;
			$infile->read ($data, 13);
		}
		case 3 {
			$id = VBI_SLICED_WSS_625; 
			$infile->read ($data, 2);
		}
		case 4 {
			$id = VBI_SLICED_WSS_CPR1204; 
			$infile->read ($data, 3);
		}
		case 7 {
			$id = VBI_SLICED_CAPTION_525; 
			$infile->read($data, 2);
		}
		else {
			die "\nOops! Unknown data type $index ".
				 "in sliced VBI file\n";
		}
                }

		die "IO: $!\n" if ($infile->error ());

		push @sliced, [$data, $id, $line];
	}

	return ($n_lines, $timestamp, \@sliced);
}

sub _vbi_pfc_block_dump {
        my ($pgno, $stream, $app_id, $block, $binary) = @_;

	printf "PFC pgno=%x stream=%u id=%u size=%u\n",
		 $pgno, $stream,
		 $app_id,
		 length($block);

	if ($binary) {
		#$io->write ($block, length $block);
	} else {
                Video::ZVBI::unpar_str ($block);
                $block =~ s#[\x00-\x1F\x7F]#.#g;
                # missing: insert \n every 75 chars

                print $block;
                print "\n";
	}
}

sub put_cc_char {
        my ($c1, $c2) = @_;

        # All caption characters are representable in UTF-8
        my $c = (($c1 << 8) + $c2) & 0x777F;
        my $ucs2_str = Video::ZVBI::caption_unicode ($c);  # !to_upper

        print $ucs2_str;
}

sub caption_command {
        my ($line, $c1, $c2) = @_;

        printf ("CC line=%3u cmd 0x%02x 0x%02x ", $line, $c1, $c2);

        if (0 == $c1) {
                printf ("null\n");
                return;
        } elsif ($c2 < 0x20) {
                printf ("invalid\n");
                return;
        }

        # Some common bit groups.

        my $ch = ($c1 >> 3) & 1; # channel
        my $a7 = $c1 & 7;
        my $f = $c1 & 1; # field
        my $b7 = ($c2 >> 1) & 7;
        my $u = $c2 & 1; # underline

        if ($c2 >= 0x40) {
                my @row = (
                        10,                # 0     # 0x1040
                        -1,                # 1     # unassigned
                        0, 1, 2, 3,        # 2     # 0x1140 ... 0x1260
                        11, 12, 13, 14,    # 6     # 0x1340 ... 0x1460
                        4, 5, 6, 7, 8, 9   # 10    # 0x1540 ... 0x1760
                );

                # Preamble Address Codes -- 001 crrr  1ri bbbu

                my $rrrr = $a7 * 2 + (($c2 >> 5) & 1);

                if ($c2 & 0x10) {
                        printf "PAC ch=%u row=%u column=%u u=%u\n",
                                $ch, $row[$rrrr], $b7 * 4, $u;
                } else {
                        printf "PAC ch=%u row=%u color=%u u=%u\n",
                                $ch, $row[$rrrr], $b7, $u;
                }
                return;
        }

        # Control codes -- 001 caaa  01x bbbu

        switch ($a7) {
        case 0 {
                if ($c2 < 0x30) {
                        my @mnemo_1 = (
                                "BWO", "BWS", "BGO", "BGS",
                                "BBO", "BBS", "BCO", "BCS",
                                "BRO", "BRS", "BYO", "BYS",
                                "BMO", "BMS", "BAO", "BAS"
                        );

                        printf "%s ch=%u\n", $mnemo_1[$c2 & 0xF], $ch;
                        return;
                }
        }
        case 1 {
                if ($c2 < 0x30) {
                        printf "mid-row ch=%u color=%u u=%u\n", $ch, $b7, $u;
                } else {
                        printf "special character ch=%u 0x%02x%02x='",
                                $ch, $c1, $c2;
                        put_cc_char ($c1, $c2);
                        print "'\n";
                }

                return;
        }
        case [2,3] { # first & second group
                printf "extended character ch=%u 0x%02x%02x='", $ch, $c1, $c2;
                put_cc_char ($c1, $c2);
                print "'\n";
                return;
        }
        case [4,5] { # f=0,1
                if ($c2 < 0x30) {
                        my @mnemo_2 = (
                                "RCL", "BS",  "AOF", "AON",
                                "DER", "RU2", "RU3", "RU4",
                                "FON", "RDC", "TR",  "RTD",
                                "EDM", "CR",  "ENM", "EOC"
                        );

                        printf "%s ch=%u f=%u\n", $mnemo_2[$c2 & 0xF], $ch, $f;
                        return;
                }
        }
        case 6 { # reserved
        }
        case 7 {
                switch ($c2) {
                case [0x21..0x23] {
                        printf "TO%u ch=%u\n", $c2 - 0x20, $ch;
                        return;
                }
                case 0x2D {
                        printf "BT ch=%u\n", $ch;
                        return;
                }
                case 0x2E {
                        printf "FA ch=%u\n", $ch;
                        return;
                }
                case 0x2F {
                        printf "FAU ch=%u\n", $ch;
                        return;
                }
                }
        }
        }

        print "unknown\n";
}

sub xds_cb {
        my ($xds_class, $xds_subclass, $buffer, $user_data) = @_;

        #_vbi_xds_packet_dump (xp, stdout);
        print "XDS packet callback: class:$xds_class,$xds_subclass\n";

        return 1; # no errors
}

sub caption {
        my ($inbuf, $line) = @_;
        my @buffer = unpack "C2", $inbuf;

        if ($option_decode_xds && 284 == $line) {
                if (!$xds->feed ($inbuf)) {
                        print "Parity error in XDS data.\n";
                }
        }

        if ($option_decode_caption
            && (21 == $line || 284 == $line # NTSC
                || 22 == $line)) { # PAL

                my $c1 = Video::ZVBI::unpar8 ($buffer[0]);
                my $c2 = Video::ZVBI::unpar8 ($buffer[1]);

                if (($c1 | $c2) < 0) {
                        printf "Parity error in CC line=%u ".
                                  " %s0x%02x %s0x%02x.\n",
                                $line,
                                ($c1 < 0) ? ">" : "", $buffer[0] & 0xFF,
                                ($c2 < 0) ? ">" : "", $buffer[1] & 0xFF;
                } elsif ($c1 >= 0x20) {
                        my $text;

                        printf "CC line=%3u text 0x%02x 0x%02x '",
                                $line, $c1, $c2;

                        # All caption characters are representable
                        # in UTF-8, but not necessarily in ASCII.
                        $text = pack "C2", $c1, $c2;

                        # Error ignored.
                        my $utf = Video::ZVBI::iconv_caption ($text, ord("?"));
                        # suppress warnings about wide characters
                        #$utf = encode("ISO-8859-1", $utf, Encode::FB_DEFAULT);

                        print $utf . "'\n";

                } elsif (0 == $c1 || $c1 >= 0x10) {
                        caption_command ($line, $c1, $c2);

                } elsif ($option_decode_xds) {
                        printf "CC line=%3u cmd 0x%02x 0x%02x ",
                                $line, $c1, $c2;
                        if (0x0F == $c1) {
                                print "XDS packet end";
                        } else {
                                print "XDS packet start/continue";
                        }
                }
        }
}

#if 3 == VBI_VERSION_MINOR # XXX port me back
#
#static void
#dump_cni                        (vbi_cni_type           type,
#                                 unsigned int           cni)
#{
#        vbi_network nk;
#        vbi_bool success;
#
#        if (!option_dump_network)
#                return;
#
#        success = vbi_network_init (&nk);
#        if (!success)
#                no_mem_exit ();
#
#        success = vbi_network_set_cni (&nk, type, cni);
#        if (!success)
#                no_mem_exit ();
#
#        _vbi_network_dump (&nk, stdout);
#        putchar ('\n');
#
#        vbi_network_destroy (&nk);
#}
#
#endif # 3 == VBI_VERSION_MINOR

sub dump_bytes {
        my ($buffer, $n_bytes) = @_;

        if ($option_dump_bin) {
                $outfile->write($buffer, $n_bytes);
                return;
        }

        if ($option_dump_hex) {
                foreach (unpack "C*", $buffer) {
                        printf "%02x ", $_;
                }
        }

        # For Teletext: Not all characters are representable
        # in ASCII or even UTF-8, but at this stage we don't
        # know the Teletext code page for a proper conversion.
        Video::ZVBI::unpar_str ($buffer);
        $buffer =~ s#[\x00-\x1F\x7F]#.#g;

        print ">". substr($buffer, 0, $n_bytes) ."<\n";
}

#if 3 == VBI_VERSION_MINOR # XXX port me back
#
#static void
#packet_8301                     (const uint8_t          buffer[42],
#                                 unsigned int           designation)
#{
#        unsigned int cni;
#        time_t time;
#        int gmtoff;
#        struct tm tm;
#
#        if (!option_decode_8301)
#                return;
#
#        if (!vbi_decode_teletext_8301_cni (&cni, buffer)) {
#                printf (_("Error in Teletext "
#                          "packet 8/30 format 1 CNI.\n"));
#                return;
#        }
#
#        if (!vbi_decode_teletext_8301_local_time (&time, &gmtoff, buffer)) {
#                printf (_("Error in Teletext "
#                          "packet 8/30 format 1 local time.\n"));
#                return;
#        }
#
#        printf ("Teletext packet 8/30/%u cni=%x time=%u gmtoff=%d ",
#                designation, cni, (unsigned int) time, gmtoff);
#
#        gmtime_r (&time, &tm);
#
#        printf ("(%4u-%02u-%02u %02u:%02u:%02u UTC)\n",
#                tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday,
#                tm.tm_hour, tm.tm_min, tm.tm_sec);
#
#        if (0 != cni)
#                dump_cni (VBI_CNI_TYPE_8301, cni);
#}
#
#static void
#packet_8302                     (const uint8_t          buffer[42],
#                                 unsigned int           designation)
#{
#        unsigned int cni;
#        vbi_program_id pi;
#
#        if (!option_decode_8302)
#                return;
#
#        if (!vbi_decode_teletext_8302_cni (&cni, buffer)) {
#                printf (_("Error in Teletext "
#                          "packet 8/30 format 2 CNI.\n"));
#                return;
#        }
#
#        if (!vbi_decode_teletext_8302_pdc (&pi, buffer)) {
#                printf (_("Error in Teletext "
#                          "packet 8/30 format 2 PDC data.\n"));
#                return;
#        }
#
#        printf ("Teletext packet 8/30/%u cni=%x ", designation, cni);
#
#        _vbi_program_id_dump (&pi, stdout);
#
#        putchar ('\n');
#
#        if (0 != pi.cni)
#                dump_cni (pi.cni_type, pi.cni);
#}
#
#endif # 3 == VBI_VERSION_MINOR

sub page_function_clear_cb {
        my ($pgno, $stream, $app_id, $block, $user_data) = @_;

        _vbi_pfc_block_dump ($pgno, $stream, $app_id, $block, $option_dump_bin);

        return 1;
}

sub idl_format_a_cb {
        my ($buffer, $flags, $user_data) = @_;

        if (!$option_dump_bin) {
                printf "IDL-A%s%s ",
                        ($flags & VBI_IDL_DATA_LOST) ? " <data lost>" : "",
                        ($flags & VBI_IDL_DEPENDENT) ? " <dependent>" : "";
        }

        dump_bytes ($buffer, length $buffer);

        return 1;
}

sub calc_spa {
        my ($spa_length, @ord) = @_;
        my $spa = 0;

        for (my $i = 0; $i < $spa_length; ++$i) {
                my $h = Video::ZVBI::unham8($ord[4 + $i]);
                $spa |= ($h << (4 * $i));
        }
        return $spa;
}

sub packet_idl {
        my ($buffer, $channel) = @_;
        my @ord = unpack "C10", $buffer;

        printf "IDL ch=%u ", $channel;

        switch ($channel) {
        case 0 {
                die "IDL: unexpected channel 0\n";
        }
        case [4, 12] {
                print "(Low bit rate audio) ";

                dump_bytes ($buffer, 42);
        }
        case [5, 6, 13, 14] {
                my $pa;
                $pa = Video::ZVBI::unham8 ($ord[3]);
                $pa |= Video::ZVBI::unham8 ($ord[4]) << 4;
                $pa |= Video::ZVBI::unham8 ($ord[5]) << 8;

                if ($pa < 0) {
                        print "Hamming error in Datavideo packet-address byte.\n";
                        return;
                }

                printf "(Datavideo) pa=0x%x ", $pa;

                dump_bytes ($buffer, 42);

        }
        case [8, 9, 10, 11, 15] {
                my $ft; # format type
                if (($ft = Video::ZVBI::unham8 ($ord[2])) < 0) {
                        printf "Hamming error in IDL format ".
                                  "A or B format-type byte.\n";
                        return;
                }

                if (0 == ($ft & 1)) {
                        my $ial; # interpretation and address length
                        my $spa_length;
                        my $spa; # service packet address

                        if (($ial = Video::ZVBI::unham8 ($ord[3])) < 0) {
                                print "Hamming error in IDL format ".
                                          "A interpretation-and-address-".
                                          "length byte.\n";
                                return;
                        }

                        $spa_length = $ial & 7;
                        if (7 == $spa_length) {
                                print "(Format A?) ";
                                dump_bytes ($buffer, 42);
                                return;
                        }

                        $spa = calc_spa($spa_length, @ord);

                        if ($spa < 0) {
                                print "Hamming error in IDL format".
                                        "A service-packet-address byte.\n";
                                return;
                        }

                        printf "(Format A) spa=0x%x ", $spa;
                } elsif (1 == ($ft & 3)) {
                        my $an; # application number
                        my $ai; # application identifier

                        $an = ($ft >> 2);

                        if (($ai = Video::ZVBI::unham8 ($ord[3])) < 0) {
                                print "Hamming error in IDL format ".
                                          "B application-number byte.\n";
                                return;
                        }

                        printf "(Format B) an=%d ai=%d ", $an, $ai;
                }

                dump_bytes ($buffer, 42);
        }
        else {
                dump_bytes ($buffer, 42);
        }
        }
}

sub teletext {
        my ($buffer, $line) = @_;
        my @ord = unpack "C42", $buffer;

        if (defined $pfc) {
                if (!$pfc->feed ($buffer)) {
                        print "Error in Teletext PFC packet.\n";
                        return;
                }
        }

        if (!($option_decode_ttx |
              $option_decode_8301 |
              $option_decode_8302 |
              $option_decode_idl)) {
                return;
        }

        my $pmag = Video::ZVBI::unham16p ($buffer);
        if ($pmag < 0) {
                print "Hamming error in Teletext packet number.\n";
                return;
        }

        my $magazine = $pmag & 7;
        if (0 == $magazine) {
                $magazine = 8;
        }
        my $packet = $pmag >> 3;

        if (8 == $magazine && 30 == $packet) {
                my $designation = Video::ZVBI::unham8 ($ord[2]);
                if ($designation < 0 ) {
                        print "Hamming error in Teletext packet 8/30 designation byte.\n";
                        return;
                }

                if ($designation >= 0 && $designation <= 1) {
#if 3 == VBI_VERSION_MINOR # XXX port me back
                        #packet_8301 ($buffer, $designation);
#endif
                        return;
                }

                if ($designation >= 2 && $designation <= 3) {
#if 3 == VBI_VERSION_MINOR # XXX port me back
                        #packet_8302 ($buffer, $designation);
#endif
                        return;
                }
        }

        if (30 == $packet || 31 == $packet) {
                if ($option_decode_idl) {
                        packet_idl ($buffer, $pmag & 15);
                        #printf ("Teletext IDL packet %u/%2u ", $magazine, $packet);
                        #dump_bytes ($buffer, 42);
                        return;
                }
        }

        if ($option_decode_ttx) {
                printf "Teletext line=%3u %x/%2u ",
                        $line, $magazine, $packet;
                dump_bytes ($buffer, 42);
                return;
        }
}

my @pr_label = ("", "");
my @label = (" " x 16, " " x 16);
my @label_off = (0, 0);

sub vps {
        my ($inbuf, $line) = @_;
        my @ord = unpack "C15", $inbuf;

        if ($option_decode_vps) {
                my $cni;

                if ($option_dump_bin) {
                        printf "VPS line=%3u ", $line;
                        $outfile->write($inbuf, 13);
                        return;
                }

                $cni = Video::ZVBI::decode_vps_cni ($inbuf);
                if (!defined $cni) {
                        printf "Error in VPS packet CNI.\n";
                        return;
                }

#if 3 == VBI_VERSION_MINOR
#                if (!vbi_decode_vps_pdc (&pi, buffer)) {
#                        printf "Error in VPS packet PDC data.\n";
#                        return;
#                }
#
#                printf "VPS line=%3u ", line;
#
#                _vbi_program_id_dump (&pi, stdout);
#
#                putchar ('\n');
#
#                if (0 != pi.cni)
#                        dump_cni (pi.cni_type, pi.cni);
#else
                printf "VPS line=%3u CNI=%x\n", $line, $cni;
#endif
        }

        if ($option_decode_vps_other) {
                my $l = ($line != 16);

                my $c = Video::ZVBI::rev8 ($ord[1]);

                if ($c & 0x80) {
                        $pr_label[$l] = substr($label[$l], 0, $label_off[$l]);
                        $label_off[$l] = 0;
                }

                my $cp = $c & 0x7F;
                $cp =~ s#[\x00-\x1F\x7F]#.#g;

                substr($label[$l], $label_off[$l], 1) = pack "C", $cp;

                $label_off[$l] = ($label_off[$l] + 1) % 16;

                printf "VPS line=%3u bytes 3-10: ".
                        "%02x %02x (%02x='%c') %02x %02x ".
                        "%02x %02x %02x %02x (\"%s\")\n",
                        $line,
                        $ord[0], $ord[1],
                        $c, $cp,
                        $ord[2], $ord[3],
                        $ord[4], $ord[5], $ord[6], $ord[7],
                        $pr_label[$l];
        }
}

#if 3 == VBI_VERSION_MINOR # XXX port me back
#
#static void
#wss_625                         (const uint8_t          buffer[2])
#{
#        if (option_decode_wss) {
#                vbi_aspect_ratio ar;
#
#                if (!vbi_decode_wss_625 (&ar, buffer)) {
#                        printf (_("Error in WSS packet.\n"));
#                        return;
#                }
#
#                fputs ("WSS ", stdout);
#
#                _vbi_aspect_ratio_dump (&ar, stdout);
#
#                putchar ('\n');
#        }
#}
#
#endif # 3 == VBI_VERSION_MINOR

sub decode_vbi {
        my ($sliced, $n_lines, $sample_time, $stream_time) = @_;
        my $last_sample_time = 0.0;
        my $last_stream_time = 0;

        if ($option_dump_time) {
                # Sample time: When we captured the data, in
                #              seconds since 1970-01-01 (gettimeofday()).
                # Stream time: For ATSC/DVB the Presentation TimeStamp.
                #              For analog the frame number multiplied by
                #              the nominal frame period (1/25 or
                #              1001/30000 s). Both given in 90000 kHz units.
                # Note this isn't fully implemented yet. */
                printf "ST %f (%+f) PTS %lld (%+lld)\n",
                        $sample_time, $sample_time - $last_sample_time,
                        $stream_time, $stream_time - $last_stream_time;

                $last_sample_time = $sample_time;
                $last_stream_time = $stream_time;
        }

        for (my $i = 0; $i < $n_lines; $i++) {
                my ($data, $id, $line) = @{$sliced->[$i]};

                if ( ($id == VBI_SLICED_TELETEXT_B_L10_625) ||
                     ($id == VBI_SLICED_TELETEXT_B_L25_625) ||
                     ($id == VBI_SLICED_TELETEXT_B_625) ) {
                        teletext ($data, $line);

                } elsif ( ($id == VBI_SLICED_VPS) ||
                         ($id == VBI_SLICED_VPS_F2) ) {
                        vps ($data, $line);

                } elsif ( ($id == VBI_SLICED_CAPTION_625_F1) ||
                          ($id == VBI_SLICED_CAPTION_625_F2) ||
                          ($id == VBI_SLICED_CAPTION_625) ||
                          ($id == VBI_SLICED_CAPTION_525_F1) ||
                          ($id == VBI_SLICED_CAPTION_525_F2) ||
                          ($id == VBI_SLICED_CAPTION_525) ) {
                        caption ($data, $line);

                } elsif ($id == VBI_SLICED_WSS_625) {
                        #3 wss_625 ($data);

                } elsif ($id == VBI_SLICED_WSS_CPR1204) {
                }
        }
}

sub dvb_feed_cb {
        my ($sliced_buf, $n_lines, $pts, $user_data) = @_;

        if ($n_lines > 0) {
                # pull all data lines out of the packed slicer buffer
                # since we want to process them by Perl code
                # (something we'd normally like to avoid, as it's slow)
                # (see export.pl for an efficient use case)
                my @sliced = ();
                foreach (0 .. $n_lines-1) {
                        my $x = [Video::ZVBI::get_sliced_line($sliced_buf, $_)];
                        push @sliced, $x;
                }
                decode_vbi (\@sliced, $n_lines,
                        0, # sample_time
                        $pts); # stream_time
        }
        # return TRUE in case we're invoked as callback via feed()
        1;
}

sub pes_mainloop {
        my $buffer;
        my $left;
        my $sliced_buf;  # must be outside of the read() loop!
        my $n_lines;
        my $pts;

        while (read (STDIN, $buffer, 2048)) {
                $left = length $buffer;

                #$n_lines = $dvb->feed ($buffer); #ALT
                #next; #ALT

                while ($left > 0) {
                        $n_lines = $dvb->cor ($sliced_buf, 64, $pts, $buffer, $left);
                        dvb_feed_cb($sliced_buf, $n_lines, $pts);
                }
        }

        print STDERR "\rEnd of stream\n";
}

sub old_mainloop {
        while (1) {
                my ($n_lines, $timestamp, $sliced) = read_sliced();
                last if !defined $n_lines;

                decode_vbi ($sliced, $n_lines, $timestamp, 0);
        }

        print STDERR "\rEnd of stream\n";
}

sub usage {
        print STDERR "\
$0 -- low-level VBI decoder\n\
Copyright (C) 2004, 2006 Michael H. Schimek\
This program is licensed under GPL 2 or later. NO WARRANTIES.\n\
Usage: %s [options] < sliced VBI data\n\
-h | --help | --usage  Print this message and exit\
-V | --version         Print the program version and exit\
Input options:\
-P | --pes             Source is a DVB PES stream [auto-detected]\
Decoding options:\n".
#if 3 == VBI_VERSION_MINOR # XXX port me back
#"-1 | --8301            Teletext packet 8/30 format 1 (local time)\
#-2 | --8302            Teletext packet 8/30 format 2 (PDC)\n"
#endif
"-c | --cc              Closed Caption\
-i | --idl             Any Teletext IDL packets (M/30, M/31)\
-t | --ttx             Decode any Teletext packet\
-v | --vps             Video Programming System (PDC)\n".
#if 3 == VBI_VERSION_MINOR # XXX port me back
#"-w | --wss             Wide Screen Signalling\n"
#endif
"-x | --xds             Decode eXtended Data Service (NTSC line 284)\
-a | --all             Everything above, e.g.\
                       -i     decode IDL packets\
                       -a     decode everything\
                       -a -i  everything except IDL\
-c | --idl-ch N\
-d | --idl-addr NNN\
                       Decode Teletext IDL format A data from channel N,\
                       service packet address NNN [0]\
-r | --vps-other       Decode VPS data unrelated to PDC\
-p | --pfc-pgno NNN\
-s | --pfc-stream NN   Decode Teletext Page Function Clear data\
                         from page NNN (for example 1DF), stream NN [0]\
Modifying options:\
-e | --hex             With -t dump packets in hex and ASCII,\
                         otherwise only ASCII\
-n | --network         With -1, -2, -v decode CNI and print\
                         available information about the network\
-b | --bin             With -t, -p, -v dump data in binary format\
                         instead of ASCII\
-T | --time            Dump capture timestamps\
";
  exit(0);
}

#short_options [] = "12abcd:ehil:np:rs:tvwxPTV";

my %CmdOpts = (
        "8301" =>      \$option_decode_8301,  # '1'
        "8302" =>      \$option_decode_8302,  # '2'
        "all" =>       \$option_all,  # 'a'
        "bin" =>       \$option_dump_bin,  # 'b'
        "cc" =>        \$option_decode_caption,  # 'c'
        "idl-addr=i",  \$option_idl_address,  # 'd'
        "hex" =>       \$option_dump_hex,  # 'e'
        #"help" =>      \$OPT,  # 'h'
        #"usage" =>     \$OPT,  # 'h'
        "idl" =>       \$option_decode_idl,  # 'i'
        "idl-ch=i" =>  \$option_idl_channel,  # 'l'
        "network" =>   \$option_dump_network,  # 'n'
        "pfc-pgno=i",  \$option_pfc_pgno,  # 'p'
        "vps-other" => \$option_decode_vps_other,  # 'r'
        "pfc-stream=i" => \$option_pfc_stream,  # 's'
        "ttx" =>       \$option_decode_ttx,  # 't'
        "vps" =>       \$option_decode_vps,  # 'v'
        "wss" =>       \$option_decode_wss,  # 'w'
        "xds" =>       \$option_decode_xds,  # 'x'
        "pes" =>       \$source_is_pes,  # 'P'
        "time" =>      \$option_dump_time,  # 'T'
);

sub main_func {
        GetOptions(%CmdOpts) || usage();

        if ($option_all) {
                $option_decode_ttx = 1;
                $option_decode_8301 = 1;
                $option_decode_8302 = 1;
                $option_decode_caption = 1;
                $option_decode_idl = 1;
                $option_decode_vps = 1;
                $option_decode_wss = 1;
                $option_decode_xds = 1;
                $option_pfc_pgno = 0x1DF;
        }

        #usage() if $option_help;
        #print  if $option_help;

        if (-t) {
                die "No VBI data on standard input.\n";
        }

        if (0 != $option_pfc_pgno) {
                $pfc = Video::ZVBI::pfc_demux::new ($option_pfc_pgno,
                                         $option_pfc_stream,
                                         \&page_function_clear_cb);
                die unless defined $pfc;
        }

        if (0 != $option_idl_channel) {
                $idl = Video::ZVBI::idl_demux::new ($option_idl_channel,
                                            $option_idl_address,
                                            \&idl_format_a_cb);
                die unless defined $idl;
        }

        if ($option_decode_xds) {
                $xds = Video::ZVBI::xds_demux::new (\&xds_cb);
                die unless defined $xds;
        }

        $outfile = new IO::Handle;
        $outfile->fdopen(fileno(STDOUT), "w");

        $infile = new IO::Handle;
        $infile->fdopen(fileno(STDIN), "r");
        my $c = ord($infile->getc() || 1);
        $infile->ungetc($c);

        if (0 == $c || $source_is_pes) {
                #$dvb = Video::ZVBI::dvb_demux::pes_new (\&dvb_feed_cb); #ALT
                $dvb = Video::ZVBI::dvb_demux::pes_new ();
                die unless defined $dvb;

                pes_mainloop ();
        } else {
#if 2 == VBI_VERSION_MINOR # XXX port me
                #open_sliced_read ($infile);
#endif
                old_mainloop ();
        }

        undef $dvb;
        undef $idl;
        undef $pfc;
        undef $xds;
}

#sub vlog  { print "LOG ".join(",",@_); }
#Video::ZVBI::set_log_fn(VBI_LOG_DEBUG, \&vlog, "\n");

main_func();

