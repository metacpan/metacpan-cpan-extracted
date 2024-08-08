use v5.30;
use Test::More;
use Scalar::Util qw/refaddr/;

use WebGPU::Direct;

my @nonempty_keys = qw/maxBindGroups maxBufferSize minUniformBufferOffsetAlignment/;

my $wgpu = WebGPU::Direct->new;

my $adapter = $wgpu->requestAdapter( { compatibleSurface => undef } );
my $device  = $adapter->requestDevice;

my $supported_limits = $wgpu->SupportedLimits->new;
my %limits           = $supported_limits->limits->%*;

$adapter->getLimits($supported_limits);

# Select a few known to not be "0"
foreach my $k (@nonempty_keys)
{
  isnt( $supported_limits->limits->$k, $limits{$k}, "$k differs like it should" );
}

# What happens when we call with a uninitalized value
$adapter->getLimits( {} );
ok( 1, 'Can call useless population of limits without results' );

done_testing;
