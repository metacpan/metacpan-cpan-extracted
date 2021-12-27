package idi;

# ABSTRACT: Easy Command-line MIDI

use strict;
use warnings;

use MIDI::Simple ();
use Music::Tempo qw(bpm_to_ms);
use Moo;
use strictures 2;
use namespace::clean;

use Exporter 'import';
our @EXPORT = qw(
    get_score
    b
    c
    d
    n
    o
    p
    r
    t
    v
    w
    x
);

our $VERSION = '0.0102';

=head1 NAME

idi - Easy Command-line MIDI

=head1 SYNOPSIS

  perl -Midi -E'x(qw(c1 f o5)); n(qw(qn Cs)); n("F"); n("Ds"); n(qw(hn Gs_d1)); w()'

  timidity idi.mid

  # Compare with:
  perl -MMIDI::Simple -E'new_score; noop qw(c1 f o5); n qw(qn Cs); n "F"; n "Ds"; n qw(hn Gs_d1); write_score shift()' idi.mid

=head1 DESCRIPTION

Easy Command-line MIDI

=head1 FUNCTIONS

=head2 b

BPM

=head2 c

Channel

Default: C<0>

=head2 d

Duration

Default: <96>

=head2 n

Add note

=head2 o

Octave

Default: C<5>

=head2 p

Patch

Default: C<0> (piano)

=head2 r

Add rest

=head2 t

Time signature

Default: C<none>

=head2 v

Volume

Default: C<64>

=head2 w

Write score.  Supply a string argument for different name.

Default filename: C<idi.mid>

=head2 x

No-op (with C<MIDI::Simple::noop>)

=for Pod::Coverage filename
=for Pod::Coverage score

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Gene Boggs.

This is free software, licensed under: The Artistic License 2.0 (GPL Compatible)

=cut

my $self;

sub BEGIN {
    has filename => (
        is      => 'ro',
        default => sub { 'idi.mid' },
    );

    has score => (
        is      => 'ro',
        default => sub { MIDI::Simple->new_score },
    );

    $self = __PACKAGE__->new;
}

sub get_score {
    return $self->score;
}

sub b {
    my ($bpm) = @_;
    $self->score->set_tempo(bpm_to_ms($bpm) * 1000);
}

sub c {
    $self->score->Channel(@_);
}

sub d {
    $self->score->Duration(@_);
}

sub n {
    $self->score->n(@_);
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

sub v {
    $self->score->Volume(@_);
}

sub w {
    my $name = shift || $self->filename;
    $self->score->write_score($name);
}

sub x {
    $self->score->noop(@_);
}

1;
