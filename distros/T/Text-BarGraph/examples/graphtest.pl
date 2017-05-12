#!/usr/bin/env perl
#
# Example of the Text::Bargraph module
#
# Kirk Baucom <kbaucom@schizoid.com>

use strict;
use warnings;

use Text::BarGraph;

# for the options below, if an option is a toggle, 0 = off, 1 = on
# all of the options have defaults

my $g = Text::BarGraph->new(

	# what character to use when printing the graphs
	# default: '.'
	dot => '#',
	
	# add color to the graph, denoting the size of the bars
	# default: 0 (off)
	enable_color => 1,

	# whether or not to print the numerical magnitude of the bar
	# default: 0 (off)
	num => 1,

	# force the graph to be larger than the data.
	# ignored if less than the max value in the data itself.
	# default: automatically determined from data
	max_data => 500,

	# whether or not to automatically determine the size of your screen. this
	# requires the module Term::Readkey. if this is off, your screen is assumed
	# to be 80 columns
	# default: 1 (on)
	autosize => 1,

	# number of columns on your display
	# this is ignored if autosize is set
	# default: 80
	columns => 40,

	# what value to set the far left of the screen to
	# default: 0
	zero => 0,

	# whether or not to automatically determine the value of the far left side
	# of the screen. if this is set, the value of 'zero' is ignored.
	# default: 0 (off)
	autozero => 0,

	# whether to sort the data by keys ("key") or values ("data"). 
	# default: "key"
	sortvalue => 'data',

	# whether to sort keys numerically ("numeric") or lexicographically ("string")
	# ignored if the sortvalue is data, which is always numeric
	# default: "string"
	sorttype => 'numeric'


);


# a small graph of some random numbers  

my %data = (
  alpha => 300,
  beta  => 400,
  gamma => 220,
  delta => 350,
);      

# print the graph. note that the graph routine just returns a text string,
# so you can manipulate it before you print it.

print "\nAutosized to screen width, if Term::ReadKey is available:\n";
print $g->graph(\%data);


# you can also modify any option on the object itself
print "\n40 columns, no autosizing:\n";
$g->dot(')');
$g->autosize(0);
$g->max_data(0);
print $g->graph(\%data);
