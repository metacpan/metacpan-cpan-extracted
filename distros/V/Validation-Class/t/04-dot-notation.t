use FindBin;
use Test::More;

use utf8;
use strict;
use warnings;

{

    package TestClass::DotNoation;
    use Validation::Class;

    has update => 0;

    field 'public.fullname' => {
        mixin    => [':str', ':full_name'],
        filters  => ['autocase'],
        required => 1,
    };

    field 'private.fullname' => {
        mixin    => ':str',
        required => 1,
    };

    field 'private.emailaddress' => {
        mixin    => ':str',
        required => 1,
        email    => 1
    };

    method 'dienice' => {
        input => ['private.emailaddress', 'private.fullname'],
        using => sub {

            my $self = shift;
               $self->update(1);

        }
    };

    package main;

    my $class = "TestClass::DotNoation";
    my $self  = $class->new(
        params => {
            'public.fullname'       => 'Al Newkirk',
            'private.fullname'      => 'Al Newkirk',
            'private.emailaddress'  => 'awncorp@cpan.org',
        }
    );

    ok $class eq ref $self, "$class instantiated";

    ok $self->can('public_fullname'),       "$class has public_fullname";
    ok $self->can('private_emailaddress'),  "$class has private_emailaddress";
    ok $self->can('private_fullname'),      "$class has private_fullname";
    ok $self->can('dienice'),               "$class has method dienice";

    ok $self->validate('private.emailaddress', 'private.fullname'),
        "$class validated private.emailaddress and private.fullname directly"
    ;

    ok $self->dienice,
        "$class validated private.emailaddress and private.fullname via dienice"
    ;

    ok $self->update,
        "$class set the 'updated' attr from the dienice self-validating method"
    ;

}

done_testing;
