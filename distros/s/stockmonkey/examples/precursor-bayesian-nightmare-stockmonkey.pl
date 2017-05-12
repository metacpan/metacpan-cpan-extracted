#!/usr/bin/perl

use strict;
use warnings;
use Finance::QuoteHist;
use Storable qw(freeze thaw);
use Math::Business::RSI;
use Math::Business::LaguerreFilter;
use Math::Business::BollingerBands;
use Math::Business::ConnorRSI;
use Math::Business::ADX;
use MySQL::Easy;
use Date::Manip;
use Algorithm::NaiveBayes;
use List::Util qw(min max sum);
use GD::Graph::lines;
use GD::Graph::Hooks;

my $dbo     = MySQL::Easy->new("scratch"); # reads .my.cnf for password and host
my @tickers = split(m/[^A-Z]/, shift || "JPM,SCTY,P,TSLA,ATVI,HIMX,ZNGA,BEARX");
my $phist   = shift || 180; # final plot history items
my $slurpp  = "10 years"; # data we want to fetch
my @proj    = map {[map {int $_} split m{/}]} @ARGV; # projections

# proj is a list of projections to consider, days/percent
@proj = (
    [10,3],[10,5],[10,10],
    [20,3],[20,5],[20,10],
);

if( $ENV{NEWK} ) {
    $dbo->do("drop table if exists stockplop");
    $dbo->do("drop table if exists stockplop_annotations");
    $dbo->do("drop table if exists stockplop_glaciers");
}

find_quotes_for()      unless $ENV{NO_FETCH};
annotate_all_tickers() unless $ENV{NO_ANNOTATE};
plot_result();

# {{{ sub find_quotes_for
sub find_quotes_for {
    for my $ticker (@tickers) {
        my $lf   = Math::Business::LaguerreFilter->new(2/(1+4));
        my $ls   = Math::Business::LaguerreFilter->new(2/(1+8));
        my $bb   = Math::Business::BollingerBands->recommended;
        my $crsi = Math::Business::ConnorRSI->recommended;
        my $adx  = Math::Business::ADX->recommended;
        my $rsi  = Math::Business::RSI->recommended;

        # NOTE: if you add to indicies, you probably need to 'newk'
        my @indicies = ($lf, $ls, $crsi, $rsi, $bb, $adx);
        my %picky_insert = (
            $adx->tag => sub {
                my ($open, $high, $low, $close, $volume) = @_;
                $adx->insert([$high, $low, $close]); # curry picky inserts
            }
        );

        my %has_multi_column_output = ( $bb->tag => 1 );
        my $time = $slurpp;

        # {{{ SCHEMA:
        SCHEMA: {
            my @moar_columns;
            for( @indicies ) {
                my $tag  = $_->tag;
                my $type = $has_multi_column_output{$tag} ? "varchar(50)" : "decimal(6,4)";

                push @moar_columns, "`$tag` $type,";
            }

            $dbo->do("create table if not exists stockplop(
                rowid int unsigned not null auto_increment primary key,
                seqno int not null default '0',

                ticker  char(5) not null,
                qtime   date not null,
                open    decimal(6,2) unsigned not null,
                high    decimal(6,2) unsigned not null,
                low     decimal(6,2) unsigned not null,
                close   decimal(6,2) unsigned not null,
                volume  int unsigned not null,

                @moar_columns

                unique(ticker,qtime),
                index(ticker,seqno)
            )");

            $dbo->do("create table if not exists stockplop_glaciers(
                ticker  char(5) not null,
                last_qtime date not null,
                tag varchar(30) not null,

                glacier blob,

                primary key(ticker,last_qtime,tag)
            )");
        }

        # }}}

        if( my @fv = grep {defined} $dbo->firstrow("select date_add(max(qtime), interval 1 day),
            max(qtime)=now(), max(qtime) from stockplop where ticker=?", $ticker) ) {

            if( $fv[1] ) {
                print "no quotes to fetch\n";
                return;
            }

            # fetch time
            $time = $fv[0];

            # we can resurrect the indexes
            my $sth = $dbo->ready("select glacier from stockplop_glaciers where ticker=? and last_qtime=? and tag=?");

            print "found rows ending with $fv[2].  setting start time to $time and trying to thaw glaciers\n";

            for( @indicies ) {
                $sth->execute($ticker, $fv[2], $_->tag);
                $sth->bind_columns(\my $glacier);
                if ( $sth->fetch ) {
                    $_ = thaw($glacier);
                    my $t = $_->tag;
                    my @r = $_->query;
                    print "thawed $t from $time: @r\n";
                }
            }

        } else {
            $time = "$time ago";
        }

        die "fatal start_date parse error" unless $time;

        my $q = Finance::QuoteHist->new(
            symbols    => [$ticker],
            start_date => $time,
            end_date   => $ENV{END_DATE_FOR_FQ}||"today",
        );

        print "fetched quotes\n";

        my $ins;
        PREPARE: {
            my @columns = ("ticker=?, qtime=?, open=?, high=?, low=?, close=?, volume=?");
            for(@indicies) {
                my $t = $_->tag;
                push @columns, "`$t`=?";
            }

            $ins = $dbo->ready("insert ignore into stockplop set " . join(", ", @columns));
        }

        print "processing rows\n";

        my $last_qtime;
        my @todump;
        for my $row ($q->quotes) {
            my ($symbol, $date, $open, $high, $low, $close, $volume) = @$row;

            next unless $date = ParseDate($date);
            $date = UnixDate($date, '%Y-%m-%d');

            my @data = ($symbol, $date, $open, $high, $low, $close, $volume);
            for(@indicies) {
                my $t = $_->tag;
                if( exists $picky_insert{$t} ) {
                    $picky_insert{$t}->($open, $high, $low, $close, $volume);

                } else {
                    $_->insert($close);
                }

                my $r;
                if( $has_multi_column_output{$t} ) {
                    my @r = $_->query;
                    $r = join("/", map {defined()?sprintf('%0.4f', $_):'-'} @r);

                } else {
                    $r = $_->query;
                }

                push @data, $r;
            }

            $ins->execute(@data);

            $last_qtime = $date;
        }

        $dbo->do('select @Q:=-1');
        $dbo->do('update stockplop set seqno=(@Q:=@Q+1) where ticker=? order by qtime asc', $ticker);

        if( $last_qtime ) {
            my $freezer = $dbo->ready("replace into stockplop_glaciers set ticker=?, last_qtime=?, tag=?, glacier=?");

            for( @indicies ) {
                my $t = $_->tag;
                print "saving $t as of $last_qtime\n";

                $freezer->execute($ticker, $last_qtime, $t, freeze($_));
            }
        }

        my @row = $dbo->firstrow("select count(*), min(qtime), max(qtime) from stockplop where ticker=?", $ticker);
        print "fetched $ticker: @row\n";

    }

    exit 0 if $ENV{ONLY_FETCH};
}

# }}}
# {{{ sub annotate_ticker
sub annotate_all_tickers {
    my @projections;

    # BUILD DATABSES

    SCHEMA: {
        for( @proj ) {
            next unless $_->[0] > 0 && $_->[1] > 0; # ignore stupid projections

            my $f = "$_->[0]_$_->[1]";
            push @projections, "
                p${f} decimal(6,6) unsigned,
                m${f} decimal(6,6) unsigned,
            ";
        }

        $dbo->do("drop table if exists stockplop_annotations");
        $dbo->do(qq^create table stockplop_annotations(
            rowid int unsigned not null,

            @projections

            description text not null,

            primary key(rowid)
        )^);
    }

    my $keep     = max(map($_->[0], @proj)); my %uniq;
    my @proj_ud  = grep {!$uniq{$_->[0]}++} @proj;
    my $sql_cols = join(", ", map {"t$_->[0].close t$_->[0]_close, t$_->[0].rowid t$_->[0]_rowid"} @proj_ud);
    my @sql_join = map {"join t$_->[0] using (seqno)"} @proj_ud;

    my $ins = $dbo->ready("insert into stockplop_annotations set rowid=?, description=?");
    my $sth = $dbo->ready(my $cross_product_sql =
        "select stockplop.*, $sql_cols from stockplop @sql_join where ticker=?");

    # DESCRIBE SITUATIONS WITH TECHNICAL ANALYSIS

    for my $ticker ($dbo->firstcol("select distinct(ticker) from stockplop")) {
        print "\nannotating $ticker\n";

        my %instance_history;

        for(@proj_ud) {
            print "creating temporary table t$_->[0]\n";
            $dbo->do("drop table if exists t$_->[0]");
            $dbo->do("create temporary table t$_->[0]
                select (seqno-$_->[0])seqno,qtime,close,rowid
                    from (select seqno,qtime,close,rowid from stockplop where ticker=? and seqno>$_->[0]
                        order by qtime desc)
                            the_future
            order by qtime asc", $ticker);
        }

        my $t = $cross_product_sql;
        $t =~ s{\?}{'$ticker'};
        print "executing fetch ($t)\n";
        $sth->execute($ticker);

        print "analyzing result rows\n";

        my @events;
        my %events;
        my @last;
        while( my $row = $sth->fetchrow_hashref ) {
            if( defined (my $rsi = $row->{'RSI(27)'}) ) {
                for (90,80,70) { $events{"rsi_$_"} = 1 if $rsi >= $_ }
                for (10,20,30) { $events{"rsi_$_"} = 1 if $rsi <= $_ }
            }

            if( defined (my $rsi = $row->{'CRSI(3,2,100)'}) ) {
                for (90,80,70) { $events{"crsi_$_"} = 1 if $rsi >= $_ }
                for (10,20,30) { $events{"crsi_$_"} = 1 if $rsi <= $_ }
            }

            if( defined (my $adx = $row->{'ADX(14)'}) ) {
                $adx = int(100 * $adx);
                for (10, 20, 30, 40, 50) { $events{"adx_$_"} = 1 if $adx >= $_ }
            }

            if( defined ( my $bbs = $row->{'BOLL(2,20)'}) ) {
                my ($L, $M, $U) = map {$_ eq "-" ? undef : (0.0+$_)} split m{/}, $bbs;
                if( defined $L and defined $M and defined $U ) {
                    $events{boll_overbought} = 1 if $row->{close} >= $U;
                    $events{boll_oversold}   = 1 if $row->{close} <= $L;
                }
            }

            if( @last ) {
                if( defined $last[-1]{"LAG(8)"} and defined $last[-1]{"LAG(4)"} ) {
                    $events{lag_break_up} = 1
                        if $last[-1]{'LAG(4)'} < $last[-1]{"LAG(8)"} and $row->{'LAG(4)'} > $row->{"LAG(8)"};

                    $events{lag_break_down} = 1
                        if $last[-1]{'LAG(4)'} > $last[-1]{"LAG(8)"} and $row->{'LAG(4)'} < $row->{"LAG(8)"};
                }

                for( 10, 20, 30 ) {
                    $events{rsi_up}    = 1 if     $events[-1]{"rsi_$_"}  and not $events{"rsi_$_"};
                    $events{rsi_down}  = 1 if not $events[-1]{"rsi_$_"}  and     $events{"rsi_$_"};
                    $events{crsi_up}   = 1 if     $events[-1]{"crsi_$_"} and not $events{"crsi_$_"};
                    $events{crsi_down} = 1 if not $events[-1]{"crsi_$_"} and     $events{"crsi_$_"};
                }

                for( 90, 80, 70 ) {
                    $events{rsi_up}    = 1 if not $events[-1]{"rsi_$_"}  and     $events{"rsi_$_"};
                    $events{rsi_down}  = 1 if     $events[-1]{"rsi_$_"}  and not $events{"rsi_$_"};
                    $events{crsi_up}   = 1 if not $events[-1]{"crsi_$_"} and     $events{"crsi_$_"};
                    $events{crsi_down} = 1 if     $events[-1]{"crsi_$_"} and not $events{"crsi_$_"};
                }

                for (10, 20, 30, 40, 50) {
                    $events{adx_up}   = 1 if not $events[-1]{"adx_$_"} and     $events{"adx_$_"};
                    $events{adx_down} = 1 if     $events[-1]{"adx_$_"} and not $events{"adx_$_"};
                }


                # TODO:
                # - other concepts like: we had a lag break and there was an rsi break x days ago
                # - looking for divergences in the various indexes would go here
                # - support levels on closing prices goes here
            }

            my @desc = sort keys %events;
            $ins->execute($row->{rowid}, "@desc");

            # train using items from @last, far enough back to avoid data snooping bias
            for(@proj) {
                my ($days, $percent) = @$_;
                if( @last >= $days ) {
                    my $_row = $last[-$days]   || die "bad maths";
                    my $_ev  = $events[-$days] || die "bad maths";

                    if( keys %$_ev ) {
                        if( $row->{close} >= $_row->{close} * (1 + ($percent/100)) ) {
                            my %d = (attributes=>$_ev, label=>my $l = "p$_->[0]_$_->[1]");
                            push @{$instance_history{$l}}, \%d;
                        }

                        elsif( $row->{close} <= $_row->{close} * (1 - ($percent/100)) ) {
                            my %d = (attributes=>$_ev, label=>my $l = "m$_->[0]_$_->[1]");
                            push @{$instance_history{$l}}, \%d;
                        }
                    }
                }
            }

            eval {
                # NOTE: This is a stupid way to do this.  We should have one
                # object that we feed more corpus data to on each iteration,
                # but the module can't handle training on each loop and ends up
                # crashing all the time because there aren't enough instance
                # items, causing division by 0 and log of 0 errors.
                #
                # ... so, since the module has no internal handlers for this
                # sort of thing I build a new object on every loop and
                # add_instance for everything we have so far to the new object.
                #
                # ... it's a dumb work around.  Don't copy this example.
                # 
                # slow, wrong, awful, slow, wrong, awful

                my $anb = Algorithm::NaiveBayes->new;

                for my $v (map {@$_} values %instance_history) {
                    $anb->add_instance(%$v);
                }

                $anb->train;

                # predict from here into the future
                if( my $result = eval {$anb->predict(attributes=>\%events)} ) {
                    my (@f, @v);
                    for my $k (keys %$result) {
                        push @f, "$k=?";         # $k is (eg) p12_20 or 20% increase in 12 days
                        push @v, $result->{$k};  # or maybe (eg) m5_7, a 5% decrease in 7 days
                    }

                    if( @f ) {
                        # TODO: this could maybe be prepared earlier, rather than built/executed for every row
                        local $" = ", ";
                        $dbo->do("update stockplop_annotations set @f where rowid=?", @v, $row->{rowid});
                        local $| = 1;
                        our $spin;
                        my $s = (qw(- \ | /))[ (++$spin)%4 ];
                        print "\r$s";
                    }
                }
            };

            push @last, $row;
            push @events, {%events};
            shift @last   if @last > $keep;
            shift @events if @events > $keep;
            %events = ();
        }
        print "\n";
    }
}

# }}}
# {{{ sub plot_result
sub plot_result {
    print "\nplot results\n";

    @proj = sort {
           ($b->[0] <=> $a->[0])           # first,  draw longer predictions first
        || (abs($b->[1]) <=> abs($b->[1])) # second, draw taller predictions first
    } @proj;

    my @sql_cols = map {("p$_", "m$_")} map {"$_->[0]_$_->[1]"} @proj;
    my $sql_cols = join(", ", @sql_cols);
    my $sth = $dbo->ready("select * from (select seqno-1 idx,qtime,close, $sql_cols
        from stockplop join stockplop_annotations using(rowid)
        where ticker=? order by seqno desc limit ?) blarg order by qtime");

    TICKER:
    for my $ticker ($dbo->firstcol("select distinct(ticker) from stockplop")) {
        print "plotting $ticker\n";

        $sth->execute($ticker, $phist);
        my @data;
        my @lines;
        my $mincolor = 0x77;

        ROW:
        while( my $row = $sth->fetchrow_hashref ) {
            # use Data::Dump qw(dump);
            # die dump($row);
            # {
            #     close  => 36.78,
            #     m12_20 => 0,
            #     m5_5   => 0,
            #     p12_20 => 0,
            #     p5_5   => 0,
            #     qtime  => "2003-10-14",
            #     idx    => 0,
            # }

            my $r = 0;

            push @{ $data[$r++] }, $row->{qtime};
            push @{ $data[$r++] }, $row->{close};

            my $_days = 0;
            my $_val  = 0;
            my $_str  = 0;
            for my $c (@sql_cols) {
                my ($dir,$days,$percent) = $c =~ m/([pm])(\d+)_(\d+)/;
                my $probability = $row->{$c};
                next ROW unless defined $probability;
                my $val = $row->{close} * ($dir eq "p" ? 1+($percent/100) : 1-($percent/100));

                $_days += $days * $probability;
                $_val  += $val  * $probability;
                $_str  += $probability;
            }

            $_days /= $_str;
            $_val  /= $_str;

            push @lines, {
                str => $_str,
                lhs => [ @{$data[0]}+0, $row->{close} ], # val_to_pixel is (1..) not (0..)
                rhs => [ @{$data[0]}+$_days, $_val ],
            }

            if abs($_val-$row->{close})/$row->{close} > 0.01;

        }

        my $max_pro = max( map{$_->[0]} @proj );
        for( 1 .. $max_pro ) {
            push @{$data[0]}, "+$_";
        }

        my @d = grep {defined} map {@$_} @data[1..$#data];
        my @p = grep {defined} map {($_->{lhs}[1], $_->{rhs}[1])} @lines;

        my $min_point = min( @d,@p );
        my $max_point = max( @d,@p );

        my $width = 100 + 11*@{$data[0]};

        my $graph = GD::Graph::lines->new($width, 500);
           $graph->set_legend(qw(close prediction));
           $graph->set(
               y_label           => "dollars $ticker",
               x_label           => 'date',
               transparent       => 0,
               dclrs             => [qw(dblue lgray)],
               y_min_value       => $min_point-0.2,
               y_max_value       => $max_point+0.2,
               y_number_format   => '%6.2f',
               x_labels_vertical => 1,

           ) or die $graph->error;

        $graph->add_hook( GD::Graph::Hooks::PRE_DATA => sub {
            my ($gobj, $gd, $left, $right, $top, $bottom, $gdta_x_axis) = @_;

            my $clr = $gobj->set_clr(0xaa, 0xaa, 0xaa);

            for my $line (@lines) {
                my @lhs = $gobj->val_to_pixel(@{ $line->{lhs} });
                my @rhs = $gobj->val_to_pixel(@{ $line->{rhs} });

                $gd->line(@lhs,@rhs,$clr);
            }
        });

        my $gd = $graph->plot(\@data) or die $graph->error;

        my $fname = "/tmp/$ticker-bn.png";
        open my $img, '>', $fname or die $!;
        binmode $img;
        print $img $gd->png;
        close $img;

        system(eog => $fname);
    }
}

# }}}
