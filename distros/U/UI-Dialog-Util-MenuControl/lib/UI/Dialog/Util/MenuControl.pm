package UI::Dialog::Util::MenuControl; ## A menu maker for dialog


use strict;
use vars qw($VERSION);

our $VERSION='0.10';



# It is an OO class to render a Dialog menu by a tree of array and hashes
# with specific form.
# a shell. It does not use curses and has no large dependencies.
#
#
# SYNOPSIS
# ========
#
#
#    use UI::Dialog::Util::MenuControl;
#    
#    my $tree = {
#                    title       =>  'Conditinal behaviour',
#                    entries     =>  [
#                                        {
#                                            title       =>  'entry A (prework for B)',
#                                            function    =>  \&doA,
#                                            condition   =>  undef,
#                                        },
#                                        {
#                                            title       =>  'entry B',
#                                            function    =>  \&doB,
#                                            condition   =>  \&aWasCalled,
#                                        },
#                                        {
#                                            title       =>  'reset A (undo prework)',
#                                            function    =>  \&resetA,
#                                            condition   =>  \&aWasCalled,
#                                        },
#                                        {
#                                            title       =>  'has also submenus',
#                                            entries     =>  [
#                                                                {
#                                                                    title   =>  'sub b 1',
#                                                                },
#                                                                {
#                                                                    title   =>  'sub b 2',
#                                                                },
#                                                            ]
#                                        },
#                    
#                                    ],
#                };
#    
#    
#    
#    my $menu_control = UI::Dialog::Util::MenuControl->new( menu => $tree );
#    
#    $menu_control->run();
#
# To build a menu, you can nest nodes with the attributes
#   
# title
# function    a reference to a function.
# condition   a reference to a function given a boolean result whether to display the item or not
# entries     array ref to further nodes
# context     a 'self" for the called function
# 
# Context
# =======
# 
# The context you can use globaly (via constructor) or in a node, can be used in different ways.
# It is an important feature to keep object oriented features, because the function call from a menu
# normaly does not know which object you want to use and usually you want to separate the menu from the
# working object.
#      
#      ... 
#      
#      our $objA = Local::UsecaseA->new();
#      
#      
#      my $tree = {
#                      title       =>  'Conditinal behaviour',
#                      entries     =>  [
#                                          {
#                                              title       =>  'entry B',
#                                              function    =>  \&doB,
#                                              condition   =>  \&Local::UsecaseA::check,
#                                              context     =>  $objA,
#                                          },
#                      
#                                      ],
#                  };
#
# In this example an object objA has been loaded before and provides a check() method.
# To run this check method in $objA context, you can tell a context to the node.
#
# What does the absolute same:
#
#      my $tree = {
#                      title       =>  'Conditinal behaviour',
#                      entries     =>  [
#                                          {
#                                              title       =>  'entry B',
#                                              function    =>  \&doB,
#                                              condition   =>  sub{ $objA->check() },
#                                          },
#                      
#                                      ],
#                  };
#
#
# But here a more elegant way:
#
#      ... 
#      
#      our $objA = Local::UsecaseA->new();
#      
#      
#      my $tree = {
#                      title       =>  'Conditinal behaviour',
#                      entries     =>  [
#                                          {
#                                              title       =>  'entry B',
#                                              function    =>  'doB( "hello" )',  # it is a simple string. Also parameters possible.
#                                              condition   =>  'check',           # called as method on $objA
#                                          },
#                      
#                                      ],
#                  };
#
#
#    my $menu_control = UI::Dialog::Util::MenuControl->new(
#                                                               menu    => $tree,
#                                                               context => $objA,  # Set the context for methods
#                                                         ); 
#    
#    $menu_control->run();
# 
#
# Try a function
# ==============
# Normaly the application dies if inside a function call a die() will happen. But you can try a function
# if it dies, it wont leave the menu.
# Therefore you have to add the magic work "try " before the function. As with dialogs the user may hit "cancel",
# I recomment to throw an exception (die) if that happens to make a difference to just "not entering a value".
# But if this menu call that function directly, the menu might also die then.
#
#   ...
#   function  => 'try askForValue',
#   ...
#
# As a try will eat all errors, you can handle them; Use 'catch' as parameter to point to an error handler function.
# This function will get the thrown error as first parameter.
#
#
#   ...
#   function  => 'try askForValue',
#   catch     => 'showErrorWithDialog',
#   ...
#
# The catch can also be globally set via constructor. So far catch can only take scalars describing a function in the same context
# as the rest. A coderef won't work. Errors in the catcher can't be handled and the menu will realy die.
#
#
#
# Negative conditions
# ===================
# It is quite simple. Just add the magic word "not " or "!" in front of a condition.
#
#   ...
#   function  => 'prepareFolder',
#   condition => 'not isFolderPrepared',
#   ...
#
#
#
# LICENSE
# =======   
# You can redistribute it and/or modify it under the conditions of LGPL.
# 
# AUTHOR
# ======
# Andreas Hernitscheck  ahernit(AT)cpan.org





# parameters
#
#   context             context object wich can be used for all called procedures (self)
#   backend             UI::Dialog Backend engine. E.g. CDialog (default), GDialog, KDialog, ...
#   backend_settings    Values as hash transfered to backend constructor
#   menu                Tree structure (see example above)
#   catch               An error catching function, which retrieves the error if first param (only if 'try' used)
#
sub new { 
    my $pkg = shift;
    my $self = bless {}, $pkg;
    my $param = { @_ };

    if ( not $param->{'menu'} ){ die "needs menu structure as key \'menu\'" };
    my $menu = $param->{'menu'};

    %{ $self } = %{ $param };
  
    my $bset = $param->{'backend_settings'} || {};

    $bset->{'listheight'} ||= 10;
    $bset->{'height'}     ||= 20;

    # if no dialog is given assume console and init now
    my $use_backend = $param->{'backend'} || 'CDialog';
    my $backend_module = "UI::Dialog::Backend::$use_backend";

    #require $backend_module;
    eval("require $backend_module"); ## no critic
    if ( $@ ){ die $@ };

    my $backend = $backend_module->new( %{ $bset } );
    $self->dialog( $backend );


    # set first node as default
    $self->_currentNode( $menu );

    return $self;
}


# Main loop method. Will return when the user selected the last exit field.
sub run{
    my $self = shift;

    while (1){
        last if not $self->showMenu();
    }

    return;
}


# Main control unit, but usually called by run().
# If you call it by yourself, you have to build your own loop around.
sub showMenu {
    my $self = shift;
    my $dialog = $self->dialog();
    my $pos = $self->_currentNode();

    my $title = $pos->{'title'};
    

    my $retval = 1;


    # node context or global or undef
    my $context = $pos->{'context'} || $self->{'context'} || undef;
    my $catch = $pos->{'catch'} || $self->{'catch'} || undef;

    # prepare entries and remember further refs by
    # the selected number
    my @list;
    my $c = 0;
    my $entries = {};
    menubuild: foreach my $e ( @{ $pos->{'entries'} } ) {
      
        # context per element entry?
        my $context_elem = $e->{'context'};

        my $condition = $e->{'condition'};

        # magic prefix "not" or "!" to negate condition?
        my $negative = 0;
        if ( $condition =~ s/^(not |\!)//i ){
            $negative = 1;
        }


        # you can skip menu entries if a condition is false.
        # it is a boolean return of a function. So you can
        # use moose's attributes.
        if ( defined($condition) ){

            my $cond_result;
            my $used_context = $context_elem || $context;

            if ( ref($condition) eq 'CODE' ){ # use a code ref like \& or sub{}
                $cond_result = &{ $condition }( $used_context );
            }elsif( not ref($condition) ){ # assume a name of a function in context
                eval( "\$cond_result = \$used_context->$condition"); ## no critic
                if ( $@ ){
                    die $@;
                }
            }
           
            # show menu entry or skip to next
            # negative negates the condition
            if ( $cond_result xor $negative ) {
                # positive means to render menu point
            }else{
                # that is negative and means skip
                next menubuild;
            } 
        }
        
        $c++; # is the entry number
        push @list, $c, $e->{'title'}; # title shown in the menu
        
        $entries->{ $c } = $e;
    }
    
    
    my $sel = $dialog->menu(
                        text => $title,
                        list => \@list,
                      );
                      
    # selection in the menu?
    if ( $sel ) {
        

        my $function = $entries->{ $sel }->{'function'};
        my $catchn    = $catch || $entries->{ $sel }->{'catch'};
        my $context_elem = $entries->{ $sel }->{'context'};
        my $used_context = $context_elem || $context;

        # does the selected item has a submenu?
        if ( $entries->{ $sel }->{'entries'} ){
       
            $self->_currentNode(  $entries->{ $sel } );
            $self->_currentNode()->{'parent'} = $pos;
            $self->showMenu();            
            
        }elsif( $function ){ # or is it a function call?

            # avoid to die if the function fails
            my $dontdie;
            if ( $function =~ s/^try //i ){
                $dontdie = 1;
            }

            if ( ref($function) eq 'CODE' ){ # use a code ref like \& or sub{}
                &{ $entries->{ $sel }->{'function'} }( $used_context );
            }elsif( not ref($function) ){ # assume a name of a function in context
                eval( "\$used_context->$function" ); ## no critic
                if ( $@ ){
                    die $@ if not $dontdie;

                    # if a catch function is given (in context), forward the error
                    if ( $dontdie && $catchn ){
                        my $err = $@;
                        if (not ref($catchn) ){
                            eval( "\$used_context->$catchn( \$err )" ); ## no critic
                        }
                    }
                }
            }
        }
        
    }else{
        # selected 'cancel' means go to partent if exists or exit app
        if ( $pos->{ 'parent' } ) {
            $self->_currentNode(  $pos->{ 'parent' } );
            $self->showMenu();
        }else{
            $retval = 0;
            exit; ## top menu cancel, does an exit
        }
        

    }
    
    return $retval;                      
}



# Points to the current displayed node in the menu tree.
sub _currentNode{
    my $self = shift;
    my $node = shift;

    if ( $node ){
        $self->{'current_node'} = $node;
    }

    return $self->{'current_node'};
}


# Holds the backend dialog system.
sub dialog{
    my $self = shift;
    my $backend = shift;

    if ( $backend ){
        $self->{'backend'} = $backend;
    }

    return $self->{'backend'};
}



1;



#################### pod generated by Pod::Autopod - keep this line to make pod updates possible ####################

=head1 NAME

UI::Dialog::Util::MenuControl - A menu maker for dialog


=head1 SYNOPSIS



   use UI::Dialog::Util::MenuControl;
   
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

To build a menu, you can nest nodes with the attributes
  
title
function    a reference to a function.
condition   a reference to a function given a boolean result whether to display the item or not
entries     array ref to further nodes
context     a 'self" for the called function



=head1 DESCRIPTION

It is an OO class to render a Dialog menu by a tree of array and hashes
with specific form.
a shell. It does not use curses and has no large dependencies.




=head1 REQUIRES


=head1 METHODS

=head2 new

 $self->new();

parameters

  context             context object wich can be used for all called procedures (self)
  backend             UI::Dialog Backend engine. E.g. CDialog (default), GDialog, KDialog, ...
  backend_settings    Values as hash transfered to backend constructor
  menu                Tree structure (see example above)
  catch               An error catching function, which retrieves the error if first param (only if 'try' used)



=head2 dialog

 $self->dialog();

Holds the backend dialog system.


=head2 run

 $self->run();

Main loop method. Will return when the user selected the last exit field.


=head2 showMenu

 $self->showMenu();

Main control unit, but usually called by run().
If you call it by yourself, you have to build your own loop around.



=head1 Try a function

Normaly the application dies if inside a function call a die() will happen. But you can try a function
if it dies, it wont leave the menu.
Therefore you have to add the magic work "try " before the function. As with dialogs the user may hit "cancel",
I recomment to throw an exception (die) if that happens to make a difference to just "not entering a value".
But if this menu call that function directly, the menu might also die then.

  ...
  function  => 'try askForValue',
  ...

As a try will eat all errors, you can handle them; Use 'catch' as parameter to point to an error handler function.
This function will get the thrown error as first parameter.


  ...
  function  => 'try askForValue',
  catch     => 'showErrorWithDialog',
  ...

The catch can also be globally set via constructor. So far catch can only take scalars describing a function in the same context
as the rest. A coderef won't work. Errors in the catcher can't be handled and the menu will realy die.





=head1 Context


The context you can use globaly (via constructor) or in a node, can be used in different ways.
It is an important feature to keep object oriented features, because the function call from a menu
normaly does not know which object you want to use and usually you want to separate the menu from the
working object.
     
     ... 
     
     our $objA = Local::UsecaseA->new();
     
     
     my $tree = {
                     title       =>  'Conditinal behaviour',
                     entries     =>  [
                                         {
                                             title       =>  'entry B',
                                             function    =>  \&doB,
                                             condition   =>  \&Local::UsecaseA::check,
                                             context     =>  $objA,
                                         },
                     
                                     ],
                 };

In this example an object objA has been loaded before and provides a check() method.
To run this check method in $objA context, you can tell a context to the node.

What does the absolute same:

     my $tree = {
                     title       =>  'Conditinal behaviour',
                     entries     =>  [
                                         {
                                             title       =>  'entry B',
                                             function    =>  \&doB,
                                             condition   =>  sub{ $objA->check() },
                                         },
                     
                                     ],
                 };


But here a more elegant way:

     ... 
     
     our $objA = Local::UsecaseA->new();
     
     
     my $tree = {
                     title       =>  'Conditinal behaviour',
                     entries     =>  [
                                         {
                                             title       =>  'entry B',
                                             function    =>  'doB( "hello" )',  # it is a simple string. Also parameters possible.
                                             condition   =>  'check',           # called as method on $objA
                                         },
                     
                                     ],
                 };


   my $menu_control = UI::Dialog::Util::MenuControl->new(
                                                              menu    => $tree,
                                                              context => $objA,  # Set the context for methods
                                                        ); 
   
   $menu_control->run();




=head1 Negative conditions

It is quite simple. Just add the magic word "not " or "!" in front of a condition.

  ...
  function  => 'prepareFolder',
  condition => 'not isFolderPrepared',
  ...





=head1 AUTHOR

Andreas Hernitscheck  ahernit(AT)cpan.org


=head1 LICENSE

You can redistribute it and/or modify it under the conditions of LGPL.



=cut
