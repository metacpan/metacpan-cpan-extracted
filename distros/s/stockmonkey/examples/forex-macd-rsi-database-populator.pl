#!/usr/bin/perl

use warnings;  # if you don't use warnings and use strict, you're going to miss bugs!!
use strict;

use MySQL::Easy;
use DBD::SQLite;
use Math::Business::RSI;
use Math::Business::MACD;
use WWW::Mechanize;
use JSON; # go ahead and use JSON::XS if it's there (SO FAST) or PP only as a last resort

MAIN: {
    my $dbo = MySQL::Easy->new('scratch');
    $dbo->do("drop table if exists blarg");
    $dbo->do("create table blarg(d datetime not null, symbol varchar(10) not null, price double, rsi double, macd double, trig double, hist double)");
    my $sth = $dbo->ready("insert into blarg set d=from_unixtime(?), symbol=?, price=?, rsi=?, macd=?, trig=?, hist=?") or die $dbo->errstr;

    grab_data($sth, "http://api.apirates.com/api/history/M1");
}

sub grab_data {
    my $sth = shift;
    my $url = shift;
    my $mech = WWW::Mechanize->new;
    my ($key) = $url =~ m/(M\d+)$/; # no need to pass this in, we can get it from the url

    # NOTE: no reason to surround this in evals unless you *want* to miss errors

    $mech->get( $url );
    
    my $struct = decode_json( $mech->content );

    # use super descriptive variable names for readability
    my %all_tickers_from_all_periods;

    # we're going to go through the data twice, first just to see what's there
    # and then next to build the actual macd data
    for my $data (@{ $struct->{$key} }) {

        # this is all the tickers from this element in the $key array, that aren't time related
        my @keys = grep { $_ !~ m/time/ } keys %$data;

        # make sure we have an entry in the hash for every ticker for this period
        # this is a confusing operation called a hash slice.

        @all_tickers_from_all_periods{ @keys } = (); 
        # it's roughly equiv to    $hash{$_} = undef for @keys;
        # but faster and clearer (if you know perl)

        # if you wonder if this is right... check:
        # use Data::Dumper; die "this right?: " . Dumper(\%all_tickers_from_all_periods);
    }

    my @all_the_relevant_symbols = sort keys %all_tickers_from_all_periods;
    my %objects;

    # be super sure the data is in time order by sorting on that key
    for my $data (sort { $a->{timestamp} <=> $b->{timestamp} } @{ $struct->{$key} }) {
        my $time = $data->{timestamp};

        for my $sym (@all_the_relevant_symbols) {
            # only create objects if they're not already defined
            $objects{$sym}{macd} //= Math::Business::MACD->recommended;
            $objects{$sym}{rsi} //= Math::Business::RSI->recommended;

            my $price = $data->{$sym};

            $objects{$sym}{macd}->insert( $price );
            $objects{$sym}{rsi}->insert( $price );

            my @values = ($time,$sym,$price,
                $objects{$sym}{rsi}->query            // undef,
                $objects{$sym}{macd}->query           // undef,
                $objects{$sym}{macd}->query_trig_ema  // undef,
                $objects{$sym}{macd}->query_histogram // undef
            );

            $sth->execute( @values );
        }
    }
}

