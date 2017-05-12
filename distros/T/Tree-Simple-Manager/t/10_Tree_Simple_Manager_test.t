#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

BEGIN { 
    use_ok('Tree::Simple::Manager');
    use_ok('Tree::Simple::Manager::Index');
    use_ok('Tree::Simple::Manager::Exceptions');    
}

