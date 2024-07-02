package Tradestie::WSBetsAPI;

# ABSTRACT: Tradestie's Wallstreet Bets API

use v5.38;
use strict;
use warnings;
use Moose;
use LWP;
use JSON;
use Carp;
use Readonly;

use Tradestie::WSBetsAPI::Reddit;
use Tradestie::WSBetsAPI::TTM_Squeeze_Stocks;

our $VERSION = '0.001';

Readonly my $API_BASE_URL => 'https://tradestie.com/api/v1/apps/';

has 'ua' => (
    isa        => 'LWP::UserAgent',
    is         => 'ro',
    lazy_build => 1,
);

sub date_formatter( $self, $month = '11', $day = '17', $year = '2022' ) {
    croak "Error: The month given is not a valid integer or date"
      unless int($month);

    croak "Error: The day given is not a valid integer or date"
      unless int($day);

    croak "Error: The year given is not a valid integer or date"
      unless int($year);

    croak "Error: The month must contain a two digit value"
      unless length($month) == 2;

    croak "Error: The day must contain a two digit value"
      unless length($day) == 2;

    croak "Error: The year must contain a four digit value"
      unless length($year) == 4;

    return "$year-$month-$day";
}

sub reddit( $self, $date = undef ) {
    my $path          = $self->_build_path( 'reddit', $date );
    my $response_list = $self->_request($path);
    my @responses;

    # Create an array that contains Reddit objects
    for my $response (@$response_list) {
        push @responses, Tradestie::WSBetsAPI::Reddit->new($response);
    }

    return @responses;
}

sub ttm_squeeze_stocks( $self, $date = "2022-11-17" ) {
    my $path          = $self->_build_path( 'ttm-squeeze-stocks', $date );
    my $response_list = $self->_request($path);
    my @responses;

    # Create an array that contains TTM_Squeeze_Stocks objects
    for my $response (@$response_list) {
        push @responses,
          Tradestie::WSBetsAPI::TTM_Squeeze_Stocks->new($response);
    }

    return @responses;
}

sub _build_path( $self, $endpoint, $date ) {
    my $uri = URI->new( $API_BASE_URL . $endpoint );

    $uri->query( $uri->query_form( date => $date ) ) if $date;

    return $uri;
}

sub _build_ua($self) {

    my $ua = LWP::UserAgent->new;
    $ua->agent("");

    return $ua;
}

sub _request( $self, $uri ) {
    my $response = $self->ua->get($uri);
    if ( $response->is_success ) {
        return decode_json( $response->decoded_content );
    }
    else {
        my $code = $response->code;
        confess "Tradestie API status code ($code)\n"
          . "Error: "
          . $response->status_line;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tradestie::WSBetsAPI - Tradestie's Wallstreet Bets API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Tradestie::WSBetsAPI is a wrapper for the L<Tradestie's|https://tradestie.com/> r/Wallstreet Bets API.

=head1 Installation

=head2 cpanm

    cpanm Tradestie::WSBetsAPI

=head2 Project Directory

    cpanm --installdeps .
    perl Makefile.PL
    make
    make install

=head1 API Key

Currently the Tradestie WallStreet Bets API does not require an API key.

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Rayhan Alcena.

This is free software, licensed under:

  The MIT (X11) License

=cut
