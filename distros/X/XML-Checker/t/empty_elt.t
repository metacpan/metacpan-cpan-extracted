# contributed by Philippe Verdret
use strict;
use lib '../lib';

print "1..2\n";

use XML::Checker::Parser;

$/ = ''; # records are now separated by an empty line

my $Test = 0;

# first parse, a valid document
$Test++;
my $doc1=<DATA>;
my $p= new XML::Checker::Parser;
eval
  { local $XML::Checker::FAIL= \&my_fail;
    $p->parse( $doc1);
  };

if( $@) { print "not ok $Test: $@\n"; }
else    { print "ok $Test\n";         }

# second parse, an invalid document
$Test++;
my $doc2 = <DATA>;
$p= new XML::Checker::Parser;

eval { 
    local $XML::Checker::FAIL= \&my_fail;
    $p->parse( $doc2);
  };

if( $@) { print "ok $Test: $@\n"; }
else    { print "not ok $Test\n";   }


# gets an error and dies after creating the error message
sub my_fail
  {  my ($code, $msg, %context)= @_;
     die " error $code ($msg) at line $context{line}, column $context{column}";
  }


__DATA__
<?xml version="1.0"?>
<!DOCTYPE X [
<!ELEMENT X (Y+)> 
<!ELEMENT Y (#PCDATA)>
]>
<X><Y></Y></X> <!-- Valid document -->

<?xml version="1.0"?>
<!DOCTYPE X [
<!ELEMENT X (Y+)> 
<!ELEMENT Y (#PCDATA)>
]>
<X></X> <!-- Not a valid document -->
