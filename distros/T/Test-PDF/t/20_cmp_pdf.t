#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester tests => 2;
use Test::More;
use File::Spec::Functions;

BEGIN { 
    use_ok('Test::PDF');
}

test_out("ok 1 - ... our PDFs were essentially the same");
test_out("ok 2 - ... our PDFs were essentially the same");
test_out("not ok 3 - ... our PDFs are not the same");
test_err("#     Failed test (t/20_cmp_pdf.t at line 35)");

test_out("ok 4 - ... our PDFs were essentially the same");
test_out("not ok 5 - ... our PDFs are not the same");
test_err("#     Failed test (t/20_cmp_pdf.t at line 47)");

cmp_pdf(
    catdir('t', 'hello_world.pdf'), 
    catdir('t', 'hello_world.pdf'), 
    '... our PDFs were essentially the same'
);

cmp_pdf(
    catdir('t', 'hello_world.pdf'), 
    catdir('t', 'hello_world_2.pdf'), 
    '... our PDFs were essentially the same'
);

cmp_pdf(
    catdir('t', 'foo_bar.pdf'), 
    catdir('t', 'hello_world.pdf'), 
    '... our PDFs are not the same'
);

cmp_pdf(
    CAM::PDF->new(catdir('t', 'foo_bar.pdf')), 
    CAM::PDF->new(catdir('t', 'foo_bar.pdf')), 
    '... our PDFs were essentially the same'
);

cmp_pdf(
    CAM::PDF->new(catdir('t', 'foo_bar.pdf')), 
    CAM::PDF->new(catdir('t', 'hello_world.pdf')), 
    '... our PDFs are not the same'
);

test_test("cmp_pdf works");