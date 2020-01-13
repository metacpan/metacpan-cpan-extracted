package XML::Invisible;

use strict;
use warnings;
use Exporter qw(import);
use Pegex::Grammar;
use Pegex::Parser;
use XML::Invisible::Receiver;

our $VERSION = '0.07';
our @EXPORT_OK = qw(make_parser ast2xml make_canonicaliser);

use constant DEBUG => $ENV{XML_INVISIBLE_DEBUG};

sub make_parser {
  my ($grammar) = @_;
  $grammar = Pegex::Grammar->new(text => $grammar) if !ref $grammar;
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

sub make_canonicaliser {
  my ($grammar_text) = @_;
  require Pegex::Compiler;
  require Pegex::Grammar::Atoms;
  my $grammar_tree = Pegex::Compiler->new->parse($grammar_text)->tree;
  my $toprule = $grammar_tree->{'+toprule'};
  my $atoms = _atoms2canonical(Pegex::Grammar::Atoms->atoms);
  sub {
    my ($ast) = @_;
    my @results = _extract_canonical($atoms, $ast, $grammar_tree, $toprule);
    return undef if grep !defined, @results;
    join '', @results;
  };
}

my %ATOM2SPECIAL = (
  ALL => "",
  BLANK => " ",
  BREAK => "\n",
  BS => "\x08",
  CONTROL => "\x00",
  CR => "\r",
  DOS => "\r\n",
  EOL => "\n",
  EOS => "",
  FF => "\x0C",
  HICHAR => "\x7f",
  NL => "\n",
  TAB => "\t",
  WORD => "a",
  WS => " ",
  _ => "",
  __ => " ",
  ws => "",
  ws1 => "",
  ws2 => " ",
);
sub _atoms2canonical {
  my ($atoms) = @_;
  my %lookup;
  for my $atom (keys %$atoms) {
    my $c = $atoms->{$atom};
    if (exists $ATOM2SPECIAL{$atom}) {
      $c = $ATOM2SPECIAL{$atom};
    } elsif ($c =~ s/^\\//) {
      # all good
    } elsif ($c =~ s/^\[//) {
      $c = substr $c, 0, 1;
    }
    $lookup{$atom} = $c;
  }
  \%lookup;
}

sub _extract_canonical {
  my ($atoms, $elt, $grammar_tree, $elt_sought, $grammar_frag, $attrs) = @_;
  $grammar_frag ||= $grammar_tree->{$elt_sought};
  $attrs ||= {};
  $attrs = { %$attrs, %{ $elt->{attributes} || {} } } if ref $elt;
  if (defined($elt)) {
    return $elt if !ref $elt; # just text node - trust here for good reason
    return undef if defined($elt_sought) and $elt_sought ne $elt->{nodename};
  } else {
    if (defined($elt_sought) and defined(my $value = $attrs->{$elt_sought})) {
      return $value;
    }
  }
  if (my $rgx = $grammar_frag->{'.rgx'}) {
    # RE, so parent of text nodes
    if (defined $elt) {
      return join('', @{$elt->{children}}) if $elt->{children};
      return $elt->{nodename};
    }
    # or just a bare regex, which is a literal "canonical" representation
    return undef if $rgx =~ /^\(/; # out of our league
    $rgx =~ s#\\##g;
    return $rgx;
  }
  if (my $all = $grammar_frag->{'.all'}) {
    # sequence of productions
    my ($childcount, @results) = (0);
    for my $i (0..$#$all) {
      my $child = $elt->{children}[$childcount];
      my $all_frag = $all->[$i];
      my $new_elt_sought = undef;
      if ($all_frag->{'-skip'}) {
        $child = undef;
      } elsif ($all_frag->{'-wrap'}) {
        $child = undef;
        $new_elt_sought = $all_frag->{'.ref'};
      } else {
        $childcount++;
      }
      my @partial = _extract_canonical(
        $atoms, $child, $grammar_tree, $new_elt_sought, $all_frag, $attrs,
      );
      return undef if grep !defined, @partial; # any non-match
      push @results, @partial;
    }
    return @results;
  } elsif (my $ref = $grammar_frag->{'.ref'}) {
    return $atoms->{$ref} if exists $atoms->{$ref};
    return undef if defined($elt) and $elt->{nodename} ne $ref;
    my $new_frag = $grammar_tree->{$ref};
    if (my $new_ref = $new_frag->{'.ref'}) {
      my $child;
      my $new_attrs = { %$attrs };
      if (!defined($elt)) {
        $child = undef;
      } elsif ($elt->{children}) {
        return undef if @{$elt->{children}} != 1;
        $child = $elt->{children}[0];
      } elsif ($new_frag->{'-wrap'}) {
        $new_attrs = { %$new_attrs, %{ $elt->{attributes} } };
      }
      return _extract_canonical(
        $atoms, $child, $grammar_tree, $new_ref, $new_frag, $new_attrs,
      );
    }
    # treat ourselves as if we're the ref-ed to thing
    return _extract_canonical(
      $atoms, $elt, $grammar_tree, $ref, $new_frag, $attrs,
    );
  } elsif (my $any = $grammar_frag->{'.any'}) {
    # choice, pick first successful
    for my $i (0..$#$any) {
      my $any_frag = $any->[$i];
      my @partial = _extract_canonical(
        $atoms, $elt, $grammar_tree,
        (defined($elt) ? $elt->{nodename} : $elt),
        $any_frag, $attrs,
      );
      next if grep !defined, @partial; # any non-match
      return @partial;
    }
    return undef;
  }
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

  # canonicalise a document
  use XML::Invisible qw(make_parser make_canonicaliser);
  my $ixml_grammar = from_file('examples/arith-grammar.ixml');
  my $transformer = make_parser($ixml_grammar);
  my $ast = $transformer->(from_file($ixml_input));
  my $canonicaliser = make_canonicaliser($ixml_grammar);
  my $canonical = $canonicaliser->($ast);

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
    attributes => { open => '(', sign => '+', close => ')' },
    children => [
      { nodename => 'left', attributes => { name => 'a' } },
      { nodename => 'right', children => [ 'b' ] },
    ],
  }

Arguments:

=over

=item an "invisible XML" Pegex grammar specification, OR a L<Pegex::Grammar> object

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

=head2 make_canonicaliser

Exportable. Returns a function that when called with an AST as produced
from a document by a L</make_parser>, returns a canonical version of
the original document, or C<undef> if it failed.

Arguments:

=over

=item an XML::Invisible grammar

=back

It uses a few heuristics:

=over

=item literals that are 0-1 (C<?>) or any number (C<*>) will be omitted

=item literals that are at least one (C<+>) will be inserted once

=item if an "any" group is given, the first one that matches will be selected

This last one means that if you want a canonical representation that is
not the bare minimum, provide that as a literal first choice (see the
C<assign> rule below - while it will accept any or no whitespace, the
"canonical" version is given):

  expr: target .assign source
  target: +name
  assign: ' = ' | (- EQUAL -)
  source: -name
  name: /( ALPHA (: ALPHA | DIGIT )* )/

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
