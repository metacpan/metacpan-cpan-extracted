# XML::CAP::Util - utilities for XML::CAP classes
# Copyright 2009 by Ian Kluft
# This is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.
# 
# derived from XML::Atom::Util

package XML::CAP::Util;
use strict;

use XML::CAP;
use Encode;
use Exporter;
our @EXPORT_OK = qw( set_ns first nodelist childlist textValue iso2dt encode_xml create_element );
our @ISA = qw( Exporter );

use Exception::Class (
	"XML::CAP::Util::Exception::UnknownVersion" => {
		isa => "XML::CAP::TracedException",
		alias => "throw_unknown_version",
		description => "unknown namespace version",
	},
);

our %NS_MAP = (
    '1.0' => "urn:oasis:names:tc:emergency:cap:1.0",
    '1.1' => "urn:oasis:names:tc:emergency:cap:1.1",
);

our %NS_VERSION = reverse %NS_MAP;

sub set_ns {
    my $thing = shift;
    my($param) = @_;
    if (my $ns = delete $param->{Namespace}) {
        $thing->{ns}      = $ns;
        $thing->{version} = $NS_VERSION{$ns};
    } else  {
        my $version = delete $param->{Version} || $XML::CAP::DefaultVersion;
        $version    = '1.0' if $version == 1;
        my $ns = $NS_MAP{$version}
		or throw_unknown_version ("Unknown version: $version");
        $thing->{ns} = $ns;
        $thing->{version} = $version;
    }
}

sub ns_to_version {
    my $ns = shift;
    $NS_VERSION{$ns};
}

sub first {
    my @nodes = nodelist(@_);
    return unless @nodes;
    return $nodes[0];
}

sub nodelist {
    return  $_[1] ? $_[0]->getElementsByTagNameNS($_[1], $_[2]) :
            $_[0]->getElementsByTagName($_[2]);
}

sub childlist {
    return  $_[1] ? $_[0]->getChildrenByTagNameNS($_[1], $_[2]) :
            $_[0]->getChildrenByTagName($_[2]);
}

sub textValue {
    my $node = first(@_) or return;
    $node->textContent;
}

sub iso2dt {
    my($iso) = @_;
    return unless $iso =~ /^(\d{4})(?:-?(\d{2})(?:-?(\d\d?)(?:T(\d{2}):(\d{2}):(\d{2})(?:\.\d+)?(?:Z|([+-]\d{2}:\d{2}))?)?)?)?/;
    my($y, $mo, $d, $h, $m, $s, $zone) =
        ($1, $2 || 1, $3 || 1, $4 || 0, $5 || 0, $6 || 0, $7);
    require DateTime;
    my $dt = DateTime->new(
               year => $y,
               month => $mo,
               day => $d,
               hour => $h,
               minute => $m,
               second => $s,
               time_zone => 'UTC',
    );
    if ($zone && $zone ne 'Z') {
        my $seconds = DateTime::TimeZone::offset_as_seconds($zone);
        $dt->subtract(seconds => $seconds);
    }
    $dt;
}

my %Map = ('&' => '&amp;', '"' => '&quot;', '<' => '&lt;', '>' => '&gt;',
           '\'' => '&apos;');
my $RE = join '|', keys %Map;

sub encode_xml {
    my($str) = @_;
    $str =~ s!($RE)!$Map{$1}!g;
    $str;
}

sub create_element {
    my($ns, $name) = @_;
    my($ns_uri, $ns_prefix);
    if (ref $ns eq 'XML::CAP::Namespace') {
        $ns_uri = $ns->{uri};
        $ns_prefix = $ns->{prefix};
    } else {
        $ns_uri = $ns;
    }
    my $elem;
    $elem = XML::LibXML::Element->new($name);
    $elem->setNamespace($ns_uri, $ns_prefix ? $ns_prefix : ());
    return $elem;
}

1;
__END__

=head1 NAME

XML::CAP::Util - Utility functions

=head1 SYNOPSIS

    use XML::CAP::Util qw( iso2dt );
    my $dt = iso2dt($entry->issued);

=head1 USAGE

=head2 iso2dt($iso)

Transforms the ISO-8601 date I<$iso> into a I<DateTime> object and returns
the I<DateTime> object.

=head2 encode_xml($str)

Encodes characters with special meaning in XML into entities and returns
the encoded string.

=head1 AUTHOR & COPYRIGHT

XML::CAP::Util was derived from XML::Atom::Util

Please see the I<XML::CAP> manpage for author, copyright, and license
information.

=cut
