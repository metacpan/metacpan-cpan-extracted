use strict;
use warnings;
use Test::More tests=> 22;
use Test::Exception;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

use URT;
use UR::Role;

subtest basic => sub {
    plan tests => 28;

    my $id_gen = 1;
    role URT::BasicRole {
        id_by => [
            role_id_property => { is => 'Integer' },
        ],
        has => [
            role_property => { is => 'String' },
        ],
        id_generator => sub { ++$id_gen },
        requires => [ 'required_property', 'required_method' ],
        excludes => [ ],
    };

    sub URT::BasicRole::role_method { 1 }

    class URT::BasicClass {
        has => [ 'regular_property', 'required_property' ],
        roles => 'URT::BasicRole',
    };

    sub URT::BasicClass::required_method { 1 }

    my $class_meta = URT::BasicClass->__meta__;
    ok($class_meta, 'BasicClass exists');
    ok(URT::BasicClass->does('URT::BasicRole'), 'BasicClass does() BasicRole');
    ok(! URT::BasicClass->does('URT::BasicClass'), "BasicClass doesn't() BasicClass");
    ok(! URT::BasicClass->does('Garbage'), "BasicClass doesn't() Garbage");

    my $role_instances = $class_meta->roles;
    is(scalar(@$role_instances), 1, 'Class has 1 roles');
    my $role_instance = $role_instances->[0];
    isa_ok($role_instance, 'UR::Role::Instance');
    is($role_instance->role_name, 'URT::BasicRole', 'Role instance role_name');
    is($role_instance->role_prototype, UR::Role::Prototype->get('URT::BasicRole'), 'Role instance role_prototype');
    is($role_instances->[0]->class_name, 'URT::BasicClass', 'Role instance class_name');
    is($role_instance->class_meta, $class_meta, 'Role instance class_meta');

    my @all_class_property_names = qw(role_id_property role_property regular_property required_property);
    my %property_is_id = (role_id_property => '0 but true', role_property => undef, regular_property => undef, required_property => undef );
    foreach my $prop_name ( @all_class_property_names ) {
        my $prop_meta = $class_meta->property($prop_name);
        is($prop_meta->is_id, $property_is_id{$prop_name}, "property $prop_name is_id value");
    }

    my %property_source = ( role_id_property => 'URT::BasicRole', role_property => 'URT::BasicRole',
                            regular_property => 'URT::BasicClass', required_property => 'URT::BasicClass' );
    foreach my $prop_name ( @all_class_property_names ) {
        my $expected_source = $property_source{$prop_name};
        my $prop_meta = $class_meta->property($prop_name);
        like($prop_meta->is_specified_in_module_header,
             qr/^$expected_source/,
             "property $prop_name is_specified_in_module_header");
    }

    my $o = URT::BasicClass->create(required_property => 1, role_property => 1, regular_property => 1);
    foreach my $method ( qw( role_id_property required_property role_property regular_property role_method required_method ) ) {
        ok($o->$method, "call $method");
    }

    is($o->id, $id_gen, 'id_generator was called to generate an ID');

    throws_ok
        {
            class URT::ClassWithBogusRole {
                roles => ['Bogus'],
            }
        }
        qr(Cannot apply role Bogus to class URT::ClassWithBogusRole: Can't locate object method "__role__" via package "Bogus"),
        'Could not create class with a bogus role';

    throws_ok { URT::BasicRole->get() }
        qr(Can't locate object method "get" via package "URT::BasicRole"),
        'Trying to get() a role by package name throws an exception';

    throws_ok { role URT::RoleWithIs { is => 'Bogus' } }
        qr(Bad Role defninition for URT::RoleWithIs.  Unrecognized properties:\s+is => Bogus),
        '"is" is not valid in a Role definition';
};

subtest 'multiple roles' => sub {
    plan tests => 6;

    sub URT::FirstRole::first_method { 1 }
    role URT::FirstRole {
        has => [ 'first_property' ],
    };

    sub URT::SecondRole::second_method { 1 }
    role URT::SecondRole {
        has => [ 'second_property' ],
    };

    sub URT::ClassWithMultipleRoles::class_method { 1 }
    class URT::ClassWithMultipleRoles {
        has => ['class_property'],
        roles => ['URT::FirstRole', 'URT::SecondRole'],
    };

    ok(URT::ClassWithMultipleRoles->__meta__, 'Created class with multiple roles');
    foreach my $role_name ( qw( URT::FirstRole URT::SecondRole ) ) {
        ok(URT::ClassWithMultipleRoles->does($role_name), "Does $role_name");
    }

    foreach my $method_name ( qw( first_method second_method class_method ) ) {
        ok(URT::ClassWithMultipleRoles->can($method_name), "Can $method_name");
    }
};

subtest requires => sub {
    plan tests => 5;

    role URT::RequiresPropertyRole {
        has => [ 'role_property' ],
        requires => ['required_property'],
    };

    throws_ok
        {
            class URT::RequiresPropertyClass {
                has => [ 'foo' ],
                roles => 'URT::RequiresPropertyRole',
            }
        }
        qr/missing required property or method 'required_property'/,
        'Omitting a required property throws an exception';



    role URT::RequiresPropertyAndMethodRole {
        requires => ['required_method', 'required_property' ],
    };

    sub URT::RequiresPropertyAndMethodHasMethod::required_method { 1 }
    throws_ok
        {
            class URT::RequiresPropertyAndMethodHasMethod {
                has => ['foo'],
                roles => 'URT::RequiresPropertyAndMethodRole',
            }
        }
        qr/missing required property or method 'required_property'/,
        'Omitting a required property throws an exception';


    throws_ok
        {
            class URT::RequiresPropertyAndMethodHasProperty {
                has => ['required_property'],
                roles => 'URT::RequiresPropertyAndMethodRole',
            }
        }
        qr/missing required property or method 'required_method'/,
        'Omitting a required method throws an exception';


    sub URT::RequiesPropertyAndMethodHasBoth::required_method { 1 }
    lives_ok
        {
            class URT::RequiesPropertyAndMethodHasBoth {
                has => ['required_property'],
                roles => 'URT::RequiresPropertyAndMethodRole',
            }
        }
        'Created class satisfying requirements';

    role URT::RequiresPropertyFromOtherRole {
        requires => ['role_property'],
    };

    lives_ok
        {
            class URT::RequiresBothRoles {
                has => ['required_property'],
                roles => ['URT::RequiresPropertyRole', 'URT::RequiresPropertyFromOtherRole'],
            }
        }
        'Created class with role requiring method from other role';

};

subtest 'conflict property' => sub {
    plan tests => 9;

    role URT::ConflictPropertyRole1 {
        has => [
            conflict_property => { is => 'RoleProperty' },
        ],
    };
    role URT::ConflictPropertyRole2 {
        has => [
            other_property => { is => 'Int' },
            conflict_property => { is => 'RoleProperty' },
        ],
    };
    throws_ok
        {
            class URT::ConflictPropertyClass {
                roles => ['URT::ConflictPropertyRole1', 'URT::ConflictPropertyRole2'],
            }
        }
        qr/Cannot compose role URT::ConflictPropertyRole2: Property 'conflict_property' conflicts with property in role URT::ConflictPropertyRole1/,
        'Composing two roles with the same property throws exception';


    throws_ok
        {
            class URT::ConflictPropertyClassWithProperty {
                has => ['conflict_property'],
                roles => ['URT::ConflictPropertyRole1', 'URT::ConflictPropertyRole2'],
            }
        }
        qr/Cannot compose role URT::ConflictPropertyRole2: Property 'conflict_property' conflicts with property in role URT::ConflictPropertyRole1/,
        'Composing two roles with the same property throws exception even if class has override property';

    sub URT::ConflictPropertyClassWithMethod::conflict_property { 1 }
    throws_ok
        {
            class URT::ConflictPropertyClassWithMethod {
                roles => ['URT::ConflictPropertyRole1', 'URT::ConflictPropertyRole2'],
            }
        }
        qr/Cannot compose role URT::ConflictPropertyRole2: Property 'conflict_property' conflicts with property in role URT::ConflictPropertyRole1/,
        'Composing two roles with the same property throws exception even if class has override method';


    lives_ok
        {
            class URT::ConflictPropertyClassWithProperty {
                has => [
                    conflict_property => { is => 'ClassProperty' },
                ],
                roles => ['URT::ConflictPropertyRole1'],
            }
        }
        'Composed role into class sharing property name';
    my $prop_meta = URT::ConflictPropertyClassWithProperty->__meta__->property('conflict_property');
    is($prop_meta->data_type, 'ClassProperty', 'Class gets the class-defined property');

    lives_ok
        {
            class URT::ConflictPropertyClassWithIdProperty {
                id_by => [ conflict_property => { is => 'ClassProperty' } ],
                roles => ['URT::ConflictPropertyRole1'],
            }
        }
        'Composed role into class sharing id-by property name';
    $prop_meta = URT::ConflictPropertyClassWithIdProperty->__meta__->property('conflict_property');
    is($prop_meta->data_type, 'ClassProperty', 'Class gets the class-defined property');
    ok($prop_meta->is_id, 'property is an id-by property');

    role URT::ConflictProperty::RoleWithIdProperty {
        id_by => 'role_id_property',
    };
    throws_ok
        {
            class URT::ConflictProperty::ClassRedefinesIdPropertyAsNonId {
                has => ['role_id_property'],
                roles => ['URT::ConflictProperty::RoleWithIdProperty'],
            }
        }
        qr(Cannot compose role URT::ConflictProperty::RoleWithIdProperty: Property 'role_id_property' was declared as a normal property in class URT::ConflictProperty::ClassRedefinesIdPropertyAsNonId, but as an ID property in the role),
        'Composing role with ID property into class as non-ID property fails';

};

subtest 'conflict methods' => sub {
    plan tests => 3;

    sub URT::ConflictMethodRole1::conflict_method { }
    role URT::ConflictMethodRole1 { };

    sub URT::ConflictMethodRole2::conflict_method { }
    role URT::ConflictMethodRole2 { };

    throws_ok
        {
            class URT::ConflictMethodClassMissingMethod {
                roles => ['URT::ConflictMethodRole1', 'URT::ConflictMethodRole2'],
            }
        }
        qr/Cannot compose role URT::ConflictMethodRole2: method conflicts with those defined in other roles\s+URT::ConflictMethodRole1::conflict_method/s,
        'Composing two roles with the same method throws exception';


    sub URT::ConflictMethodClassHasMethod::conflict_method { 1; }
    throws_ok
        {
            class URT::ConflictMethodClassHasMethod {
                roles => ['URT::ConflictMethodRole1'],
            }
        }
        qr/Cannot compose role URT::ConflictMethodRole1: Method name conflicts with class URT::ConflictMethodClassHasMethod:\s+conflict_method \(from URT::ConflictMethodClassHasMethod\)\s+Did you forget to add the 'Overrides' attribute\?/,
        'Composing a role with conflicting method in the class throws exception';


    sub URT::ParentClassHasConflictMethod::conflict_method { 1 }
    class URT::ParentClassHasConflictMethod { };
    throws_ok
        {
            class URT::ConflictMethodParentHasMethod {
                is => 'URT::ParentClassHasConflictMethod',
                roles => ['URT::ConflictMethodRole1'],
            }
        }
        qr/Cannot compose role URT::ConflictMethodRole1: Method name conflicts with class URT::ConflictMethodParentHasMethod:\s+conflict_method \(from URT::ParentClassHasConflictMethod\)\s+Did you forget to add the 'Overrides' attribute\?/,
        'Composing a role with method conflicting a parent class throws exception';
};

subtest 'conflict methods with overrides' => sub {
    plan tests => 9;

    sub URT::ConflictMethodOverrideRole1::conflict_method { 0; }
    role URT::ConflictMethodOverrideRole1 { };

    sub URT::ConflictMethodOverrideRole2::conflict_method { 0; }
    role URT::ConflictMethodOverrideRole2 { };

    do {
        package URT::ConflictMethodClassOverridesRole1;
        use URT;
        our $class_method_called = 0;
        sub URT::ConflictMethodClassOverridesRole1::conflict_method : Overrides(URT::ConflictMethodOverrideRole1)
            { $class_method_called++; 1 }
    };

    throws_ok
        {
            class URT::ConflictMethodClassOverridesRole1 {
                roles => ['URT::ConflictMethodOverrideRole1', 'URT::ConflictMethodOverrideRole2'],
            }
        }
        qr/Cannot compose role URT::ConflictMethodOverrideRole2: Method name conflicts with class URT::ConflictMethodClassOverridesRole1:\s+conflict_method \(from URT::ConflictMethodClassOverridesRole1\)\s+Did you forget to add the 'Overrides' attribute\?/,
        'Class declaring override for one role but not the other throws exception';

    lives_ok
        {
            class URT::ConflictMethodClassOverridesRole1 {
                roles => ['URT::ConflictMethodOverrideRole1'],
            }
        }
        'Class declares override for composing class';
    ok(URT::ConflictMethodClassOverridesRole1->conflict_method, 'Called conflict_method on the class');
    is($URT::ConflictMethodClassOverridesRole1::class_method_called, 1, 'Correct method was called');


    do {
        package URT::ConflictMethodClassOverridesBothRoles;
        use URT;
        sub URT::ConflictMethodClassOverridesBothRoles::conflict_method : Overrides(URT::ConflictMethodOverrideRole1, URT::ConflictMethodOverrideRole2)
            { 1 }
    };

    lives_ok
        {
            class URT::ConflictMethodClassOverridesBothRoles {
                roles => ['URT::ConflictMethodOverrideRole1', 'URT::ConflictMethodOverrideRole2'],
            }
        }
        'Class conflict method declares overrides for both roles';

    do {
        sub URT::ConflictMethodParentNoOverride::conflict_method { }
        class URT::ConflictMethodParentNoOverride { };

        package URT::ConflictMethodClassDoesOverride;
        use URT;
        sub URT::ConflictMethodClassDoesOverride::conflict_method : Overrides(URT::ConflictMethodOverrideRole1) { }
    };
    lives_ok
        {
            class URT::ConflictMethodClassDoesOverride {
                is => ['URT::ConflictMethodParentNoOverride'],
                roles => ['URT::ConflictMethodOverrideRole1'],
            }
        }
        'Class declared override even though parent did not';


    role URT::RoleWithPropertyOverriddenInClass {
        has => ['a_property'],
    };
    lives_ok
        {
            package URT::ClassUsesRoleAndOverridesPropertyWithMethod;
            use URT;
            sub a_property : Overrides(URT::RoleWithPropertyOverriddenInClass) { }
            class URT::ClassUsesRoleAndOverridesPropertyWithMethod {
                roles => ['URT::RoleWithPropertyOverriddenInClass'],
            }
        }
       'Class can declare method to override a role property';

    throws_ok
        {
            package URT::ClassDeclaresOverrideForNonExistantMethod;
            use URT;
            sub bogus : Overrides(URT::ConflictMethodOverrideRole1) { }
            class URT::ClassDeclaresOverrideForNonExistantMethod {
                roles => ['URT::ConflictMethodOverrideRole1'],
            };
        }
        qr(Cannot compose role URT::ConflictMethodOverrideRole1: Class method 'bogus' declares it Overrides non-existant method in the role),
        'Overriding a non-existant method throws an exception';

    throws_ok
        {
            package URT::ClassDeclaresOverrideForNonConsumedRole;
            use URT;
            sub bogus : Overrides(URT::ClassDeclaresOverride__RoleDoesNotExist) { }
            class URT::ClassDeclaresOverrideForNonConsumedRole { };
        }
        qr(Class method 'bogus' declares Overrides for roles the class does not consume: URT::ClassDeclaresOverride__RoleDoesNotExist),
        'Class Overriding a role it does not consume throws an exception';
};

subtest 'dynamic loading' => sub {
    plan tests => 4;

    sub URT::DynamicLoading::required_class_method { 1 }
    my $class =  class URT::DynamicLoading {
        has => ['required_class_param'],
        roles => ['URT::TestRole'],
    };
    ok($class, 'Created class with dynamically loaded role');
    ok($class->role_method, 'called role_method on the class');

    throws_ok { class URT::DynamicLoadingFail1 { roles => 'URT::NotExistant' } }
        qr/Cannot apply role URT::NotExistant to class URT::DynamicLoadingFail1: Can't locate object method "__role__" via package "URT::NotExistant"/,
        'Defining class with non-existant role throws exception';

    throws_ok { class URT::DynamicLoadingFail2 { roles => 'URT::Thingy' } }
        qr/Cannot apply role URT::Thingy to class URT::DynamicLoadingFail2: URT::Thingy was auto-generated successfully but cannot find method __role__ /,
        'Defing a class with a class name used as a role throws exception';
};

subtest 'inherits from class with role' => sub {
    plan tests => 5;

    role ParentClassRole {
        has => ['parent_role_param'],
    };
    sub ParentClass::parent_class_method { 1 }
    class ParentClass {
        roles => ['ParentClassRole'],
        has => ['parent_class_param'],
    };

    class ChildClass {
        is => 'ParentClass',
    };

    role GrandchildClassRole {
        has => ['grandchild_role_param'],
        requires => ['parent_class_param', 'parent_class_method'],
    };

    class GrandchildClass {
        is => 'ChildClass',
        roles => ['GrandchildClassRole'],
    };

    my $o = GrandchildClass->create(parent_class_param => 1,
                                    parent_role_param => 1,
                                    grandchild_role_param => 1);
    ok($o, 'Create object');
    ok($o->can('grandchild_role_param'), 'can grandchild_role_param');
    ok($o->can('parent_role_param'), 'can parent_role_param');
    ok($o->does('GrandchildClassRole'), 'does GrandchildClassRole');
    ok($o->does('ParentClassRole'), 'does ParentClassRole');
};

subtest 'role property saves to DB' => sub {
    plan tests => 10;

    my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
    ok($dbh->do(q(CREATE TABLE savable (id INTEGER NOT NULL PRIMARY KEY, class_property TEXT, role_property TEXT))),
        'Create table');
    ok($dbh->do(q(INSERT INTO savable VALUES (1, 'class', 'role'))),
        'Insert row');

    role SavablePropertyRole {
        has => ['role_property'],
    };
    class SavableToDb {
        roles => 'SavablePropertyRole',
        id_by => 'id',
        has => ['class_property'],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'savable',
    };

    foreach my $prop ( qw( class_property role_property ) ) {
        ok(SavableToDb->can($prop), "SavableToDb can $prop");
    }

    my $got = SavableToDb->get(1);
    ok($got, 'Get object from DB');
    is($got->class_property, 'class', 'class_property value');
    is($got->role_property, 'role', 'role_property value');

    my $saved = SavableToDb->create(id => 2, class_property => 'saved_class', role_property => 'saved_role');
    ok($saved, 'Create object');
    ok(UR::Context->commit(), 'commit');

    my $row = $dbh->selectrow_hashref('SELECT * from savable where id = 2');
    is_deeply($row,
              { id => 2, class_property => 'saved_class', role_property => 'saved_role' },
              'saved to the DB');
};

subtest 'role import function' => sub {
    plan tests => 8;

    my($import_called, @import_args) = (0, ());
    *RoleWithImport::__import__  = sub { $import_called++; @import_args = @_ };
    role RoleWithImport { };
    sub RoleWithImport::another_method { 1 }

    is($import_called, 0, '__import__ was not called after defining role');

    class ClassWithImport {
        roles => ['RoleWithImport'],
    };
    is($import_called, 1, '__import__ called when role is used');
    is_deeply(\@import_args,
              [ 'RoleWithImport', ClassWithImport->__meta__ ],
              '__import__called with role name and class meta as args');
    ok(! defined(&ClassWithImport::__import__), '__import__ was not imported into the class namespace');


    $import_called = 0;
    @import_args = ();
    class AnotherClassWithImport {
        roles => ['RoleWithImport'],
    };
    is($import_called, 1, '__import__ called when role is used again');
    is_deeply(\@import_args,
              [ 'RoleWithImport', AnotherClassWithImport->__meta__ ],
              '__import__called with role name and class meta as args');
    ok(! defined(&ClassWithImport::__import__), '__import__ was not imported into the class namespace');


    $import_called = 0;
    @import_args = ();
    class ChildClassWithImport {
        is => 'ClassWithImport',
    };

    is($import_called, 0, '__import__ was not called when a child class is defined');
};

subtest 'basic overloading' => sub {
    plan tests => 5;

    package OverloadingAddRole;
    use overload '+' => '_add_return_zero';
    our $add_called = 0;
    sub OverloadingAddRole::_add_return_zero {
        my($self, $other) = @_;
        $add_called++;
        return 0;
    }
    role OverloadingAddRole { };

    package OverloadingSubRole;
    use overload '-' => \&OverloadingRole::_sub_return_zero;
    our $sub_called = 0;
    sub OverloadingRole::_sub_return_zero {
        my($self, $other) = @_;
        $sub_called++;
        return 0;
    }
    role OverloadingSubRole { };

    package main;
    class OverloadingClass {
        roles => [qw( OverloadingAddRole OverloadingSubRole )],
    };

    my $o = OverloadingClass->create();
    ok(defined($o), 'Create object from class with overloading role');
    is($o + 1, 0, 'Adding to object returns overloaded value');
    is($OverloadingAddRole::add_called, 1, 'overloaded add called');

    is($o - 1, 0, 'Adding to object returns overloaded value');
    is($OverloadingSubRole::sub_called, 1, 'overloaded subtract called');
};

subtest 'overload fallback' => sub {
    plan tests => 6;

    package RoleWithOverloadFallbackFalse;
    use overload '+' => 'add_overload',
                fallback => 0;
    role RoleWithOverloadFallbackFalse { };
    sub add_overload { }

    package AnotherRoleWithOverloadFallbackFalse;
    use overload '-' => 'sub_overload',
                fallback => 0;
    role AnotherRoleWithOverloadFallbackFalse { };
    sub sub_overload { }

    package RoleWithOverloadFallbackTrue;
    use overload '*' => 'mul_overload',
                fallback => 1;
    role RoleWithOverloadFallbackTrue { };
    sub mul_overload { }

    package AnotherRoleWithOverloadFallbackTrue;
    use overload '/' => 'div_overload',
                fallback => 1;
    role AnotherRoleWithOverloadFallbackTrue { };
    sub div_overload { }

    package RoleWithOverloadFallbackUndef;
    use overload '""' => 'str_overload',
                fallback => undef;
    role RoleWithOverloadFallbackUndef { };
    sub str_overload { }

    package AnotherRoleWithOverloadFallbackUndef;
    use overload '%' => 'mod_overload';
    role AnotherRoleWithOverloadFallbackUndef { };
    sub mod_overload { }

    package main;
    lives_ok {
        class ClassWithMatchingFallbackFalse {
            roles => ['RoleWithOverloadFallbackFalse', 'AnotherRoleWithOverloadFallbackFalse'],
        } }
        'Composed two classes with overload fallback false';

    lives_ok {
        class ClassWithMatchingFallbackTrue {
            roles => ['RoleWithOverloadFallbackTrue', 'AnotherRoleWithOverloadFallbackTrue'],
        } }
        'Composed two classes with overload fallback true';

    lives_ok {
        class ClassWithMatchingFallbackUndef {
            roles => ['RoleWithOverloadFallbackUndef', 'AnotherRoleWithOverloadFallbackUndef'],
        }}
        'Composed wto classes with overload fallback undef';

    lives_ok {
        class ClassWithOneFallbackFalse {
            roles => ['RoleWithOverloadFallbackFalse', 'RoleWithOverloadFallbackUndef'],
        }}
        'Composed one role with fallback false and one fallback undef';

    lives_ok {
        class ClassWithOneFallbackTrue {
            roles => ['RoleWithOverloadFallbackTrue', 'RoleWithOverloadFallbackUndef'],
        }}
        'Composed one role with fallback true and one fallback undef';

    throws_ok {
        class ClassWithConflictFallback {
            roles => ['RoleWithOverloadFallbackFalse', 'RoleWithOverloadFallbackTrue'],
        }}
        qr(fallback value '1' conflicts with fallback value 'FALSE' in role RoleWithOverloadFallbackFalse),
        'Overload fallback conflict throws exception';
};

subtest 'overload conflict' => sub {
    plan tests => 5;

    package OverloadConflict1;
    use overload '+' => '_foo';
    role OverloadConflict1 { };
    sub OverloadConflict1::_foo { }

    package OverloadConflict2;
    use overload '+' => '_bar';
    role OverloadConflict2 { };
    sub OverloadConflict1::_bar { }

    package main;
    throws_ok { class OverloadConflictClass {
                    roles => [qw( OverloadConflict1 OverloadConflict2 )],
                } }
        qr(Cannot compose role OverloadConflict2: Overload '\+' conflicts with overload in role OverloadConflict1),
        'Roles with conflicting overrides cannot be composed together';


    package OverloadConflictResolvedClass;
    our $overload_called = 0;
    use overload '+' => sub { $overload_called++; return 'Overloaded' };

    package main;
    lives_ok
        {
            class OverloadConflictResolvedClass {
                roles => [qw( OverloadConflict1 OverloadConflict2 )],
        } }
        'Class with overrides composes both roles with overrides';

    my $o = OverloadConflictResolvedClass->create();
    ok(defined($o), 'Created instance');
    is($o + 1, 'Overloaded', 'overloaded method called');
    is($OverloadConflictResolvedClass::overload_called, 1, 'overload method called once');
};

subtest 'excludes' => sub {
    plan tests => 3;

    role Excluded { };
    role Excluder { excludes => ['Excluded'] };
    role NotExcluded { };

    lives_ok
        {
            class ExcludeClassWorks { roles => ['Excluder', 'NotExcluded'] };
        }
        'Define class with exclusion role not triggered';

    throws_ok
        {
            class ExcludeClass { roles => ['Excluded', 'Excluder'] };
        }
        qr(Cannot compose role Excluded into class ExcludeClass: Role Excluder excludes it),
        'Composing class with excluded role throws exception';

    throws_ok
        {
            class ExcludeClass2 { roles => ['Excluder', 'Excluded'] };
        }
        qr(Cannot compose role Excluded into class ExcludeClass2: Role Excluder excludes it),
        'Composing excluded roles in the other order also throws exception';
};

subtest 'class meta attribs' => sub {
    plan tests => 5;

    role RoleWithMetaAttribs {
        data_source => 'URT::DataSource::SomeSQLite',
        doc => 'doc from role',
        id_generator => 'generate_id_from_role',
        valid_signals => ['role_signal'],
    };
    lives_ok
        {
            class ClassGetsMetaAttribsFromRole {
                roles => ['RoleWithMetaAttribs'],
            }
        }
        'Define class using role which defines class meta attribs';

    my $meta = ClassGetsMetaAttribsFromRole->__meta__;
    is($meta->data_source_id, 'URT::DataSource::SomeSQLite', 'data source');
    is($meta->doc, 'doc from role', 'doc');
    is($meta->id_generator, 'generate_id_from_role', 'id_generator');
    is_deeply($meta->valid_signals, ['role_signal'], 'valid_signals');
};

subtest 'class overrides some meta attribs in role' => sub {
    plan tests => 5;

    lives_ok
        {
            class ClassOverridesSomeAttribs {
                roles => ['RoleWithMetaAttribs'],
                id_generator => 'generate_id_from_class',
            }
        }
        'Define class that overrides some meta attribs in role';

    my $meta = ClassOverridesSomeAttribs->__meta__;
    is($meta->data_source_id, 'URT::DataSource::SomeSQLite', 'data source');
    is($meta->doc, 'doc from role', 'doc');
    is($meta->id_generator, 'generate_id_from_class', 'id_generator');
    is_deeply($meta->valid_signals, ['role_signal'], 'valid_signals');
};

subtest 'roles with meta attrib conflicts' => sub {
    plan tests => 6;

    role AnotherRoleWithMetaAttribs {
        id_generator => 'generate_id_from_other_role',
    };

    throws_ok
        {
            class ClassComposesConflictingMetaAttrbRoles {
                roles => ['RoleWithMetaAttribs', 'AnotherRoleWithMetaAttribs'],
            }
        }
        qr(Meta property 'id_generator' conflicts with meta property from role RoleWithMetaAttribs),
        'Composing roles with conflicting class meta attribs throws exception';

    lives_ok
        {
            class ClassOverridesConflictingMetaAttrbRoles {
                roles => ['RoleWithMetaAttribs', 'AnotherRoleWithMetaAttribs'],
                id_generator => 'generate_id_from_class',
                valid_signals => ['class_signal'],
            }
        }
        'Compose roles with conflicting meta attribs, class overrides conflict';

    my $meta = ClassOverridesConflictingMetaAttrbRoles->__meta__;
    is($meta->data_source_id, 'URT::DataSource::SomeSQLite', 'data source');
    is($meta->doc, 'doc from role', 'doc');
    is($meta->id_generator, 'generate_id_from_class', 'id_generator');
    is_deeply($meta->valid_signals, ['class_signal','role_signal'], 'valid_signals');
};

subtest 'autogenerated ghost classes do not get roles' => sub {
    plan tests => 6;

    role LiveTestRole {
        requires => ['live_class_method'],
    };
    sub LiveTestRole::role_method { }

    class URT::LiveClass {
       roles => 'LiveTestRole',
    };
    sub URT::LiveClass::live_class_method { }

    my $o = URT::LiveClass->__define__(id => 1);
    ok($o, 'Created live class instance');
    ok($o->can('role_method'), 'Live instance can role_method');
    ok($o->delete, 'delete it');

    my $g;
    lives_ok { $g = URT::LiveClass::Ghost->get(1) }
        'Get ghost object';

    my $ghost_meta = UR::Object::Type->get('URT::LiveClass::Ghost');
    is(scalar(@{ $ghost_meta->roles }), 0, 'Ghost class has no roles');
    ok(! $g->can('role_method'), 'Ghost object cannot role_method');
};

subtest 'parameterized role' => sub {
    plan tests => 19;

    package ParameterizedRole;
    use URT;
    our $prop_type : RoleParam(prop_type);
    role ParameterizedRole {
        has => [
            role_prop => { is => $prop_type },
        ],
    };
    sub prop_type { $prop_type }
    sub anon_sub_with_prop_type { return sub { $prop_type } }

    package main;
    isa_ok($ParameterizedRole::prop_type,
            'UR::Role::Param',
            'Before being composed, role param');

    foreach my $class_data ( [ 'ClassWithParameterizedRole', 'Text' ], ['AnotherClassWithParameterizedRole', 'Number' ] ) {
        my($class_name, $role_param_value) = @$class_data;

        UR::Object::Type->define(
            class_name => $class_name,
            roles => [ ParameterizedRole->create(prop_type => $role_param_value) ],
        );

        my $roles = $class_name->__meta__->roles;
        is(scalar(@$roles), 1, 'Class has 1 roles');
        isa_ok($roles->[0], 'UR::Role::Instance');
        is_deeply($roles->[0]->role_params,
                    { prop_type => $role_param_value },
                    'Role instance params');

        is($class_name->__meta__->property('role_prop')->data_type,
            $role_param_value,
            'Role property metadata was filled in with the role param value');

        is($class_name->prop_type,
            $role_param_value,
            'Class method from role returns value of role param');

        my $o = $class_name->create();
        is($o->prop_type(),
            $role_param_value,
            'Object method from role returns value of role param');

        TODO: {
            local $TODO = "Returned subs aren't tagged with the originating invocant";

            my $sub = $class_name->anon_sub_with_prop_type();
            lives_and { is($sub->(),
                            $role_param_value,
                            "Sub run in the role's context returns value of the role param"); };
        };
    }

    throws_ok {
        class ClassWithTooManyRoleParams {
            roles => [ ParameterizedRole->create(prop_type => 111, bogus_param => 222) ],
        } }
        qr(Role ParameterizedRole does not recognize these params: bogus_param),
        'Passing unrecognized role params throws an exception';

    throws_ok {
        class ClassWithTooFewRoleParams {
            roles => [ ParameterizedRole->create() ],
        } }
        qr(Role ParameterizedRole expects values for these params: prop_type),
        'Omitting some role params throws an exception';

    throws_ok {
        class AntherClassWithTooFewRoleParams {
            roles => 'ParameterizedRole',
        } }
        qr(Role ParameterizedRole expects values for these params: prop_type),
        'Omitting some role params by using role name throws an exception';

    # we want to delay parsing this until now.  The attribute handler runs at compile time
    throws_ok {
        eval q(
                package RoleWithBadRoleParamAttribute;
                use URT;
                our $var : RoleParam;
                role RoleWithBadRoleParamAttribute { };
            );
            die $@ if $@;
        }
        qr(RoleParam attribute requires a name in parens),
        'Omitting name from RoleParam attribute throws exception';
};

subtest 'method modifier before' => sub {
    no warnings 'once';
    plan tests => 7;
    my @results;
    do {
        package RoleWithBeforeModifier;
        use UR::Role qw(before);
        role RoleWithBeforeModifier { };
        before test_sub => sub {
            my $str = join(',', @_);
            push @results, "before:$str";
            return undef;
        };

        package ClassWithBeforeModifier;
        *ClassWithBeforeModifier::test_sub = sub {
            my $str = join(',',@_);
            push @results, "test_sub:$str";
            return 1;
        };
        class ClassWithBeforeModifier { roles => 'RoleWithBeforeModifier' };
    };

    throws_ok
        { class ClassWithoutTestSub { roles => 'RoleWithBeforeModifier' } }
        qr/Method "test_sub" not found via class ClassWithoutTestSub/,
        'Consuming role modifying non-existent method throws exception';

    my $rv = ClassWithBeforeModifier->test_sub('foo');
    is($rv, 1, 'sub return value');
    is_deeply(\@results,
              ['before:ClassWithBeforeModifier,foo', 'test_sub:ClassWithBeforeModifier,foo'],
              'before modifer');


    @results = ();
    class ChildClassWithBeforeModifier {
        is => 'ClassWithBeforeModifier',
        roles => 'RoleWithBeforeModifier',
    };
    is(ChildClassWithBeforeModifier->test_sub('bar'), 1, 'child class sub return value');
    is_deeply(\@results,
              ['before:ChildClassWithBeforeModifier,bar',  # twice because it's wrapped in
               'before:ChildClassWithBeforeModifier,bar',  # both parent and child classes
               'test_sub:ChildClassWithBeforeModifier,bar',
              ],
              'before modifer');


    @results = ();
    class ParentClassWithMethodToOverride { };
    *ParentClassWithMethodToOverride::test_sub = sub {
        my $str = join(',', @_);
        push @results, "parent_test_sub:$str";
        2;
    };
    class ChildClassWithoutMethod {
        is => 'ParentClassWithMethodToOverride',
        roles => 'RoleWithBeforeModifier',
    };
    is(ChildClassWithoutMethod->test_sub('baz'), 2, 'child class with inherited method return value');
    is_deeply(\@results,
              ['before:ChildClassWithoutMethod,baz', 'parent_test_sub:ChildClassWithoutMethod,baz'],
              'before modifier on inherited method');
};

subtest 'method modifier after' => sub {
    plan tests => 8;
    my @results;
    my($wantarray_modifier, $wantarray_test_sub);
    do {
        package RoleWithAfterModifier;
        use UR::Role qw(after);
        role RoleWithAfterModifier { };
        after test_sub => sub {
            my $rv = shift || '<undef>';
            my $str = join(',',@_);
            push @results, "after:$rv:$str";
            $wantarray_modifier = wantarray();
            return undef;
        };

        package ClassWithAfterModifier;
        *ClassWithAfterModifier::test_sub = sub {
            my $str = join(',',@_);
            push @results, "test_sub:$str";
            $wantarray_test_sub = wantarray();
            return 1;
        };
        class ClassWithAfterModifier { roles => 'RoleWithAfterModifier' };
    };

    my $rv = ClassWithAfterModifier->test_sub('foo');
    is($rv, 1, 'sub return value');
    is($wantarray_modifier, '', 'scalar modifier wantarray');
    is($wantarray_test_sub, '', 'scalar test_sub wantarray');
    is_deeply(\@results,
              ['test_sub:ClassWithAfterModifier,foo', 'after:1:ClassWithAfterModifier,foo'],
              'after modifier');

    my @rv = ClassWithAfterModifier->test_sub();
    is($wantarray_modifier, 1, 'list modifier wantarray');
    is($wantarray_test_sub, 1, 'list test_sub wantarray');

    ClassWithAfterModifier->test_sub();
    is($wantarray_modifier, undef, 'list modifier wantarray');
    is($wantarray_test_sub, undef, 'list test_sub wantarray');
};

subtest 'method modifier around' => sub {
    plan tests => 2;
    my @results;
    do {
        package RoleWithAroundModifier;
        use UR::Role qw(around);
        role RoleWithAroundModifier { };
        around test_sub => sub {
            my $orig = shift;
            my $str = join(',',@_);
            push @results, "pre:$str";
            $orig->('multiple','params');
            push @results, "post:$str";
            undef;
        };

        package ClassWithAroundModifier;
        *ClassWithAroundModifier::test_sub = sub {
            my $str = join(',', @_);
            push @results, "test_sub:$str";
            return 1;
        };
        class ClassWithAroundModifier { roles => 'RoleWithAroundModifier' };
    };

    my $rv = ClassWithAroundModifier->test_sub('foo');
    is($rv, undef, 'sub return value');
    is_deeply(\@results,
              ['pre:ClassWithAroundModifier,foo', 'test_sub:multiple,params', 'post:ClassWithAroundModifier,foo'],
              'around modifier');
};
