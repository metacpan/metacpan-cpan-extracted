##==============================================================================
## t/fields-aliased.t - test file for fields::aliased
##==============================================================================
## $Id: fields-aliased.t,v 1.2 2004/10/17 06:22:45 kevin Exp $
##==============================================================================
require 5.006;
use strict;
use warnings;
use Test::More tests => 31;

##==============================================================================
## This module tests the basic functionality: creating an object with the basic
## kinds of instance variables, and seeing the aliases are created correctly.
##==============================================================================
package Testing;
use strict;
use fields qw(
    $scalar @array %hash nosigil _%privhash _@privarray _private
);
Test::More::ok(1);

sub new {
    my $class = shift;
    my Testing $self = fields::new($class);
    use fields::aliased qw(
        $self $scalar @array %hash nosigil _%privhash _@privarray _private
    );

    $scalar = 1;
    $array[1] = 7;
    $hash{'foo'} = 'bar';
    $nosigil = 4;
    $_privhash{'foo'} = 'bar';
    @_privarray = (0 .. 3);
    $_private = 'huh?';

    return $self;
}

sub method {
    my Testing $self = shift;
    use fields::aliased qw(
        $self $scalar @array %hash nosigil _%privhash _@privarray _private
    );

    Test::More::ok($scalar == 1);
    Test::More::ok($array[1] == 7);
    Test::More::ok($hash{'foo'} eq 'bar');
    Test::More::ok($nosigil == 4);
    Test::More::ok($_privhash{'foo'} eq 'bar');
    Test::More::ok($_privarray[1] == 1);
    Test::More::ok($_private eq 'huh?');

    $scalar++;

    Test::More::ok($self->{'nosigil'} == 4);
    Test::More::ok($self->{'@array'}[1] == 7);
    Test::More::ok($self->{'$scalar'} == 2);
    Test::More::ok($self->{'%hash'}{'foo'} eq 'bar');
    Test::More::ok($self->{'_%privhash'}{'foo'} eq 'bar');
    Test::More::ok($self->{'_@privarray'}[1] == 1);
    Test::More::ok($self->{'_private'} eq 'huh?');
}

##==============================================================================
## Create a subclass of the package above to check inheritance issues.
##==============================================================================
package Testing::Subclass;
use base qw(Testing);
use fields qw($myscalar @myarray %myhash mynosigil);

sub new {
    my Testing::Subclass $self = shift->SUPER::new;
    use fields::aliased qw(
        $self $myscalar @myarray %myhash mynosigil
        $scalar @array %hash nosigil
    );

    Test::More::ok($scalar == 1);
    Test::More::ok($array[1] == 7);
    Test::More::ok($hash{'foo'} eq 'bar');
    Test::More::ok($nosigil == 4);

    $myscalar = 3;
    $myarray[0] = 'subclass';
    $myhash{'electric'} = 'slide';
    $mynosigil = 'nada';

    return $self;
}


sub method {
    my Testing::Subclass $self = shift;
    use fields::aliased qw(
        $self $scalar @array %hash nosigil
        $myscalar @myarray %myhash mynosigil
    );

    Test::More::ok($scalar == 1);
    Test::More::ok($array[1] == 7);
    Test::More::ok($hash{'foo'} eq 'bar');
    Test::More::ok($nosigil == 4);

    Test::More::ok($myscalar == 3);
    Test::More::ok($myarray[0] eq 'subclass');
    Test::More::ok($myhash{'electric'} eq 'slide');
    Test::More::ok($mynosigil eq 'nada');

    Test::More::ok($self->{'$myscalar'} == 3);
    Test::More::ok($self->{'@myarray'}[0] eq 'subclass');
    Test::More::ok($self->{'%myhash'}{'electric'} eq 'slide');
    Test::More::ok($self->{'mynosigil'} eq 'nada');
}

##==============================================================================
## Then create an instance of the object and check things out.
##==============================================================================
package main;
use strict;

my $object = new Testing;

$object->method;

my $object2 = new Testing::Subclass;

$object2->method;

##==============================================================================
## $Log: fields-aliased.t,v $
## Revision 1.2  2004/10/17 06:22:45  kevin
## Add tests for private fields.
##
## Revision 1.1  2004/10/01 02:51:46  kevin
## Many more tests, including testing a subclass.
##
## Revision 1.0  2004/09/28 02:57:31  kevin
## Initial revision
##==============================================================================
