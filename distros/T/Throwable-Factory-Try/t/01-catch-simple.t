#!perl -T
use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Test::More;

use lib 'lib';
use Throwable::Factory::Try;

plan tests => 8;

my $ok;

###### "catch all" test
$ok = 0;
try {
    die
}
catch [
    '*' => sub { $ok = 1 },
];

ok($ok, "'Catch all' catch");

######  finally via catch test
$ok = 0;
try {
    die
}
catch [
    '*' => sub {}
],
finally {
    $ok = 1
};

ok($ok, "Finally via catch");

###### string test
$ok = 0;
try {
    die 'test'
}
catch [
    ':str' => sub { $ok = 1 },
];

ok($ok, "String catch");

###### string regexp test
$ok = 0;
try {
    die 'test regexp'
}
catch [
    [':str', qr/^test/] => sub { $ok = 1 },
];

ok($ok, "String regexp catch");

###### class test
$ok = 0;
try {
    my $obj = bless {}, 'My::Exception::Class';
    die $obj
}
catch [
    'My::Exception::Class' => sub { $ok = 1 },
];

ok($ok, "Class catch");

###### class regexp test
$ok = 0;
try {
    my $obj = bless {}, 'My::Exception::Class';
    die $obj
}
catch [
    qr/^My::.+::Stuff$/ => sub { $ok = 0 },
    qr/^My::.+::Class$/ => sub { $ok = 1 },
];

ok($ok, "Class regexp catch");

###### class list test
$ok = 0;
try {
    my $obj = bless {}, 'My::Exception::Class';
    die $obj
}
catch [
    ['My::Awesome::Class', 'My::Exception::Class'] => sub { $ok = 1 },
];

ok($ok, "Class list catch");

###### role test
$ok = 0;
{
    package My::Role;
    our $VAR=0;
    package My::Class;
    use base 'My::Role';
    
    sub new { return bless {}, 'My::Class' };
    
    package main;
    
    try {
        my $obj = My::Class->new;
        die $obj;
    }
    catch [
        'My::Role' => sub { $ok = 1 }
    ]
}

ok($ok, "Role catch");

