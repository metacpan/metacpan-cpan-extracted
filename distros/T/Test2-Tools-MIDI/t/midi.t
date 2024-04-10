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
# track display (it does parse them).

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

    open my $short, '<', \"too short" or die "open: $!\n";
    my $header = 'NOPE' . pack( Nnnn => 3, 42, 99, 0 );
    open my $wrong, '<', \$header;
    my $events = intercept {
        midi_header $short, 0, 1, 96;
        midi_header $wrong, 0, 1, 96;
    };
    my $struct = $events->squash_info->flatten();
    #use Data::Dumper; warn Dumper $struct;
    is( $struct->[0]{diag}[0], "byte_count [9,14]" );
    is( $struct->[1]{diag}[0],
        "id [NOPE,MThd] header_length [3,6] format [42,0] tracks [99,1] division [0,96]"
    );
}

# MIDI Track (and thus also MIDI Event) tests. The MIDI::Event
# documentation is a handy reference.
#
#   use MIDI::Simple;
#   my $o = new_score;
#   $o->{Score} = [];    # KLUGE clear the init text_event
#   noop c9, o4;
#   for ( 1 .. 4 ) {
#       n 'qn', 'Gs';
#   }
#   write_score 'cowbell.midi';
{
    my $fh = with_file 't/cowbell.midi';
    midi_header $fh, 0, 1, 96;
    midi_track $fh, 36, sub {
        for ( 1 .. 4 ) {
            midi_note_on $_[0], 0, 9, 56, 64;
            midi_note_off $_[0], 96, 9, 56, 0;
        }
        midi_footer $_[0], 0;
    };

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
        midi_footer $fh, 17;
        midi_track $fh, 8, sub { };

        seek $fh, 0, 0;
        midi_note_on $fh, 1, 7, 42, 120;
        midi_note_off $fh, 1, 7, 42, 120;

        # test coverage...
        seek $fh, 0, 0;
        midi_track $fh, 8, sub { };
        seek $fh, 0, 0;
        midi_note_off $fh, 1, 7, 42, 120;
        midi_note_on $fh, 1, 7, 42, 120;

        $onoff .= "\x42";
        midi_footer $fh, 640;
    };
    my $struct = $events->squash_info->flatten();
    is( $struct->[0]{diag}[0], "dtime [640,17] length [2,3]" );
    is( $struct->[1]{diag}[0], "byte_count [0,8]" );
    is( $struct->[2]{diag}[0],
        "dtime [23,1] channel [0,7] pitch [60,42] velocity [96,120]" );
    is( $struct->[3]{diag}[0],
        "dtime [1234,1] channel [0,7] pitch [60,42] velocity [0,120]" );
}

# some more test coverage
{
    my $short = "blah";
    open my $fh, '<', \$short or die "open $!";
    my $events = intercept {
        midi_skip $fh, 99;
    };
    my $struct = $events->squash_info->flatten();
    is( $struct->[0]{diag}[0], "byte_count [4,99]" );

    # TODO is there a better way to force a read failure?
    diag "closed filehandle reads ...";
    close $fh;
    like( dies { midi_header $fh, 0, 1, 96 }, qr/midi_header read/ );
    like(
        dies {
            midi_track $fh, 36, sub { }
        },
        qr/midi_track read/
    );
    like( dies { midi_skip $fh, 99 }, qr/midi_skip read/ );
    like( dies { Test2::Tools::MIDI::read_vlq $fh, 99 },
        qr/read_vlq read/ );

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
    is( $struct->[0]{diag}[0], "length [2,3]" );
    #use Data::Dumper; warn Dumper $struct;
}

done_testing;
