package Test2::Harness::Pipeline::Muxer;
use strict;
use warnings;

use File::Spec;

use Test2::Harness::Util::ActiveFile;

use parent 'Test2::Harness::Pipeline';
use Test2::Harness::HashBase qw{
    -mux_fh
    -muxed_buffer
    -event_counter

    -_hnum -_hstamp
};

sub init {
    my $self = shift;
    $self->{+EVENT_COUNTER} = 0;
    $self->{+MUXED_BUFFER} = {full => {}, part => {}};
}

sub process {
    my $self = shift;

    # If there is no mux file we simply return the events we get
    unless ($self->{+MUX_FH}) {
        my $mux_file = File::Spec->catfile($self->{+JOB_DIR}, 'muxed');

        $self->{+MUX_FH} ||= Test2::Harness::Util::ActiveFile->maybe_open_file($mux_file)
            or return @_;
    }

    # Populate our muxed buffer. Muxed file is written before regular handles,
    # and we are reading it after, so theoretically any event in the event
    # buffer will either be in the muxed buffer, or will not be muxed at all.
    $self->fill_muxed_buffer;

    my @e_buffer;
    for my $e (@_) {
        my $event_num = $self->{+EVENT_COUNTER}++;
        my $f         = $e->facet_data;
        my $raw       = $f->{harness}->{raw};
        my $mux       = $raw ? $self->find_mux($raw) : undef;

        push @e_buffer => [$e, $event_num, $f->{harness}->{stamp}, $mux];
    }

    return map { $_->[0] } sort event_sort @e_buffer;
}

sub event_sort {
    my ($a, $a_num, $a_stamp, $a_mux) = @$a;
    my ($b, $b_num, $b_stamp, $b_mux) = @$b;

    my $num_ord = $a_num <=> $b_num;
    my $stamp_ord = ($a_stamp && $b_stamp) ? $a_stamp <=> $b_stamp : 0;

    return $stamp_ord || $num_ord unless $a_mux && $b_mux;

    my ($a_handle, $a_mstamp) = @$a_mux;
    my ($b_handle, $b_mstamp) = @$b_mux;

    return $a_mstamp <=> $b_mstamp || $stamp_ord || $num_ord;
}

sub find_mux {
    my $self = shift;
    my ($raw) = @_;

    my $mux_buffer = $self->{+MUXED_BUFFER};

    if (my $full = $mux_buffer->{full}->{$raw}) {
        return shift @$full if @$full;
    }

    my @parts = sort { length($a) <=> length($b) } keys %{$mux_buffer->{part}};
    for my $part (@parts) {
        next unless $raw =~ m/^\Q$part\E/;
        my $set = $mux_buffer->{part}->{$part};
        next unless @$set;
        return shift @$set;
    }

    return undef;
}

sub fill_muxed_buffer {
    my $self = shift;
    my $buffer = $self->{+MUXED_BUFFER};

    my $fh = $self->{+MUX_FH} or return $buffer;

    my @lines;
    while (my $line = $fh->read_line) {
        if ($line =~ m/^START-TEST2-SYNC-(\d+):\s*(\S+)$/) {
            die "Extra START directive" if $self->{+_HNUM};
            ($self->{+_HNUM}, $self->{+_HSTAMP}) = ($1, $2);
            next;
        }

        die "Missing START directive:\n$line\n " unless $self->{+_HNUM};

        if ($line =~ m/^(\+|-)STOP-TEST2-SYNC-(\d+):\s*(\S+)$/) {
            die "Malformed STOP directive" unless $self->{+_HNUM} == $2 && $self->{+_HSTAMP} == $3;

            push @{$buffer->{part}->{pop @lines}} => [$self->{+_HNUM}, $self->{+_HSTAMP}] if $1 eq '-';
            push @{$buffer->{full}->{$_}} => [$self->{+_HNUM}, $self->{+_HSTAMP}] for @lines;

            ($self->{+_HNUM}, $self->{+_HSTAMP}) = (undef, undef);

            next;
        }

        push @lines => $line;
    }

    return $buffer;
}

1;
