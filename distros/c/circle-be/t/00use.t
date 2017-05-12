use strict;
use warnings;

use Test::More tests => 24;

use_ok( "Circle" );
use_ok( "Circle::Command" );
use_ok( "Circle::CommandInvocation" );
use_ok( "Circle::Commandable" );
use_ok( "Circle::Configurable" );
use_ok( "Circle::GlobalRules" );
use_ok( "Circle::RootObj" );
use_ok( "Circle::Rule::Chain" );
use_ok( "Circle::Rule::Resultset" );
use_ok( "Circle::Rule::Store" );
use_ok( "Circle::Ruleable" );
use_ok( "Circle::Session::Tabbed" );
use_ok( "Circle::TaggedString" );
use_ok( "Circle::Widget" );
use_ok( "Circle::Widget::Box" );
use_ok( "Circle::Widget::Entry" );
use_ok( "Circle::Widget::Label" );
use_ok( "Circle::Widget::Scroller" );
use_ok( "Circle::WindowItem" );

use_ok( "Circle::Net::IRC" );
use_ok( "Circle::Net::IRC::Target" );
use_ok( "Circle::Net::IRC::Channel" );
use_ok( "Circle::Net::IRC::User" );

use_ok( "Circle::Net::Raw" );
