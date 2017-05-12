use strict;
use Test::More skip_all => "because these tests are too hard to mock";
use Test;
use Win32::Mock;
use Win32;

my $path = "Long Path $$";
unlink($path);
END { unlink $path }

plan tests => 5;

Win32::CreateFile($path);
ok(-f $path);

my $short = Win32::GetShortPathName($path);
ok($short, qr/^\S{1,8}(\.\S{1,3})?$/);
ok(-f $short);

unlink($path);
ok(!-f $path);
ok(!defined Win32::GetShortPathName($path));
