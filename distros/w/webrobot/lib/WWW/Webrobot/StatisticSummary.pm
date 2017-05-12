package WWW::Webrobot::StatisticSummary;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG


sub statistic {
    my ($s, $title) = @_;
    print "$title\n" if $title;
    print "(Sum_x, Sum_x^2, n) = (",
        join(", ", $s->sum_x, $s->sum_x2, $s->n),
        ")\n";
    print "Mean          : ", $s->mean, "\n";
    print "Median        : ", $s->median, "\n";
    print "Quadratic mean: ", $s->quad_mean, "\n";
    print "Std. deviation: ", $s->standard_deviation, "\n";
    print "Minimum       : ", $s->min, "\n";
    print "Maximum       : ", $s->max, "\n";
    print "Total time    : ", $s->{total_time}, "\n" if defined $s->{total_time};
    print "Requests/sec  : ", $s->n / $s->{total_time}, "\n" if defined $s->{total_time};
}

sub histogram {
    my ($histogram, $log_y, $scale, $title) = @_;

    print "$title\n" if $title;
    my ($hist_neg, $hist_pos) = $histogram->histogram();
    my $max = max(@$hist_neg, @$hist_pos);
    $max = log($max) if ($log_y && $max>=1);
    $max = 1 if $max < 1;
    printf "%3s %7s .. %7s %5s %s\n", "", "from/s", "to/s", "count", "";
    for (my $i = 1 - scalar @$hist_neg; $i < scalar @$hist_pos; $i++) {
        my $value = ($i>=0) ? $hist_pos->[$i] : $hist_neg->[-$i];
        my $stars = $value;
        $stars = log($stars) if ($log_y && $stars>=1);
        $stars = $stars*($scale/$max) if ($log_y || $max>$scale);
        my ($r0, $r1) = range($i, $histogram->base);
        printf "%3d %7.3f .. %7.3f %5d %s\n", $i, $r0, $r1, $value, "*"x$stars;
    }
}

sub url_statistic {
    my ($url_statistic, $title) = @_;
    print "$title\n" if $title;
    my @sorted = sort {
        $url_statistic->{$a}->mean <=> $url_statistic->{$b}->mean
    } keys %$url_statistic;
    # # applied Schwartz' transform
    # my @sorted =
    #     map {$_->[0]}
    #     sort {$a->[1] <=> $b->[1]}
    #     map {[$_, $url_statistic->{$_}->mean]}
    #     keys %$url_statistic;
    printf "   Mean  StdDev Url\n";
    foreach (@sorted) {
        my $stat = $url_statistic->{$_};
        printf "%7.3f %7.3f %s\n", $stat->mean, $stat->standard_deviation, "$_";
    }
}

sub http_errcodes {
    my ($http_errcode, $title) = @_;
    print "$title\n" if $title;
    printf(" %3s %6d\n", $_, $http_errcode->{$_}) foreach (keys %$http_errcode);
}

sub assert_codes {
    my ($assert_ok, $title) = @_;
    print "$title\n" if $title;
    my $ok_count = shift(@$assert_ok) || 0;
    my $fail_count = 0;
    $fail_count += $_ foreach (@$assert_ok);
    print "Ok  : $ok_count\n";
    print "FAIL: $fail_count\n";
}


# === private functions ================================================

# return ($base^n, $base^(n-1))
sub range {
    my ($n, $base) = @_;
    my $first = $base**$n;
    return ($first, $base * $first);
}

# return max value of list
sub max {
    my $max = undef;
    foreach (@_) {
        $max = $_ if !defined $max || $_ > $max;
    }
    return $max;
}


1;
