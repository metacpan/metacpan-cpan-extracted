############################################################
#
# $Header: /var/lib/cvs/Tk_Multi/Multi/Toplevel.pm,v 1.9 2004/10/11 14:54:00 domi Exp $
#
# $Source: /var/lib/cvs/Tk_Multi/Multi/Toplevel.pm,v $
# $Revision: 1.9 $
# $Locker:  $
# 
############################################################

package Tk::Multi::Toplevel ;

use Carp ;

use strict ;
use Tk::Multi::Any ;
require Tk::Toplevel;
require Tk::Derived;

use vars qw(@ISA $VERSION) ;
$VERSION = sprintf "%d.%03d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/;

@ISA = qw(Tk::Derived Tk::Toplevel);

Tk::Widget->Construct('MultiTop') ;


sub Populate
  {
    my ($cw,$args) = @_ ;
    Tk::Multi::Any::normalize($cw,$args) ;

    require Tk::Multi::Manager ;
    require Tk::Multi::Frame ;
    require Tk::Multi::Text ;
    require Tk::ObjScanner ;
    
    $cw->{manager} = delete $args->{-manager} || $cw ;
    $cw->{podName} = delete $args->{-podName} ;
    $cw->{podSection} = delete $args->{-podSection} ;

    my $showDebug = sub 
      { 
        # must not create 2 scanner windows
        my $t = 'internals' ;
        unless (defined $cw->getSlave($t))
          {
            my $f = $cw -> newSlave(type => 'MultiFrame', 
                                    title => $t, 
                                    destroyable => 1);
            $f -> ObjScanner('caller' => $cw->{manager}, destroyable => 0) 
              -> pack(-expand => 1);
          }
      } ;

    # create common menu bar
    my $w_menu = $cw ->
      Frame(-relief => 'raised', -borderwidth => 2) -> pack(-fill => 'x');

    my $fmenu= $w_menu->Menubutton(-text => 'File', -underline => 0) ;
    $fmenu-> pack(-side => 'left' );

    $cw->Advertise('fileMenu' => $fmenu->menu);

    $fmenu->command
      (
       -label => 'close',  
       -command => sub{$cw->destroy;}
      );

    $fmenu->command
      (
       -label => 'show internals...',  
       -command => $showDebug 
      );

    $cw->Advertise('menubar' => $w_menu);

    # load MultiText::manager
    my $mmgr = $cw -> MultiManager 
      ( 
       'title' => 'windows' , 
       'menu' => $w_menu ,
       'help' => sub {$cw->showHelp() ;}
      ) 
        -> pack (-expand => 1, -fill => 'both');
    
    $cw->Advertise('multiMgr' => $mmgr);
    # bind dump info 
    #$self->{tk}{toplevel}->bind ('<Meta-d>', $showDebug);
    

    $cw->ConfigSpecs(
                     '-relief' => [$cw],
                     '-borderwidth' => [$cw],
                     'DEFAULT' => [$cw]
                    ) ;
    $cw->Delegates
      (
       newSlave => 'multiMgr',
       getSlave => 'multiMgr',
       hide => 'multiMgr',
       show => 'multiMgr',
       destroySlave => 'multiMgr',
       'add' => 'fileMenu',
       'delete' => 'fileMenu',
       'insert' => 'fileMenu',
       DEFAULT => $cw
      ) ;

    # needed to avoid geometry problems with packAdjuster
    #$cw->DoWhenIdle(sub{ $cw->packPropagate(0);}) ;
    $cw->SUPER::Populate($args);
  }


sub menuCommand
  {
    my $cw = shift ;
    my %args = Tk::Multi::Any::normalize($cw,@_) ;
    my $name = $args{-name};
    my $menu = $args{-menu} ;

    unless (defined $cw->Subwidget($menu))
      {
        my $mb = $cw->Subwidget('menubar') -> 
          Menubutton (-text => $menu) ;
        $mb-> pack ( -fill => 'x' , -side => 'left');
        $cw->Advertise($menu => $mb );
        
        # first fill
        $mb->command (-label => $name, -command => $args{-command}) ;
        @{$cw->{menuItems}{$menu}} = ($name);
        return ;
      }

    push @{$cw->{menuItems}{$menu}}, $name;

    my %hash;
    my $i = 1 ;
    map($hash{$_}= $i++, sort @{$cw->{menuItems}{$menu}}) ;

    my $pos = $hash{$name} == ($i-1) ? 'end' : $hash{$name} ;
    $cw->Subwidget($menu) -> menu -> insert
      (
       $pos,'command',
       -label => $name,
       -command => $args{-command}
      );
  }

sub menuRemove
  {
    my $cw = shift ;
    my %args = Tk::Multi::Any::normalize($cw,@_) ; # name , menu
    my $name = $args{-name}; # can be an array ref
    my $menu = $args{-menu};

    my %hash;
    my $i = 1;
    map($hash{$_}= $i++, sort @{$cw->{menuItems}{$menu}}) ;

    my @array = ref($name) ? @$name : ($name) ;
    foreach (@array)
      {
        my $pos = $hash{$_} == ($i-1) ? 'end' : $hash{$_} ;

        $cw->Subwidget($menu) -> menu ->delete($pos) ;
        delete $hash{$_};
        @{$cw->{menuItems}{$menu}} = keys %hash ; # ugly
      }
    
    # cleanup 
    if (scalar @{$cw->{menuItems}{$menu}} == 0)
      {
        delete $cw->{menuItems}{$menu};
        $cw->Subwidget($menu)-> destroy ;
        delete $cw->{SubWidget}{$menu}; # Tk::mega bug workaround
      }
  }

sub showHelp
  {
    my $cw = shift ;
    my %args = $cw->normalize(@_) ; 
    my $podName = $args{-pod} ;
    my $podSection = $args{-section} ;

    require Tk::Pod::Text ;
    require Tk::Pod ;
    
    my $class =  defined $podName ? $podName : 
      defined $cw->{podName} ? $cw->{podName} : ref($cw);
    my $section = defined $podSection ? $podSection :
      defined  $cw->{podSection} ? $cw->{podSection} : 'DESCRIPTION' ;

    my $podSpec = $class.'/"'.$section.'"' ;

    my $topTk = $cw->MainWindow ;

    #print "podW is ",ref($podWidget)," children ",$topTk->children,"\n";
    my ($pod)  = grep (ref($_) eq 'Tk::Pod',$topTk->children) ;
    #print "1 pod is $pod, ",ref($pod),"\n";

    unless (defined $pod) 
      {
        #print "Creating Tk::Pod\n";
        $pod = $topTk->Pod() ;
      }

    #print "2 pod is $pod, ",ref($pod),"\n";

#    $podWidget = $topTk->Pod() 
#      unless (defined $podWidget and ref($podWidget) eq 'Tk::Pod' );

    # first param is 'reuse' or 'new'.
    # Pod::Text cannot find a section befire it is displayed
    #print $podSpec,"\n";
    $pod->Subwidget('pod')->Link('reuse',undef, $podSpec)

  }

1;

__END__

=head1 NAME

Tk::Multi::Toplevel - Toplevel MultiManager

=head1 SYNOPSIS

 use Tk::Multi::Toplevel ;

 my $mw = MainWindow-> new ;
 
 my $p = $mw->MultiTop();

 # If Multi::Toplevel is the only Tk window of your application
 $mw -> withdraw ; # hide the main window
 # destroy the main window when close is called
 $p -> OnDestroy(sub{$mw->destroy});

 # add a 'bar' menu with a 'foo' button on the menu bar
 $p->menuCommand(name => 'foo', menu => 'bar', 
                 sub => sub{warn "invoked  bar->foo\n";});

 # add a menu button on the 'File' menu
 $p->add(
         'command', 
         -label => 'baz', 
         -command => sub {warn "invoked  File->baz\n";}
        );

=head1 DESCRIPTION

This class is a L<Tk::Multi::Manager> packed in a Toplevel window. It
features also :

=over 4

=item *

'File->show internal...' button to invoke an Object Scanner 
(See L<Tk::ObjScanner>)

=item *

A facility to manage user menus with sorted buttons

=item *

A help facility based on L<Tk::Pod>

=back

=head1 Users menus

By default the Multi::Toplevel widget comes with 3 menubuttons:

=over 4

=item *

'File' for the main widget commands

=item *

'windows' to manage the Multi slaves widget

=item *

'Help'

=back

The user can also add its own menus and menu buttons to the main menubar. 
When needed the user can call the menuCommand method to add a new menu button
(and as new menu if necessary) . Then the user can remove the menu button 
with the menuRemove command.

For instance, if the user call :

 $widget->->menuCommand(name => 'foo', menu => 'example', 
   sub => \&a_sub);
  
The menubar will feature a new 'example' menu with a 'foo' button.

Then if the user call : 

 $widget->->menuCommand(name => 'bar', menu => 'example', 
   sub => \&a_sub);

The menubar will feature a new 'bar' button in the 'example' menu. Note that 
menu buttons are sorted alphabetically.

Then if the user call : 

 $widget->menuRemove(name => 'bar', menu => 'example');

The bar button will be removed from the menu bar.

=head1 Constructor configuration options

=head2 manager

Object reference that will be scanned by the ObjScanner. Usefull when you
want to debug the object that actually use the Multi::TopLevel. By default
the ObjScanner will scan the Multi::TopLevel object.

=head2 podName

This the name of the pod file that will be displayed with the 
'Help'->'global' button. This should be set to the pod file name of the
class or the application using this widget. 

By default, the help button will display the pod file of
Multi::TopLevel.

=head2 podSection

This the section of the pod file that will be displayed with the 
'Help'->'global' button.

By default, the help button will display the 'DESCRIPTION' pod section.

=head1 Advertised widgets

=over 4

=item *

fileMenu: 'File' Tk::Menu (on the left of the menu bar)

=item *

menubar : the Tk::Frame containing the menu buttons

=item *

multiMgr: The Tk::Multi::Manager

=back
 
Users menus are also advertised (See below)

=head1 delegated methods

=over 4

=item *

newSlave, hide, show, destroySlave : To the Tk::Multi::Manager 

=item *

add, delete, insert : To the 'File' Tk::Menu

=back

=head1 Methods

=head2 menuCommand()

Parameters are :

=over 4

=item *

name: button_name

=item *

menu: menu_name 

=item *

command: subref

=back

Will add the 'button_name' button in the 'menu_name' menu to invoke the sub 
ref. If necessary, the 'menu_name' menu will be created.

=head2 menuRemove ()

=over 4

=item *

name: button_name 

=item *

menu: menu_name 

=back

Will remove the 'button_name' button from the 'menu_name' menu.
If no buttons are left, the 'menu_name' menu will be removed from the menu
bar.

=head2 showHelp (...)

Parameters are :

=over 4

=item *

pod: pod file name (optional, defaults to the file name passed to the
constructor or to 'Tk::Multi::Toplevel')

=item *

section: pod_section (optional, defaults to the sectione name passed to the
constructor or to 'DESCRIPTION')

=back

Will invoke the Tk::Pod documentation widget of the specified
pod file and pod section.

=head1 BUGS

Users menu does not fold when you insert a lot of buttons.

Tk::Pod 0.10 does not display the specified section. Use a later version or
this patch (http://www.xray.mpe.mpg.de/mailing-lists/ptk/1998-11/msg00033.html)

=head1 AUTHOR

Dominique Dumont, domi@komarr.grenoble.hp.com

Copyright (c) 1997-1998,2004 Dominique Dumont. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), Tk(3), Tk::Multi::Manager(3), Tk::Pod(3), Tk::ObjScanner(3),
Tk::mega(3)

=cut


