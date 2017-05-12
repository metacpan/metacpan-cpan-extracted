#!/usr/bin/perl -w

use strict;

use File::Spec;
use lib File::Spec->catfile("t", "lib");
use CondTestMore tests => 3;

use WWW::Form;

# Test Suite #1: a simple one.
{
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

    my %fields_values = 
    (
        'first_name' => "Shlomi",
        'comments' => "I'm too lame to put anything here",
    );
    
    my $form = WWW::Form->new(\%fields_data, \%fields_values);

    my $first_name = $form->getField("first_name");

    # TEST
    is($first_name->{label}, "First Name", "getfield-label");
    # TEST
    is($first_name->{type}, "text", "getfield-text");
    # TEST
    is($first_name->{defaultValue}, "Joe", "getfield-defaultValue");
}

