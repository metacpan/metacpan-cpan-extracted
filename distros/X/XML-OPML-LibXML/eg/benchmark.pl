#!/usr/bin/perl
use strict;
use lib "lib";
use warnings;
use Benchmark qw(:all);
use FindBin;

use XML::OPML::LibXML;
use XML::OPML;

my $file = $ARGV[0] || "presentation.opml";
my $path = "$FindBin::Bin/../t/samples/$file";

cmpthese 1000, {
    'XML::OPML' => \&xml_opml,
    'XML::OPML::LibXML' => \&xml_opml_libxml,
    'XML::OPML::LibXML walkdown' => \&xml_opml_libxml_walkdown,
};

sub xml_opml {
    my $opml = XML::OPML->new;
    $opml->parse($path);
    my $text = $opml->{outline}->[0]->{text};
}

sub xml_opml_libxml {
    my $doc = XML::OPML::LibXML->new->parse_file($path);
    my $text = $doc->outline->[0]->text;
}

sub xml_opml_libxml_walkdown {
    my $doc = XML::OPML::LibXML->new->parse_file($path);
    $doc->walkdown(sub { my $text = $_[0]->text; die });
}

__DATA__
                             Rate XML::OPML XML::OPML::LibXML XML::OPML::LibXML walkdown
XML::OPML                  85.9/s        --              -78%                       -84%
XML::OPML::LibXML           389/s      353%                --                       -26%
XML::OPML::LibXML walkdown  524/s      509%               35%                         --
