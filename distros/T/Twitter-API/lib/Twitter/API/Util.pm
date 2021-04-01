package Twitter::API::Util;
# ABSTRACT: Utilities for working with the Twitter API
$Twitter::API::Util::VERSION = '1.0006';
use 5.14.1;
use warnings;
use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use Time::Local qw/timegm/;
use Try::Tiny;
use namespace::clean;

use Sub::Exporter::Progressive -setup => {
    exports => [ qw/
        is_twitter_api_error
        timestamp_to_gmtime
        timestamp_to_localtime
        timestamp_to_time
    /],
};

sub is_twitter_api_error {
    blessed($_[0]) && $_[0]->isa('Twitter::API::Error');
}

my %month;
@month{qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/} = 0..11;
sub _parse_ts {
    local $_ = shift() // return;

    # "Wed Jun 06 20:07:10 +0000 2012"
    my ( $M, $d, $h, $m, $s, $y ) = /
        ^(?:Sun|Mon|Tue|Wed|Thu|Fri|Sat)
        \ (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)
        \ (\d\d)\ (\d\d):(\d\d):(\d\d)
        \ \+0000\ (\d{4})$
    /x or return;
    return ( $s, $m, $h, $d, $month{$M}, $y - 1900 );
};

sub timestamp_to_gmtime    { gmtime timestamp_to_time($_[0]) }
sub timestamp_to_localtime { localtime timestamp_to_time($_[0]) }
sub timestamp_to_time      {
    my $ts = shift // return undef;
    my @t = _parse_ts($ts) or croak "invalid timestamp: $ts";
    timegm @t;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Twitter::API::Util - Utilities for working with the Twitter API

=head1 VERSION

version 1.0006

=head1 SYNOPSIS

    use Twitter::API::Util ':all';

    # Given a timestamp in Twitter's text format:
    my $ts = $status->{created_at}; # "Wed Jun 06 20:07:10 +0000 2012"

    # Convert it UNIX epoch seconds (a Perl "time" value):
    my $time = timestamp_to_time($status->{created_at});

    # Or a Perl localtime:
    my $utc = timestamp_to_timepiece($status->{created_at});

    # Or a Perl gmtime:
    my $utc = timestamp_to_gmtime($status->{created_at});

    # Check to see if an exception is a Twitter::API::Error
    if ( is_twitter_api_error($@) ) {
        warn "Twitter API error: " . $@->twitter_error_text;
    }

=head1 DESCRIPTION

Exports helpful utility functions.

=head1 METHODS

=head2 timestamp_to_gmtime

Returns C<gmtime> from a Twitter timestamp string. See L<perlfunc/gmtime-EXPR>
for details.

=head2 timestamp_to_localtime

Returns C<localtime> for a Twitter timestamp string. See
L<perlfunc/localtime-EXPR> for details.

=head2 timestamp_to_time

Returns a UNIX epoch time for a Twitter timestamp string. See L<perlfunc/time>
for details.

=head2 is_twitter_api_error

Returns true if the scalar passed to it is a L<Twitter::API::Error>. Otherwise,
it returns false.

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2021 by Marc Mims.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
