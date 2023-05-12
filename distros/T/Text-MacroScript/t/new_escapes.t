#!/usr/bin/perl

# Copyright (c) 2015 Paulo Custodio. All Rights Reserved.
# May be used/distributed under the GPL.

use strict;
use warnings;
use Test::More;

my $ms;
use_ok 'Text::MacroScript';

# escapes and concat
$ms = new_ok('Text::MacroScript');
is $ms->expand(), "";
is $ms->expand("hello"), "hello";

is $ms->expand("hello \\\n world"), "hello   world";
is $ms->expand("hello \\% world"), "hello % world";
is $ms->expand("hello \\# world"), "hello # world";
is $ms->expand("hello ## world"), "helloworld";

# escapes and concat
$ms = new_ok('Text::MacroScript', [-embedded => 1]);
is $ms->expand(), "";
is $ms->expand("hello"), "hello";

is $ms->expand("hello \\\n world"), "hello \\\n world";
is $ms->expand("hello \\% world"), "hello \\% world";
is $ms->expand("hello \\# world"), "hello \\# world";
is $ms->expand("hello ## world"), "hello ## world";

is $ms->expand("hello <:\\\n:> world"), "hello   world";
is $ms->expand("hello <:\\% world"), "hello % world";
is $ms->expand("hello \\# :>world"), "hello # world";
is $ms->expand("<:hello ## :>world"), "helloworld";

done_testing;
