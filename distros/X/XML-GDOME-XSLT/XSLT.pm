# $Id: LibXSLT.pm,v 1.33 2001/11/25 17:29:03 matt Exp $

package XML::GDOME::XSLT;

use strict;
use vars qw($VERSION @ISA);

use XML::GDOME 0.75;

require Exporter;

$VERSION = "0.75";

require DynaLoader;

@ISA = qw(DynaLoader);

bootstrap XML::GDOME::XSLT $VERSION;

sub new {
    my $class = shift;
    my %options = @_;
    my $self = bless \%options, $class;
    return $self;
}

sub xpath_to_string {
    my @results;
    while (@_) {
        my $value = shift(@_); $value = '' unless defined $value;
        push @results, $value;
        next if @results % 2;
        if ($value =~ /\'/) {
            $results[-1] = join('', 
                "concat(", 
                        join(', ', 
                                map { "'$_', \"'\"" } 
                                split /\'/, $value), 
                                ")");
        }
        else {
            $results[-1] = "'$results[-1]'";
        }
    }
    return @results;
}

sub callbacks {
    my $self = shift;
    if (@_) {
        my ($match, $open, $read, $close) = @_;

        $self->{XML_LIBXSLT_MATCH} = $match ;
        $self->{XML_LIBXSLT_OPEN} = $open ;
        $self->{XML_LIBXSLT_READ} = $read ;
        $self->{XML_LIBXSLT_CLOSE} = $close ;
    }
    else {
        return
            $self->{XML_LIBXSLT_MATCH},
            $self->{XML_LIBXSLT_OPEN},
            $self->{XML_LIBXSLT_READ},
            $self->{XML_LIBXSLT_CLOSE};
    }
}

sub match_callback {
    my $self = shift;
    $self->{XML_LIBXSLT_MATCH} = shift if scalar @_;
    return $self->{XML_LIBXSLT_MATCH};
}

sub open_callback {
    my $self = shift;
    $self->{XML_LIBXSLT_OPEN} = shift if scalar @_;
    return $self->{XML_LIBXSLT_OPEN};
}

sub read_callback {
    my $self = shift;
    $self->{XML_LIBXSLT_READ} = shift if scalar @_;
    return $self->{XML_LIBXSLT_READ};
}

sub close_callback {
    my $self = shift;
    $self->{XML_LIBXSLT_CLOSE} = shift if scalar @_;
    return $self->{XML_LIBXSLT_CLOSE};
}

sub parse_stylesheet {
    my $self = shift;
    if (!ref($self) || !$self->{XML_LIBXSLT_MATCH}) {
        return $self->_parse_stylesheet(@_);
    }
    local $XML::GDOME::match_cb = $self->{XML_LIBXSLT_MATCH};
    local $XML::GDOME::open_cb = $self->{XML_LIBXSLT_OPEN};
    local $XML::GDOME::read_cb = $self->{XML_LIBXSLT_READ};
    local $XML::GDOME::close_cb = $self->{XML_LIBXSLT_CLOSE};
    $self->_parse_stylesheet(@_);
}

sub parse_stylesheet_file {
    my $self = shift;
    if (!ref($self) || !$self->{XML_LIBXSLT_MATCH}) {
        return $self->_parse_stylesheet_file(@_);
    }
    local $XML::GDOME::match_cb = $self->{XML_LIBXSLT_MATCH};
    local $XML::GDOME::open_cb = $self->{XML_LIBXSLT_OPEN};
    local $XML::GDOME::read_cb = $self->{XML_LIBXSLT_READ};
    local $XML::GDOME::close_cb = $self->{XML_LIBXSLT_CLOSE};
    $self->_parse_stylesheet_file(@_);
}

1;
__END__

=head1 NAME

XML::GDOME::XSLT - Interface to the gnome libxslt library

=head1 SYNOPSIS

  use XML::GDOME::XSLT;
  use XML::GDOME;
  
  my $parser = XML::GDOME->new();
  my $xslt = XML::GDOME::XSLT->new();
  
  my $source = $parser->parse_file('foo.xml');
  my $style_doc = $parser->parse_file('bar.xsl');
  
  my $stylesheet = $xslt->parse_stylesheet($style_doc);
  
  my $results = $stylesheet->transform($source);
  
  print $stylesheet->output_string($results);

=head1 DESCRIPTION

This module is an interface to the gnome project's libxslt. This is an
extremely good XSLT engine, highly compliant and also very fast. I have
tests showing this to be more than twice as fast as Sablotron.

=head1 OPTIONS

XML::GDOME::XSLT has some global options. Note that these are probably not
thread or even fork safe - so only set them once per process. Each one
of these options can be called either as class methods, or as instance
methods. However either way you call them, it still sets global options.

Each of the option methods returns its previous value, and can be called
without a parameter to retrieve the current value.

=head2 max_depth

  XML::GDOME::XSLT->max_depth(1000);

This option sets the maximum recursion depth for a stylesheet. See the
very end of section 5.4 of the XSLT specification for more details on
recursion and detecting it. If your stylesheet or XML file requires
seriously deep recursion, this is the way to set it. Default value is
250.

=head2 debug_callback

  XML::GDOME::XSLT->debug_callback($subref);

Sets a callback to be used for debug messages. If you don't set this,
debug messages will be ignored.

=head1 API

The following methods are available on the new XML::GDOME::XSLT object:

=head2 parse_stylesheet($doc)

C<$doc> here is an XML::GDOME::Document object (see L<XML::GDOME>)
representing an XSLT file. This method will return a 
XML::GDOME::XSLT::Stylesheet object, or undef on failure. If the XSLT is
invalid, an exception will be thrown, so wrap the call to 
parse_stylesheet in an eval{} block to trap this.

=head2 parse_stylesheet_file($filename)

Exactly the same as the above, but parses the given filename directly.

=head1 XML::GDOME::XSLT::Stylesheet

The main API is on the stylesheet, though it is fairly minimal.

One of the main advantages of XML::GDOME::XSLT is that you have a generic
stylesheet object which you call the transform() method passing in a
document to transform. This allows you to have multiple transformations
happen with one stylesheet without requiring a reparse.

=head2 transform(doc, %params)

  my $results = $stylesheet->transform($doc, foo => "value);

Transforms the passed in XML::GDOME::Document object, and returns a
new XML::GDOME::Document. Extra hash entries are used as parameters.

=head2 transform_file(filename, %params)

  my $results = $stylesheet->transform_file($filename, bar => "value");

=head2 output_string(result)

Returns a scalar that is the XSLT rendering of the XML::GDOME::Document
object using the desired output format (specified in the xsl:output tag
in the stylesheet). Note that you can also call $result->toString, but
that will *always* output the document in XML format, and in UTF8, which
may not be what you asked for in the xsl:output tag.

=head2 output_fh(result, fh)

Outputs the result to the filehandle given in C<$fh>.

=head2 output_file(result, filename)

Outputs the result to the file named in C<$filename>.

=head2 output_encoding

Returns the output encoding of the results. Defaults to "UTF-8".

=head2 media_type

Returns the output media_type of the results. Defaults to "text/html".

=head1 Parameters

LibXSLT expects parameters in XPath format. That is, if you wish to pass
a string to the XSLT engine, you actually have to pass it as a quoted
string:

  $stylesheet->transform($doc, param => "'string'");

Note the quotes within quotes there!

Obviously this isn't much fun, so you can make it easy on yourself:

  $stylesheet->transform($doc, XML::GDOME::XSLT::xpath_to_string(
        param => "string"
        ));

The utility function does the right thing with respect to strings in XPath,
including when you have quotes already embedded within your string.

=head1 BENCHMARK

Included in the distribution is a simple benchmark script, which has two
drivers - one for LibXSLT and one for Sablotron. The benchmark requires
the testcases files from the XSLTMark distribution which you can find
at http://www.datapower.com/XSLTMark/

Put the testcases directory in the directory created by this distribution,
and then run:

  perl benchmark.pl -h

to get a list of options.

The benchmark requires XML::XPath at the moment, but I hope to factor that
out of the equation fairly soon. It also requires Time::HiRes, which I
could be persuaded to factor out, replacing it with Benchmark.pm, but I
haven't done so yet.

I would love to get drivers for XML::XSLT and XML::Transformiix, if you
would like to contribute them. Also if you get this running on Win32, I'd
love to get a driver for MSXSLT via OLE, to see what we can do against
those Redmond boys!

=head1 AUTHOR

Matt Sergeant is the author of XML::LibXSLT.  XML::GDOME::XSLT
is an adaption of XML::LibXSLT for XML::GDOME.

Please contact TJ Mather at tjmather@tjmather.com with any
comments, suggestions or patches.

Copyright 2001, AxKit.com Ltd. All rights reserved.

Copyright 2002, T.J. Mather

=head1 SEE ALSO

L<XML::GDOME>, L<XML::LibXSLT>

=cut
