package Unblock::HTTP::_AltSvc;

use strict;
use warnings;
use Carp qw(croak);

# A deliberately narrow Alt-Svc cache. It accepts h3 on the same hostname,
# on a specified UDP port. Cross-host endpoints are not enabled yet.
sub new {
    my ($class, %option) = @_;
    my $clock = delete $option{clock} || sub { time };
    croak 'alt_svc_clock must be a coderef' unless ref($clock) eq 'CODE';
    my $max_age = delete $option{max_age} || 86_400;
    my $max_entries = delete $option{max_entries} || 256;
    for my $pair ([max_age => $max_age], [max_entries => $max_entries]) {
        croak "Alt-Svc $pair->[0] must be a positive integer"
            unless defined($pair->[1]) && !ref($pair->[1])
                && $pair->[1] =~ /\A[0-9]+\z/ && $pair->[1] > 0;
    }
    croak 'unknown Alt-Svc option' if %option;
    return bless {
        clock => $clock,
        max_age => $max_age,
        max_entries => $max_entries,
        entries => {},
    }, $class;
}

sub _elements {
    my ($value) = @_;
    return unless defined($value) && length($value) <= 4096;
    my (@values, $part, $quote, $escaped) = ((), '', 0, 0);
    for my $char (split //, $value) {
        if ($escaped) {
            $part .= $char;
            $escaped = 0;
            next;
        }
        if ($quote && $char eq '\\') {
            $part .= $char;
            $escaped = 1;
            next;
        }
        if ($char eq '"') {
            $quote = !$quote;
            $part .= $char;
            next;
        }
        if (!$quote && $char eq ',') {
            push @values, $part;
            $part = '';
            next;
        }
        $part .= $char;
    }
    return if $quote || $escaped;
    push @values, $part;
    return \@values;
}

sub _valid_age {
    my ($value) = @_;
    return unless defined($value) && $value =~ /\A(?:0|[1-9][0-9]*)\z/;
    # Larger numbers can be treated as expired without numeric overflow.
    return 2_147_483_647 if length($value) > 9;
    return 0 + $value;
}

sub observe {
    my ($self, $key, $response) = @_;
    return unless defined($key) && $response && $response->can('header_values');
    my $headers = $response->header_values('alt-svc');
    return unless $headers && @$headers;

    my @elements;
    for my $value (@$headers) {
        my $list = _elements($value);
        return unless $list;
        push @elements, @$list;
    }

    # Any Alt-Svc response replaces prior origin alternatives. The clear
    # directive takes precedence, even if the rest of the field is invalid.
    delete $self->{entries}{$key};
    for my $element (@elements) {
        $element =~ s/\A[ \t]+|[ \t]+\z//g;
        return if $element eq 'clear';
    }

    my $age = _valid_age($response->header('age'));
    $age = 0 unless defined $age;
    my $now = $self->{clock}->();
    for my $element (@elements) {
        $element =~ s/\A[ \t]+|[ \t]+\z//g;
        next unless $element =~ /\Ah3[ \t]*=[ \t]*":([0-9]+)"(.*)\z/s;
        my ($port, $params) = ($1, $2);
        next if length($port) > 5 || !$port || $port > 65535;
        my $ma = 86_400;
        my $bad = 0;
        my %seen;
        while (length $params) {
            if ($params =~ s/\A[ \t]*;[ \t]*([A-Za-z][A-Za-z0-9_-]*)[ \t]*=[ \t]*([A-Za-z0-9_-]+|"[^"]*")//) {
                my ($name, $value) = (lc($1), $2);
                if ($name eq 'ma') {
                    my $number = _valid_age($value);
                    if ($seen{ma}++ || !defined $number) { $bad = 1; last }
                    $ma = $number;
                }
                next;
            }
            if ($params =~ /\A[ \t]*\z/) { $params = ''; last }
            $bad = 1;
            last;
        }
        next if $bad;
        $ma = $self->{max_age} if $ma > $self->{max_age};
        next if $ma <= $age;

        # Limit memory even when an application visits many unique origins.
        my $entries = $self->{entries};
        for my $existing (keys %$entries) {
            delete $entries->{$existing} if $entries->{$existing}{expires} <= $now;
        }
        if (keys(%$entries) >= $self->{max_entries}) {
            my ($oldest) = sort {
                $entries->{$a}{expires} <=> $entries->{$b}{expires}
            } keys %$entries;
            delete $entries->{$oldest};
        }
        $entries->{$key} = { port => 0 + $port, expires => $now + $ma - $age };
        last;
    }
    return;
}

sub lookup {
    my ($self, $key) = @_;
    my $item = $self->{entries}{$key} or return;
    if ($item->{expires} <= $self->{clock}->()) {
        delete $self->{entries}{$key};
        return;
    }
    return { %$item };
}

sub invalidate {
    my ($self, $key) = @_;
    delete $self->{entries}{$key};
    return;
}

sub clear {
    my ($self) = @_;
    $self->{entries} = {};
    return;
}

1;

__END__

=head1 NAME

Unblock::HTTP::_AltSvc - Bounded in-memory HTTP/3 alternative discovery

=head1 DESCRIPTION

Internal cache used by the shared Client. Only a same-host alternative
with the C<h3=":PORT"> form is supported. Known lifetime is shortened by
the response Age value and capped to 24 hours by default. Every new Alt-Svc
field replaces the origin entry; C<clear> removes it immediately.

The Client accepts advertisements only from explicitly authenticated HTTPS
connections. The framework must also verify an alternative QUIC connection
as authoritative for the original HTTPS origin. This cache is not a DNS,
certificate validation, or transport implementation.

=cut
