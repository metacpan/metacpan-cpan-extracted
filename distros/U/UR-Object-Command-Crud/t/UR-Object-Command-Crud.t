#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use Path::Class;
use lib file(__FILE__)->dir->stringify;
use TestCrudClasses;

use Test::Exception;
use Test::More tests => 4;

my %test;
subtest 'setup' => sub{
    plan tests => 1;

    %test = (
        pkg => 'UR::Object::Command::Crud',
        target_class => 'Test::Muppet',
        namespace => 'Test::Muppet::Command',
        target_name => 'test muppet',
        target_name_pl => 'test muppets',
        target_name_ub => 'test_muppet',
        target_name_ub_pl => 'test_muppets',
    );
    use_ok($test{pkg}) or die;

};

subtest 'create_command_subclasses' => sub{
    plan tests => 8;

    throws_ok(sub{ UR::Object::Command::Crud->create_command_subclasses; }, qr/No target_class given/, 'fails w/o target_class');

    my %sub_command_configs = map { $_ => { skip => 1 } } UR::Object::Command::Crud->buildable_sub_command_names;
    lives_ok(sub{
            $test{crud} = UR::Object::Command::Crud->create_command_subclasses(
                target_class => $test{target_class},
                sub_command_configs => \%sub_command_configs,
                );},
           'create_command_subclasses skipping all');
    for ( UR::Object::Command::Crud->buildable_sub_command_names ) {
        ok(!UR::Object::Type->get($test{namespace}.'::'.ucfirst($_)), "did not create sub command for $_");
    }
    $test{crud}->delete;

    lives_ok(sub{ $test{crud} = UR::Object::Command::Crud->create_command_subclasses(target_class => $test{target_class}); }, 'create_command_subclasses');

};

subtest 'crud and namespace target names' => sub{
    plan tests => 12;

    my $crud = $test{crud};
    for my $property (qw/ namespace target_class target_name target_name_pl target_name_ub target_name_ub_pl /) {
        is($test{crud}->$property, $test{$property}, "CRUD $property");
        is($test{namespace}->$property, $test{$property}, "$test{namespace} $property");
    }

};

subtest 'commands' => sub{
    plan tests => 17;

    for ( UR::Object::Command::Crud->buildable_sub_command_names ) {
        my $class_name = $test{crud}->sub_command_class_name_for($_);
        is($class_name, $test{namespace}.'::'.ucfirst($_), "$_ subcommand class name");
        lives_ok(sub { $class_name->__meta__; }, "$_ comand was created"); # will unit test individual commands
    }

    is_deeply([sort $test{crud}->namespace_sub_command_names], [sort UR::Object::Command::Crud->buildable_sub_command_names], 'namespace_sub_command_names');
    my @namespace_sub_command_classes = map { $test{crud}->sub_command_class_name_for($_); } UR::Object::Command::Crud->buildable_sub_command_names;
    is_deeply([sort $test{crud}->namespace_sub_command_classes], [sort @namespace_sub_command_classes], 'namespace_sub_command_classes');

    my @property_names = sort (qw/ name title job friends best_friend /);
    my $update_class = join('::', $test{namespace}, 'Update');
    my @expected_sub_command_classes = map { my $p = $_; join('::', $update_class, join('', map { ucfirst } split(/_/, ucfirst($_)))) } @property_names;
    is_deeply([$update_class->sub_command_classes], \@expected_sub_command_classes, 'update property sub command classes');
    my @existing_sub_commands = map { UR::Object::Type->get($_) } @expected_sub_command_classes;
    is(@existing_sub_commands, @expected_sub_command_classes, 'expected sub commands exist');

    for my $name (qw/ friends / ) {
        for my $type (qw/ Add Remove /) {
            my $update_property_tree_class = join('::', $update_class, join('', map { ucfirst } split(/_/, $name)), $type);
            my $sub_command = UR::Object::Type->get($update_property_tree_class);
            ok($sub_command, "$update_property_tree_class exists");
        }
    }

    my $relationship_sub_command = UR::Object::Type->get(join('::', $test{namespace}, 'Update', 'Relationship'));
    ok(!$relationship_sub_command, "relationship sub command does not exist");

};

done_testing();
