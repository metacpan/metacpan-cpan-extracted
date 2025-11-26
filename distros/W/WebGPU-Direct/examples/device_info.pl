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

my $adapter = $wgpu->createAdapter( { compatibleSurface => $gpuContext } );

local $Data::Dumper::Sortkeys = 1;

warn Data::Dumper::Dumper( $adapter->getFeatures );

if ( my $limits = $adapter->getLimits )
{
  warn Data::Dumper::Dumper($limits);
}

if ( my $info = $adapter->getInfo )
{
  warn Data::Dumper::Dumper($info);
}
