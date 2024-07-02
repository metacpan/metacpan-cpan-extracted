#!/usr/bin/env perl

use v5.38;
use strict;
use warnings;

use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Tradestie::WSBetsAPI;

# Date Formatter properly formats the date to pass to the functions
my $date_formatter = Tradestie::WSBetsAPI->new;

# Parameters: Month(mm), Day(dd), Year(yyyy)
# Pass dates that falls on days that the Market is open (i.e. Monday through Friday)
# If the date is invalid then the defaulted date will be used 11/17/2022
# The proper format(yyyy-mm-dd): 2022-11-17
my $date = $date_formatter->date_formatter('01', '26', '2024');
print $date; # Output: "2024-01-26"

# Reddit Endpoint
# No date is set by default
my $reddit = Tradestie::WSBetsAPI->new;

my @list = $reddit->reddit; 
foreach my $reddit ( @list ) {
    print "Number of comments: " . $reddit->no_of_comments . "\n";
    print "Sentiment: " . $reddit->sentiment . "\n";
    print "Sentiment Score: " . $reddit->sentiment_score . "\n";
    print "Ticker: " . $reddit->ticker . "\n";
}

# A date can be set using the date formatter
@list = $reddit->reddit($date); 
foreach my $reddit ( @list ) {
    print "Number of Comments: " . $reddit->no_of_comments . "\n";
    print "Sentiment: " . $reddit->sentiment . "\n";
    print "Sentiment Score: " . $reddit->sentiment_score . "\n";
    print "Ticker: " . $reddit->ticker . "\n";
}

# TTM Squeeze Stocks Endpoint
# Default date is set to 11/17/2022
my $ttm = Tradestie::WSBetsAPI->new;

@list = $ttm->ttm_squeeze_stocks;
foreach my $ttm ( @list ) {
    print "Date: " . $ttm->date . "\n";
    print "In the Squeeze: " . $ttm->in_squeeze . "\n";
    print "Number of Days In the Squeeze: " . $ttm->no_of_days_in_squeeze . "\n";
    print "Number of Days Out of the Squeeze: " . $ttm->no_of_days_out_of_squeeze . "\n";
    print "Out of the Squeeze: " . $ttm->out_of_squeeze . "\n";
    print "Ticker: " . $ttm->ticker . "\n";
}

# A date can be set using the date formatter
@list = $ttm->ttm_squeeze_stocks($date);
foreach my $ttm ( @list ) {
    print "Date: " . $ttm->date . "\n";
    print "In the Squeeze: " . $ttm->in_squeeze . "\n";
    print "Number of Days In the Squeeze: " . $ttm->no_of_days_in_squeeze . "\n";
    print "Number of Days Out of the Squeeze: " . $ttm->no_of_days_out_of_squeeze . "\n";
    print "Out of the Squeeze: " . $ttm->out_of_squeeze . "\n";
    print "Ticker: " . $ttm->ticker . "\n";
}