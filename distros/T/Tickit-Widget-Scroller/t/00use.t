#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

require Tickit::Widget::Scroller;

require Tickit::Widget::Scroller::Item::Text;
require Tickit::Widget::Scroller::Item::RichText;

pass( 'Modules loaded' );
done_testing;
