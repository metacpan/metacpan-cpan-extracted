#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use_ok("Text::Lorem::More");
use Text::Lorem::More qw(lorem);

is(lorem->process("++name"), "+name");
like(lorem->process("+++name"), qr/^\+/);
isnt(lorem->process("+++name"), "+name");
isnt(lorem->process("+++name"), "++name");
isnt(lorem->process("+++name"), "+++name");
