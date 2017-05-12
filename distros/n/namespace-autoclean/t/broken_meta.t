use strict;
use warnings;
use Test::More 0.88;

{
    package OldMoose;
    sub meta { }
    sub does {  # copied roughly from Moose::Object, pre-2.0300
        my ($self, $role_name) = @_;
        my $meta = $self->meta;
        return 1 if $meta->can('does_role') && $meta->does_role($role_name);
        return 0;
    }
    sub dump {}
}

{
    package Foo;
    use base 'OldMoose';
    sub bar { }
    use namespace::autoclean;
    sub moo { }
    BEGIN { *kooh = *kooh = do { package Moo; sub { }; }; }
}

ok( Foo->can('bar'), 'Foo can bar - standard method');
ok( Foo->can('moo'), 'Foo can moo - standard method');
ok(!Foo->can('kooh'), 'Foo cannot kooh - anon sub from another package assigned to glob');
ok( Foo->can('dump'), 'Foo can dump - standard method from parent');

done_testing();
