#!/usr/bin/perl

$|=1;


use strict;
use warnings;

# a CDialog lib copy in local example folder
use lib '../lib',
        'lib';


use UI::Dialog::Util::MenuControl;



our $objA = Local::UsecaseA->new();


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
                                        condition   =>  \&Local::UsecaseA::check,
                                        context     =>  $objA,
                                    },
                                    {
                                        title       =>  'reset A (undo prework)',
                                        function    =>  \&resetA,
                                        condition   =>  \&Local::UsecaseA::check,
                                        context     =>  $objA,
                                    },
                
                                ],
            };



my $menu_control = UI::Dialog::Util::MenuControl->new( menu => $tree );

$menu_control->run();

exit;




sub doA{

    print "doing A\n";

    $objA->{"a_called"} = 1;

    return;
}


sub doB{
    print "doing B\n";

    return;
}

sub resetA{

    $objA->{"a_called"} = 0;

    return;
}


##################################

package Local::UsecaseA;


sub new{
    return bless {}, shift;
}

sub check{
    my $self = shift;

    return $self->{"a_called"};
}


1;
