use 5.008;
use strict;
use warnings;
## skip Test::Tabs

package XML::Saxon::XSLT2;

use Carp;
use IO::Handle;
use Scalar::Util qw[blessed];
use XML::LibXML;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.010';

my $classpath;

BEGIN
{
	foreach my $path (qw(
		/usr/share/java/saxon9he.jar
		/usr/local/share/java/saxon9he.jar
		/usr/share/java/saxonb.jar
		/usr/local/share/java/saxonb.jar
		/usr/local/share/java/classes/saxon9he.jar
	)) {
		$classpath = $path if -e $path;
		last if defined $classpath;
	}

	require Inline;
}

sub import
{
	my ($class, @args) = @_;
	shift @args
		if @args && exists $args[0] && defined $args[0] && $args[0] =~ /^[\d\.\_]{1,10}$/;
	Inline->import( Java => 'DATA', CLASSPATH => $classpath, @args );
}

sub new
{
	my ($class, $xslt, $baseurl) = @_;
	$xslt = $class->_xml($xslt);
	
	if ($baseurl)
	{
		return bless { 'transformer' => XML::Saxon::XSLT2::Transformer->new($xslt, $baseurl) }, $class;
	}
	else
	{
		return bless { 'transformer' => XML::Saxon::XSLT2::Transformer->new($xslt) }, $class;
	}
}

sub parameters
{
	my ($self, %params) = @_;
	$self->{'transformer'}->paramClear();
	while (my ($k,$v) = each %params)
	{
		if (ref $v eq 'ARRAY')
		{
			(my $type, $v) = @$v;
			my $func = 'paramAdd' . {
				double    => 'Double',
				string    => 'String',
				long      => 'Long',
				'int'     => 'Long',
				integer   => 'Long',
				decimal   => 'Decimal',
				float     => 'Float',
				boolean   => 'Boolean',
				bool      => 'Boolean',
				qname     => 'QName',
				uri       => 'URI',
				date      => 'Date',
				datetime  => 'DateTime',
				}->{lc $type};
			croak "$type is not a supported type"
				if $func eq 'paramAdd';
			$self->{'transformer'}->$func($k, $v);
		}
		elsif (blessed($v) && $v->isa('DateTime'))
		{
			$self->{'transformer'}->paramAddDateTime($k, "$v");
		}	
		elsif (blessed($v) && $v->isa('Math::BigInt'))
		{
			$self->{'transformer'}->paramAddLong($k, $v->bstr);
		}
		elsif (blessed($v) && $v->isa('URI'))
		{
			$self->{'transformer'}->paramAddURI($k, "$v");
		}	
		else
		{
			$self->{'transformer'}->paramAddString($k, "$v");
		}
	}
	return $self;
}

sub transform
{
	my ($self, $doc, $type) = @_;
	$type = ($type =~ /^(text|html|xhtml|xml)$/i) ? (lc $type) : 'default';
	$doc  = $self->_xml($doc);
	return $self->{'transformer'}->transform($doc, $type);
}

sub transform_document
{
	my $self = shift;
	my $r    = $self->transform(@_);
	
	$self->{'parser'} ||= XML::LibXML->new;
	return $self->{'parser'}->parse_string($r);
}

sub messages
{
	my ($self) = @_;
	return @{ $self->{'transformer'}->messages };
}

sub media_type
{
	my ($self, $default) = @_;
	return $self->{'transformer'}->media_type || $default;
}

sub doctype_public
{
	my ($self, $default) = @_;
	return $self->{'transformer'}->doctype_public || $default;
}

sub doctype_system
{
	my ($self, $default) = @_;
	return $self->{'transformer'}->doctype_system || $default;
}

sub version
{
	my ($self, $default) = @_;
	return $self->{'transformer'}->version || $default;
}

sub encoding
{
	my ($self, $default) = @_;
	return $self->{'transformer'}->encoding || $default;
}

sub _xml
{
	my ($proto, $xml) = @_;
	
	if (blessed($xml) && $xml->isa('XML::LibXML::Document'))
	{
		return $xml->toString;
	}
	elsif (blessed($xml) && $xml->isa('IO::Handle'))
	{
		local $/;
		my $str = <$xml>;
		return $str;
	}
	elsif (ref $xml eq 'GLOB')
	{
		local $/;
		my $str = <$xml>;
		return $str;
	}
	
	return $xml;
}

1;

=head1 NAME

XML::Saxon::XSLT2 - process XSLT 2.0 using Saxon 9.x.

=head1 SYNOPSIS

 use XML::Saxon::XSLT2;
 
 # make sure to open filehandle in right encoding
 open(my $input, '<:encoding(UTF-8)', 'path/to/xml') or die $!;
 open(my $xslt, '<:encoding(UTF-8)', 'path/to/xslt') or die $!;
 
 my $trans  = XML::Saxon::XSLT2->new($xslt, $baseurl);
 my $output = $trans->transform($input);
 print $output;
 
 my $output2 = $trans->transform_document($input);
 my @paragraphs = $output2->getElementsByTagName('p');

=head1 DESCRIPTION

This module implements XSLT 1.0 and 2.0 using Saxon 9.x via L<Inline::Java>.

It expects Saxon to be installed in either '/usr/share/java/saxon9he.jar'
or '/usr/local/share/java/saxon9he.jar'. Future versions should be more
flexible. The saxon9he.jar file can be found at L<http://saxon.sourceforge.net/> -
just dowload the latest Java release of Saxon-HE 9.x, open the Zip archive,
extract saxon9he.jar and save it to one of the two directories above.

=head2 Import

 use XML::Saxon::XSLT2;

You can include additional parameters which will be passed straight on to
Inline::Java, like this:

 use XML::Saxon::XSLT2 EXTRA_JAVA_ARGS => '-Xmx256m';

The C<import> function I<must> be called. If you load this module without
importing it, it will not work. (Don't worry, it won't pollute your namespace.)

=head2 Constructor

=over 4

=item C<< XML::Saxon::XSLT2->new($xslt, [$baseurl]) >>

Creates a new transformation. $xslt may be a string, a file handle or an
L<XML::LibXML::Document>. $baseurl is an optional base URL for resolving
relative URL references in, for instance, E<lt>xsl:importE<gt> links.
Otherwise, the current directory is assumed to be the base. (For base URIs
which are filesystem directories, remember to include the trailing slash.)

=back

=head2 Methods

=over 4

=item C<< $trans->parameters($key=>$value, $key2=>$value2, ...) >>

Sets transformation parameters prior to running the transformation.

Each key is a parameter name.

Each value is the parameter value. This may be a scalar, in which case
it's treated as an xs:string; a L<DateTime> object, which is treated as
an xs:dateTime; a L<URI> object, xs:anyURI; a L<Math::BigInt>, xs:long;
or an arrayref where the first element is the type and the second the
value. For example:

 $trans->parameters(
    now             => DateTime->now,
    madrid_is_capital_of_spain => [ boolean => 1 ],
    price_of_fish   => [ decimal => '1.99' ],
    my_link         => URI->new('http://example.com/'),
    your_link       => [ uri => 'http://example.net/' ],
 );

The following types are supported via the arrayref notation: float, double,
long (alias int, integer), decimal, bool (alias boolean), string, qname, uri,
date, datetime. These are case-insensitive.

=item C<< $trans->transform($doc, [$output_method]) >>

Run a transformation, returning the output as a string.

$doc may be a string, a file handle or an L<XML::LibXML::Document>.

$output_method may be 'xml', 'xhtml', 'html' or 'text' to override
the XSLT output method; or 'default' to use the output method specified
in the XSLT file. 'default' is the default. In the current release,
'default' is broken. :-(

=item C<< $trans->transform_document($doc, [$output_method]) >>

As per <transform>, but returns the output as an L<XML::LibXML::Document>.

This method is slower than C<transform>.

=item C<< $trans->messages >>

Returns a list of string representations of messages output by
E<lt>xsl:messageE<gt> during the last transformation run.

=item C<< $trans->media_type($default) >>

Returns the output media type for the transformation.

If the transformation doesn't specify an output type, returns the default.

=item C<< $trans->doctype_public($default) >>

Returns the output DOCTYPE public identifier for the transformation.

If the transformation doesn't specify a doctype, returns the default.

=item C<< $trans->doctype_system($default) >>

Returns the output DOCTYPE system identifier for the transformation.

If the transformation doesn't specify a doctype, returns the default.

=item C<< $trans->version($default) >>

Returns the output XML version for the transformation.

If the transformation doesn't specify a version, returns the default.

=item C<< $trans->encoding($default) >>

Returns the output encoding for the transformation.

If the transformation doesn't specify an encoding, returns the default.

=back

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<XML::LibXSLT> is probably more reliable in terms of easy installation on a
variety of platforms, and it allows you to define your own XSLT extension
functions. However, the libxslt library that it's based on only supports XSLT
1.0.

This module uses L<Inline::Java>.

L<http://saxon.sourceforge.net/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2010-2012, 2014 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

__DATA__
__Java__
import net.sf.saxon.s9api.*;
import org.xml.sax.Attributes;
import org.xml.sax.ContentHandler;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.XMLFilterImpl;
import org.w3c.dom.Document;
import org.xml.sax.Attributes;
import org.xml.sax.ContentHandler;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.XMLFilterImpl;

import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.ErrorListener;
import javax.xml.transform.SourceLocator;
import javax.xml.transform.TransformerException;
import javax.xml.transform.sax.SAXSource;
import javax.xml.transform.stream.StreamSource;
import javax.xml.transform.OutputKeys;
import java.io.*;
import java.math.BigDecimal;
import java.net.URI;
import java.util.*;

public class Transformer
{
	private XsltExecutable xslt;
	private Processor proc;
	private HashMap<String, XdmAtomicValue> params;
	public List messagelist;

	public Transformer (String stylesheet)
		throws SaxonApiException
	{
		proc = new Processor(false);
		XsltCompiler comp = proc.newXsltCompiler();
		xslt = comp.compile(new StreamSource(new StringReader(stylesheet)));
		params = new HashMap<String, XdmAtomicValue>();
		messagelist = new ArrayList();
	}
	
	public Transformer (String stylesheet, String baseuri)
		throws SaxonApiException
	{
		proc = new Processor(false);
		XsltCompiler comp = proc.newXsltCompiler();
		xslt = comp.compile(new StreamSource(new StringReader(stylesheet), baseuri));
		params = new HashMap<String, XdmAtomicValue>();
		messagelist = new ArrayList();
	}
	
	public void paramAddString (String key, String value)
	{
		params.put(key, new XdmAtomicValue(value));
	}

	public void paramAddLong (String key, long value)
	{
		params.put(key, new XdmAtomicValue(value));
	}

	public void paramAddDecimal (String key, BigDecimal value)
	{
		params.put(key, new XdmAtomicValue(value));
	}

	public void paramAddFloat (String key, float value)
	{
		params.put(key, new XdmAtomicValue(value));
	}

	public void paramAddDouble (String key, double value)
	{
		params.put(key, new XdmAtomicValue(value));
	}

	public void paramAddBoolean (String key, boolean value)
	{
		params.put(key, new XdmAtomicValue(value));
	}

	public void paramAddURI (String key, String value)
		throws java.net.URISyntaxException
	{
		params.put(key, new XdmAtomicValue(new URI(value.toString())));
	}

	public void paramAddQName (String key, String value)
	{
		params.put(key, new XdmAtomicValue(new QName(value.toString())));
	}

	public void paramAddDate (String key, String value)
		throws SaxonApiException
	{
		ItemTypeFactory itf = new ItemTypeFactory(proc);
		ItemType dateType = itf.getAtomicType(new QName("http://www.w3.org/2001/XMLSchema", "date"));
		params.put(key, new XdmAtomicValue(value, dateType));
	}

	public void paramAddDateTime (String key, String value)
		throws SaxonApiException
	{
		ItemTypeFactory itf = new ItemTypeFactory(proc);
		ItemType dateTimeType = itf.getAtomicType(new QName("http://www.w3.org/2001/XMLSchema", "datetime"));
		params.put(key, new XdmAtomicValue(value, dateTimeType));
	}

	public XdmAtomicValue paramGet (String key)
	{
		return params.get(key);
	}

	public void paramRemove (String key)
	{
		params.remove(key);
	}
	
	public void paramClear ()
	{
		params.clear();
	}
	
	public Object[] messages ()
	{
		return messagelist.toArray();
	}
	
	public String media_type ()
	{
		return xslt.getUnderlyingCompiledStylesheet().getOutputProperties().getProperty(OutputKeys.MEDIA_TYPE);
	}

	public String doctype_public ()
	{
		return xslt.getUnderlyingCompiledStylesheet().getOutputProperties().getProperty(OutputKeys.DOCTYPE_PUBLIC);
	}

	public String doctype_system ()
	{
		return xslt.getUnderlyingCompiledStylesheet().getOutputProperties().getProperty(OutputKeys.DOCTYPE_SYSTEM);
	}

	public String method ()
	{
		return xslt.getUnderlyingCompiledStylesheet().getOutputProperties().getProperty(OutputKeys.METHOD);
	}

	public String version ()
	{
		return xslt.getUnderlyingCompiledStylesheet().getOutputProperties().getProperty(OutputKeys.VERSION);
	}

	public String standalone ()
	{
		return xslt.getUnderlyingCompiledStylesheet().getOutputProperties().getProperty(OutputKeys.STANDALONE);
	}

	public String encoding ()
	{
		return xslt.getUnderlyingCompiledStylesheet().getOutputProperties().getProperty(OutputKeys.ENCODING);
	}

	public String indent ()
	{
		return xslt.getUnderlyingCompiledStylesheet().getOutputProperties().getProperty(OutputKeys.INDENT);
	}

	public String transform (String doc, String method)
		throws SaxonApiException
	{
		XdmNode source = proc.newDocumentBuilder().build(
			new StreamSource(new StringReader(doc))
			);

		XsltTransformer trans = xslt.load();
		trans.setInitialContextNode(source);

		Serializer out = new Serializer();
		StringWriter sw = new StringWriter();
		out.setOutputWriter(sw);
		trans.setDestination(out);

		if (!method.equals("default"))
		{
			out.setOutputProperty(Serializer.Property.METHOD, method);
		}

		Iterator i = params.keySet().iterator();
		while (i.hasNext())
		{
			Object k = i.next();
			XdmAtomicValue v = params.get(k);
			
			trans.setParameter(new QName(k.toString()), v);
		}

		messagelist.clear();
		trans.setMessageListener(
			new MessageListener() {
				public void message(XdmNode content, boolean terminate, SourceLocator locator) {
					messagelist.add(content.toString());
				}
			}
		);
		
		trans.transform();
				
		return sw.toString();
	}
}

