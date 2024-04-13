# -*- Perl -*-
#
# A module to test MIDI file contents.

package Test2::Tools::MIDI;
our $VERSION = '0.02';
use 5.10.0;
use strict;
use warnings;
use Carp 'confess';
use Test2::API 'context';

use base 'Exporter';
our @EXPORT = qw(
  midi_aftertouch midi_channel_aftertouch midi_control_change midi_eof
  midi_footer midi_header midi_note_off midi_note_on midi_patch
  midi_pitch_wheel midi_skip midi_skip_dtime midi_tempo midi_text midi_track
);

sub _failure ($$\@) {
    my $result = 1;
    if ( @{ $_[2] } ) {
        $_[0]->fail( $_[1], join ' ',
            map { "$_->[0] [$_->[1],$_->[2]]" } @{ $_[2] } );
        $result = 0;
    } else {
        $_[0]->pass( $_[1] );
    }
    $_[0]->release;
    return $result;
}

# note_on, note_off and a few others share this pattern, though you may
# need to squint a little to make the "controller" and "value" of
# control_change fit the pitch and velocity fields
sub _dpv ($$$$$$$) {
    my ( $fh, $dtime, $channel, $pitch, $velocity, $want_code, $name ) =
      @_;

    my @failure;
    my $q = read_vlq($fh);
    if ( $q != $dtime ) {
        push @failure, [ dtime => $q, $dtime ];
    }
    my $amount = read $fh, my $track, 3;
    confess "$name read $!" unless defined $amount;
    if ( $amount != 3 ) {
        push @failure, [ length => $amount, 3 ];
        goto FAIL_DPV;
    }
    my ( $pa, $re, $ci ) = unpack CCC => $track;
    my ( $ch, $code ) = ( $pa & 0xF, $pa & 0xF0 );
    if ( $ch != $channel ) {
        push @failure, [ channel => $ch, $channel ];
    }
    if ( $code != $want_code ) {
        push @failure, [ code => $ch, $want_code ];
    }
    if ( $re != $pitch ) {
        push @failure, [ pitch => $re, $pitch ];
    }
    if ( $ci != $velocity ) {
        push @failure, [ velocity => $ci, $velocity ];
    }
  FAIL_DPV:
    _failure( context(), $name, @failure );
}

sub midi_aftertouch ($$$$$) {
    push @_, 0xA0, 'MIDI key_after_touch';
    goto &_dpv;
}

sub midi_channel_aftertouch ($$$$) {
    my ( $fh, $dtime, $channel, $velocity ) = @_;
    my @failure;
    my $q = read_vlq($fh);
    if ( $q != $dtime ) {
        push @failure, [ dtime => $q, $dtime ];
    }
    my $amount = read $fh, my $track, 2;
    confess "midi_channel_aftertouch read $!" unless defined $amount;
    if ( $amount != 2 ) {
        push @failure, [ length => $amount, 2 ];
        goto FAIL_CHAFT;
    }
    my ( $pa, $velo ) = unpack CC => $track;
    my ( $ch, $code ) = ( $pa & 0xF, $pa & 0xF0 );
    if ( $ch != $channel ) {
        push @failure, [ channel => $ch, $channel ];
    }
    if ( $code != 0xD0 ) {
        push @failure, [ code => $code, 0xD0 ];
    }
    if ( $velo != $velocity ) {
        push @failure, [ velocity => $velo, $velocity ];
    }
  FAIL_CHAFT:
    _failure( context(), 'MIDI channel_aftertouch', @failure );
}

sub midi_control_change ($$$$$) {
    push @_, 0xB0, 'MIDI control_change';
    goto &_dpv;
}

sub midi_eof ($) {
    my $eof    = eof $_[0];
    my $ctx    = context();
    my $result = 1;
    if ($eof) {
        $ctx->pass('MIDI EOF');
    } else {
        $ctx->fail('MIDI EOF');
        $result = 0;
    }
    $ctx->release;
    return $result;
}

sub midi_footer ($$) {
    my ( $fh, $dtime ) = @_;
    my @failure;
    my $q = read_vlq($fh);
    if ( $q != $dtime ) {
        push @failure, [ dtime => $q, $dtime ];
    }
    my $amount = read $fh, my $footer, 3;
    confess "midi_footer read $!" unless defined $amount;
    if ( $amount != 3 ) {
        push @failure, [ length => $amount, 3 ];
        goto FAIL_FOOTER;
    }
    my $expect = "\xFF\x2F\x00";
    if ( $footer ne $expect ) {
        push @failure,
          [ footer => map { sprintf '%vx', $_ } $footer, $expect ];
    }
  FAIL_FOOTER:
    _failure( context(), 'MIDI footer', @failure );
}

sub midi_header ($$$$) {
    my ( $fh, $want_format, $want_tracks, $want_division ) = @_;

    my $amount = read $fh, my $header, 14;
    confess "midi_header read $!" unless defined $amount;
    my @failure;
    if ( $amount != 14 ) {
        push @failure, [ byte_count => $amount, 14 ];
        goto FAIL_HEADER;
    }
    my ( $mthd, $header_len, $format, $tracks, $division ) =
      unpack a4Nnnn => $header;
    if ( $mthd ne 'MThd' ) {
        push @failure, [ id => $mthd, 'MThd' ];
    }
    if ( $header_len != 6 ) {
        push @failure, [ header_length => $header_len, 6 ];
    }
    if ( $format != $want_format ) {
        push @failure, [ format => $format, $want_format ];
    }
    if ( $tracks != $want_tracks ) {
        push @failure, [ tracks => $tracks, $want_tracks ];
    }
    if ( $division != $want_division ) {
        push @failure, [ division => $division, $want_division ];
    }
  FAIL_HEADER:
    _failure( context(), 'MIDI header', @failure );
}

sub midi_note_off ($$$$$) {
    push @_, 0x80, 'MIDI note_off';
    goto &_dpv;
}

sub midi_note_on ($$$$$) {
    push @_, 0x90, 'MIDI note_on';
    goto &_dpv;
}

# TODO probably need to support some more events around about here

sub midi_patch ($$$$) {
    my ( $fh, $dtime, $channel, $want_patch ) = @_;
    my @failure;
    my $q = read_vlq($fh);
    if ( $q != $dtime ) {
        push @failure, [ dtime => $q, $dtime ];
    }
    my $amount = read $fh, my $track, 2;
    confess "midi_patch read $!" unless defined $amount;
    if ( $amount != 2 ) {
        push @failure, [ length => $amount, 2 ];
        goto FAIL_PATCH;
    }
    my ( $pa, $patch ) = unpack CC => $track;
    my ( $ch, $code )  = ( $pa & 0xF, $pa & 0xF0 );
    if ( $ch != $channel ) {
        push @failure, [ channel => $ch, $channel ];
    }
    if ( $code != 0xC0 ) {
        push @failure, [ code => $code, 0xC0 ];
    }
    if ( $patch != $want_patch ) {
        push @failure, [ patch => $patch, $want_patch ];
    }
  FAIL_PATCH:
    _failure( context(), 'MIDI patch', @failure );
}

sub midi_pitch_wheel ($$$$) {
    my ( $fh, $dtime, $channel, $wheel ) = @_;
    my @failure;
    my $q = read_vlq($fh);
    if ( $q != $dtime ) {
        push @failure, [ dtime => $q, $dtime ];
    }
    my $amount = read $fh, my $track, 3;
    if ( $amount != 3 ) {
        push @failure, [ length => $amount, 3 ];
        goto FAIL_WHEEL;
    }
    my ( $pa, $high, $low ) = unpack CCC => $track;
    my ( $ch, $code ) = ( $pa & 0xF, $pa & 0xF0 );
    if ( $ch != $channel ) {
        push @failure, [ channel => $ch, $channel ];
    }
    if ( $code != 0xE0 ) {
        push @failure, [ code => $code, 0xE0 ];
    }
    my $value = $high | ( $low << 7 ) - 0x2000;
    if ( $value != $wheel ) {
        push @failure, [ wheel => $value, $wheel ];
    }
  FAIL_WHEEL:
    _failure( context(), 'MIDI pitch_wheel', @failure );
}

sub midi_skip ($$) {
    my ( $fh, $size ) = @_;
    my $amount = read $fh, my ($unused), $size;
    confess "midi_skip read $!" unless defined $amount;
    my @failure;
    if ( $amount != $size ) {
        push @failure, [ byte_count => $amount, $size ];
    }
    _failure( context(), 'MIDI skip', @failure );
}

sub midi_skip_dtime ($$) {
    read_vlq( $_[0] );
    goto &midi_skip;
}

sub midi_tempo ($$$) {
    my ( $fh, $dtime, $tempo_want ) = @_;
    my @failure;
    my $q = read_vlq($fh);
    if ( $q != $dtime ) {
        push @failure, [ dtime => $q, $dtime ];
    }
    my $amount = read $fh, my $track, 6;
    confess "midi_tempo read $!" unless defined $amount;
    if ( $amount != 6 ) {
        push @failure, [ length => $amount, 6 ];
        goto FAIL_TEMPO;
    }
    my ( $code, $high, $low ) = unpack Z3Cn => $track;
    my $expect = "\xFF\x51\x03";
    if ( $code ne $expect ) {
        push @failure,
          [ tempo_code => map { sprintf '%vx', $_ } $code, $expect ];
    }
    my $tempo = ( $high << 16 ) | $low;
    if ( $tempo != $tempo_want ) {
        push @failure, [ tempo => $tempo, $tempo_want ];
    }
  FAIL_TEMPO:
    _failure( context(), 'MIDI tempo', @failure );
}

sub midi_text ($$$$) {
    my ( $fh, $dtime, $type, $want_string ) = @_;
    my $code;
    if ( $type eq 'text' ) {
        $code = "\xFF\x01";
    } elsif ( $type eq 'copyright' ) {
        $code = "\xFF\x02";
    } elsif ( $type eq 'name' ) {
        $code = "\xFF\x03";
    } elsif ( $type eq 'instrument' ) {
        $code = "\xFF\x04";
    } elsif ( $type eq 'lyric' ) {
        $code = "\xFF\x05";
    } elsif ( $type eq 'marker' ) {
        $code = "\xFF\x06";
    } elsif ( $type eq 'cue' ) {
        $code = "\xFF\x07";
    } elsif ( $type eq 'text8' ) {
        $code = "\xFF\x08";
    } elsif ( $type eq 'text9' ) {
        $code = "\xFF\x09";
    } elsif ( $type eq 'texta' ) {
        $code = "\xFF\x0A";
    } elsif ( $type eq 'textb' ) {
        $code = "\xFF\x0B";
    } elsif ( $type eq 'textc' ) {
        $code = "\xFF\x0C";
    } elsif ( $type eq 'textd' ) {
        $code = "\xFF\x0D";
    } elsif ( $type eq 'texte' ) {
        $code = "\xFF\x0E";
    } elsif ( $type eq 'textf' ) {
        $code = "\xFF\x0F";
    } else {
        confess "unknown type '$type'";
    }
    my @failure;
    my $q = read_vlq($fh);
    if ( $q != $dtime ) {
        push @failure, [ dtime => $q, $dtime ];
    }
    my $amount = read $fh, my $track, 2;
    confess "midi_text read $!" unless defined $amount;
    if ( $amount != 2 ) {
        push @failure, [ code_length => $amount, 2 ];
        goto FAIL_TEXT;
    }
    if ( $track ne $code ) {
        push @failure,
          [ text_code => map { sprintf '%vx', $_ } $track, $code ];
    }
    my $string_length = read_vlq($fh);
    $amount = read $fh, $track, $string_length;
    if ( $amount != $string_length ) {
        push @failure, [ text_length => $amount, $string_length ];
        goto FAIL_TEXT;
    }
    if ( $track ne $want_string ) {
        push @failure, [ text => $track, $want_string ];
    }
  FAIL_TEXT:
    _failure( context(), "MIDI text_$type", @failure );
}

sub midi_track ($$) {
    my ( $fh, $want_length ) = @_;

    my $amount = read $fh, my $track, 8;
    confess "midi_track read $!" unless defined $amount;
    my @failure;
    if ( $amount != 8 ) {
        push @failure, [ byte_count => $amount, 8 ];
        goto FAIL_TRACK;
    }
    my ( $mtrk, $track_len ) = unpack a4N => $track;
    if ( $mtrk ne 'MTrk' ) {
        push @failure, [ id => $mtrk, 'MTrk' ];
    }
    if ( $track_len != $want_length ) {
        push @failure, [ track_length => $track_len, $want_length ];
        goto FAIL_TRACK;
    }
  FAIL_TRACK:
    _failure( context(), 'MIDI track', @failure );
}

sub read_vlq ($) {
    my $q = 0;
    while (1) {
        my $r = read $_[0], my $byte, 1;
        confess "read_vlq read $!" unless defined $r;
        confess "read_vlq eof" if $r == 0;
        my $n = unpack C => $byte;
        $q = ( $q << 7 ) | ( $n & 0x7f );
        if ( $n < 0x80 ) {
            confess "read_vlq range $q" if $q > 0xFFFFFFF;
            return $q;
        }
    }
}

1;
__END__

=head1 NAME

Test2::Tools::MIDI - test MIDI file contents

=head1 SYNOPSIS

  use MIDI::Simple;
  my $o = new_score;
  $o->{Score} = [];    # KLUGE clear the init text_event
  noop c9, o4;
  for (1 .. 4) { n 'qn', 'Gs' }
  write_score 'cowbell.midi';

  use Test2::Tools::MIDI;
  open my $fh, '<', 'cowbell.midi' or die "open $!\n";
  binmode $fh;
  midi_header $fh, 0, 1, 96; # format 0, 1 track, 96 ticks
  midi_track $fh, 36;
  for (1 .. 4) {
      midi_note_on  $fh,  0, 9, 56, 64;
      midi_note_off $fh, 96, 9, 56,  0;
  }
  midi_footer $fh, 0;
  midi_eof $fh;

=head1 DESCRIPTION

This module offers functions that test whether MIDI files (or an
in-memory string) contain particular MIDI structures and events. See the
L<MIDI> module (among other software and hardware) for means to generate
MIDI files.

Details of the MIDI protocol might be good to know. In brief, there is a
B<midi_header> structure that indicates among other things how many
tracks there are. Each B<midi_track> has a header structure and a footer
event, in between which are various MIDI events of some predetermined
length (including that of the footer event). Events are generally
composed of a time delay (a variable length quantity, see B<read_vlq>),
followed by an event ID, followed by event specific data, if any.
L<MIDI::Event> documents the general structure of the events.

=head1 FUNCTIONS

The C<midi_*> functions are exported by default; other utility functions
are not. Various functions will B<confess> if something goes awry,
usually due to I/O errors on the MIDI I<file-handle>.

=over 4

=item B<midi_aftertouch> I<file-handle> I<dtime> I<channel> I<pitch> I<velocity>

Test that a C<key_after_touch> event is what it should be.

=item B<midi_channel_aftertouch> I<file-handle> I<dtime> I<channel> I<velocity>

Check that a MIDI C<channel_aftertouch> is correct.

=item B<midi_control_change> I<file-handle> I<dtime> I<channel> I<controller> I<value>

Test a MIDI control change event. Note that I<controller> may be
reported as a pitch problem and I<value> as a velocity problem due to
this sharing code with B<midi_note_on> and similar functions.

=item B<midi_eof> I<file-handle>

Test that the I<file-handle> ends where it is expected to.

=item B<midi_header> I<file-handle> I<format> I<ntracks> I<division>

Test for a MIDI header which among other things will have a
particular I<format> (C<0> for a single track, C<1> for multiple
tracks, or possibly other values), some number of tracks I<ntracks>,
and a particular I<division> (usually a positive number of ticks such
as C<96>).

A MIDI header is generally followed by some number of tracks (that
ideally should agree with I<ntracks>), each of which containing some
number of events.

=item B<midi_footer> I<file-handle> I<dtime>

Check that there is a MIDI footer event with the given I<dtime> (usually
C<0>) in the I<file-handle>. (The L<MIDI::Opus> module hides the footer
in dumps though does parse it.)

=item B<midi_note_off> I<file-handle> I<dtime> I<channel> I<pitch> I<velocity>

Check that there is a MIDI note_off event with the given details in the
I<file-handle>. See the L<MIDI::Event> module for more documentation on
the fields.

=item B<midi_note_on> I<file-handle> I<dtime> I<channel> I<pitch> I<velocity>

Like B<midi_note_off> but checks for a slightly different MIDI code.
Some software (LilyPond comes to mind) does not generate
B<midi_note_off> events but instead issues a B<midi_note_on> with the
I<velocity> set to C<0>.

=item B<midi_patch> I<file-handle> I<dtime> I<channel> I<patch>

Check for a patch change event with the given details.

=item B<midi_pitch_wheel> I<file-handle> I<dtime> I<channel> I<wheel>

Test that a MIDI pitch wheel event is correct. The I<wheel> is a 14-bit
value split into two bytes that has an offset applied to it.

=item B<midi_skip> I<file-handle> I<size>

Skips over I<size> bytes in the I<file-handle>. Good for any pesky MIDI
events that are not (yet?) supported by this module.

=item B<midi_skip_dtime> I<file-handle> I<size>

Like B<midi_skip> but first skips over a variable length quantity, which
will be of some unknown length between 1 and 4 bytes, inclusive.

  $ perl -E 'say for map { length pack w => $_ } 0, 0xFFFFFFF'
  1
  4

=item B<midi_tempo> I<file-handle> I<dtime> I<tempo>

Check that a MIDI tempo event with the given I<dtime> and
I<tempo> is present.

=item B<midi_track> I<file-handle> I<length>

Test that a MIDI track is of a certain I<length> in bytes.

=item B<midi_text> I<file-handle> I<dtime> I<text-type> I<string>

Test that there is a text event of the given I<text-type> with the text
I<string>. I<text-type> must be one of:

  text copyright name instrument lyric marker cue
  text8 text9 texta textb textc textd texte textf

=item B<read_vlq> I<file-handle>

Reads a variable length quantity (VLQ) from the I<file-handle>, or
failing that throws an error. VLQ are used for MIDI durations (dtime).
The C<w> template to the C<pack> or C<unpack> functions is a more
efficient way to convert such quantities, though does not work on a
file handle.

=back

=head1 BUGS

None known. However, the module is very incomplete.

=head1 SEE ALSO

L<MIDI::Event>, L<Test2::Suite>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<https://opensource.org/licenses/BSD-3-Clause>

=cut
