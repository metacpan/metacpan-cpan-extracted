
# $Id: dump.t 113 2006-08-13 05:42:19Z rmuhle $

use Test::More tests=>1;

    package MixMe;
    sub mixed_in {'yes'};

    package main;
    use classes
        name  => 'MySuper',
        attrs => ['color'],
        new   => 'classes::new_args',
    ;

    use classes
        name            => 'MyClass',
        extends         => 'MySuper',
        new             => 'classes::new_init',
        init            => 'classes::init_args',
        throws          => 'X::Usage',
        exceptions      => 'X::MyOwn',
        mixes           => 'MixMe',
        class_attrs_ro  => { 'Read_Only_Attr'=>'yes' },
        class_attrs     => { 'Attr'=>1 },
        attrs_ro        => [ 'read_only_attr' ],
        attrs           => [ 'attr' ],
        class_methods   => { 'Empty_Method'=>0 },
        methods         => { abstract_method=>'ABSTRACT' },
    ;

    my $object = MyClass->new(attr=>'ok');
    $object->set_color('green');
#    $object->classes::dump;

    is $object->get_attr, 'ok';

#TODO

