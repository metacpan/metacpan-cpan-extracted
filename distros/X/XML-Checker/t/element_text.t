# contributed by Michel Rodriguez
use strict;

print "1..2\n";

use XML::Checker::Parser;

$/=''; # records are now separated by an empty line

# first parse, a valid document
my $doc1=<DATA>;
my $p= new XML::Checker::Parser;
eval
  { local $XML::Checker::FAIL= \&my_fail;
    $p->parse( $doc1);
  };

if( $@) { print "not ok 1: # $@\n"; }
else    { print "ok 1\n";         }

# second parse, an invalid document
my $doc2=<DATA>;
$p= new XML::Checker::Parser;

eval
  { local $XML::Checker::FAIL= \&my_fail;
    $p->parse( $doc2);
  };

if( $@) { print "ok 2\n"; }
else    { print "not ok 2\n";         }

# gets an error and dies after creating the error message
sub my_fail
  {  my ($code, $msg, %context)= @_;
     die " error $code ($msg) at line $context{line}, column
$context{column}";
  }

__DATA__
<?xml version="1.0"?>
<!DOCTYPE doc [
<!ELEMENT doc (elt+)>
<!ELEMENT elt (#PCDATA)>
]>
<!-- This document is valid -->
<doc><elt>foo</elt><elt>bar</elt></doc>

<?xml version="1.0"?>
<!DOCTYPE doc [
<!ELEMENT doc (elt|elt2)+>
<!ELEMENT elt (#PCDATA)>
<!ELEMENT elt2 EMPTY>
]>
<!-- This document is NOT valid -->
<doc>toto<!-- should trigger error -->
<elt2>not empty <!-- error --></elt2><elt>foo</elt><elt>bar</elt></doc>
