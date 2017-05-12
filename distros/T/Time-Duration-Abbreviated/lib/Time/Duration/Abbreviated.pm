package Time::Duration::Abbreviated;
use 5.008005;
use strict;
use warnings;
use Time::Duration qw();
use parent qw(Exporter);

our $VERSION = "0.01";

our @EXPORT = qw(later later_exact earlier earlier_exact
                 ago ago_exact from_now from_now_exact
                 duration duration_exact concise);
our @EXPORT_OK = ('interval', @EXPORT);

sub concise {
    Time::Duration::concise($_[0]);
}

sub later {
    interval($_[0], $_[1], '%s ago', '%s later');
}

sub later_exact {
    interval_exact($_[0], '%s ago', '%s later');
}

sub earlier {
    interval($_[0], $_[1], '%s later', '%s ago');
}

sub earlier_exact {
    interval_exact($_[0], '%s later', '%s ago');
}

sub ago {
    &earlier
}

sub ago_exact {
    &earlier_exact
}

sub from_now {
    &later
}

sub from_now_exact {
    &later_exact
}

sub duration_exact {
    (my $span = shift) || return '0 sec';
    _render('%s', Time::Duration::_separate(abs $span));
}

sub duration {
    (my $span = shift) || return '0 sec';
    my $precision = int(shift || 0) || 2;  # precision (default: 2)
    _render(
        '%s',
        Time::Duration::_approximate($precision, Time::Duration::_separate(abs $span))
    );
}

sub interval_exact {
    my ($span, $neg_direction, $pos_direction) = @_;

    _render(
        _determine_direction($span, $neg_direction, $pos_direction),
        Time::Duration::_separate($span)
    );
}

sub interval {
    my ($span, $precision, $neg_direction, $pos_direction) = @_;

    $precision = int($precision || 0) || 2;
    _render(
        _determine_direction($span, $neg_direction, $pos_direction),
        Time::Duration::_approximate($precision, Time::Duration::_separate($span))
    );
}

sub _determine_direction {
    my ($span, $neg_direction, $pos_direction) = @_;

    no warnings qw(numeric uninitialized);
    my $direction = ($span <= -1) ? $neg_direction
                  : ($span >=  1) ? $pos_direction
                  : 'now';
    use warnings;

    return $direction;
}

my %units = (
    second => 'sec',
    minute => 'min',
    hour   => 'hr',
    day    => 'day',
    year   => 'yr',
);

sub _render {
    my ($direction, @pieces) = @_;

    my @wheel;
    for my $piece (@pieces) {
        next if $piece->[1] == 0;

        my $val  = $piece->[1];
        my $unit = $units{$piece->[0]};
        if ($unit =~ /\A(?:hr|day|yr)\Z/) {
            $unit .= 's' if $val > 1;
        }

        push @wheel, "$val $unit";
    }

    return "now" unless @wheel;
    return sprintf($direction, join ' ', @wheel);
}

1;
__END__

=encoding utf-8

=head1 NAME

Time::Duration::Abbreviated - Describe time duration in abbreviated English

=head1 SYNOPSIS

    use Time::Duration::Abbreviated;

    duration(12345, 2); # => "3 hrs 26 min"
    earlier(12345, 2);  # => "3 hrs 26 min ago"
    later(12345, 2);    # => "3 hrs 26 min later"

    duration_exact(12345); # => "3 hrs 25 min 45 sec"
    earlier_exact(12345);  # => "3 hrs 25 min 45 sec ago"
    later_exact(12345);    # => "3 hrs 25 min 45 sec later"

=head1 DESCRIPTION

Time::Duration::Abbreviated is a abbreviated version of L<Time::Duration>.

=head1 SEE ALSO

L<Time::Duration>

=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut

