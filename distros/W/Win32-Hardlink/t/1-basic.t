use strict;
use Test::More tests => 3;
use FindBin;
use File::Spec;
use Win32::Hardlink;

ok(Win32::Hardlink->VERSION);

my $foo = File::Spec->catdir($FindBin::Bin, 'foo');
open FH, "> $foo" or die "Can't write to $foo: $!";
print FH "TEST";
close FH;

SKIP: {
    my $has_link = eval { Win32::Hardlink::link($foo => "$foo.new") };
    skip("No symlink available -- Not on NTFS?", 2) unless $has_link;

    ok(-f "$foo.new", "hardlink works");

    open FH, "< $foo.new" or die "Can't read from $foo.new: $!";
    is(scalar <FH>, "TEST", "hardlink preserves content");
    close FH;
}

END {
    unlink "$foo.new";
    unlink $foo;
}
