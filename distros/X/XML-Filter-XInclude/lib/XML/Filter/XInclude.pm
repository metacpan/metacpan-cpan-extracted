# $Id: XInclude.pm,v 1.1.1.1 2002/01/21 08:22:26 matt Exp $

package XML::Filter::XInclude;
use strict;

use URI;
use XML::SAX::Base;
use Cwd;

use vars qw($VERSION @ISA);
@ISA = qw(XML::SAX::Base);
$VERSION = '1.0';

use constant XINCLUDE_NAMESPACE => 'http://www.w3.org/2001/XInclude';
use constant NS_XML => 'http://www.w3.org/XML/1998/namespace';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{depth} = 0;
    $self->{level} = 0;
    $self->{locators} = [];
    $self->{bases} = [];
    return $self;
}

sub set_document_locator {
    my ($self, $locator) = @_;
    push @{$self->{locators}}, $locator;
    my $cwd = cwd . "/";
    my $uri = URI->new($locator->{SystemId})->abs($cwd) ||
        throw XML::SAX::Exception::NotSupported(
            Message => "Unrecognized SYSTEM ID: $locator->{SystemId}"
        );
    push @{$self->{bases}}, $uri;
    $self->SUPER::set_document_locator($locator);
}

sub _inside_xinclude_element {
    return shift->{level} != 0;
}

sub start_element {
    my ($self, $el) = @_;
    if ($self->{level} == 0) {
        my $atts = $el->{Attributes};

        # handle xml:base stuff
        my $parent_base = $self->{bases}[-1];
        my $current_base = $parent_base;
        if (exists $atts->{"{".NS_XML."}base"}) {
            my $base = $atts->{"{".NS_XML."}base"}{Value};
            $current_base = URI->new_abs($base, $parent_base) ||
                throw XML::SAX::Exception(
                    Message => "Malformed base URL: $base"
                );
        }
        push @{$self->{bases}}, $current_base;

        # handle xincludes
        if ( ($el->{NamespaceURI} eq XINCLUDE_NAMESPACE)
            && ($el->{LocalName} eq "include") )
        {
            my $href = $atts->{"{}href"}{Value} ||
                throw XML::SAX::Exception(
                    Message => "Missing href attribute"
                );
    
            # don't care about auto-vivication here - xinclude element vanishes
            my $parse = $atts->{"{}parse"}{Value} || "xml";
    
            if ($parse eq "text") {
                $self->_include_text_document($href, $atts->{"{}encoding"}{Value});
            }
            elsif ($parse eq "xml") {
                $self->_include_xml_document($href);
            }
            else {
                throw XML::SAX::Exception(
                    Message => "Illegal value for parse attribute: $parse"
                );
            }
            $self->{level}++;
        }
        else {
            $self->SUPER::start_element($el);
        }
    }
}

sub end_element {
    my ($self, $el) = @_;
    if ( ($el->{NamespaceURI} eq XINCLUDE_NAMESPACE)
         && ($el->{LocalName} eq "include") )
    {
        $self->{level}--;
    }
    elsif ($self->{level} == 0) {
        pop @{$self->{bases}};
        $self->SUPER::end_element($el);
    }
}

sub start_document {
    my ($self, $doc) = @_;
    $self->{level} = 0;
    $self->SUPER::start_document($doc) if $self->{depth} == 0;
    $self->{depth}++;
}

sub end_document {
    my ($self, $doc) = @_;
    pop @{$self->{locators}};
    $self->{depth}--;
    return $self->SUPER::end_document($doc) if $self->{depth} == 0;
}

sub start_prefix_mapping {
    my ($self, $mapping) = @_;
    $self->SUPER::start_prefix_mapping($mapping) if $self->{level} == 0;
}

sub end_prefix_mapping {
    my ($self, $mapping) = @_;
    $self->SUPER::end_prefix_mapping($mapping) if $self->{level} == 0;
}

sub characters {
    my ($self, $chars) = @_;
    $self->SUPER::characters($chars) if $self->{level} == 0;
}

sub ignorable_whitespace {
    my ($self, $chars) = @_;
    $self->SUPER::ignorable_whitespace($chars) if $self->{level} == 0;
}

sub processing_instruction {
    my ($self, $pi) = @_;
    $self->SUPER::processing_instruction($pi) if $self->{level} == 0;
}

sub _get_location {
    my $self = shift;
    my $locator = $self->{locators}[-1] || {};
    return " in document included from " .
            ($locator->{PublicId} || "") .
            " at " .
            ($locator->{SystemId} || "") .
            " at line " .
            ($locator->{LineNumber} || -1) .
            ", column " .
            ($locator->{ColumnNumber} || -1);
}

sub _include_text_document {
    my ($self, $url, $encoding) = @_;
    my $base = $self->{bases}[-1];
    my $source = URI->new_abs($url, $base);
    
    if (-e $source && -f _) {
        open(SOURCE, "<$source") ||
            throw XML::SAX::Exception(
                Message => "Unable to open $source: $!"
            );
        # TODO binmode encoding on 5.7.2
        while(<SOURCE>) {
            $self->characters({ Data => $_ });
        }
        close SOURCE;
    }
    else {
        require LWP::UserAgent;
        my $ua = LWP::UserAgent->new;
        $ua->agent("Perl/XML/Filter/XInclude/1.0 " . $ua->agent);
        
        my $req = HTTP::Request->new(GET => $source);
        
        my $callback = sub {
            my ($data, $response, $protocol) = @_;
            $self->characters({Data => $data});
        };
        
        my $res = $ua->request($req, $callback, 4096);
        
        if (!$res->is_success) {
            throw XML::SAX::Exception(
                Message => "LWP Request Failed"
            );
        } 
    }
}

sub _include_xml_document {
    my ($self, $url) = @_;
    my $base = $self->{bases}[-1];
    my $source = URI->new_abs($url, $base);

    # This should work, but doesn't
#    $self->parse(
#        { Source => { SystemId => $source } }
#    );
    
    my $parser = XML::SAX::ParserFactory->parser(
        Handler => $self
    );
    local $self->{level} = 0;
    if (grep { $_ eq $source } @{$self->{bases}}) {
        throw XML::SAX::Exception(
            Message => "Circular XInclude Reference to $source ".
                        $self->_get_location
                    );
    }
    push @{$self->{bases}}, $source;
    $parser->parse(
        { Source => { SystemId => $source } }
    );
    pop @{$self->{bases}};
    
}

1;
__END__

=head1 NAME

XML::Filter::XInclude - XInclude as a SAX Filter

=head1 SYNOPSIS

  use XML::SAX;
  use XML::SAX::Writer;
  use XML::Filter::XInclude;

  my $parser = XML::SAX::ParserFactory->parser(
      Handler => XML::Filter::XInclude->new(
          Handler => XML::SAX::Writer->new()
      )
  );
  $parser->parse_uri("foo.xml");

=head1 DESCRIPTION

This module implements a simple SAX filter that provides XInclude
support. It does I<NOT> support XPointer.

XInclude is very simple, just include something like this in
your XML document:

  <xi:include href="foo.xml" 
    xmlns:xi="http://www.w3.org/2001/XInclude"/>

And it will load F<foo.xml> and parse it in the current SAX stream.

If you specify the attribute parse="text", it will be treated as
a plain text file, and inserted into the stream as a series of calls
to the characters() method.

URI's are supported via LWP.

Currently encoding is not supported.

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org

=head1 LICENSE

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

