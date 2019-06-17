#!/usr/bin/perl -w

use strict;

use File::Spec;
use lib File::Spec->catfile("t", "lib");
use CondTestMore tests => 33;

# TEST
BEGIN { use_ok("WWW::Form"); }

sub make_obj
{
    my $self = {};

    bless $self, "WWW::Form";

    $self->{fieldsOrder} = shift || [];

    return $self;
}

# Test Suite #1: a simple one.
{
    my $form = make_obj();
    my %fields_data =
    (
        'first_name' =>
        {
            label => "First Name",
            defaultValue => "Joe",
            type => "text",
        },
        'comments' =>
        {
            label => "Your Comments",
            defaultValue => "Enter your comments here.",
            type => "textarea",
        },
    );

    $form->_setFields(\%fields_data, {});

    # TEST
    is($form->{fields}{first_name}{label}, "First Name", "simple-fn-label");
    # TEST
    is($form->{fields}{first_name}{defaultValue}, "Joe", "simple-fn-dv");
    # TEST
    is($form->{fields}{first_name}{type}, "text", "simple-fn-type");
    # TEST
    is($form->{fields}{comments}{label}, "Your Comments", "simple-comments-label");
    # TEST
    is($form->{fields}{comments}{defaultValue}, "Enter your comments here.", "simple-comments-dv");
    # TEST
    is($form->{fields}{comments}{type}, "textarea", "simple-comments-type");
}

# Test Suite #2: an invalid value being entered
{
    my $form = make_obj();
    my %fields_data =
    (
        'first_name' =>
        {
            label => "First Name",
            defaultValue => "Joe",
            type => "text",
            fooportuklok => "Roonda",
        },
        'comments' =>
        {
            label => "Your Comments",
            defaultValue => "Enter your comments here.",
            type => "textarea",
        },
    );

    $form->_setFields(\%fields_data, {});

    # TEST
    is($form->{fields}{first_name}{label}, "First Name", "non-existent-fn-label");
    # TEST
    is($form->{fields}{first_name}{defaultValue}, "Joe", "non-existent-fn-dv");
    # TEST
    is($form->{fields}{first_name}{type}, "text", "non-existent-fn-type");
    # TEST
    is($form->{fields}{comments}{label}, "Your Comments", "non-existent-comments-label");
    # TEST
    is($form->{fields}{comments}{defaultValue}, "Enter your comments here.", "non-existent-comments-dv");
    # TEST
    is($form->{fields}{comments}{type}, "textarea", "non-existent-comments-type");
    # TEST
    ok( (!exists($form->{fields}{first_name}{fooportuklok})), "non-existent-non-existent");
}

# Test Suite #3: hint
{
    my $form = make_obj();
    my %fields_data =
    (
        'first_name' =>
        {
            label => "First Name",
            defaultValue => "Joe",
            type => "text",
            hint => "Type your first name here",
        },
        'comments' =>
        {
            label => "Your Comments",
            defaultValue => "Enter your comments here.",
            type => "textarea",
        },
    );

    $form->_setFields(\%fields_data, {});

    # TEST
    is($form->{fields}{first_name}{label}, "First Name", "hint-fn-label");
    # TEST
    is($form->{fields}{first_name}{defaultValue}, "Joe", "hint-fn-dv");
    # TEST
    is($form->{fields}{first_name}{type}, "text", "hint-fn-type");
    # TEST
    is($form->{fields}{comments}{label}, "Your Comments", "hint-comments-label");
    # TEST
    is($form->{fields}{comments}{defaultValue}, "Enter your comments here.", "hint-comments-dv");
    # TEST
    is($form->{fields}{comments}{type}, "textarea", "hint-comments-type");
    # TEST
    is($form->{fields}{first_name}{hint}, "Type your first name here", "hint-fn-hint");
    # TEST
    ok((! exists($form->{fields}{comments}{hint})), "hint-comments-hint");
}

# Tests for _setField()
{
    my $form = make_obj();

    $form->{fields} = {};

    my @params =
    (
        'name' => 'first_name',
        'params' =>
        {
            label => "First Name",
            defaultValue => "Daniel",
            type => "text",
            hint => "Type your first name here",
        },
        'value' => "Eran",
    );

    my $out = $form->_getFieldInitParams(@params);
    # TEST
    is ($out->{label}, "First Name");
    # TEST
    is ($out->{defaultValue}, "Daniel");
    # TEST
    is ($out->{type}, "text");
    # TEST
    is ($out->{hint}, "Type your first name here");
    # TEST
    is ($out->{value}, "Eran");

    # Final test - make sure that $self->{fields} is unharmed.
    # _getFieldInitParams() is a functional (as in Functional Programming)
    # routine

    # TEST
    ok ((scalar(keys(%{$form->{fields}})) == 0), "_getFieldInitParams() does not touches the \$self->{fields} hash");

    $form->_setField(
        @params,
    );

    # TEST
    is ($form->{fields}->{first_name}{label}, "First Name");
    # TEST
    is ($form->{fields}->{first_name}{defaultValue}, "Daniel");
    # TEST
    is ($form->{fields}->{first_name}{type}, "text");
    # TEST
    is ($form->{fields}->{first_name}{hint}, "Type your first name here");
    # TEST
    is ($form->{fields}->{first_name}{value}, "Eran");
}
