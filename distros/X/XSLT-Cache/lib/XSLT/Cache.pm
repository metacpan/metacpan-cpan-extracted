package XSLT::Cache;

use vars qw($VERSION);
$VERSION = 0.2;

use strict;
use XML::LibXML;
use XML::LibXSLT;
use File::Cache::Persistent;

sub new {
    my ($class, %args) = @_;

    my $cache = new File::Cache::Persistent(
        prefix => $args{prefix} || undef,
        timeout => $args{timeout} || 0,
        reader => \&_read_xsl_file
    );

    my $this = {
        cache => $cache,
    };
    bless $this, $class;

    return $this;
}

sub transform {
    my ($this, $xmldoc, $xsltpath) = @_;

    $xmldoc = $this->_get_xmldocument($xmldoc) unless ref $xmldoc && $xmldoc->isa("XML::LibXML::Document");
    $xsltpath = $this->_get_xsltpath($xmldoc) unless $xsltpath;

    die "No path to XSLT specified\n" unless $xsltpath;
    
    $xsltpath = $this->{prefix} . '/' . $xsltpath if $this->{prefix};
    my $xsldoc = $this->{cache}->get($xsltpath);

    return $xsldoc->output_string($xsldoc->transform($xmldoc));
}

sub status {
    my $this = shift;
    
    return $this->{cache}->status();
}

sub _get_xmldocument {
    my ($this, $xmldoc) = @_;

    my $xmlparser = new XML::LibXML();

    die "Empty XML document passed\n" unless $xmldoc;

    if ($xmldoc =~ /^<\?xml/) {
        $xmldoc = $xmlparser->parse_string($xmldoc);
    }
    elsif (-f $xmldoc) {
        $xmldoc = $xmlparser->parse_file($xmldoc);
    }
    else {
        die "Cannot open XML File '$xmldoc'\n";
    }
}

sub _get_xsltpath {
    my ($this, $xmldoc) = @_;

    my @stylesheet = $xmldoc->findnodes("processing-instruction('xml-stylesheet')");
    if (@stylesheet) {
        my $stylesheet = $stylesheet[0]->nodeValue;
        if ($stylesheet =~ m{type\s*=\s*['"]text/xslt?['"]}) {
            my ($href) = $stylesheet =~ m{href\s*=\s*['"](.*?)['"]};
            return $href;
        }
    }

    return undef;
}

sub _read_xsl_file {
    my $path = shift;

    my $xslparser = new XML::LibXSLT();

    return $xslparser->parse_stylesheet_file($path);
}

1;

__END__

=head1 NAME

XSLT::Cache - Transparent preparsing and caching XSLT documents

=head1 SYNOPSIS

 # Running under mod_perl
 my $tr = new XSLT::Cache(timeout => 60);
 . . .
 sub handler {
     . . .
     $html = $tr->transform('/www/server/index.xml');
     . . .
 }
    
=head1 ABSTRACT

XSLT::Cache provides a mechanism for transparent caching XSLT files and
checking their updates.

=head1 DESCRIPTION

Using XSLT in real life often leads to the need of preliminary parsing and
caching XSLT documents before applying them to incoming XML trees. This module
makes caching transparent and allows the user not to think about that. It is
possible to make cache available for some time interval. If a file was once
stored to the cache, it will be available even after it is deleted from disk.

=head2 new

Builds a new instance of cache object.
 
 my $tr = new XSLT::Cache;
 
This method accepts two optional named parameters that define behaviour of
cache.

 my $tr = new XSLT::Cache(
     prefix  => '/www/data/xsl',
     timeout => 600     
 );

C<prefix> parameter determines where XSLT files are located. By default they are
looked for in the current directory.

C<timeout> defines duration (in seconds) of the period of unconditional using
cache. Before timeout happens transformation are always executed with an
XSLT-document from cache, even if original file was modified or deleted.

=head2 transform

To apply a transformation it is only needed to call C<transform> method.

 say $tr->transform($xml_document);
 
First argument should contain XML document that is to be transformed. It may be
either a reference to XML::LibXML::Document object, or a path to XML file on disk,
or text variable containing XML as a text.

Return value is a scalar containing transformation result as text.

Here is an example of how to use XML document which is already built. Note that
the document itself may also be cached with the help of File::Cache::Persistent
module.

 my $xmlparser = new XML::LibXML;
 my $xmldoc = $xmlparser->parse_file('/www/xml/index.xml');
 my $html = $tr->transform($xmldoc);

Passing filename allows to avoid manual reading and parsing of XML.

 $html = $tr->transform('/www/xml/index.xml');

And, finally, it is possible to pass XML text directly.

 $html = $tr->transform(<<XML);
 <?xml version="1.0" encoding="UTF-8"?>
 <?xml-stylesheet type="text/xsl" href="/www/data/transform.xsl"?>
 <my_document>
     . . .
 </my_document>
XML

Path to XSLT file must either be specified in the XML document itself or be
passed as a second argument of C<transform> method.

Passing the path to XSLT file in the ducument requires C<xml-stylesheet>
processing instruction:

 <?xml-stylesheet type="text/xsl" href="data/transform.xsl"?>

XSLT location is always affected by C<prefix> argument if it was used in object
constructor.

=head1 How cache works

Caching logic is simple. Every XSLT file took place in a transformation is beeing
put to the cache. When another query to make the same transformation is received,
and there were no C<timeout> specified, the file is checked and if it is modified,
it is re-read and cache is updating; otherwise current cached document is used.

If caching object was built with a C<timeout> specified, it never makes any
checks before timeout happen. 

When a transformation is found in the cache but original file is already deleted
from disk, cached copy will always be used, even before timeout period.

=head2 status

This method allows to learn out which version was used for the transformation and
returns the status of last C<transform> call. Return valus are described in details
in appropriate section of File::Cache::Persistent module documentation.

=head1 SEE ALSO

XML::ApplyXSLT module offeres similar functionality.

Detailed logic of checking file modifications is described in a documentation of
File::Cache::Persistent module.    
    
=head1 AUTHOR

Andrew Shitov, <andy@shitov.ru>

=head1 COPYRIGHT AND LICENSE
  
XSLT::Cache module is a free software. 
You may redistribute and (or) modify it under the same terms as Perl itself
whichever version it is.

=cut
