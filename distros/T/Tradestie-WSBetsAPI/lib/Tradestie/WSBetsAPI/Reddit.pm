package Tradestie::WSBetsAPI::Reddit;

# ABSTRACT: Reddit Wallstreet Bets class

use v5.38;
use strict;
use warnings;
use Moose;

has 'no_of_comments' => (
    is  => 'rw',
    isa => 'Int',
);

has 'sentiment' => (
    is  => 'rw',
    isa => 'Maybe[Str]',
);

has 'sentiment_score' => (
    is  => 'rw',
    isa => 'Maybe[Num]',
);

has 'ticker' => (
    is  => 'rw',
    isa => 'Str',
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tradestie::WSBetsAPI::Reddit - Reddit Wallstreet Bets class

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    [
        {
        "no_of_comments": 179,
        "sentiment": "Bullish",
        "sentiment_score": 0.13,
        "ticker": "GME"
        },
        {
        "no_of_comments": 37,
        "sentiment": "Bullish",
        "sentiment_score": 0.159,
        "ticker": "AMC"
        },
        {
        "no_of_comments": 17,
        "sentiment": "Bullish",
        "sentiment_score": 0.22,
        "ticker": "PLTR"
        },
        ...
    ]

=head1 DESCRIPTION

L<Reddit - Wallstreet Bets|https://tradestie.com/apps/reddit/api/>

Get top 50 stocks discussed on Reddit subeddit - Wallstreetbets

To find the stocks discussed by date, specify date paraemeter.

Note - The list gets updated every 15 mins. Every 15 minutes, algorithm takes in to account all the comments till that point of time and re-calculates the sentiment. The sentiment reflects the daily sentiment.

=head1 Attributes

=head2 no_of_comments

Holds the total number (or count) of comments related to the ticker.

=head2 sentiment

Holds the sentiment of the ticker which is eith "Bullish" or "Bearish".

=head2 sentiment_score

Holds the sentiment score of the ticker.

=head2 ticker

Holds the ticker's symbol.

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Rayhan Alcena.

This is free software, licensed under:

  The MIT (X11) License

=cut
