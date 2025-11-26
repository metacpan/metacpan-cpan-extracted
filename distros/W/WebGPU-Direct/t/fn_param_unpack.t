use v5.30;
use Test::More;

use WebGPU::Direct;

my @nonempty_keys = qw/maxBindGroups maxBufferSize minUniformBufferOffsetAlignment/;

my $wgpu = WebGPU::Direct->new;

my $adapter = $wgpu->createAdapter( { compatibleSurface => undef } );
my $device  = $adapter->createDevice;

my $supported_limits = $wgpu->Limits->new;
my %limits           = $supported_limits->%*;

$adapter->getLimits($supported_limits);

# Select a few known to not be "0"
foreach my $k (@nonempty_keys)
{
  isnt( $supported_limits->$k, $limits{$k}, "$k differs like it should" );
}

# What happens when we call with a uninitalized value
$adapter->getLimits( {} );
ok( 1, 'Can call useless population of limits without results' );

done_testing;
