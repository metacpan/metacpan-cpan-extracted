#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester tests => 2;
use Test::More;
use File::Spec::Functions;

BEGIN { 
    use_ok('Test::Image::GD');
}

my $path_to_cpan_gif  = catdir('t', 'cpan.gif');
my $path_to_cpan2_gif = catdir('t', 'cpan2.gif');
my $path_to_perl_gif  = catdir('t', 'download_perl.gif');

{
    my $cpan = GD::Image->new(200, 100);
    $cpan->colorAllocate(255, 255, 255);
    $cpan->string(GD::gdSmallFont(), (10 * $_), (10 * $_), "CPAN Rules", $cpan->colorAllocate(0, 0, 0))
        foreach 1 .. 5;
    open GIF1, ">", $path_to_cpan_gif || die "Could not create test GIF file";
    print GIF1 $cpan->gif;
    close GIF1;
}
{
    my $cpan2 = GD::Image->new(200, 100);
    $cpan2->colorAllocate(255, 255, 255);
    $cpan2->string(GD::gdSmallFont(), (10 * $_), (10 * $_), "CPAN Rules", $cpan2->colorAllocate(0, 0, 0))
        foreach 1 .. 5;
    open GIF2, ">", $path_to_cpan2_gif || die "Could not create test GIF file";
    print GIF2 $cpan2->gif;
    close GIF2;
}
{
    my $perl = GD::Image->new(200, 100);
    $perl->colorAllocate(255, 255, 255);
    $perl->string(GD::gdSmallFont(), (10 * $_), (10 * $_), "Perl Rules", $perl->colorAllocate(0, 0, 0))
        foreach 1 .. 5;
    open GIF3, ">", $path_to_perl_gif || die "Could not create test GIF file";
    print GIF3 $perl->gif;
    close GIF3;
}

test_out("ok 1 - ... these are the exact same images");
test_out("ok 2 - ... these are the same images visually");
test_out("not ok 3 - ... these are not the same images");
test_err("#     Failed test (t/20_cmp_image.t at line 58)");
test_out("ok 4 - ... these are the exact same images");
test_out("ok 5 - ... these are the same images visually");
test_out("not ok 6 - ... these are not the same images");
test_err("#     Failed test (t/20_cmp_image.t at line 66)");

cmp_image($path_to_cpan_gif, $path_to_cpan_gif, '... these are the exact same images');
cmp_image($path_to_cpan_gif, $path_to_cpan2_gif, '... these are the same images visually');

cmp_image($path_to_cpan_gif, $path_to_perl_gif, '... these are not the same images');

my $cpan  = GD::Image->new($path_to_cpan_gif);
my $cpan2 = GD::Image->new($path_to_cpan2_gif);
my $perl  = GD::Image->new($path_to_perl_gif);

cmp_image($cpan, $cpan2, '... these are the exact same images');
cmp_image($cpan, $cpan2, '... these are the same images visually');
cmp_image($cpan, $perl, '... these are not the same images');

test_test("cmp_image works");

unlink $path_to_cpan_gif;
unlink $path_to_cpan2_gif;
unlink $path_to_perl_gif;
