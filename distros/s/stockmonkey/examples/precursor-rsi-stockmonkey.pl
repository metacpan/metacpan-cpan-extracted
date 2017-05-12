#!/usr/bin/perl

use strict;
use warnings;
use Finance::QuoteHist;
use Storable qw(store retrieve);
use Algorithm::NaiveBayes;
use Math::Business::RSI;
use Data::Dump qw(dump);
use GD::Graph::mixed;
use List::Util qw(min max);

my $ticker = shift || "JPM";

my $slurpp                      = "10 years"; # data we want to fetch
my $period                      = 5;          # days into the future we want to predict
my $significant_pdiff           = 0.01;       # this is a significant price jump (0.1 is 10%)
my $train_size                  = 0.80;       # use this amount of the data for training (only)
my $significant_bayesian_signal = 0.70;       # probability high enough to plot on the output graph
my $allow_neutral_signals       = 1;          # predictions are always buy or sell? or should neutral be an option

my $quotes   = find_quotes_for($ticker=>$slurpp);
my $sz       = @$quotes;
my $train_sz = int($sz * $train_size);

train_on( $period+1   .. $train_sz );
solve_on( $train_sz+1 .. $#$quotes );

plot_result();

# {{{ sub solve_on
sub solve_on {
    our $anb ||= Algorithm::NaiveBayes->new;

    for my $i( @_ ) {
        my $day  = $quotes->[$i-$period];
        my $prev = $quotes->[$i-$period-1];

        my $attrs  = find_attrs($day, $prev);
        my $result = $anb->predict(attributes=>$attrs);

        print "[predict] ", dump({given=>$attrs, result=>$result}), "\n";

        $day->{buy_p}  = $result->{buy};
        $day->{sell_p} = $result->{sell};
    }
}

# }}}
# {{{ sub train_on
sub train_on {
    our $anb ||= Algorithm::NaiveBayes->new;

    for my $i( @_ ) {
        my $future = $quotes->[$i];           # the quote we're learning about
        my $day    = $quotes->[$i-$period];   # the quote we can know about beforehand
        my $prev   = $quotes->[$i-$period-1]; # the quote the day before that

        my $attrs = find_attrs($day,$prev);

        my $diff  = $future->{close} - $day->{close};
        my $pdiff = $diff / $day->{close};

        my $label = $pdiff >=  $significant_pdiff ? "buy"
                  : $pdiff <= -$significant_pdiff ? "sell"
                  : "neutral";

        next if $label eq "neutral" and not $allow_neutral_signals;
        next unless %$attrs;

        $anb->add_instance( attributes=>$attrs, label=>$label );
        print "[train pdiff=$pdiff] ", dump($attrs), " => $label\n";
    }

    $anb->train;
}

# }}}
# {{{ sub find_attrs
sub find_attrs {
    my ($day, $prev) = @_;

    die "no rsi?? " . dump({day=>$day, prev=>$prev}) unless defined $day->{rsi};
    die "no rsi?? " . dump({day=>$day, prev=>$prev}) unless defined $prev->{rsi};

    my %attrs;

    # traditional interpretations
    $attrs{rsi_overbought} = 1 if $day->{rsi} >= 90;
    $attrs{rsi_oversold} = 1   if $day->{rsi} <= 10;
    $attrs{rsi_sell} = 1       if $day->{rsi} >= 90 and $prev->{rsi} < 90;
    $attrs{rsi_buy} = 1        if $day->{rsi} <= 10 and $prev->{rsi} > 10;
    # NOTE: if I have these backwards, it doesn't really matter, Bayes will sort that out

    # other factoids of questionable value and unknown meaning
    $attrs{rsi_above} = 1           if $day->{rsi} > 50;
    $attrs{rsi_below} = 1           if $day->{rsi} < 50;
    $attrs{rsi_moar_above} = 1      if $day->{rsi} > 65;
    $attrs{rsi_moar_below} = 1      if $day->{rsi} < 35;
    $attrs{rsi_prev_above} = 1      if $prev->{rsi} > 50;
    $attrs{rsi_prev_below} = 1      if $prev->{rsi} < 50;
    $attrs{rsi_prev_moar_above} = 1 if $prev->{rsi} > 65;
    $attrs{rsi_prev_moar_below} = 1 if $prev->{rsi} < 35;
    $attrs{rsi_trend_up}   = 1      if $day->{rsi} > $prev->{rsi};
    $attrs{rsi_trend_down} = 1      if $day->{rsi} < $prev->{rsi};

    return \%attrs;
}

# }}}
# {{{ sub find_quotes_for
sub find_quotes_for {
    our $rsi ||= Math::Business::RSI->recommended;

    my $tick = uc(shift || "MSFT");
    my $time = lc(shift || "6 months");
    my $fnam = "/tmp/p1-$tick-$time.dat";

    my $res = eval { retrieve($fnam) };
    return $res if $res;


    my $q = Finance::QuoteHist->new(
        symbols    => [$tick],
        start_date => "$time ago",
        end_date   => 'today',
    );

    my @todump;
    for my $row ($q->quotes) {
        my ($symbol, $date, $open, $high, $low, $close, $volume) = @$row;

        $rsi->insert( $close );
        my $v = $rsi->query;

        push @todump, { date=>$date, close=>$close, rsi=>$v } if defined $v;
    }

    store(\@todump => $fnam);

    return \@todump;
}

# }}}
# {{{ sub plot_result
sub plot_result {

    my @data;

    for(@$quotes[$train_sz+1 .. $#$quotes]) {
        no warnings 'uninitialized'; # most of the *_P are undefined, and that's ok! treat them as 0

        push @{ $data[0] }, $_->{date};
        push @{ $data[1] }, $_->{close};
        push @{ $data[2] }, $_->{sell_p} > $significant_bayesian_signal ? $_->{close}*0.95 : undef;
        push @{ $data[3] }, $_->{buy_p}  > $significant_bayesian_signal ? $_->{close}*1.05 : undef;
    }

    my $min_point = min( grep {defined} map {@$_} @data[1..$#data] );
    my $max_point = max( grep {defined} map {@$_} @data[1..$#data] );

    my $width = 100 + 11*@{$data[0]};

    my $graph = GD::Graph::mixed->new($width, 500);
       $graph->set_legend(qw(close sell-signal buy-signal));
       $graph->set(
           y_label           => "dollars $ticker",
           x_label           => 'date',
           transparent       => 0,
           dclrs             => [qw(dgray red green)],
           types             => [qw(lines points points)],
           y_min_value       => $min_point-0.2,
           y_max_value       => $max_point+0.2,
           y_number_format   => '%0.2f',
           x_labels_vertical => 1,

       ) or die $graph->error;

    my $gd = $graph->plot(\@data) or die $graph->error;
    open my $img, '>', ".graph.png" or die $!;
    binmode $img;
    print $img $gd->png;
    close $img;

    system(qw(eog .graph.png));
}

# }}}
