#!/usr/bin/env perl

use Test::More;
use Test::Exception;
use Test::MockObject::Extends;

package MyModule;

use strict;
use warnings;

use fields qw(field1 field2);

sub new
{
    my $self = shift;
    $self    = fields::new($self) unless ref $self;
    return $self;
}

package main;

use Test::MockObject::Extends;
my $fieldy = MyModule->new;
isa_ok $fieldy, 'MyModule';

my $mocky;
lives_ok { $mocky = Test::MockObject::Extends->new( $fieldy ) }
    'fields-based object should be mockstensible';
isa_ok $mocky, 'MyModule';

done_testing;
