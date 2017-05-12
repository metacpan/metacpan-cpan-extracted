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

test_out("ok 1 - ... image is 200");
test_out("not ok 2 - ... image is not 100");
test_err("# ... (image => (width))");
test_err("#    w: (10 => 100)");
test_err("#     Failed test (t/50_width_ok.t at line 41)");
test_out("ok 3 - ... image is 400");
test_out("not ok 4 - ... image is not 200");
test_err("# ... (image => (width))");
test_err("#    w: (400 => 200)");
test_err("#     Failed test (t/50_width_ok.t at line 46)");

{
    my $img = GD::Image->new(200, 100);
    width_ok($img, 200, '... image is 200');
}

{
    my $img = GD::Image->new(10, 10);
    width_ok($img, 100, '... image is not 100');
}

{
    width_ok($image_path, 400, '... image is 400');
    width_ok($image_path, 200, '... image is not 200');
}


test_test("width_ok works");

unlink $image_path;
