#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Test::MockFile ();

my $path = '/some/nonexistant/path';
my $mock = Test::MockFile->file($path);

is( $mock->filename, $path, "$path is set when the file isn't there." );

open( my $fh, '>', $path ) or die;
print $fh "abc";
close $fh;

is( $mock->filename, $path, "$path is set when the file is there." );

done_testing();
