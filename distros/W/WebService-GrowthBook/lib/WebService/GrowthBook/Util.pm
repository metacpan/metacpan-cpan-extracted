package WebService::GrowthBook::Util;
use strict;
use warnings;
use Exporter qw(import);
use URI;
use List::Util qw(sum);
use String::CamelCase qw(decamelize);

our $VERSION = '0.003'; ## VERSION

our @EXPORT_OK = qw(gbhash in_range get_query_string_override get_equal_weights get_bucket_ranges adjust_args_camel_to_snake choose_variation in_namespace);

sub fnv1a32 {
    my ($str) = @_;
    my $hval = 0x811C9DC5;
    my $prime = 0x01000193;
    my $uint32_max = 2 ** 32;

    foreach my $s (split //, $str) {
        $hval = $hval ^ ord($s);
        $hval = ($hval * $prime) % $uint32_max;
    }

    return $hval;
}
sub gbhash {
    my ($seed, $value, $version) = @_;

    if ($version == 2) {
        my $n = fnv1a32(fnv1a32($seed . $value));
        return ($n % 10000) / 10000;
    }
    if ($version == 1) {
        my $n = fnv1a32($value . $seed);
        return ($n % 1000) / 1000;
    }
    return undef;
}

sub in_range {
    my ($n, $range) = @_;
    return $range->[0] <= $n && $n < $range->[1];
}


sub get_query_string_override {
    my ($id, $url, $num_variations) = @_;
    my $uri = URI->new($url);

    # Return undef if there is no query string
    return undef unless $uri->query;

    my %qs = $uri->query_form;

    # Return undef if the id is not in the query string
    return undef unless exists $qs{$id};

    my $variation = $qs{$id};

    # Return undef if the variation is not defined or not a digit
    return undef unless defined $variation && $variation =~ /^\d+$/;

    my $var_id = int($variation);

    # Return undef if the variation id is out of range
    return undef if $var_id < 0 || $var_id >= $num_variations;

    return $var_id;
}

sub get_equal_weights {
    my ($num_variations) = @_;
    return [] if $num_variations < 1;
    my $weight = 1 / $num_variations;
    return [($weight) x $num_variations];
}

sub get_bucket_ranges {
    my ($num_variations, $coverage, $weights) = @_;
    $coverage //= 1;
    $weights //= get_equal_weights($num_variations);

    if ($coverage < 0) {
        $coverage = 0;
    }
    if ($coverage > 1) {
        $coverage = 1;
    }
    if (@$weights != $num_variations) {
        $weights = get_equal_weights($num_variations);
    }
    if (sum(@$weights) < 0.99 || sum(@$weights) > 1.01) {
        $weights = get_equal_weights($num_variations);
    }

    my $cumulative = 0;
    my @ranges;
    foreach my $w (@$weights) {
        my $start = $cumulative;
        $cumulative += $w;
        push @ranges, [$start, $start + $coverage * $w];
    }

    return \@ranges;
}

sub choose_variation {
    my ($n, $ranges) = @_;
    for (my $i = 0; $i < @$ranges; $i++) {
        if (in_range($n, $ranges->[$i])) {
            return $i;
        }
    }
    return -1;
}

sub adjust_args_camel_to_snake {
    my ($args) = @_;
    for my $key (keys %$args) {
        my $snake_key = decamelize($key);
        if ($key eq $snake_key) {
            next;
        }
        $args->{$snake_key} = delete $args->{$key};
    }
}

sub in_namespace {
    my ($user_id, $namespace) = @_;
    my $n = gbhash("__" . $namespace->[0], $user_id, 1);
    return 0 unless defined $n;
    return $namespace->[1] <= $n && $n < $namespace->[2];
}
1;
