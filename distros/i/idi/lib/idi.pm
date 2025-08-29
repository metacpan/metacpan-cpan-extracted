package idi;

# ABSTRACT: Easy, command-line MIDI

use strict;
use warnings;

use Moo;
use strictures 2;
use File::Slurper qw(read_binary);
use File::Temp qw(tempfile);
use MIDI::RtController ();
use MIDI::Simple ();
use MIDI::Drummer::Tiny ();
use Music::Tempo qw(bpm_to_ms);
use namespace::clean;
use Exporter qw(import);
our @EXPORT = qw(
    b
    c
    d
    e
    g
    i
    n
    o
    p
    r
    t
    u
    v
    w
    x
);

our $VERSION = '0.0505';

my $self;

sub BEGIN {
    has filename => (
        is      => 'rw',
        builder => 1,
    );
    sub _build_filename {
        my ($fh, $filename) = tempfile('idi-XXXX',
            DIR    => '.',
            SUFFIX => '.mid',
            UNLINK => 1,
        );
        return $filename;
    }

    has score => (
        is      => 'ro',
        default => sub { MIDI::Simple->new_score },
    );

    has drummer => (
        is => 'lazy',
    );
    sub _build_drummer {
        my ($self) = @_;
        MIDI::Drummer::Tiny->new(file => $self->filename);
    }

    has play => (
        is      => 'rw',
        default => sub { 1 },
    );

    has is_written => (
        is      => 'rw',
        default => sub { 0 },
    );

    has is_drums => (
        is      => 'rw',
        default => sub { 0 },
    );

    $self = __PACKAGE__->new;
}

sub END {
    if ($self->play) {
        my $content;
        if ($self->is_drums) {
            $self->drummer->write unless $self->is_written;
            $content = read_binary($self->drummer->file);
        }
        else {
            $self->score->write_score($self->filename) unless $self->is_written;
            $content = read_binary($self->filename);
        }
        print $content;
    }
}

sub b {
    my ($bpm) = @_;
    $self->drummer->set_bpm($bpm);
    $self->score->set_tempo(bpm_to_ms($bpm) * 1000);
}

sub c {
    $self->score->Channel(@_);
}

sub d {
    $self->score->Duration(@_);
}

sub e {
    my ($value) = @_;
    $self->play($value);
}

sub g {
    return $self->score;
}

sub i {
    my $rtc = MIDI::RtController->new(input => $_[0], output => $_[1], verbose => 1);
    $rtc->run;
}

sub n {
    if (ref $_[0] eq 'ARRAY') {
        for my $notes (@_) {
            $self->score->n(@$notes);
        }
    }
    else {
        $self->score->n(@_);
    }
}

sub o {
    $self->score->Octave(@_);
}

sub p {
    $self->score->patch_change(@_);
}

sub r {
    $self->score->r(@_);
}

sub t {
    my ($signature) = @_;
    my ($beats, $divisions) = split /\//, $signature;
    $self->score->time_signature(
        $beats,
        ($divisions == 8 ? 3 : 2),
        ($divisions == 8 ? 24 : 18 ),
        8
    );
}

sub u {
    my ($reps, $kick, $snare, $hhat) = @_;
    $self->drummer->sync_patterns(
        $self->drummer->kick      => $kick,
        $self->drummer->snare     => $snare,
        $self->drummer->closed_hh => $hhat,
        duration => $self->drummer->sixteenth,
    ) for 1 .. $reps;
    $self->is_drums(1);
    $self->drummer->score;
}

sub v {
    my ($vol) = @_;
    $self->drummer->set_volume($vol);
    $self->score->Volume($vol);
}

sub w {
    my ($name) = @_;
    if ($name) {
        $self->filename($name);
        $self->drummer->file($name);
    }
    if ($self->is_drums) {
        $self->drummer->write;
    }
    else {
        $self->score->write_score($self->filename);
    }
    $self->is_written(1);
}

sub x {
    $self->score->noop(@_);
}

1;

=encoding utf8

=head1 NAME

idi - Easy, command-line MIDI

=head1 SYNOPSIS

  perl -Midi -E 'x(qw(c1 f o5)); n([qw(qn Cs)],"F","Ds",[qw(hn Gs_d1)])' | timidity -Od -
  # or with fluidsynth

  # Compare with:
  perl -MMIDI::Simple -E 'new_score; noop qw(c1 f o5); n qw(qn Cs); n "F"; n "Ds"; n qw(hn Gs_d1); write_score shift()' idi.mid
  timidity -Od idi.mid

  # Play a drum back-beat:
  perl -Midi -E 'u(4,["1000000010000000"],["0000100000001000"],["1010101010101010"])' | timidity -Od -

  # Control a MIDI device (uniquely named "usb") in real-time
  perl -Midi -E 'i(@ARGV)' keyboard usb

=head1 DESCRIPTION

Easy, command-line MIDI!

=head1 FUNCTIONS

=head2 b

  b(100)

Set BPM

=head2 c

  c(15)

Channel

Default: C<0>

=head2 d

  d(128)

Duration

Default: C<96>

=head2 e

  e(0)

Play at end

Default: C<1>

=head2 g

Return the L<MIDI::Simple> score object.

=head2 i

Invoke L<MIDI::RtController> to control the second argument with the
first.

=head2 n

  n(qw(hn C))
  n(qw(hn 60))
  n(qw(hn C E G))
  n(qw(hn 60 64 67))
  n([qw(hn 60 64 67)], [qw(hn 65 69 71)], ...)
  n(\@note_spec1, \@note_spec2, ...)

Add notes as either a list of a single note-spec or a list of
array-references of note-specs. Please see the L<MIDI::Simple>
documentation for what a "note_spec" is.

=head2 o

  o(3)

Octave

Default: C<5>

=head2 p

  p($channel, $patch_number)

Patch

Default: C<0, 0> (channel 0, piano)

=head2 r

  r($note_duration)

Add rest. See the L<MIDI::Simple> documentation for what
"note_durations" are valid.

=head2 t

  t("$numerator/$denominator")

Time signature

Default: C<none>

=head2 u

  u($bars, $kick, $snare, $hihat)
  u(4, ["1000000010000000"], ["0000100000001000"], ["1010101010101010"])

  # extended example:
  use String::Random ();
  my $gen = String::Random->new;
  my $pat = sub { $gen->randregex("[01]{16}") };
  u(4, map { [$pat->()] } 1 .. 3);

Play a drum pattern à la L<MIDI::Drummer::Tiny> with 16th-note beat
resolution.

=head2 v

  v(127)

Volume

Default: C<64>

=head2 w

  w("filename.mid")

Write score to a file.

=head2 x

No-op (with C<MIDI::Simple::noop>)

=for Pod::Coverage filename
=for Pod::Coverage score
=for Pod::Coverage play
=for Pod::Coverage is_written

=head1 SEE ALSO

The F<t/01-methods.t> file in this distribution

L<Exporter>

L<File::Slurper>

L<File::Temp>

L<MIDI::Drummer::Tiny>

L<MIDI::RtController>

L<MIDI::Simple>

L<Music::Tempo>

L<Moo>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022-2025 by Gene Boggs.

This is free software, licensed under: The Artistic License 2.0 (GPL Compatible)

=cut
