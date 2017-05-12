#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 32;

my $undef;
my $integer = 42;
my $float = 3.1415927;
my $string = 'Hello, world!';
my @array;
my %hash;
my $sub = sub {};
my $type = \&autobox::universal::type;
my $eundef = qr{^Can't call method "autobox_class" on an undefined value\b};

{
    use autobox UNIVERSAL => 'autobox::universal';

    # confirm that UNIVERSAL doesn't include UNDEF if UNDEF is not explicitly bound
    eval { is(undef->autobox_class->can('type'), $type) };
    like ($@, $eundef);

    eval { is($undef->autobox_class->can('type'), $type) };
    like ($@, $eundef);

    is(42->autobox_class->can('type'), $type);
    is(42->type, 'INTEGER');
    is($integer->autobox_class->can('type'), $type);
    is($integer->type, 'INTEGER');
    is(3.1415927->autobox_class->can('type'), $type);
    is(3.1415927->type, 'FLOAT');
    is($float->autobox_class->can('type'), $type);
    is(3.1415927->type, 'FLOAT');
    is(''->autobox_class->can('type'), $type);
    is(''->type, 'STRING');
    is('Hello, world!'->autobox_class->can('type'), $type);
    is('Hello, world!'->type, 'STRING');
    is($string->autobox_class->can('type'), $type);
    is($string->type, 'STRING');
    is([]->autobox_class->can('type'), $type);
    is([]->type, 'ARRAY');
    is(@array->autobox_class->can('type'), $type);
    is(@array->type, 'ARRAY');
    is({}->autobox_class->can('type'), $type);
    is({}->type, 'HASH');
    is(%hash->autobox_class->can('type'), $type);
    is(%hash->type, 'HASH');
    is((\&type)->autobox_class->can('type'), $type);
    is((\&type)->type, 'CODE');
    is($sub->autobox_class->can('type'), $type);
    is($sub->type, 'CODE');

    # add support for UNDEF
    use autobox UNDEF => 'autobox::universal';

    is(undef->autobox_class->can('type'), $type);
    is(undef->type, 'UNDEF');
    is($undef->autobox_class->can('type'), $type);
    is($undef->type, 'UNDEF');
}
