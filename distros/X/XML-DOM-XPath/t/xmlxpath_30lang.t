# $Id: xmlxpath_30lang.t,v 1.1 2003/12/04 22:46:57 mrodrigu Exp $

use Test;
plan( tests => 4);
use XML::DOM::XPath;
ok(1);

my $parser= XML::DOM::Parser->new;
my $t= $parser->parse( \*DATA); 
ok( $t);

my @en = $t->findnodes( '//*[lang("en")]');
ok(@en, 2);

my @de = $t->findnodes( '//content[lang("de")]');
ok(@de, 1);

__DATA__
<page xml:lang="en">
  <content>Here we go...</content>
  <content xml:lang="de">und hier deutschsprachiger Text :-)</content>
</page>
