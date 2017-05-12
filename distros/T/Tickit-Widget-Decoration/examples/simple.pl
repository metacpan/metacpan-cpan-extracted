#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Tickit::DSL;
use Tickit::Widget::Decoration;

Tickit->new(root => Tickit::Widget::Decoration->new)->run;


