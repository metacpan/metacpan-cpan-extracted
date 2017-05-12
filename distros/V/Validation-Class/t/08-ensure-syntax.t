use FindBin;
use Test::More;

use utf8;
use strict;
use warnings;

{
    package TestClass::EnsureMethod1;
    use Validation::Class;

    field name => { required => 1, min_length => 2 };

    sub append_name {
        my ($self, $text) = @_;
        $text ||= 'is a genius';
        $self->name($self->name . ' ' . $text);
        return $self->name;
    }

    ensure append_name => { input => ['name'], output => ['name'] };

    package main;

    my $class = "TestClass::EnsureMethod1";
    my $self  = $class->new;

    ok $class eq ref $self, "$class instantiated";

    $self->name('i');
    ok ! $self->append_name('is a fool'), 'validation failed';
    like $self->errors_to_string => qr/2 char/, 'has error message';
    
    $self->name('me');
    ok $self->append_name('is a fool'), 'routine executed';
    like $self->name => qr/is a fool/, 'name appended as expected';
    ok ! $self->errors_to_string, 'no errors exist';
}

{
    package TestClass::EnsureMethod2;
    use Validation::Class;

    field  name => { required => 1, min_length => 2 };
    ensure name => { output => ['+name'] };

    package main;

    my $class = "TestClass::EnsureMethod2";
    my $self  = $class->new;

    ok $class eq ref $self, "$class instantiated";

    eval { $self->name('i') };
    like $@ => qr/less.*2 char/, 
        "post-field update failed validation";

    eval { $self->name('me') };
    die $@ if $@;
    ok !$@ && $self->is_valid, 
        "post field update passed validation";
}

done_testing;
