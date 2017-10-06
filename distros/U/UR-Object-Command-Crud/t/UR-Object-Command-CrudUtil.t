#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use Path::Class;
use lib file(__FILE__)->dir->stringify;
use TestCrudClasses;

use Test::Exception;
use Test::More tests => 2;

my %test = ( pkg => 'UR::Object::Command::CrudUtil', );
subtest 'setup' => sub{
    plan tests => 2;

    use_ok($test{pkg}) or die;

    $test{muppet} = Test::Muppet->create(name => 'ernie');
    ok($test{muppet}, 'create muppet');

};

subtest 'display_id_for_value' => sub{
    plan tests => 5;

    is($test{pkg}->display_id_for_value, 'NULL', 'display_id_for_value for undef');
    is($test{pkg}->display_id_for_value(1), 1, 'display_id_for_value for string');
    is($test{pkg}->display_id_for_value($test{muppet}), $test{muppet}->id, 'display_id_for_value for object w/ id');

    throws_ok(sub{ $test{pkg}->display_id_for_value({}); }, qr/Do not pass/, 'fails w/ hash'); 
    throws_ok(sub{ $test{pkg}->display_id_for_value([]); }, qr/Do not pass/, 'fails w/ array'); 

};

done_testing();
