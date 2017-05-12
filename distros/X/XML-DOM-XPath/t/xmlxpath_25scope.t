# $Id: xmlxpath_25scope.t,v 1.1.1.1 2003/12/04 20:40:43 mrodrigu Exp $

use strict;

use Test;
plan( tests => 4);
use XML::DOM::XPath;
ok(1);

eval
{
  # Removing the 'my' makes this work?!?
  my $parser= XML::DOM::Parser->new;
  my $t= $parser->parse( '<test/>');
  ok( $t);

  $t->findnodes( '/test');

  ok(1);

  die "This should be caught\n";

};

if ($@)
{
  ok(1);
}
else {
    ok(0);
}
