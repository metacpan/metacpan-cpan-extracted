# $Id: pod_coverage.t,v 1.1 2006/01/24 17:45:08 mrodrigu Exp $

eval "use Test::Pod::Coverage 1.00 tests => 1";
if( $@)
  { print "1..1\nok 1\n";
    warn "Test::Pod::Coverage 1.00 required for testing POD coverage";
    exit;
  }

pod_coverage_ok( "Tree::DAG_Node::XPath");
