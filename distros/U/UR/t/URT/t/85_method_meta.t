use strict;
use warnings;
use Test::More skip_all => 'under development';
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';
use UR;

package Foo;

class Foo {
    
};

package main;

isa_ok('Foo',"UR::Object");
