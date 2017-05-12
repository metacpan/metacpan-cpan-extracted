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
                                        title       =>  'entry A (prework for B)',
                                        function    =>  \&doA,
                                        condition   =>  undef,
                                    },
                                    {
                                        title       =>  'entry B',
                                        function    =>  \&doB,
                                        condition   =>  \&aWasCalled,
                                    },
                                    {
                                        title       =>  'reset A (undo prework)',
                                        function    =>  \&resetA,
                                        condition   =>  \&aWasCalled,
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
