# NAME

XML::Invisible - transform "invisible XML" documents into XML using a grammar

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/mohawk2/xml-invisible.svg?branch=master)](https://travis-ci.org/mohawk2/xml-invisible) |

[![CPAN version](https://badge.fury.io/pl/XML-Invisible.svg)](https://metacpan.org/pod/XML::Invisible) [![Coverage Status](https://coveralls.io/repos/github/mohawk2/xml-invisible/badge.svg?branch=master)](https://coveralls.io/github/mohawk2/xml-invisible?branch=master)

# SYNOPSIS

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

# DESCRIPTION

An implementation of Steven Pemberton's Invisible XML concept, using
[Pegex](https://metacpan.org/pod/Pegex). Supply it with your grammar, in Pegex format (slightly
different from Steven's specification due to differences between his
notation and Pegex's), it returns you a function, which you can call to
transform "invisible XML" documents into actual XML.

This is largely a Pegex "receiver" class that exploits the `+` and `-`
syntax in rules in slightly unintended ways, and a wrapper to make
this operate.

# GRAMMAR SYNTAX

See [Pegex::Syntax](https://metacpan.org/pod/Pegex::Syntax). Generally, all rules will result in an XML
element. All terminals will need to capture with `()` (see example
below).

However, if you specify a dependent token with `+` it will
instead become an attribute (equivalent of Steven's `@`). If `-`,
this will "flatten" (equivalent of Steven's `-`) - the children will
be included without making an element of that node. Since in Pegex any
element can be skipped entirely with `.`, you can use that instead of
`-` to omit terminals.

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

When given `(a+b)` yields:

    <expr open="(" sign="+" close=")">
      <left name="a"/>
      <right>b</right>
    </expr>

# FUNCTIONS

## make\_parser

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

- an "invisible XML" grammar specification, in Pegex format

See [XML::Invisible::Receiver](https://metacpan.org/pod/XML::Invisible::Receiver) for more.

## ast2xml

Exportable. Turns an AST, as output by ["make\_parser"](#make_parser),
from [XML::Invisible::Receiver](https://metacpan.org/pod/XML::Invisible::Receiver) into an object of class
[XML::LibXML::Document](https://metacpan.org/pod/XML::LibXML::Document). Needs [XML::LibXML](https://metacpan.org/pod/XML::LibXML) installed, which as of
version 0.05 of this module is only a suggested dependency, not required.

Arguments:

- an AST from [XML::Invisible::Receiver](https://metacpan.org/pod/XML::Invisible::Receiver)

# DEBUGGING

To debug, set environment variable `XML_INVISIBLE_DEBUG` to a true value.

# SEE ALSO

[Pegex](https://metacpan.org/pod/Pegex)

[https://homepages.cwi.nl/~steven/ixml/](https://homepages.cwi.nl/~steven/ixml/) - Steven Pemberton's Invisible XML page

# AUTHOR

Ed J, `<etj at cpan.org>`

# BUGS

Please report any bugs or feature requests on
[https://github.com/mohawk2/xml-invisible/issues](https://github.com/mohawk2/xml-invisible/issues).

Or, if you prefer email and/or RT: to `bug-xml-invisible
at rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Invisible](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Invisible). I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

# LICENSE AND COPYRIGHT

Copyright 2018 Ed J.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)
