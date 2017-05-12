#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok( 'Tickit::Widgets' );

use_ok( 'Tickit::Widget::Border' );
use_ok( 'Tickit::Widget::Button' );
use_ok( 'Tickit::Widget::CheckButton' );
use_ok( 'Tickit::Widget::Entry' );
use_ok( 'Tickit::Widget::Fill' );
use_ok( 'Tickit::Widget::Frame' );
use_ok( 'Tickit::Widget::GridBox' );
use_ok( 'Tickit::Widget::HBox' );
use_ok( 'Tickit::Widget::HSplit' );
use_ok( 'Tickit::Widget::Placegrid' );
use_ok( 'Tickit::Widget::RadioButton' );
use_ok( 'Tickit::Widget::Spinner' );
use_ok( 'Tickit::Widget::VBox' );
use_ok( 'Tickit::Widget::VSplit' );

done_testing;
