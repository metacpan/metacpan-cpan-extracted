#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester tests => 2;
use Test::More;
use File::Spec::Functions;

BEGIN { 
    use_ok('Test::Image::GD');
}

my $image_path = catdir('t', 'temp.gif');

{
    my $img = GD::Image->new(400, 400);
    open GIF, ">", $image_path || die "Could not create test GIF file";
    print GIF $img->gif;
    close GIF;
}

test_out("ok 1 - ... image is (200 x 100)");
test_out("not ok 2 - ... image is not (100 x 200)");
test_err("# ... (image => (width, height))");
test_err("#    w: (100 => 100)");
test_err("#    h: (100 => 200)");
test_err("#     Failed test (t/30_size_ok.t at line 43)");
test_out("ok 3 - ... image is (400 x 400)");
test_out("not ok 4 - ... image is not (100 x 200)");
test_err("# ... (image => (width, height))");
test_err("#    w: (400 => 100)");
test_err("#    h: (400 => 200)");
test_err("#     Failed test (t/30_size_ok.t at line 48)");

{
    my $img = GD::Image->new(200, 100);
    size_ok($img, [ 200, 100 ], '... image is (200 x 100)');
}

{
    my $img = GD::Image->new(100, 100);
    size_ok($img, [ 100, 200 ], '... image is not (100 x 200)');
}

{
    size_ok($image_path, [ 400, 400 ], '... image is (400 x 400)');
    size_ok($image_path, [ 100, 200 ], '... image is not (100 x 200)');
}


test_test("size_ok works");

unlink $image_path;
