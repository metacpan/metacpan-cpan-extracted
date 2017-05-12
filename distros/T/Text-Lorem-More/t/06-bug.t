#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use_ok("Text::Lorem::More");
use Text::Lorem::More qw(lorem);
srand int(time * $$);
for (0 .. 2 ** 8) {
	unlike(lorem->mail, qr/name/, "$_: test for a e-mail \"domainname\" bug");
}
