# $Id: /tree-xpathengine/trunk/t/00-load.t 21 2006-02-13T10:47:57.335542Z mrodrigu  $
use Test::More tests => 1;

BEGIN {
use_ok( 'Tree::XPathEngine' );
}

diag( "Testing Tree::XPathEngine $Tree::XPathEngine::VERSION, Perl 5.008007, /usr/bin/perl" );
