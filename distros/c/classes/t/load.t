# $Id: load.t 113 2006-08-13 05:42:19Z rmuhle $

use strict;

use Test::More;
eval 'use Test::Exception';
if ($@) {
    plan skip_all => 'Test::Exception needed';
} else {
    plan tests => 4;
}

use_ok( 'classes' );
can_ok 'classes', 'load';

lives_and( sub {
    package DefinedPkg;
    sub ihavesym {'ihavesym'};
    package main;
    classes::load('DefinedPkg');
    is( DefinedPkg->ihavesym, 'ihavesym'); 
}, 'load, ok with package that is already defined and not in file');

throws_ok( sub {
    classes::load('doesntexist');
}, 'X::Empty');
