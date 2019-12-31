package XML::Invisible;

use strict;
use warnings;
use Exporter qw(import);
use Pegex::Grammar;
use Pegex::Parser;
use XML::Invisible::Receiver;

our $VERSION = '0.05';
our @EXPORT_OK = qw(make_parser ast2xml);

use constant DEBUG => $ENV{XML_INVISIBLE_DEBUG};

sub make_parser {
  my ($grammar_text) = @_;
  my $grammar = Pegex::Grammar->new(text => $grammar_text);
  my $parser = Pegex::Parser->new(
    grammar => $grammar,
    receiver => XML::Invisible::Receiver->new,
    debug => DEBUG,
  );
  sub {
    my ($ixml_text) = @_;
    $parser->parse($ixml_text);
  };
}

my $xml_loaded = 0;
sub ast2xml {
  do { require XML::LibXML; $xml_loaded = 1 } unless $xml_loaded;
  my ($ast) = @_;
  my $doc = XML::LibXML->createDocument("1.0", "UTF-8");
  $doc->addChild(_item2elt($ast));
  $doc;
}

sub _item2elt {
  my ($item) = @_;
  die "Unknown item '$item' passed" if ref $item ne 'HASH';
  my $elt = XML::LibXML::Element->new($item->{nodename});
  my $attrs = $item->{attributes} || {};
  $elt->setAttribute($_, $attrs->{$_}) for keys %$attrs;
  for (@{ $item->{children} || [] }) {
    if (!ref) {
      $elt->appendTextNode($_);
    } else {
      $elt->addChild(_item2elt($_));
    }
  }
  $elt;
}

1;

__END__
=head1 NAME

XML::Invisible - transform "invisible XML" documents into XML using a grammar

=begin markdown

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/mohawk2/xml-invisible.svg?branch=master)](https://travis-ci.org/mohawk2/xml-invisible) |

[![CPAN version](https://badge.fury.io/pl/XML-Invisible.svg)](https://metacpan.org/pod/XML::Invisible) [![Coverage Status](https://coveralls.io/repos/github/mohawk2/xml-invisible/badge.svg?branch=master)](https://coveralls.io/github/mohawk2/xml-invisible?branch=master)

=end markdown

=head1 SYNOPSIS

  use XML::Invisible qw(make_parser);
  my $transformer = make_parser(from_file($ixmlspec));
  my $ast = $transformer->(from_file($ixml_input));

  use XML::Invisible qw(make_parser ast2xml);
  my $transformer = make_parser(from_file($ixmlspec));
  my $xmldoc = ast2xml($transformer->(from_file($ixml_input)));
  to_file($outputfile, $xmldoc->toStringC14N(1));

  # or, with conventional pre-compiled Pegex grammar
  my $parser = Pegex::Parser->new(
    grammar => My::Thing::Grammar->new,
    receiver => XML::Invisible::Receiver->new,
  );
  my $got = $parser->parse($input);

  # from command line
  cpanm XML::Invisible XML::Twig
  perl -MXML::Invisible=make_parser,ast2xml -e \
    'print ast2xml(make_parser(join "", <>)->("(a+b)"))->toStringC14N(1)' \
    examples/arith-grammar.ixml | xml_pp

=head1 DESCRIPTION

An implementation of Steven Pemberton's Invisible XML concept, using
L<Pegex>. Supply it with your grammar, in Pegex format (slightly
different from Steven's specification due to differences between his
notation and Pegex's), it returns you a function, which you can call to
transform "invisible XML" documents into actual XML.

This is largely a Pegex "receiver" class that exploits the C<+> and C<->
syntax in rules in slightly unintended ways, and a wrapper to make
this operate.

=head1 GRAMMAR SYNTAX

See L<Pegex::Syntax>. Generally, all rules will result in an XML
element. All terminals will need to capture with C<()> (see example
below).

However, if you specify a dependent token with C<+> it will
instead become an attribute (equivalent of Steven's C<@>). If C<->,
this will "flatten" (equivalent of Steven's C<->) - the children will
be included without making an element of that node. Since in Pegex any
element can be skipped entirely with C<.>, you can use that instead of
C<-> to omit terminals.

E.g.

  expr: +open -arith +close
  open: /( LPAREN )/
  close: /( RPAREN )/
  arith: left -op right
  left: +name
  right: -name
  name: /(a)/ | /(b)/
  op: +sign
  sign: /( PLUS )/

When given C<(a+b)> yields:

  <expr open="(" sign="+" close=")">
    <left name="a"/>
    <right>b</right>
  </expr>

=head1 FUNCTIONS

=head2 make_parser

Exportable. Returns a function that when called with an "invisible XML"
document, it will return an abstract syntax tree (AST), of the general form:

  {
    nodename => 'expr',
    type => 'element',
    attributes => { open => '(', sign => '+', close => ')' },
    children => [
      {
        nodename => 'left',
        type => 'element',
        attributes => { name => 'a' },
      },
      { nodename => 'right', type => 'element', children => [ 'b' ] },
    ],
  }

Arguments:

=over

=item an "invisible XML" grammar specification, in Pegex format

=back

See L<XML::Invisible::Receiver> for more.

=head2 ast2xml

Exportable. Turns an AST, as output by L</make_parser>,
from L<XML::Invisible::Receiver> into an object of class
L<XML::LibXML::Document>. Needs L<XML::LibXML> installed, which as of
version 0.05 of this module is only a suggested dependency, not required.

Arguments:

=over

=item an AST from L<XML::Invisible::Receiver>

=back

=head1 DEBUGGING

To debug, set environment variable C<XML_INVISIBLE_DEBUG> to a true value.

=head1 SEE ALSO

L<Pegex>

L<https://homepages.cwi.nl/~steven/ixml/> - Steven Pemberton's Invisible XML page

=head1 AUTHOR

Ed J, C<< <etj at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests on
L<https://github.com/mohawk2/xml-invisible/issues>.

Or, if you prefer email and/or RT: to C<bug-xml-invisible
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Invisible>. I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Ed J.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut
