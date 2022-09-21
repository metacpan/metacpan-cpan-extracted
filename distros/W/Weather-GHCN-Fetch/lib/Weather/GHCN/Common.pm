# Weather::GHCN::Common.pm - common functions for GHCN scripts and modules

## no critic (Documentation::RequirePodAtEnd)

=head1 NAME

Weather::GHCN::Common - common functions for GHCN scripts and modules

=head1 VERSION

version v0.0.003

=head1 SYNOPSIS

  use Weather::GHCN::Common qw(:all);


=head1 DESCRIPTION

The B<Weather::GHCN::Common> module provides functions that are used in more
than one GHCN module, or that may be useful in application scripts;
e.g. rng_valid() to validate number ranges that might be provided
to a script using command line arguments.

The module is primarily for use by modules Weather::GHCN::Fetch, Weather::GHCN::Options, 
Weather::GHCN::Station, and Weather::GHCN::StationTable.

=cut

use v5.18;  # minimum for Object::Pad

package Weather::GHCN::Common;

our $VERSION = 'v0.0.003';


use feature 'signatures';
no warnings 'experimental::signatures';

## no critic [ProhibitSubroutinePrototypes]

use Exporter;
use parent 'Exporter';

use Carp                qw(croak);
use Const::Fast;
use Try::Tiny;
use Set::IntSpan::Fast;

const my $EMPTY => q();
const my $TAB   => qq(\t);
const my $NL    => qq(\n);

const my $RANGE_RE      => qr{ \d+ (?: [-] \d+ )? }xms;
const my $RANGE_LIST_RE => qr{ \A $RANGE_RE (?: [,] $RANGE_RE )* \Z }xms;

our %EXPORT_TAGS = ( 'all' => [ qw(
    commify
    np_trim
    rng_new
    rng_valid
    rng_within
    tsv
    iso_date_time
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );


=head1 FUNCTIONS

=head2 commify($number)

Insert commas into a number so that digits are grouped in threes;
e.g. 12345 becomes 12,345.

The argument can be a number or a string of digits, with or without
a decimal.  Digits after a decimal are unaffected.

=cut

# insert commas into a number
sub commify ($arg) {

    $arg //= q();

    my $text = reverse $arg;

    $text =~ s{ (\d\d\d) (?=\d) (?! \d* [.] ) }{$1,}xmsg;

    return scalar reverse $text;
}

=head2 rng_new(@args)

Wrapper for Set::IntSpan::Fast->new(), it provides a shorter name
as well as:

 - allowing an undef $range to create an empty set
 - croaking if new() fails for any reason

The arguments to rng_new can consist of a range string (e.g. '1-5,12')
or a perl list of numbers (e.g. 1,7,12,20..25) or a mix of both.

=cut

sub rng_new (@args) {   ## no critic [RequireFinalReturn]
    my $s;

    # treat undef as an empty range
    my @ranges = map { $_ // q() } @args;

    try {
        $s = Set::IntSpan::Fast->new( @ranges );
    } catch {
        croak 'Common::rng_new ' . $_;
    };
    return $s;
}

=head2 rng_valid($range)

Returns true if the range string is valid for Set::IntSpan::Fast.  Valid
ranges consist of numbers, a pair of numbers delimited by dash
(e.g 15-75), or a mix of those delimited by commas (e.g. '5-9,12,25-30').

=cut

sub rng_valid ($rng) {
    return $rng =~ $RANGE_LIST_RE;
}


=head2 rng_within($range, $domain)

Returns true if the range string is lies within the domain range.  For
example rng_within('3-5', '1-12') return true, whereas
rng_within('1800,1950', '1900-2100') returns false because 1800 is
not within the domain of 1900 to 2100.

=cut

sub rng_within ($rng, $domain) {
    croak "*E* invalid range argument: $rng"
        unless $rng =~ $RANGE_LIST_RE;
    croak "*E* invalid domain argument: $rng"
        unless $domain =~ $RANGE_LIST_RE;

    my $rng_obj = rng_new($rng);
    my $domain_obj = rng_new($domain);

    return $rng_obj->subset($domain_obj);
}


=head2 tsv($list_or_list_of_lists)

Takes a perl list and returns an equivalent tab-separated string.
Alternatively, takes a list of lists and returns a newline-separated
string of tab-separated values.

=cut

sub tsv ($list_or_list_of_lists) {
    return $EMPTY if not defined $list_or_list_of_lists;
    return $EMPTY if not $list_or_list_of_lists->@*;

    my $argref = ref $list_or_list_of_lists->[0];

    my $result = $EMPTY;

    if ($argref eq 'ARRAY') {
        my @rows;
        foreach my $row_aref ( $list_or_list_of_lists->@* ) {
            push @rows, join $TAB, $row_aref->@*;
        }
        $result = join $NL, @rows;
    } elsif ($argref eq $EMPTY) {
        $result = join $NL, $list_or_list_of_lists->@*;
    } else {
        croak '*E* tsv() invalid argument: ' . $argref;
    }

    return $result;
}


=head2 iso_date_time(@now)

Takes the first 6 elements from a perl localtime array and formats
them into an ISO date string YYYY-MM-DD HH:MM:SS.

=cut

sub iso_date_time (@now) {
    ## no critic [ProhibitMagicNumbers]

    croak 'iso_date_time requires at least a 6-element localtime array'
        if @now < 6;

    my @ymdhms = ( $now[5]+1900, $now[4]+1, $now[3], $now[2], $now[1], $now[0] );

    return wantarray
        ? @ymdhms
        : sprintf '%4d-%02d-%02d %02d:%02d:%02d', @ymdhms
        ;
}

1;

=head1 AUTHOR

Gary Puckering (jgpuckering@rogers.com)

=head1 LICENSE AND COPYRIGHT

Copyright 2022, Gary Puckering

=cut
