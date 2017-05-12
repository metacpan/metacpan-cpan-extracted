use strict;
use warnings;

package Win32::MinXSLT;
$Win32::MinXSLT::VERSION = '0.04';
use Carp;
use Win32::OLE;

our $Dom;
our $MsVer;
our $status;

BEGIN {
    $MsVer  = undef;
    $status = 'ok';
}

sub import {
    my $self = shift;

    $status = 'unknown';

    for my $v (@_) {
        unless ($v =~ m{\A : v ([\d.]+) \z}xmsi) {
            local $" = "', '";
            croak "Invalid parameter - use Win32::MinXSLT('@_') - not format /^:v9.9\$/ ==> '$v'";
        }

        if (defined $MsVer) {
            croak "Invalid duplicate of use Win32::MinXSLT (old version = '$MsVer', new version = '$1')";
        }

        $MsVer = $1;
    }

    $status = 'ok';
}

CHECK {
    unless ($status eq 'ok') { return; }

    unless (defined $MsVer) { $MsVer = '6.0'; }

    unless ($MsVer =~ m{\.}xms) {
        $MsVer .= '.0';
    }

    if ($MsVer eq '1.0') {
        $Dom = 'Microsoft.XMLDOM';
    }
    else {
        $Dom = 'Msxml2.DOMDocument';
        unless ($MsVer eq '2.0') {
            $Dom .= '.'.$MsVer;
        }
    }

    my $test_doc = Win32::OLE->new($Dom) or croak "Can not create Win32::OLE->new('$Dom') during initialisation";

    $test_doc->{async} = 'False';
    my $test = '<?xml version="1.0"?><root></root>';
    unless ($test_doc->LoadXML($test)) {
        croak "Can not do '$Dom' Win32::OLE->LoadXML('$test')";
    }
}

sub new { bless [], $_[0]; }

sub parse_stylesheet { $_[1]; }

# **************************************************************************
# Here is a new package "Win32::MinXML" that does the bulk of the workload:
# **************************************************************************

package Win32::MinXML;
$Win32::MinXML::VERSION = '0.04';
use Carp;
use Win32::OLE;

sub new { bless [], $_[0]; }

sub parse_file {
    my $xml_doc = Win32::OLE->new($Dom)
      or croak "Can not create Win32::OLE->new('$Dom') during Win32::MinXML->parse_file";

    $xml_doc->{async}           = 'False';
    $xml_doc->{validateOnParse} = 'True';

    unless ($xml_doc->Load($_[1])) {
        my $Rs = $xml_doc->{parseError}->{reason}; $Rs =~ s{\r}''xmsg; chomp $Rs;
        my $Ln = $xml_doc->{parseError}->{line};
        my $Ps = $xml_doc->{parseError}->{linePos};
        my $Tx = $xml_doc->{parseError}->{srcText};
        croak "XML-file '$_[1]' did not load for $Dom at line $Ln, pos $Ps, reason: $Rs, text: '$Tx'";
    }

    bless \$xml_doc, ref($_[0]);
}

sub parse_string {
    my $xml_doc = Win32::OLE->new($Dom)
      or croak "Can not create Win32::OLE->new('$Dom') during Win32::MinXML->parse_string";

    $xml_doc->{async}           = 'False';
    $xml_doc->{validateOnParse} = 'True';

    unless ($xml_doc->LoadXML($_[1])) {
        my $Rs = $xml_doc->{parseError}->{reason}; $Rs =~ s{\r}''xmsg; chomp $Rs;
        my $Ln = $xml_doc->{parseError}->{line};
        my $Ps = $xml_doc->{parseError}->{linePos};
        my $Tx = $xml_doc->{parseError}->{srcText};
        croak "XML-text did not load for $Dom at line $Ln, pos $Ps, reason: $Rs, text: '$Tx'";
    }

    bless \$xml_doc, ref($_[0]);
}

sub transform {
    my ($xslt_doc, $xml_doc) = (${$_[0]}, ${$_[1]});

    my $html_doc = Win32::OLE->new($Dom) or croak "Can not create Win32::OLE->new('$Dom') during Win32::MinXML->transform";

    # Do the work, i.e. take the xml-input and transform it (using the xslt stylesheet)
    $xml_doc->transformNodeToObject($xslt_doc, $html_doc);
    if (Win32::OLE::LastError()) {
        my $Rs = Win32::OLE::LastError(); $Rs =~ s{\s+}' 'xmsg;
        croak "XSLT-file has syntax-errors for $Dom: $Rs";
    }

    bless \$html_doc;
}

sub output_file {
    my $self = shift;

    my ($html_doc, $filename) = (${$_[0]}, $_[1]);

    # Save the html to the output-file
    my $rc = $html_doc->save($filename);
    if (Win32::OLE::LastError()) {
        my $Rs = Win32::OLE::LastError(); $Rs =~ s{\s+}' 'xmsg;
        croak "Can't save to output-file '$filename' for $Dom, reason: $Rs";
    }
    elsif ($rc) {
        croak "Can't save to output-file '$filename' for $Dom, returncode = $rc";
    }
}

sub output_string { ${$_[1]}->xml; }

1;
__END__

=head1 NAME

Win32::MinXSLT - XSLT Interface to the Win32 Msxml2.DOMDocument library

=head1 SYNOPSIS

An example that performs a file-to-file transformation:

  use Win32::MinXSLT;

  my $parser     = Win32::MinXML->new();
  my $xslt       = Win32::MinXSLT->new();

  my $source     = $parser->parse_file('foo.xml');
  my $style_doc  = $parser->parse_file('bar.xsl');

  my $stylesheet = $xslt->parse_stylesheet($style_doc);
  my $results    = $stylesheet->transform($source);

  $stylesheet->output_file($results, 'output.html');

Another example that performs an in-memory transformation:

  use Win32::MinXSLT;
  
  my $parser     = Win32::MinXML->new();
  my $xslt       = Win32::MinXSLT->new();
  
  my $source     = $parser->parse_string(
  q{<?xml version="1.0" encoding="iso-8859-1"?>
    <index>
      <data>aaa</data>
      <data>bbb</data>
      <data>ccc</data>
      <data>ddd</data>
    </index>
    });

  my $style_doc  = $parser->parse_string(
  q{<?xml version="1.0" encoding="iso-8859-1"?>
    <xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
      <xsl:output method="xml" indent="yes" encoding="iso-8859-1"/>
      <xsl:template match="/">
        <html>
          <body>
            <title>Test</title>
            Data:
            <hr/>
            <xsl:for-each select="index/data">
              <p>Test: *** <xsl:value-of select="."/> ***</p>
            </xsl:for-each>
          </body>
        </html>
      </xsl:template>
    </xsl:stylesheet>
    });

  my $stylesheet = $xslt->parse_stylesheet($style_doc);
  my $results    = $stylesheet->transform($source);

  print $stylesheet->output_string($results);

=head1 DESCRIPTION

You are on Windows and you would like to use XML::LibXSLT, but there is no pre-compiled
version of XML::LibXSLT available (that is, for example, currently the case on
64-bit Windows, where only 32-bit versions of XML::LibXSLT are available).

In that case you can use Win32::MinXSLT as a drop-in replacement for XML::LibXSLT. In
fact, I have copied the interface from XML::LibXSLT to work with MSXML.

Win32::MinXSLT uses Win32::OLE to call function in 'Msxml2.DOMDocument', version 6, to
do the XSLT transformation.

Different versions of 'Msxml2.DOMDocument' can be selected by using an additional parameter.
For example, the following use statement selects 'Msxml2.DOMDocument', version 3:

  use Win32::MinXSLT qw(:v3);

=head1 AUTHOR

Klaus Eichner, E<lt>klaus03@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

The library Win32::MinXSLT is Copyright (C) 2009 by Klaus Eichner.

The interface, which has been copied from XML::LibXSLT, however, is
not owned by Klaus Eichner.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
