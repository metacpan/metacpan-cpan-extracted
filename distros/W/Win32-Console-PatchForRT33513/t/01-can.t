use strict;
use warnings;
use Test::More;
use Win32::Console::PatchForRT33513;

my $package = 'Win32::Console::PatchForRT33513';

ok( $package->can( 'VERSION' ), "$package can 'VERSION'" );

my $v;
ok( $v = $package->VERSION, "$package VERSION is '$v'" );

done_testing;
