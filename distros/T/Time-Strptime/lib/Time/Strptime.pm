package Time::Strptime;
use 5.008005;
use strict;
use warnings;

our $VERSION = "1.04";

use parent qw/Exporter/;
our @EXPORT_OK = qw/strptime/;

use Carp ();
use Time::Strptime::Format;

my %instance_cache;
sub strptime {
    my ($format_text, $date_text) = @_;

    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    my $format = $instance_cache{$format_text} ||= Time::Strptime::Format->new($format_text);
    return $format->parse($date_text);
}

1;
__END__

=encoding utf-8

=head1 NAME

Time::Strptime - parse date and time string.

=head1 SYNOPSIS

    use Time::Strptime qw/strptime/;

    # function
    my ($epoch_f, $offset_f) = strptime('%Y-%m-%d %H:%M:%S', '2014-01-01 00:00:00');

    # OO style
    my $fmt = Time::Strptime::Format->new('%Y-%m-%d %H:%M:%S');
    my ($epoch_o, $offset_o) = $fmt->parse('2014-01-01 00:00:00');

=head1 DESCRIPTION

Time::Strptime is pure perl date and time string parser.
In other words, This is pure perl implementation a L<strptime(3)>.

This module allows you to perform better by pre-compile the format by string.

benchmark:GMT(-0000) C<tp=Time::Piece, ts=Time::Strptime, pt=POSIX::strptime(+Time::Local), tm=Time::Moment>

    Benchmark: running pt, tm, tp, tp(cached), ts(cached) for at least 10 CPU seconds...
            pt: 11 wallclock secs (10.41 usr +  0.01 sys = 10.42 CPU) @ 297345.59/s (n=3098341)
            tm: 10 wallclock secs (10.17 usr +  0.01 sys = 10.18 CPU) @ 2481673.28/s (n=25263434)
            tp: 10 wallclock secs (10.52 usr +  0.01 sys = 10.53 CPU) @ 56390.98/s (n=593797)
    tp(cached): 11 wallclock secs (10.53 usr +  0.01 sys = 10.54 CPU) @ 80838.24/s (n=852035)
    ts(cached): 11 wallclock secs (10.60 usr +  0.01 sys = 10.61 CPU) @ 267686.15/s (n=2840150)
                    Rate         tp tp(cached) ts(cached)         pt         tm
    tp           56391/s         --       -30%       -79%       -81%       -98%
    tp(cached)   80838/s        43%         --       -70%       -73%       -97%
    ts(cached)  267686/s       375%       231%         --       -10%       -89%
    pt          297346/s       427%       268%        11%         --       -88%
    tm         2481673/s      4301%      2970%       827%       735%         --

benchmark:Asia/Tokyo(-0900) C<tp=Time::Piece, ts=Time::Strptime, pt=POSIX::strptime(+Time::Local), tm=Time::Moment>

    Benchmark: running pt, tm, tp, tp(cached), ts(cached) for at least 10 CPU seconds...
            pt: 10 wallclock secs (10.29 usr +  0.05 sys = 10.34 CPU) @ 147048.07/s (n=1520477)
            tm: 10 wallclock secs (10.00 usr +  0.03 sys = 10.03 CPU) @ 2344311.67/s (n=23513446)
            tp: 10 wallclock secs (10.15 usr +  0.02 sys = 10.17 CPU) @ 44565.39/s (n=453230)
    tp(cached): 11 wallclock secs (10.41 usr +  0.06 sys = 10.47 CPU) @ 50136.29/s (n=524927)
    ts(cached): 10 wallclock secs (10.73 usr +  0.07 sys = 10.80 CPU) @ 114871.48/s (n=1240612)
                    Rate         tp tp(cached) ts(cached)         pt         tm
    tp           44565/s         --       -11%       -61%       -70%       -98%
    tp(cached)   50136/s        13%         --       -56%       -66%       -98%
    ts(cached)  114871/s       158%       129%         --       -22%       -95%
    pt          147048/s       230%       193%        28%         --       -94%
    tm         2344312/s      5160%      4576%      1941%      1494%         --

=head1 FAQ

=head2 What's the difference between this module and other modules?

This module is fast and not require XS. but, support epoch C<strptime> only.
L<DateTime> is very useful and stable! but, It is slow.
L<Time::Piece> is fast and useful! but, treatment of time zone is confusing. and, require XS.
L<Time::Moment> is very fast and useful! but, does not support C<strptime>. and, require XS.

=head2 How to specify a time zone?

Set time zone name or L<DateTime::TimeZone> object to C<time_zone> option.

    use Time::Strptime::Format;

    my $format = Time::Strptime::Format->new('%Y-%m-%d %H:%M:%S', { time_zone => 'Asia/Tokyo' });
    my ($epoch, $offset) = $format->parse('2014-01-01 00:00:00');

=head2 How to specify a locale?

Set locale name object to C<locale> option.

    use Time::Strptime::Format;

    my $format = Time::Strptime::Format->new('%Y-%m-%d %H:%M:%S', { locale => 'ja_JP' });
    my ($epoch, $offset) = $format->parse('2014-01-01 00:00:00');

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
