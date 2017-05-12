#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Warn;

use Text::Lorem::More;

plan qw/no_plan/;

my $lorem = Text::Lorem::More->new;
warning_is { $lorem->fullname(20) } undef;
