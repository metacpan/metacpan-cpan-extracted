#!/usr/bin/env perl

use v5.30;
use Data::Dumper;
use Time::HiRes qw/time/;
use WebGPU::Direct qw/:all/;

my $wgpu = WebGPU::Direct->new;

my $width  = 600;
my $height = 600;

my $gpuContext = $wgpu->createSurface(
  {
    nextInChain => WebGPU::Direct->new_window( $width, $height ),
  }
);

my $adapter = $wgpu->requestAdapter({ compatibleSurface => $gpuContext });

my $limits = $wgpu->SupportedLimits->new;
if ( $adapter->getLimits($limits) )
{
  warn Data::Dumper::Dumper($limits);
}

my $features = $adapter->enumerateFeatures;
warn Data::Dumper::Dumper($features);

my $properties = WebGPU::Direct::AdapterProperties->new;
$adapter->getProperties($properties);
warn Data::Dumper::Dumper($properties);
