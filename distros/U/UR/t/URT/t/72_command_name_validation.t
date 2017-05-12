#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";

use UR;
use Test::More;

my %tests = (
    'WordWord' => 'word-word',
    'Word456Word' => 'word456-word',
    'Word456aWord' => 'word456a-word',
    '456Word' => '456-word',
    'Word456' => 'word456',
    'WWWord' => 'w-w-word',
    '456' => '456',
);          
               
plan tests => scalar(keys(%tests));

for my $class (keys %tests) {

    my $self = 'URT::' . $class;

    UR::Object::Type->define(
        class_name => $self,
        is => 'Command',
    );

    
    my $command_name = $self->command_name_brief($class);
    is($command_name, $tests{$class}, 'command name for class style: ' . $class);
}
