use strict;
use Test;
BEGIN { plan tests => 4 };

use FindBin;
use File::Spec;
use Win32::Symlink;

ok(Win32::Symlink->VERSION);

my $foo = File::Spec->catdir($FindBin::Bin, 'foo');
mkdir $foo or die $!;

my $has_symlink = eval { Win32::Symlink::symlink( $foo => "$foo.new" ) };

if (!$has_symlink) {
    skip(1) for 1..3;
    exit;
}

ok(-d "$foo.new");

open FH, "> ".File::Spec->catfile($foo, 'bar') or die $!;
print FH "TEST";
close FH;

open FH, "< ".File::Spec->catfile("$foo.new", 'bar') or die $!;
ok(scalar <FH>, "TEST");
close FH;

ok(readlink("$foo.new"), $foo);

END {
    unlink File::Spec->catfile($foo, 'bar');
    rmdir "$foo.new";
    rmdir $foo;
}
