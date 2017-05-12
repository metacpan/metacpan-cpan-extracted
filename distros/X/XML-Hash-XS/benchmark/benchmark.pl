#!/usr/bin/env perl

use FindBin;
use lib ("$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch");
use LWP::Simple 'get';
use XML::Hash::LX;
use XML::Hash;
use XML::Simple;
use XML::LibXML;
use XML::Hash::XS qw();
use Benchmark qw(:all);
use XML::Bare;

my $xml_converter = XML::Hash->new();
my $xml = getXml();
my $xh_hash = $xml_converter->fromXMLStringtoHash($xml);
my $lx_hash = xml2hash($xml);
my $xs_hash = XMLin($xml);
my $xs_conv = XML::Hash::XS->new();

print "\nHash to XML:\n";
cmpthese -3, {
    'XML::Hash' => sub {
        my $oxml = $xml_converter->fromHashtoXMLString($xh_hash);
    },
    'XML::Simple' => sub {
        my $oxml = XMLout($xs_hash);
    },
    'XML::Hash::LX' => sub {
        my $oxml = hash2xml($lx_hash);
    },
    'XML::Hash::XS' => sub {
        my $oxml = XML::Hash::XS::hash2xml($xs_hash);
    },
};

print "\nXML to Hash:\n";

cmpthese -3, {
#    'XML::Hash' => sub {
#        my $oxml = $xml_converter->fromXMLStringtoHash($xh_hash);
#    },
    'XML::Simple' => sub {
        my $oxml = XMLin($xml);
    },
    'XML::Hash::LX' => sub {
        my $oxml = hash2xml($lx_hash);
    },
    'XML::Hash::XS' => sub {
        my $oxml = XML::Hash::XS::xml2hash($xml);
    },
    'XML::Bare' => sub {
        my $oxml = XML::Bare->new(text => $xml)->parse();
    },
};

sub getXml {
    my $fn = "$FindBin::Bin/uploads.rdf";
    open my $f, '<',$fn  or return do {
        warn "Fetching file\n";
        my $data = get 'http://search.cpan.org/uploads.rdf';
        open my $fo, '>', $fn;
        print $fo $data;
        close $fo;
        $data;
    };
    warn "Have preloaded file\n";
    local $/;
    <$f>
}
