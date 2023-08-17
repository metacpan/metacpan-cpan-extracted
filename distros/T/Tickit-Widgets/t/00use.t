#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

require Tickit::WidgetRole::SingleChildContainer;

require Tickit::Widgets;

require Tickit::Widget::Border;
require Tickit::Widget::Box;
require Tickit::Widget::Button;
require Tickit::Widget::CheckButton;
require Tickit::Widget::Entry;
require Tickit::Widget::Fill;
require Tickit::Widget::Frame;
require Tickit::Widget::GridBox;
require Tickit::Widget::HBox;
require Tickit::Widget::HLine;
require Tickit::Widget::HSplit;
require Tickit::Widget::Placegrid;
require Tickit::Widget::RadioButton;
require Tickit::Widget::Spinner;
require Tickit::Widget::VBox;
require Tickit::Widget::VLine;
require Tickit::Widget::VSplit;

pass( "Modules loaded" );
done_testing;
