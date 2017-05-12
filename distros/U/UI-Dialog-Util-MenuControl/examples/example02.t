#!/usr/bin/perl

$|=1;


use strict;
use warnings;

# a CDialog lib copy in local example folder
use lib '../lib',
        'lib';


use UI::Dialog::Util::MenuControl;

our $a_called = 0;


my $tree = {
                title       =>  'Conditinal behaviour',
                entries     =>  [
                                    {
                                        title       =>  'has submenus',
                                        entries     =>  [
                                                            {
                                                                title   =>  'sub a 1',
                                                            },
                                                            {
                                                                title   =>  'sub a 2',
                                                            },
                                                        ]
                                    },
                
                                    {
                                        title       =>  'has also submenus',
                                        entries     =>  [
                                                            {
                                                                title   =>  'sub b 1',
                                                            },
                                                            {
                                                                title   =>  'sub b 2',
                                                            },
                                                        ]
                                    },
                                ],
            };



my $menu_control = UI::Dialog::Util::MenuControl->new( menu => $tree );

$menu_control->run();

exit;




sub doA{

    print "doing A\n";

    $a_called = 1;

    return;
}

sub aWasCalled{
    return $a_called;
}

sub doB{
    print "doing B\n";

    return;
}

sub resetA{

    $a_called = 0;

    return;
}

1;
