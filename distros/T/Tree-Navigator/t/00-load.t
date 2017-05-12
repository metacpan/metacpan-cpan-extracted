#!perl -T

use Test::More tests => 11;

BEGIN {
  use_ok( 'Tree::Navigator' ) || print "Bail out!\n";
  use_ok('Tree::Navigator::App::PerlDebug');
  use_ok('Tree::Navigator::Node');
  use_ok('Tree::Navigator::Node::DBI');
  use_ok('Tree::Navigator::Node::DBIDM');
  use_ok('Tree::Navigator::Node::Filesys');
  use_ok('Tree::Navigator::Node::Perl::Ref');
  use_ok('Tree::Navigator::Node::Perl::StackTrace');
  use_ok('Tree::Navigator::Node::Perl::Symdump');
#  use_ok('Tree::Navigator::Node::Win32::Registry');
  use_ok('Tree::Navigator::View');
  use_ok('Tree::Navigator::View::TT2');
}

diag( "Testing Tree::Navigator $Tree::Navigator::VERSION, Perl $], $^X" );
