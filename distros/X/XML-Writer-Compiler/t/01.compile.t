#!/usr/bin/perl -w
use strict;

use t::lib::T;
use t::lib::U;

ok( my $compiler = XML::Writer::Compiler->new, 'XML::Writer::Compiler instance' );

my $tree = XML::TreeBuilder->new({ 'NoExpand' => 0, 'ErrorContext' => 0 });
$tree->parsefile("t/InvoiceAdd.xml");

my $firstdepth = 4;
my $prepend_lib = '';
my $class = 't::lib::InvoiceAdd';
my $pkgstring = $compiler->buildclass($class => $tree, $firstdepth, $prepend_lib);

my $description = 'test package generation';
my $file = 't/lib/InvoiceAdd.pm.expected';
file_contents_eq_or_diff($file, $pkgstring, $description);

done_testing;

