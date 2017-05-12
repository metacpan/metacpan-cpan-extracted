#!/usr/bin/perl -w

# perl -MO=Terse dot.pl
require Carp;
sub dd {
die("foo");
}
dd(1,2,3);
die("foo","xx ");
