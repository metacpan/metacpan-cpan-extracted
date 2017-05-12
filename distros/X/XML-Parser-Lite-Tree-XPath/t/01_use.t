use Test::More tests => 7;

use strict;
use lib 'lib';

BEGIN { use_ok('XML::Parser::Lite::Tree::XPath') };
BEGIN { use_ok('XML::Parser::Lite::Tree::XPath::Tokener') };
BEGIN { use_ok('XML::Parser::Lite::Tree::XPath::Token') };
BEGIN { use_ok('XML::Parser::Lite::Tree::XPath::Tree') };
BEGIN { use_ok('XML::Parser::Lite::Tree::XPath::Eval') };
BEGIN { use_ok('XML::Parser::Lite::Tree::XPath::Result') };
BEGIN { use_ok('XML::Parser::Lite::Tree::XPath::Axis') };
