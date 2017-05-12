use strict;
use warnings;
use T 'More';

t->ok(1, "ok works");
t is => ('a', 'a', "'is' works");

t note => "done_testing comes next";
t->done_testing;
