#! /usr/bin/perl -w

use Text::Reform;

$data = "Now is the winter of our discontent made glorious summer...";

print form
	">>>> [[[[[[[[[[[[[[[[[[[[",
	'Foo:', $data;


print form
	"Foo: <<<<<<<<<<<<<<<<<<<<",
	      $data,
	"     [[[[[[[[[[[[[[[[[[[[",
	      $data;
