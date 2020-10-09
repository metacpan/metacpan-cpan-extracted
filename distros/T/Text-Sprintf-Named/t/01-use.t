#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;

use Text::Sprintf::Named ();

# Instantiate an object.
{
    my $obj = Text::Sprintf::Named->new({fmt => "Hello %(name)s!"});

    # TEST
    ok ($obj, "Object was instantiated");
}

{
    my $obj = Text::Sprintf::Named->new({fmt => "95%% Humidity"});

    # TEST
    is ($obj->format(), "95% Humidity", "Checking ->format() - 1");
    # TEST
    is ($obj->format({args => {}}), "95% Humidity",
        "Checking ->format() - 2 - empty hashref"
    );
    # TEST
    is ($obj->format({args => {foo => "Bardom", "isaac" => "Newton"}}),
        "95% Humidity",
        "Checking ->format() - 3 - full hashref"
    );
}

# TODO : test for:
# 1. Consecutive percent signs.
# 2. More than one double percent sign in a string.

# n_s == named_sprintf
sub n_s
{
    my $format = shift;
    my $args = shift || {};

    return
        Text::Sprintf::Named->new({fmt => $format})
            ->format({args => $args})
        ;
}

# TODO: test several different calls to the same format returning
# different strings.

{
    # TEST
    is (n_s("Format me %%%%%% There %%%%", {}),
        "Format me %%% There %%",
        "Testing multiple consecutive %-signs"
    );

    # TEST
    is (n_s("I want\n%% Plus\n%% Minus%% Thrice\n%% Dice\n", {}),
        "I want\n% Plus\n% Minus% Thrice\n% Dice\n",
        "Testing multiple consecutive % sign"
    );
}

{
    # TEST
    is (n_s("Hello %(name)s!", {name => "Tim"}),
        "Hello Tim!",
        "%(name)s conversion"
    );
}

{
    # TEST
    is (n_s("Welcome to %(year)d!", {name => "Tim", year => 20}),
        "Welcome to 20!",
        "%(name)d conversion"
    );
}

{
    # TEST
    is (n_s("You have 0x%(bytes)x bytes left, and your lucky character is %(mychar)c",
            {bytes => 500, mychar => ord('C'),}),
        "You have 0x1f4 bytes left, and your lucky character is C",
        "Testing the %(name)x and %(name)c conversions"
    );
}

{
    # TEST
    is (n_s("[%(name)10s]", { name => "Sophie" }),
        "[    Sophie]",
        "Testing a %(name)10s conversion"
    );
}

{
    # TEST
    is (n_s("1.57 + 2.32 = %(result)5.2f", { result => 3.98 }),
        "1.57 + 2.32 =  3.98",
        "Testing a %(name)5.2f conversion"
    );
}

{
    my $obj = Text::Sprintf::Named->new(
        {
            fmt => "Hello %(name)s. Your lucky number is %(num)04d!"
        }
    );

    # TEST
    ok ($obj, "Object was instantiated");

    # TEST
    is ($obj->format({args => {'name' => "Jill", 'num' => "5" }}),
        "Hello Jill. Your lucky number is 0005!",
        "Testing multiple ->format calls for the same object - 1"
    );

    # TEST
    is ($obj->format({args => {'name' => "Avi", 'num' => "6508" }}),
        "Hello Avi. Your lucky number is 6508!",
        "Testing multiple ->format calls for the same object - 2"
    );
}
