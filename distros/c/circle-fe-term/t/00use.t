#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;

use_ok( "Circle::FE::Term" );
use_ok( "Circle::FE::Term::Tab" );
use_ok( "Circle::FE::Term::Ribbon" );

use_ok( "Circle::FE::Term::Widget::Box" );
use_ok( "Circle::FE::Term::Widget::Scroller" );
use_ok( "Circle::FE::Term::Widget::Label" );
use_ok( "Circle::FE::Term::Widget::Entry" );


done_testing;
