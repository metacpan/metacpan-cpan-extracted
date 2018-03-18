package Test2::Tools::xUnit 0.003;

use strict;
use warnings;

use B;
use Test2::Workflow;
use Test2::Workflow::Runner;
use Test2::Workflow::Task::Action;

sub import {
    my @caller = caller;

    # This sets up the root Test2::Workflow::Build for the package we are
    # being called from.  All tests will be added as actions later.
    my $root = Test2::Workflow::init_root(
        $caller[0],
        code  => sub { },
        frame => \@caller,
    );

    # Each test method is run in its own instance.  This setup action will
    # be called before each test method is invoked, and instantiates a new
    # object.
    #
    # If the caller does not provide a "new" constructor, we bless a hashref
    # into the calling package and use that.
    #
    # Each coderef is called with the Test2::Workflow::Runner as the first
    # argument.  We abuse this so that we can pass the same instance variable
    # to the setup, test and teardown methods.
    $root->add_primary_setup(
        Test2::Workflow::Task::Action->new(
            code => sub {
                shift->{xUnit}
                    = $caller[0]->can('new')
                    ? $caller[0]->new
                    : bless {}, $caller[0];
            },
            name     => 'object_construction',
            frame    => \@caller,
            scaffold => 1,
        )
    );

    # We add a follow-up task to the top hub in the stack, which will be
    # executed when done_testing or END is seen.
    Test2::API::test2_stack->top->follow_up(
        sub { Test2::Workflow::Runner->new( task => $root->compile )->run } );

    # This sub will be called whenever the Perl interpreter hits a subroutine
    # with attributes in our caller.
    #
    # It closes over $root so that it can add the actions, and @caller so that
    # it knows which package it's in.
    my $modify_code_attributes = sub {
        my ( undef, $code, @attrs ) = @_;

        my $name = B::svref_2object($code)->GV->NAME;

        my ( $method, $class_method, %options, @unhandled );

        for (@attrs) {
            if ( $_ eq 'Test' ) {
                $method = 'add_primary';
            }
            # All the setup methods count as 'scaffolding'.
            # Test2::Workflow docs are light on what this actually does;
            # something to do with filtering out the events?  Anyway,
            # Test2::Tools::Spec does it.
            elsif ( $_ eq 'BeforeEach' ) {
                $method = 'add_primary_setup';
                $options{scaffold} = 1;
            }
            elsif ( $_ eq 'AfterEach' ) {
                $method = 'add_primary_teardown';
                $options{scaffold} = 1;
            }
            # BeforeAll/AfterAll are called as class methods, not instance
            # methods.
            elsif ( $_ eq 'BeforeAll' ) {
                $method            = 'add_setup';
                $options{scaffold} = 1;
                $class_method      = 1;
            }
            elsif ( $_ eq 'AfterAll' ) {
                $method            = 'add_teardown';
                $options{scaffold} = 1;
                $class_method      = 1;
            }
            # We default to the name of the current method if no reason is
            # given for Skip/Todo.
            elsif (/^Skip(?:\((.+)\))?/) {
                $method = 'add_primary';
                $options{skip} = $1 || $name;
            }
            elsif (/^Todo(?:\((.+)\))?/) {
                $method = 'add_primary';
                $options{todo} = $1 || $name;
            }
            # All unhandled attributes are returned for someone else to
            # deal with.
            else {
                push @unhandled, $_;
            }
        }

        if ($method) {
            my $task = Test2::Workflow::Task::Action->new(
                code => $class_method
                ? sub { $caller[0]->$code }
                : sub { shift->{xUnit}->$code },
                frame => \@caller,
                name  => $name,
                %options,
            );

            $root->$method($task);
        }

        return @unhandled;
    };

    # Let's hope the caller doesn't try to load two modules which pull this
    # trick!
    no strict 'refs';
    *{"$caller[0]::MODIFY_CODE_ATTRIBUTES"} = $modify_code_attributes;
}

1;
