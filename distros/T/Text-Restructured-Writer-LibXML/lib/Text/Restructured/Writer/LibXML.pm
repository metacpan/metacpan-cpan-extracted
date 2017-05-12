package Text::Restructured::Writer::LibXML;
use strict;
use warnings;
use XML::LibXML;

$Text::Restructured::Writer::LibXML::VERSION='0.01';

=head1 NAME

Text::Restructured::Writer::LibXML

=head1 SYNOPSIS

  use Text::Restructured;
  use Text::Restructured::Writer::LibXML;

  my $parser=Text::Restructured->new($opts,'gino');
  my $dudom=$parser->Parse($input,$filename);
  my $xdoc=Text::Restructured::Writer::LibXML->new->ProcessDOM($dudom);

=head1 DESCRIPTION

This module implements a "Writer" for L<Text::Restructured>, that
instead of returning a string, returns a L<XML::LibXML> DOM.

The DOM will have non-namespaced elements according to the docutils
vocabulary, and namespcaed elements according to the MathML
vocabulary.

This is probably the fastest way to transform a
L<Text::Restructured::DOM> structure into a proper XML DOM.

=head1 METHODS

=head2 C<new>

Returns a new object.

=cut

sub new {
    my ($class)=@_;
    return bless {},$class;
}

=head2 I<xml_dom>C<= ProcessDOM(>I<docutils_dom>C<)>

Given an object of type L<Text::Restructured::DOM>, processes it
recursively and builds an XML DOM into a new document. Returns the
document, or dies trying.

=cut

sub ProcessDOM {
    my ($self,$dudom)=@_;
    my $xdoc=XML::LibXML->createDocument();
    $xdoc->setDocumentElement(_docutils2xml($dudom,$xdoc));
    return $xdoc;
}

my $MATHML='http://www.w3.org/1998/Math/MathML';

sub _mathml2xml {
    my ($mnode,$xdoc)=@_;

    if ($mnode->isText) {
        return $xdoc->createTextNode($mnode->nodeValue);
    }


    my @children=map {_mathml2xml($_,$xdoc)}
        $mnode->childNodes();

    my $elem=$xdoc->createElementNS($MATHML,$mnode->nodeName);
    for my $attname ($mnode->attributeList) {
        next if $attname eq 'xmlns';
        $elem->setAttribute($attname,
                            $mnode->attribute($attname))
    }

    $elem->appendChild($_) for @children;

    return $elem;
}

sub _docutils2xml {
    my ($dunode,$xdoc)=@_;

    if ($dunode->{tag} eq '#PCDATA') {
        return $xdoc->createTextNode($dunode->{text} || '');
    }

    if ($dunode->{tag} eq 'mathml') {
        return _mathml2xml($dunode->{attr}{mathml},$xdoc);
    }

    my @children=map {_docutils2xml($_,$xdoc)}
        @{ $dunode->{content} || [] };

    my $elem=$xdoc->createElement($dunode->{tag});

    if (defined $dunode->{attr}) {
        while (my ($attname,$attval)=each %{$dunode->{attr}}) {
            if (! defined $attval) {
                $attval='';
            }
            elsif (ref($attval) eq 'ARRAY') {
                $attval=join ' ',@$attval;
            }
            $elem->setAttribute($attname,$attval);
        }
    }
    $elem->appendChild($_) for @children;

    return $elem;
}

1;
