# -*- Perl -*-
#
# A module to test MIDI file contents.

package Test2::Tools::MIDI;
our $VERSION = '0.01';
use 5.10.0;
use strict;
use warnings;
use Carp 'confess';
use Test2::API 'context';

use base 'Exporter';
our @EXPORT =
  qw(midi_header midi_track midi_footer midi_note_off midi_note_on midi_skip);

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

sub midi_track ($$&) {
    my ( $fh, $want_length, $event_tests ) = @_;

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
    $event_tests->( $fh, $want_length );
  FAIL_TRACK:
    _failure( context(), 'MIDI track', @failure );
}

# note_on, note_off and a few others share this pattern
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

sub midi_footer ($$) {
    my ( $fh, $dtime ) = @_;
    my @failure;
    my $q = read_vlq($fh);
    if ( $q != $dtime ) {
        push @failure, [ dtime => $q, $dtime ];
    }
    my $amount = read $fh, my $footer, 3;
    confess "midi_note_on read $!" unless defined $amount;
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

sub midi_note_off ($$$$$) {
    push @_, 0x80, 'MIDI note_off';
    goto &_dpv;
}

sub midi_note_on ($$$$$) {
    push @_, 0x90, 'MIDI note_on';
    goto &_dpv;
}

# TODO probably need to support some more events around about here

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

  use Test2::Tools::MIDI;

  open my $fh, '<', 'foo.midi' or die "open 'foo.midi': $!\n";
  binmode $fh;

  midi_header( $fh, 1, 3, 96 ); # format 1, 3 tracks, 96 tick
  ...

=head1 DESCRIPTION

This module offers functions that test whether MIDI files (or an
in-memory string) contain particular MIDI structures and events.

=head1 FUNCTIONS

The various C<midi_*> functions are exported by default; the other
utility functions are not.

=over 4

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

Check that there is a MIDI note_on event with the given details in the
I<file-handle>.

=item B<midi_skip> I<file-handle> I<size>

Skips over I<size> bytes in the I<file-handle>. Good for any pesky MIDI
events that are not (yet?) supported by this module.

=item B<midi_track> I<file-handle> I<length> I<event-callback>

Test that a MIDI track is of a certain I<length> in bytes. Calls the
I<event-callback> to handle any MIDI events in the track; there should
be I<length> bytes of events and the I<file-handle> will have been
advanced to the first of them.

    midi_track( $fh, 64, 0,
        sub ( $fh, $length ) {
            # test MIDI events including the track footer here ...
        }
    );

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
