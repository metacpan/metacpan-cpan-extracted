#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

require Tickit;

require Tickit::Term;
require Tickit::Pen;
require Tickit::Rect;
require Tickit::RectSet;
require Tickit::Utils;
require Tickit::StringPos;

require Tickit::Window;
require Tickit::RenderBuffer;

pass( 'Modules loaded' );
done_testing;
