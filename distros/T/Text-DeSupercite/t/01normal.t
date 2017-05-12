use strict;
use Test::More tests => 9;


use_ok('Text::DeSupercite',qw(desupercite));


##
#  Simple Example
##

my $t1 = <<T1;
>>>>> "Foo" == Foo  <foo.net> writes:

>> some stuff here 

Bob> quoted text here 

Unquoted 
-- 
sig goes here 
T1

my $f1 = <<F1;
>>>>> "Foo" == Foo  <foo.net> writes:

>> some stuff here 

> quoted text here 

Unquoted 
-- 
sig goes here 
F1


my $r1;
ok($r1 = desupercite($t1));
is($r1, $f1, "simple example");



##
# Nested example
## 


my $t2 = <<T2;
>>>>> "Foo" == Foo  <foo.net> writes:

>> some stuff here 

> Bob> quoted text here 

Unquoted 
-- 
sig goes here 
T2

my $f2 = <<F2;
>>>>> "Foo" == Foo  <foo.net> writes:

>> some stuff here 

> > quoted text here 

Unquoted 
-- 
sig goes here 
F2


my $r2;
ok($r2 = desupercite($t2));
is($r2, $f2, "nested  example");


##
# Double Nested example
## 


my $t3 = <<T3;
>>>>> "Foo" == Foo  <foo.net> writes:

>> some stuff here 

Bob> Bob> quoted text here 

Unquoted 
-- 
sig goes here 
T3

my $f3 = <<F3;
>>>>> "Foo" == Foo  <foo.net> writes:

>> some stuff here 

> > quoted text here 

Unquoted 
-- 
sig goes here 
F3


my $r3;
ok($r3 = desupercite($t3));
is($r3, $f2, "double nested");

##
#  Other bad quote Nested example
## 


my $t4 = <<T4;
>>>>> "Foo" == Foo  <foo.net> writes:

>> some stuff here 

| Bob> quoted text here 

Unquoted 
-- 
sig goes here 
T4

my $f4 = <<F4;
>>>>> "Foo" == Foo  <foo.net> writes:

>> some stuff here 

| > quoted text here 

Unquoted 
-- 
sig goes here 
F4


my $r4;
ok($r4 = desupercite($t4));
is($r4, $f4, "bad quote");



