#!/usr/bin/perl

use strict;
use warnings;
use Finance::QuoteHist;
use Storable qw(store retrieve);
use Math::Business::RSI;
use Math::Business::LaguerreFilter;
use Data::Dump qw(dump);
use GD::Graph::lines;
use GD::Graph::Hooks;
use List::Util qw(min max);

my $ticker = shift || "SCTY";
my $phist  = shift || 150; # final plot history items
my $lagf   = shift || 4;   # speed of fast laguerre filter
my $lags   = shift || 8;   # speed of slow laguerre filter
my $slurpp = "10 years"; # data we want to fetch
my $quotes = find_quotes_for($ticker=>$slurpp);

scan_for_events();
plot_result();

# {{{ sub scan_for_events
sub scan_for_events {
    my $last_row = $quotes->[0];

    print "\n-------: scanning for events:\n";

    for my $row ( @$quotes[1..$#$quotes] ) {

        if( exists $last_row->{event} ) {
            if( not exists $last_row->{max_age} ) {
                $row->{event}   = $last_row->{event};
                $row->{age}     = 1 + $last_row->{age};

            } elsif( $last_row->{age} < $last_row->{max_age} ) {
                $row->{event}   = $last_row->{event};
                $row->{age}     = 1 + $last_row->{age};
                $row->{max_age} = $last_row->{max_age};
            }
        }

        if( $last_row->{rsi} < 70 and $row->{rsi} >= 70 ) {
            $row->{event} = "OVERBOUGHT";
            $row->{age} = 1;
            delete $row->{max_age};
            print "$row->{event} ";
        }

        if( $last_row->{rsi} > 30 and $row->{rsi} <= 30 ) {
            $row->{event} = "OVERSOLD";
            $row->{age} = 1;
            delete $row->{max_age};
            print "$row->{event} ";
        }

        next unless exists $row->{event};

        if( $row->{event} eq "OVERBOUGHT" and $last_row->{rsi} > 60 and $row->{rsi} <= 60 ) {
            $row->{event}   = "DIP";
            $row->{age}     = 1;
            $row->{max_age} = 5;
            print "$row->{event} ";
        }

        elsif ( $row->{event} eq "OVERSOLD" and $last_row->{rsi} < 40 and $row->{rsi} >= 40 ) {
            $row->{event}   = "SPIKE";
            $row->{age}     = 1;
            $row->{max_age} = 5;
            print "$row->{event} ";
        }

        if( $row->{event} eq "DIP" and $row->{lagf} < $row->{lags} ) {
            $row->{event}   = "SELL";
            $row->{age}     = 1;
            $row->{max_age} = 1;
            print "!$row->{event}! ";
        }

        elsif( $row->{event} eq "SPIKE" and $row->{lagf} > $row->{lags} ) {
            $row->{event}   = "BUY";
            $row->{age}     = 1;
            $row->{max_age} = 1;
            print "!$row->{event}! ";
        }

        $last_row = $row;
    }

    print "\n\n";
}

# }}}
# {{{ sub find_quotes_for
sub find_quotes_for {
    our $rsi  ||= Math::Business::RSI->recommended;
    our $lf   ||= Math::Business::LaguerreFilter->new(2/(1+$lagf));
    our $ls   ||= Math::Business::LaguerreFilter->new(2/(1+$lags));

    my $tick = uc(shift || "SCTY");
    my $time = lc(shift || "6 months");
    my $fnam = "/tmp/p2-$tick-$time-$lagf-$lags.dat";

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
        $lf->insert( $close );
        $ls->insert( $close );

        my $row = {
            date  => $date,
            close => $close,
            rsi   => $rsi->query,
            lagf  => $lf->query,
            lags  => $ls->query,
        };

        # only insert rows that are all defined
        push @todump, $row unless grep {not defined} values %$row;
    }

    store(\@todump => $fnam);

    return \@todump;
}

# }}}
# {{{ sub plot_result
sub plot_result {
    print "-------: plotting results:\n";
    # {{{ my $gd_price = do
    my $gd_price = do {
        my @data;

        for(@$quotes[-$phist .. -1]) {
            no warnings 'uninitialized'; # most of the *_P are undefined, and that's ok! treat them as 0

            push @{ $data[0] }, ''; # $_->{date};
            push @{ $data[1] }, $_->{close};
            push @{ $data[2] }, $_->{lagf};
            push @{ $data[3] }, $_->{lags};
        }

        my $min_point = min( grep {defined} map {@$_} @data[1..$#data] );
        my $max_point = max( grep {defined} map {@$_} @data[1..$#data] );

        my $width = 100 + 11*@{$data[0]};

        my $graph = GD::Graph::lines->new($width, 500);
           $graph->set_legend(map { sprintf "%6s",$_ } qw(close lagf lags) );
           $graph->set(
               legend_placement  => 'RT',
               y_label           => "dollars $ticker",
               x_label           => '',
               transparent       => 0,
               dclrs             => [qw(dblue lblue lgreen)],
               y_min_value       => $min_point-0.2,
               y_max_value       => $max_point+0.2,
               y_number_format   => '%6.2f',
               x_labels_vertical => 1,

           ) or die $graph->error;

        $graph->add_hook( GD::Graph::Hooks::PRE_AXIS => sub {
            my ($gobj, $gd, $left, $right, $top, $bottom, $gdta_x_axis) = @_;

            $gdta_x_axis->set_align('bottom', 'center');
            my $x = 1;
            for(@$quotes[-$phist..-1]) {
                if( exists $_->{event} and $_->{age} == 1 and $_->{event} ~~ [qw(BUY SELL)]) {
                    my @lhs = $gobj->val_to_pixel($x, $_->{lagf}*($_->{event} eq "BUY" ? 0.9 : 1.1));

                    $gdta_x_axis->set_text(lc $_->{event});
                    $gdta_x_axis->draw(@lhs, 1.5707);

                    print "labeling $_->{event} on $_->{date}\n";
                }
                $x ++;
            }
        });

        # }}}

        # return gd
        $graph->plot(\@data) or die $graph->error;
    };

    # }}}
    # {{{ my $gd_rsi = do
    my $gd_rsi = do {
        my @data;

        for(@$quotes[-$phist..-1]) {
            no warnings 'uninitialized'; # most of the *_P are undefined, and that's ok! treat them as 0

            push @{ $data[0] }, $_->{date};
            push @{ $data[1] }, $_->{rsi};
        }

        my $width = 100 + 11*@{$data[0]};

        my $graph = GD::Graph::lines->new($width, 150);
           $graph->set_legend( map { sprintf "%6s", $_ } qw(rsi) );
           $graph->set(
               legend_placement  => 'RT',
               y_label           => "rsi $ticker",
               x_label           => 'date',
               transparent       => 0,
               dclrs             => [qw(dgray)],
               types             => [qw(lines)],
               y_min_value       => 0,
               y_max_value       => 100,
               y_number_format   => '%6.2f',
               x_labels_vertical => 1,

           ) or die $graph->error;

        $graph->add_hook( GD::Graph::Hooks::PRE_AXIS => sub {
            my ($gobj, $gd, $left, $right, $top, $bottom, $gdta_x_axis) = @_;

            my $rsi_axis_clr = $gobj->set_clr(0xaa,0xaa,0xaa);
                my @lhs = $gobj->val_to_pixel(1,50);
                my @rhs = $gobj->val_to_pixel( @{$data[0]}+0, 50 );
                $gd->line(@lhs,@rhs,$rsi_axis_clr);

            $rsi_axis_clr = $gobj->set_clr(0xdd,0xdd,0xdd);
                @lhs = $gobj->val_to_pixel(1,100);
                @rhs = $gobj->val_to_pixel( @{$data[0]}+0, 70 );
                $gd->filledRectangle(@lhs,@rhs,$rsi_axis_clr);

                @lhs = $gobj->val_to_pixel(1,30);
                @rhs = $gobj->val_to_pixel( @{$data[0]}+0, 0 );
                $gd->filledRectangle(@lhs,@rhs,$rsi_axis_clr);

            $gdta_x_axis->set_align('bottom', 'center');
            my $x = 1;
            for(@$quotes[-$phist..-1]) {
                if( exists $_->{event} and $_->{age} == 1 and not $_->{event} ~~ [qw(BUY SELL)]) {
                    @lhs = $gobj->val_to_pixel($x,50);

                    $gdta_x_axis->set_text(lc $_->{event});
                    $gdta_x_axis->draw(@lhs, 1.5707);

                    print "labeling $_->{event} on $_->{date}\n";
                }
                $x ++;
            }
        });

        # }}}

        $graph->plot(\@data) or die $graph->error;
    };

    # }}}

    die "something is wrong" unless $gd_price->width == $gd_rsi->width;

    my $gd = GD::Image->new( $gd_price->width, $gd_price->height + $gd_rsi->height );

    $gd->copy( $gd_price, 0,0,                 0,0, $gd_price->width, $gd_price->height);
    $gd->copy( $gd_rsi,   0,$gd_price->height, 0,0, $gd_rsi->width,   $gd_rsi->height);

    open my $img, '>', ".graph.png" or die $!;
    binmode $img;
    print $img $gd->png;
    close $img;

    system(qw(eog .graph.png));
}

# }}}
