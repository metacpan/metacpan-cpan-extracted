#!/usr/bin/perl

use strict;
use Pod::Simple::HTMLBatch;

my $outdir = "$ENV{HOME}/WebServicesTechnoratiPod";
mkdir($outdir);
my $batchconv = Pod::Simple::HTMLBatch->new;
$batchconv->batch_convert( 'lib', $outdir );
print "output the html docs in $outdir\n";


