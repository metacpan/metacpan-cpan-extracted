#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use_ok( 'Tickit' );

use_ok( 'Tickit::Term' );
use_ok( 'Tickit::Pen' );
use_ok( 'Tickit::Rect' );
use_ok( 'Tickit::RectSet' );
use_ok( 'Tickit::Utils' );
use_ok( 'Tickit::StringPos' );

use_ok( 'Tickit::Window' );

done_testing;
