package Unblock::HTTP1::_Engine;

use strict;
use warnings;
use Carp qw(croak);
use utf8 ();

sub _init_engine {
    my ($self, %option) = @_;
    my %known = map { $_ => 1 } qw(
        max_head_size
        max_headers
        max_chunk_extension_size
        high_water
        low_water
    );
    for my $key (sort keys %option) {
        croak "new(): unknown option '$key'" unless $known{$key};
    }
    $self->{max_head_size} = exists $option{max_head_size} ? $option{max_head_size} : 65_536;
    $self->{max_headers} = exists $option{max_headers} ? $option{max_headers} : 100;
    $self->{max_chunk_extension_size} = exists $option{max_chunk_extension_size}
        ? $option{max_chunk_extension_size} : 16_384;
    $self->{high_water} = exists $option{high_water} ? $option{high_water} : 65_536;
    $self->{low_water} = exists $option{low_water} ? $option{low_water} : 32_768;
    for my $key (qw(max_head_size max_headers max_chunk_extension_size high_water low_water)) {
        croak "new(): $key must be a non-negative integer"
            unless defined($self->{$key}) && !ref($self->{$key}) && $self->{$key} =~ /\A[0-9]+\z/;
    }
    croak 'new(): max_head_size must be positive' unless $self->{max_head_size} > 0;
    croak 'new(): max_headers must be between 1 and 256'
        unless $self->{max_headers} >= 1 && $self->{max_headers} <= 256;
    croak 'new(): low_water must not exceed high_water'
        if $self->{low_water} > $self->{high_water};
    $self->{input} = '';
    $self->{output} = '';
    $self->{closed} = 0;
    $self->{switched} = 0;
    $self->{remainder} = '';
    $self->{driving} = 0;
    $self->{eof} = 0;
    return $self;
}

sub is_closed { $_[0]{closed} ? 1 : 0 }
sub is_switched { $_[0]{switched} ? 1 : 0 }
sub want_read { !$_[0]{closed} && !$_[0]{switched} ? 1 : 0 }
sub want_write { length($_[0]{output}) ? 1 : 0 }

sub input {
    my ($self, $bytes) = @_;
    croak 'input(): bytes must be a scalar' if ref($bytes);
    $bytes = '' unless defined $bytes;
    my $copy = "$bytes";
    croak 'input(): bytes must be a byte string' unless utf8::downgrade($copy, 1);
    return 0 unless length $copy;
    croak 'input(): cannot be called recursively from an engine callback' if $self->{driving};
    if ($self->{switched}) {
        $self->{remainder} .= $copy;
        return length $copy;
    }
    croak 'input(): connection is closed' if $self->{closed};
    $self->{input} .= $copy;
    local $self->{driving} = 1;
    $self->_drive;
    return length $copy;
}

sub _input_borrowed {
    my ($self, $window, $length, $head, $message) = @_;
    croak '_input_borrowed(): cannot be called recursively from an engine callback'
        if $self->{driving};
    return (4, 0, 0) if $self->{switched};
    return (3, 0, 0) if $self->{closed};
    if (length $self->{input}) {
        croak '_input_borrowed(): buffered fallback requires a native input window'
            unless ref($window)
                && $window->isa('Unblock::HTTP1::_Native::BorrowedWindow');
        $self->{input} .= $window->slice(0, $length);
        local $self->{driving} = 1;
        $self->_drive;

        my $status = $self->{closed} ? 3 : $self->{switched} ? 4 : 0;
        return ($status, $length, $self->_borrowed_native_head_ready);
    }

    my ($status, $consumed);
    {
        local $self->{borrowed_input} = $window;
        local $self->{borrowed_length} = $length;
        local $self->{borrowed_offset} = 0;
        local $self->{borrowed_head} = $head;
        local $self->{borrowed_message} = $message;
        local $self->{driving} = 1;
        $self->_drive;

        my $remaining = $self->_input_length;
        if ($self->{closed}) {
            $status = 3;
        } elsif ($self->{switched}) {
            $status = 4;
        } elsif ($remaining && $self->_borrowed_should_buffer_tail) {
            $self->{input} .= $self->_input_take($remaining);
            $status = 0;
        } elsif ($remaining) {
            $status = 1;
        } else {
            $status = 0;
        }
        $consumed = $self->{borrowed_offset};
        my $head_ready = $self->_borrowed_native_head_ready;
        return ($status, $consumed, $head_ready);
    }
}

sub _borrowed_input_eof {
    my ($self) = @_;
    $self->input_eof;
    return 4 if $self->{switched};
    return 3 if $self->{closed};
    return 0;
}

sub _input_length {
    my ($self) = @_;
    if (exists $self->{borrowed_input}) {
        return $self->{borrowed_length} - $self->{borrowed_offset};
    }
    return length $self->{input};
}

sub _input_window {
    my ($self) = @_;
    return ($self->{borrowed_input}, $self->{borrowed_offset})
        if exists $self->{borrowed_input};
    return ($self->{input}, 0);
}

sub _input_take {
    my ($self, $length) = @_;
    return '' unless $length;
    if (exists $self->{borrowed_input}) {
        my $offset = $self->{borrowed_offset};
        my $bytes = $self->{borrowed_input}->slice($offset, $length);
        $self->{borrowed_offset} += $length;
        return $bytes;
    }
    return substr($self->{input}, 0, $length, '');
}

sub _input_discard {
    my ($self, $length) = @_;
    return unless $length;
    if (exists $self->{borrowed_input}) {
        $self->{borrowed_offset} += $length;
        return;
    }
    substr($self->{input}, 0, $length, '');
    return;
}

sub _input_clear {
    my ($self) = @_;
    if (exists $self->{borrowed_input}) {
        $self->{borrowed_offset} = $self->{borrowed_length};
    } else {
        $self->{input} = '';
    }
    return;
}

sub _input_remaining {
    my ($self) = @_;
    if (exists $self->{borrowed_input}) {
        return $self->{borrowed_input}->slice(
            $self->{borrowed_offset}, $self->_input_length,
        );
    }
    return $self->{input};
}

sub _borrowed_should_buffer_tail { 0 }
sub _borrowed_native_head_ready { 0 }

sub input_eof {
    my ($self) = @_;
    return $self if $self->{eof};
    croak 'input_eof(): cannot be called recursively from an engine callback' if $self->{driving};
    $self->{eof} = 1;
    local $self->{driving} = 1;
    $self->_on_eof;
    return $self;
}

sub output {
    my ($self, $max) = @_;
    croak 'output(): cannot be called recursively from an engine callback' if $self->{driving};
    return '' unless length $self->{output};
    my $take = length $self->{output};
    if (defined $max) {
        croak 'output(): maximum must be a positive integer'
            unless !ref($max) && $max =~ /\A[0-9]+\z/ && $max > 0;
        $take = $max if $max < $take;
    }
    my $bytes = substr($self->{output}, 0, $take, '');
    $self->_after_output;
    return $bytes;
}

sub take_remainder {
    my ($self) = @_;
    croak 'take_remainder(): HTTP/1 connection has not switched protocols'
        unless $self->{switched};
    my $bytes = $self->{remainder};
    $self->{remainder} = '';
    return $bytes;
}

sub close {
    my ($self, $error) = @_;
    return $self if $self->{closed};
    $self->{closed} = 1;
    $self->_fail_all(defined($error) && length($error) ? "$error" : 'HTTP/1 connection closed');
    return $self;
}

sub _queue_output {
    my ($self, $bytes) = @_;
    return unless defined $bytes && length $bytes;
    $self->{output} .= $bytes;
    return;
}

sub _mark_switched {
    my ($self) = @_;
    return if $self->{switched};
    $self->{switched} = 1;
    if (!exists $self->{borrowed_input}) {
        $self->{remainder} .= $self->{input};
        $self->{input} = '';
    }
    return;
}

sub _after_output {
    my ($self) = @_;
    $self->_maybe_drain if length($self->{output}) <= $self->{low_water};
    return;
}

sub _stream_ok {
    my ($self) = @_;
    return length($self->{output}) < $self->{high_water} ? 1 : 0;
}

sub _maybe_drain { return }
sub _fail_all { return }

1;
