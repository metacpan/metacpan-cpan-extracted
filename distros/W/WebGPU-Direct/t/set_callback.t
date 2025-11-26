use v5.30;
use Test::More;

use WebGPU::Direct;

my $wgpu = WebGPU::Direct->new;

my $obj___ = eval { $wgpu->UncapturedErrorCallbackInfo->new };
my $obj_c_ = eval { $wgpu->UncapturedErrorCallbackInfo->new({ callback => sub {...} }) };
my $obj__u = eval { $wgpu->UncapturedErrorCallbackInfo->new({ userdata => {} }) };
my $obj_cu = eval { $wgpu->UncapturedErrorCallbackInfo->new({ callback => sub {...}, userdata => {} }) };
my $obj_cx = eval { $wgpu->UncapturedErrorCallbackInfo->new({ callback => sub {...}, userdata => 'callback' }) };
my $obj_xu = eval { $wgpu->UncapturedErrorCallbackInfo->new({ callback => 'callback', userdata => {} }) };
my $obj_Xu = eval { $wgpu->UncapturedErrorCallbackInfo->new({ callback => undef, userdata => {} }) };
$wgpu->UncapturedErrorCallbackInfo->new({ callback => undef, userdata => {} });

isnt( $obj___,           undef, '(__) Default new works' );

isnt( $obj_c_,           undef, '(c_) callback, no userdata, works' );
isnt( $obj_c_->callback, undef, '(c_) callback is not undef' );
is( $obj_c_->userdata, undef, '(c_) userdata is undef' );

isnt( $obj__u, undef, '(_u) userdata, no callback, works' );
is( $obj__u->callback, undef, '(_u) callback is undef' );
isnt( $obj__u->userdata, undef, '(_u) userdata is not undef' );

isnt( $obj_cu,           undef, '(cu) callback and userdata, works' );
isnt( $obj_cu->callback, undef, '(cu) callback is not undef' );
isnt( $obj_cu->userdata, undef, '(cu) userdata is not undef' );

isnt( $obj_cx,           undef, '(cx) callback and userdata, works' );
isnt( $obj_cx->userdata, undef, '(cx) userdata is not undef' );
is( ref $obj_cx->userdata, '', '(cx) userdata can be a string' );

is( $obj_xu, undef, '(xu) callback cannot be a string');

isnt($obj_Xu, undef, '(Xu) callback can be explictly undef');

# Check case when pack repacks the same data doesn't destroy things

done_testing;
