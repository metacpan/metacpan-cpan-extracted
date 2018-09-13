package eris::dictionary::eris;
# ABSTRACT: Contains fields eris adds to events

use Moo;
use namespace::autoclean;
with qw(
    eris::role::dictionary::hash
);

our $VERSION = '0.007'; # VERSION


sub _build_priority { 100; }


my $_hash=undef;
sub hash {
    return $_hash if defined $_hash;
    my %data;
    while(<DATA>) {
        chomp;
        my ($k,$desc) = split /\s+/, $_, 2;
        $data{lc $k} = $desc;
    }
    $_hash = \%data;
}


1;

=pod

=encoding UTF-8

=head1 NAME

eris::dictionary::eris - Contains fields eris adds to events

=head1 VERSION

version 0.007

=head1 SYNOPSIS

This dictionary adds fields the L<eris::log::contextualizer> may add to a document.

=head1 ATTRIBUTES

=head2 priority

Defaults to 100, or near the end

=for Pod::Coverage hash

=head1 SEE ALSO

L<eris::dictionary>, L<eris::role::dictionary>

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

__DATA__
referer For web request, the Referrer, note, mispelled as in the RFC
sld Second-Level Domain, ie what you'd buy on a registrar
filetype File type or Extension
mimetype MIME Type of the file
time_ms Time in millis action took
response_ms For web requests, total time to send response
upstream_ms For web requests, total time to get response from upstream service
src_user Source username
dst_user Destination username
src_geoip GeoIP Data for the source IP
dst_geoip GeoIP Data for the destination IP
attacks Attacks root node
attack_score Total score of all attack detection checks
attack_triggers Total unique instances of tokens tripping attack checks
name Name of the event
class Class of the event
