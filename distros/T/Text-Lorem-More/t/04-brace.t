#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use_ok("Text::Lorem::More");
use Text::Lorem::More qw(lorem);

like(lorem->generate("prefix+{name}suffix"), qr/^prefix.*suffix$/);
eval { lorem->generate("prefix+namesuffix") };
like($@, qr/^couldn't find generatelet for "namesuffix"/);
