package eris::dictionary::eris;

use Moo;
use namespace::autoclean;
with qw(
    eris::role::dictionary::hash
);
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

eris::dictionary::eris

=head1 VERSION

version 0.003

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

__DATA__
source The source of the message
eris_source Where the eris system contextualized this message
timestamp The timestamp encoded in the message
message Message contents, often truncated to relevance.
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
name Name of the event
class Class of the event
