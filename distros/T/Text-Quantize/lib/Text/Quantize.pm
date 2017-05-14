package Text::Quantize;
# ABSTRACT: render a list of numbers as a textual chart
use strict;
use warnings;
use List::Util 'sum';
use Sub::Exporter -setup => {
    exports => ['quantize', 'bucketize'],
    groups  => {
        default => ['quantize'],
    },
};

sub bucketize {
    my $elements = shift;
    my $options  = {
        add_endpoints => 1,
        %{ shift(@_) || {} },
    };

    my %buckets;
    for my $element (@$elements) {
        my $bucket;

        if ($element == 0) {
            $bucket = 0;
        }
        elsif ($element < 0) {
            # log(negative) is an error, so take the log of the absolute value then negate it
            $bucket = -1 * (2 ** int(log(-$element) / log(2)));
        }
        else {
            # which power of 2 is this greater-than-or-equal to?
            $bucket = 2 ** int(log($element) / log(2));
        }

        $buckets{$bucket}++;
    }

    # allow user to specify only one of the two endpoints if desired, and figure the other out
    if ($options->{add_endpoints}) {
        unless (defined($options->{minimum}) && defined($options->{maximum})) {
            my ($min, $max) = _endpoints_for(\%buckets);
            $options->{minimum} = $min if !defined($options->{minimum});
            $options->{maximum} = $max if !defined($options->{maximum});
        }
    }

    # if add_endpoints, then use the expanded range that we calculated or the user specified
    # otherwise, start at the first bucket with data and go until the last bucket with data
    my ($start, $end) = $options->{add_endpoints}
                      ? ($options->{minimum}, $options->{maximum})
                      : (sort { $a <=> $b } keys %buckets)[0,-1];

    # force every bucket in the range to exist
    my $i = $start;
    while ($i <= $end) {
        $buckets{$i} ||= 0;
        if ($i == 0) {
            $i = 1;
        }
        elsif ($i == -1) {
            $i = 0;
        }
        elsif ($i < 0) {
            $i /= 2; # since we're negative, increasing means smaller numbers
        }
        else {
            $i *= 2;
        }
    }
    return \%buckets;
}

sub quantize {
    my $elements = shift;
    my %options  = (
        distribution_width     => 40,
        distribution_character => '@',
        left_label             => 'value',
        middle_label           => 'Distribution',
        right_label            => 'count',
        %{ shift(@_) || {} },
    );

    my $buckets = bucketize($elements, \%options);

    # pull these out because we consult them a lot, and in loops
    my $distribution_width     = $options{distribution_width};
    my $distribution_character = $options{distribution_character};

    # the divisor deciding how wide each bucket's bar will be
    my $sum = sum values %$buckets;

    # how wide must the first column (with the left_label and values) be?
    my $left_width = length($options{left_label});
    for my $bucket (keys %$buckets) {
        $left_width = length($bucket)
            if length($bucket) > $left_width;
    }
    # add that extra space before every row
    $left_width++;

    # how many - characters do we need?
    my $middle_spacer = $distribution_width - length($options{middle_label}) - 2;

    # these will be different when $middle_spacer is odd, but we
    # always want them to sum to $middle_spacer.
    my $middle_left = int($middle_spacer / 2);
    my $middle_right = $middle_spacer - $middle_left;

    my @output = sprintf '%*s  %s %s %s %s',
        $left_width,
        $options{left_label},
        ('-' x $middle_left),
        $options{middle_label},
        ('-' x $middle_right),
        $options{right_label};

    for my $bucket (sort { $a <=> $b } keys %$buckets) {
        my $count = $buckets->{$bucket};
        my $ratio = ($count / $sum);
        my $width = $distribution_width * $ratio;

        push @output, sprintf '%*d |%-*s %d',
            $left_width,
            $bucket,
            $distribution_width,
            ($distribution_character x $width),
            $count;
    }

    return wantarray ? @output : (join "\n", @output)."\n";
}

# given a set of buckets, find the power of two smaller than the
# smallest element, and the power of two greater than or equal to the
# largest element. used for add_endpoints
sub _endpoints_for {
    my $buckets = shift;
    my ($min_endpoint, $max_endpoint);

    my @sorted_buckets = (sort { $a <=> $b } keys %$buckets);
    my ($min, $max) = @sorted_buckets[0, -1];

    if ($min == 0) {
        $min_endpoint = -1;
    }
    elsif ($min == 1) {
        $min_endpoint = 0;
    }
    elsif ($min < 0) {
        $min_endpoint = -1 * (2 ** (int(log(-$min) / log(2)) + 1));
    }
    else {
        $min_endpoint = 2 ** (int(log($min) / log(2)) - 1);
    }

    if ($max == 0) {
        $max_endpoint = 1;
    }
    elsif ($max == -1) {
        $max_endpoint = 0;
    }
    elsif ($max < 0) {
        $max_endpoint = -1 * (2 ** (int(log(-$max) / log(2)) - 1));
    }
    else {
        $max_endpoint = 2 ** (int(log($max) / log(2)) + 1);
    }

    return ($min_endpoint, $max_endpoint);
}

1;



=pod

=head1 NAME

Text::Quantize - render a list of numbers as a textual chart

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    use Text::Quantize;
    
    print quantize([26, 24, 51, 77, 21]);
    
    __END__
    
     value  ------------- Distribution ------------- count
         8 |                                         0
        16 |@@@@@@@@@@@@@@@@@@@@@@@@                 3
        32 |@@@@@@@@                                 1
        64 |@@@@@@@@                                 1
       128 |                                         0

=head1 FUSSY SYNOPSIS

    use Text::Quantize ();

    print Text::Quantize::quantize([map { chomp; $_ } <DATA>], {
        left_label             => 'microseconds',
        middle_label           => 'Calls per time bucket',
        right_label            => 'syscalls',
        distribution_width     => 80,
        distribution_character => '=',
    });
    
    __END__
    
     microseconds  ---------------------------- Calls per time bucket ----------------------------- syscalls
              256 |                                                                                 0
              512 |====                                                                             5
             1024 |=====                                                                            7
             2048 |==================                                                               23
             4096 |============================                                                     36
             8192 |=======                                                                          9
            16384 |=                                                                                2
            32768 |                                                                                 1
           262144 |                                                                                 1
           524288 |                                                                                 1
          1048576 |                                                                                 1
          2097152 |=======                                                                          9
          4194304 |===                                                                              4
          8388608 |                                                                                 1
         16777216 |                                                                                 0

=head1 FUNCTIONS

=head2 C<quantize([integers], {options})>

C<quantize> takes an array reference of integers and an optional
hash reference of options, and produces a textual histogram of the
integers bucketed into powers-of-2 sets.

Options include:

=over 4

=item C<left_label> (default: C<value>)

Controls the text of the left-most label which represents the
bucket's contents.

=item C<middle_label> (default: C<Distribution>)

Controls the text of the middle label which can be used to title
the histogram.

=item C<right_label> (default: C<count>)

Controls the text of the right-most label which represents how many
items are in that bucket.

=item C<distribution_width> (default: C<40>)

Controls how many characters wide the textual histogram is. This
does not include the legends.

=item C<distribution_character> (default: C<@>)

Controls the character used to represent the data in the histogram.

=item C<add_endpoints> (default: C<1>)

Controls whether the top and bottom lines (which are going to have
values of 0) are added. They're included by default because it hints
that the data set is complete.

=back

=head2 C<bucketize([integers], {options})>

C<bucketize> takes an array reference of integers and an optional
hash reference of options, and produces a hash reference of those
integers bucketed into powers-of-2 sets.

Options include:

=over 4

=item add_endpoints (default: C<1>)

Controls whether extra buckets, smaller than the minimum value and
larger than the maximum value, (which are going to have values of
0) are added. They're included by default because it hints that the
data set is complete.

=back

=head1 SEE ALSO

C<DTrace>, which is where I first saw this kind of C<quantize()>
histogram.

L<dip>, which ported C<quantize()> to Perl first, and from which I
took a few insights.

=head1 AUTHOR

Shawn M Moore <code@sartak.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


