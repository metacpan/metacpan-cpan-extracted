#!perl
#
# It may be handy to have a means to dump the contents of MIDI files
# while testing, e.g.
#
#   #!/usr/bin/env perl
#   use MIDI;
#   my $file = shift;
#   die "Usage: dump.pl midi-file\n" unless defined $file;
#   MIDI::Opus->new( { from_file => $file } ) ->dump( { dump_tracks => 1 } );
#
# though do note that MIDI.pm does not include MIDI footer events in the
# track display (it does parse them, and will convert them to text
# events if the dtime is non-zero).

use Test2::V0;
use Test2::Tools::MIDI;
use Test2::API 'intercept';

sub with_file {
    open my $fh, '<', $_[0] or die "open '$_[0]': $!\n";
    binmode $fh;    # this bytes
    return $fh;
}

# MIDI Header tests
{
    my $fh = with_file 't/header.midi';
    midi_header $fh, 1, 3, 96;
    midi_eof $fh;

    open my $short, '<', \"too short" or die "open: $!\n";
    my $header = 'NOPE' . pack( Nnnn => 3, 42, 99, 0 );
    open my $wrong, '<', \$header;
    my $events = intercept {
        midi_header $short, 0, 1, 96;
        midi_header $wrong, 0, 1, 96;
    };
    my $struct = $events->squash_info->flatten();
    #use Data::Dumper; warn Dumper $struct;
    is $struct->[0]{diag}[0], "byte_count [9,14]";
    is $struct->[1]{diag}[0],
      "id [NOPE,MThd] header_length [3,6] format [42,0] tracks [99,1] division [0,96]";
}

# MIDI Track (and thus also some MIDI Event) tests. The MIDI::Event
# documentation is a handy reference.
{
    my $fh = with_file 't/cowbell.midi';
    midi_header $fh, 0, 1, 96;
    midi_track $fh, 36;
    for ( 1 .. 4 ) {
        midi_note_on $fh, 0, 9, 56, 64;
        midi_note_off $fh, 96, 9, 56, 0;
    }
    midi_footer $fh, 0;

    my $onoff =
        pack( w => 23 )
      . "\x90\x3c\x60"
      . pack( w => 1234 )
      . "\x80\x3c\x00"
      . pack( w => 640 )
      . "\xFE\xED";
    open $fh, '<', \$onoff or die "open: $!\n";
    midi_skip $fh, 4;
    midi_note_off $fh, 1234, 0, 60, 0;

    my $events = intercept {
        midi_eof $fh;
        midi_footer $fh, 17;
        midi_track $fh, 8;

        seek $fh, 0, 0;
        midi_note_on $fh, 1, 7, 42, 120;
        midi_note_off $fh, 1, 7, 42, 120;

        # test coverage...
        seek $fh, 0, 0;
        midi_track $fh, 8;
        seek $fh, 0, 0;
        midi_note_off $fh, 1, 7, 42, 120;
        midi_note_on $fh, 1, 7, 42, 120;

        $onoff .= "\x42";    # MIDI footer is supposed to end with \x00
        midi_footer $fh, 640;
    };
    my $struct = $events->squash_info->flatten();
    is $struct->[0]{name},    'MIDI EOF';
    is $struct->[1]{diag}[0], "dtime [640,17] length [2,3]";
    is $struct->[2]{diag}[0], "byte_count [0,8]";
    is $struct->[3]{diag}[0],
      "dtime [23,1] channel [0,7] pitch [60,42] velocity [96,120]";
    is $struct->[4]{diag}[0],
      "dtime [1234,1] channel [0,7] pitch [60,42] velocity [0,120]";

    seek $fh, 0, 0;
    midi_skip_dtime $fh, 3;
    midi_note_off $fh, 1234, 0, 60, 0;
}

# midi_aftertouch
{
    my $channel = 3;
    my $track   = pack wCCC => 0, 0xA0 | $channel, 67, 109;
    open my $fh, '<', \$track or die "open $!";
    midi_aftertouch $fh, 0, $channel, 67, 109;
}

# midi_channel_aftertouch
{
    my $channel = 2;
    my $track =
        pack( wCC => 128, 0xD0 | $channel, 83 )
      . pack( wCC => 0, 0xC0 | 3, 17 )
      . pack( wC => 0, 0xD0 );
    open my $fh, '<', \$track or die "open $!";
    midi_channel_aftertouch $fh, 128, $channel, 83;
    my $events = intercept {
        midi_channel_aftertouch $fh, 128, $channel, 83;
        midi_channel_aftertouch $fh, 0,   0,        42;
    };
    my $struct = $events->squash_info->flatten();
    is $struct->[0]{diag}[0],
      "dtime [0,128] channel [3,2] code [192,208] velocity [17,83]";
    is $struct->[1]{diag}[0], "length [1,2]";
}

# midi_control_change
{
    my $channel = 3;
    my $track   = pack wCCC => 0, 0xB0 | $channel, 1, 2;
    open my $fh, '<', \$track or die "open $!";
    midi_control_change $fh, 0, $channel, 1, 2;
}

# midi_patch
{
    my $channel = 1;
    my $patch   = 8;
    my $track   = pack wCCwCCwC => 0,
      0xC0 | $channel, $patch, 0, 0xD0, $patch, 0, 0xC0;
    open my $fh, '<', \$track or die "open $!";
    midi_patch $fh, 0, $channel, $patch;
    my $events = intercept {
        midi_patch $fh, 640, 7, 42;
        midi_patch $fh, 0,   7, 42;
    };
    my $struct = $events->squash_info->flatten();
    is $struct->[0]{diag}[0],
      "dtime [0,640] channel [0,7] code [208,192] patch [8,42]";
    is $struct->[1]{diag}[0], "length [1,2]";
}

# midi_pitch_wheel
{
    my $channel = 1;
    my $track =
        pack( wCCC => 64, 0xE0 | $channel, 0x66, 0x7b )
      . pack( wCCC => 0, 0xC0 | 3, 0x66, 0x7b )
      . pack( wC => 0, 0xE0 );
    open my $fh, '<', \$track or die "open $!";
    midi_pitch_wheel $fh, 64, $channel, 7654;
    my $events = intercept {
        midi_pitch_wheel $fh, 64, $channel, -42;
        midi_pitch_wheel $fh, 0,  0,        42;
    };
    my $struct = $events->squash_info->flatten();
    is $struct->[0]{diag}[0],
      "dtime [0,64] channel [3,1] code [192,224] wheel [7654,-42]";
    is $struct->[1]{diag}[0], "length [1,3]";
}

# midi_tempo
{
    my $track =
        pack( w => 9999 )
      . "\xFF\x51\x03\x08\x49\xEA"
      . pack( w => 0 )
      . "\xFF\x52\x03\x00\x00\x00"
      . pack( w => 0 )
      . "\xFF\x52";
    open my $fh, '<', \$track or die "open $!";
    midi_tempo $fh, 9999, 543210;
    seek $fh, 0, 0;
    my $events = intercept {
        midi_tempo $fh, 42, 640;
        midi_tempo $fh, 0,  0;
        midi_tempo $fh, 0,  0;
    };
    my $struct = $events->squash_info->flatten();
    is $struct->[0]{diag}[0], "dtime [9999,42] tempo [543210,640]";
    is $struct->[1]{diag}[0], "tempo_code [ff.52.3,ff.51.3]";
    is $struct->[2]{diag}[0], "length [2,6]";
}

# midi_text
{
    my $track = '';
    my $text  = 'blah';
    my $len   = length $text;
    for my $code ( 1 .. 15 ) {
        $track .= pack( wCCw => 0, 0xFF, $code, $len ) . $text;
    }
    open my $fh, '<', \$track or die "open $!";
    for my $type (
        qw{text copyright name instrument lyric marker cue
        text8 text9 texta textb textc textd texte textf}
    ) {
        midi_text $fh, 0, $type, $text;
    }
    like( dies { midi_text $fh, 0, 'nope', $text }, qr/unknown type/ );

    my $short = pack wC => 640, 0xFF;
    open my $afh, '<', \$short or die "open $!";
    my $whack = pack( wCCw => 0, 0xFE, 0xED, 2 ) . 'n';
    open my $bfh, '<', \$whack or die "open $!";
    my $events = intercept {
        midi_text $afh, 0, 'text', 'nope';
        midi_text $bfh, 0, 'text', 'nope';
        seek $fh, 0, 0;
        midi_text $fh, 0, 'text', 'bla';
    };
    my $struct = $events->squash_info->flatten();
    is $struct->[0]{diag}[0], "dtime [640,0] code_length [1,2]";
    is $struct->[1]{diag}[0], "text_code [fe.ed,ff.1] text_length [1,2]";
    is $struct->[2]{diag}[0], "text [blah,bla]";
}

# some more test coverage
{
    my $short = "blah";
    open my $fh, '<', \$short or die "open $!";
    my $events = intercept {
        midi_skip $fh, 99;
    };
    my $struct = $events->squash_info->flatten();
    is $struct->[0]{diag}[0], "byte_count [4,99]";

    # TODO is there a better way to force a read failure?
    diag "closed filehandle reads ...";
    close $fh;
    like( dies { midi_header $fh, 0, 1, 96 }, qr/midi_header read/ );
    like( dies { midi_track $fh, 99 }, qr/midi_track read/ );
    like( dies { midi_skip $fh,  99 }, qr/midi_skip read/ );
    like( dies { Test2::Tools::MIDI::read_vlq $fh, 99 },
        qr/read_vlq read/ );

    # Nope, this gets a length [0,3] and does not throw an error. TODO
    # forcing a filehandle read failure after some number of bytes
    # would probably need a mock filehandle object that knows how to
    # fail like that?
    #my $only_vlq = pack w => 0;
    #open $fh, '<', \$only_vlq or die "open $!";
    #like( dies { midi_footer $fh, 0 }, qr/midi_footer read/ );

    my $bigdtime = pack( w => 268435640 );
    open $fh, '<', \$bigdtime or die "open $!";
    like( dies { Test2::Tools::MIDI::read_vlq $fh, 268435640 },
        qr/read_vlq range/ );
    like( dies { Test2::Tools::MIDI::read_vlq $fh, 7 },
        qr/read_vlq eof/ );

    my $trun = pack( w => 7 ) . "\xFE\xED";
    open $fh, '<', \$trun or die "open $!";
    $events = intercept {
        midi_note_on $fh, 7, 0, 42, 120;
    };
    $struct = $events->squash_info->flatten();
    is $struct->[0]{diag}[0], "length [2,3]";
}

done_testing;
