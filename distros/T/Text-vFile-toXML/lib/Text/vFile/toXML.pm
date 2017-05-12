package Text::vFile::toXML;

use strict;
use warnings;

=head1 NAME

Text::vFile::toXML - Convert vFiles into equivalent XML

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

use Carp qw(croak);
use Text::vFile::asData;
use XML::Quick;

use base qw(Exporter);
our @EXPORT_OK = qw(to_xml xCalNS);

our %attrs = qw(language xml:lang);
our $xCalNS  = 'urn:ietf:params:xml:ns:xcal';

=head1 SYNOPSIS

This module converts iCalendar (iCal : generically, vFile) files into their
(equivalent) XML (xCalendar / xCal) representation, according to Royer's IETF
Draft (L<http://tools.ietf.org/html/draft-royer-calsch-xcal-03>).

    # Enable functional interface
    use Text::vFile::toXML qw(to_xml);

    # Input filename
    my $arg = "input.file";
    my $a = Text::vFile::toXML->new(filename => $arg)->to_xml;
    my $b = Text::vFile::toXML->new(filehandle =>
        do { open my $fh, $arg or die "can't open ics: $!"; $fh }
    )->to_xml;

    use Text::vFile::asData; # to make the functional example work
    my $data =
        Text::vFile::asData->new->parse(
            do {
                open my $fh, $arg
                    or die "Can't open vFile: $!"; $fh
                }
            );
    my $c = Text::vFile::toXML->new(data => $data)->to_xml;

    # Use functional interface
    my $d = to_xml($data);

    # Now ($a, $b, $c, $d) all contain the same XML string.

=head1 EXPORT

No functions are exported by default; you can choose to import the 'to_xml'
function if you wish to use the functional interface.

=head1 METHODS

=head2 new

Creates a new Text::vFile::toXML object; takes a list of key-value pairs for initialization, which must contain exactly one of the following:

    filehandle => (filehandle object)
    filename   => (string)
    data       => (Text::vFile::asData struct)

=cut

sub new {
    my ($type, %args) = @_;

    croak "Must provide exactly one of (filehandle, filename, or data)"
        unless +@{[ grep defined, @args{qw(filehandle filename data)} ]} == 1;

    $args{_data} = delete $args{data}
        || Text::vFile::asData->new->parse(
            $args{filehandle} || ($args{filename} &&
                do { open my $fh, $args{filename} or die; $fh }
            ));
    
    bless \%args, $type
}

=head2 to_xml

Wraps the convert() function; returns an XML string. Can be called as an
instance method (OO-style) or as a function (functional style), in which case
it takes a Text::vFile::asData-compatible data structure as its only parameter.

=cut

sub to_xml {
    xml({ convert($_[0]->{_data}{objects} || $_[0]->{objects}) },
        { root => 'iCalendar',  attrs => { 'xmlns:xCal' => $xCalNS } })
}

=head2 convert

Recursively converts Text::vFile::asData structures to XML::Quick-compatible
ones.

=cut

sub convert {
    my ($data) = @_;
    my %result;

    for my $object (@$data) {
        my ($props, $objects, $type) = @$object{qw(properties objects type)};

        push @{ $result{lc $type} }, +{
            convert($objects),
            map {
                my $propname = $_;
                lc $propname => [ map { my ($p, $v) = @$_{qw(param value)}; +{
                    _cdata => $v,
                    _attrs => +{ map { $attrs{lc $_} || lc $_ => $p->{$_} } keys %$p } }
                } @{ $props->{$propname} } ]
            } keys %$props
        };
    }

    return %result;
}

=head1 AUTHOR

Darren Kulp, C<< <kulp at cpan.org> >>

=head1 BUGS

Probably. Email me at the address above with bug reports.

=head1 ACKNOWLEDGEMENTS

The L<Text::vFile::asData> and L<XML::Quick> modules proved very useful, to the
point of nearly trivializing this module.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Darren Kulp.

This program is released under the terms of the BSD license.

=cut

1; # End of Text::vFile::toXML
__END__

# vi: set ts=4 sw=4 et ai: #
