# $Id: 2_more.t,v 1.4 2002/10/11 02:00:46 grantm Exp $
##############################################################################
# These tests require a functional XML::SAX installation
#

use strict;
use Test::More;

BEGIN { # Seems to be required by older Perls

  unless(eval { require XML::SAX::Writer }) {
    plan skip_all => 'XML::SAX::Writer not installed';
  }

  unless(eval { require XML::SAX::ParserFactory }) {
    plan skip_all => 'XML::SAX::ParserFactory not installed';
  }

  # Test SAX installation

  eval {
    my $xml = '';
    my $writer = XML::SAX::Writer->new(Output => \$xml);
    my $parser = XML::SAX::ParserFactory->parser(Handler => $writer);
    $parser->parse_string('<doc>text</doc>');
  };
  if($@) {
    plan skip_all => "XML::SAX is not installed correctly: $@";
  }

}

plan tests => 32;

$^W = 1;

##############################################################################
# Confirm that the module compiles
#

use XML::Filter::NSNormalise;

ok(1, 'XML::Filter::NSNormalise compiled OK');


##############################################################################
# Create a filter, feed a document through it and confirm that the resulting
# document matches our expectations.
#

my $xml = '';
my $writer = XML::SAX::Writer->new(Output => \$xml);

my $filter = XML::Filter::NSNormalise->new(
  Map => {
    'http://purl.org/dc/elements/1.1/' => 'dc',
  },
  Handler => $writer,
);

ok(ref($filter), 'Created a filter object');

my $p = XML::SAX::ParserFactory->parser(Handler => $filter);
ok(ref($p), 'Created a parser object');

$@ = '';
eval {$p->parse_string(q{
  <rdf:RDF
   xmlns="http://purl.org/rss/1.0/"
   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
   xmlns:theonetruedublincore="http://purl.org/dc/elements/1.1/" >
    <theonetruedublincore:date>2002-10-08</theonetruedublincore:date>
  </rdf:RDF>
  });
};
is($@, '', 'Parsed with no errors');

ok($xml =~ s{xmlns=('|")http://purl\.org/rss/1\.0/\1}{ATTR},
   "Default namespace declaration untouched");

ok($xml =~ s{xmlns:rdf=('|")http://www.w3.org/1999/02/22-rdf-syntax-ns#\1}{ATTR},
   "RDF namespace declaration untouched");

ok($xml =~ s{xmlns:dc=('|")http://purl.org/dc/elements/1.1/\1}{ATTR},
   "DC namespace declaration mapped successfully");

like($xml, qr{
  ^\s*                               # optional leading whitespace
  <rdf:RDF\s+ATTR\s+ATTR\s+ATTR      # root element with three ns attrs
   \s*>                              # end the tag
   \s+<dc:date>2002-10-08</dc:date>  # date element with remapped prefix
   \s+</rdf:RDF>
   \s*$
}xs, "Got expected output");


##############################################################################
# Do it again and confirm that prefixes on attributes get mapped too.
#

$xml = '';
$writer = XML::SAX::Writer->new(Output => \$xml);

$filter = XML::Filter::NSNormalise->new(
  Map => {
    'companya.com' => 'a',
    'companyb.com' => 'b',
  },
  Handler => $writer,
);

my $p = XML::SAX::ParserFactory->parser(Handler => $filter);

$@ = '';
eval {$p->parse_string(q{
  <doc xmlns:alpha="companya.com" xmlns:beta="companyb.com">
    <ignore>Does nothing</ignore>
    <alpha:para id="1" alpha:align="left">paragraph one</alpha:para>
    <beta:para id="2" beta:align="right">paragraph two</beta:para>
  </doc>
  });
};
is($@, '', 'Parsed namespaced attributes with no errors');

ok($xml =~ s{xmlns:a=('|")companya.com\1}{ATTR},
   "Company A namespace declaration mapped successfully");

ok($xml =~ s{xmlns:b=('|")companyb.com\1}{ATTR},
   "Company B namespace declaration mapped successfully");

ok($xml =~ s{\s+id=('|")1\1}{ ATTR_A}, "Company A bare attribute unscathed");

ok($xml =~ s{\s+a:align=('|")left\1}{ ATTR_A},
   "Company A namespaced attribute mapped successfully");

ok($xml =~ s{\s+id=('|")2\1}{ ATTR_B}, "Company B bare attribute unscathed");

ok($xml =~ s{\s+b:align=('|")right\1}{ ATTR_B},
   "Company B namespaced attribute mapped successfully");

like($xml, qr{
  ^\s*                                # optional leading whitespace
  <doc\s+ATTR\s+ATTR\s*>              # root element with two ns attrs
   \s+<ignore>Does\snothing</ignore>  # innocent bystander
   \s+<a:para\s+ATTR_A\s+ATTR_A\s*>paragraph\sone</a:para>
   \s+<b:para\s+ATTR_B\s+ATTR_B\s*>paragraph\stwo</b:para>
   \s+</doc\s*>
   \s*$
}xs, "Namespaced attributes handled correctly");


##############################################################################
# Try mapping a URI to a prefix which is already used and ensure that it
# gets caught.
#

$xml = '';
$writer = XML::SAX::Writer->new(Output => \$xml);

$filter = XML::Filter::NSNormalise->new(
  Map => {
    'companya.com' => 'a',
  },
  Handler => $writer,
);

my $p = XML::SAX::ParserFactory->parser(Handler => $filter);

$@ = '';
eval {$p->parse_string(q{
  <doc xmlns:alpha="companya.com" xmlns:a="aardvark.com">
    <alpha:para>paragraph one</alpha:para>
    <a:para>paragraph two</a:para>
  </doc>
  });
};

like($@, qr/Cannot map 'companya\.com' to 'a' - prefix already occurs in document/, 
   'Caught attempt to map to a used prefix');


##############################################################################
# Try mapping a URI to the same prefix which is already used and ensure that it
# all still works.
#

$xml = '';
$writer = XML::SAX::Writer->new(Output => \$xml);

$filter = XML::Filter::NSNormalise->new(
  Map => {
    'companya.com' => 'a',
  },
  Handler => $writer,
);

my $p = XML::SAX::ParserFactory->parser(Handler => $filter);

$@ = '';
eval {$p->parse_string(q{
  <doc xmlns:a="companya.com" xmlns:aa="aardvark.com">
    <a:para>paragraph one</a:para>
    <aa:para>paragraph two</aa:para>
  </doc>
  });
};

is($@, '', 'Mapping to same prefix succeeded');

ok($xml =~ s{xmlns:a=('|")companya.com\1}{ATTR},
   "Original 'a' prefix declaration mapped successfully to itself");

ok($xml =~ s{xmlns:aa=('|")aardvark.com\1}{ATTR},
   "Original 'aa' prefix declaration survived unscathed");

like($xml, qr{
  ^\s*                                # optional leading whitespace
  <doc\s+ATTR\s+ATTR\s*>              # root element with two ns attrs
   \s+<a:para\s*>paragraph\sone</a:para>
   \s+<aa:para\s*>paragraph\stwo</aa:para>
   \s+</doc\s*>
   \s*$
}xs, "Resulting document unchanged");



##############################################################################
# Try mapping a URI used for the default namespace
#

$xml = '';
$writer = XML::SAX::Writer->new(Output => \$xml);

$filter = XML::Filter::NSNormalise->new(
  Map => {
    'companya.com' => 'a',
  },
  Handler => $writer,
);

my $p = XML::SAX::ParserFactory->parser(Handler => $filter);

$@ = '';
eval {$p->parse_string(q{
  <doc xmlns="companya.com">
    <para>paragraph one</para>
  </doc>
  });
};
is($@, '', 'Parsed mapped default namespace with no errors');

ok($xml =~ s{xmlns=('|")companya.com\1}{ATTR},
   "Default namespace declaration mapped successfully");

ok($xml =~ s{xmlns:a=('|")companya.com\1}{ATTR},
   "Explicit namespace prefix declaration added");

like($xml, qr{
  ^\s*                                  # optional leading whitespace
  <a:doc\s+ATTR\s+ATTR\s*>              # root element with two ns attrs
   \s+<a:para\s*>paragraph\sone</a:para>
   \s+</a:doc\s*>
   \s*$
}xs, "Default namespaced mapped correctly");


##############################################################################
# Try same again but with a couple of (different) nested default namespaces
#

$xml = '';
$writer = XML::SAX::Writer->new(Output => \$xml);

$filter = XML::Filter::NSNormalise->new(
  Map => {
    'companya.com' => 'a',
    'companyb.com' => 'b',
  },
  Handler => $writer,
);

my $p = XML::SAX::ParserFactory->parser(Handler => $filter);

$@ = '';
eval {$p->parse_string(q{
  <doc xmlns="companya.com">
    <para>paragraph one</para>
    <section xmlns="companyb.com">
      <para>paragraph two</para>
    </section>
    <section xmlns="companyc.com">
      <para>paragraph three</para>
    </section>
  </doc>
  });
};
is($@, '', 'Parsed nested default namespaces with no errors');

ok($xml =~ s{xmlns=('|")companya.com\1}{ATTR_A},
   "Default namespace declaration mapped successfully");

ok($xml =~ s{xmlns:a=('|")companya.com\1}{ATTR_A},
   "Explicit namespace prefix declaration added");

ok($xml =~ s{xmlns=('|")companyb.com\1}{ATTR_B},
   "Default namespace declaration mapped successfully");

ok($xml =~ s{xmlns:b=('|")companyb.com\1}{ATTR_B},
   "Explicit namespace prefix declaration added");

ok($xml =~ s{xmlns=('|")companyc.com\1}{ATTR_C},
   "Default namespace declaration mapped successfully");

like($xml, qr{
  ^\s*                                      # optional leading whitespace
  <a:doc\s+ATTR_A\s+ATTR_A\s*>              # root element with two ns attrs
   \s+<a:para\s*>paragraph\sone</a:para>
   \s+<b:section\s+ATTR_B\s+ATTR_B\s*>      # section with mapped default ns
     \s+<b:para\s*>paragraph\stwo</b:para>
   \s+</b:section\s*>
   \s+<section\s+ATTR_C\s*>                 # section with non-mapped default ns
     \s+<para\s*>paragraph\sthree</para>
   \s+</section\s*>
   \s+</a:doc\s*>
   \s*$
}xs, "Nested default namespaces mapped correctly");

