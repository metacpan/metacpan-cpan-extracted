package Tk::Multi::Manager;

use strict;
use vars qw($VERSION @ISA $errno);

use Carp ;
use Tk::Derived;
use Tk::Frame;
use Tk::Adjuster ;
use Tie::IxHash ;
use Tk::Multi::Any ;

@ISA = qw(Tk::Derived Tk::Frame);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

$VERSION = sprintf "%d.%03d", q$Revision: 2.5 $ =~ /(\d+)\.(\d+)/;

Tk::Widget->Construct('MultiManager');

my $title_num = 0;

sub Populate
  {
    my ($cw,$args) = @_ ;
    Tk::Multi::Any::normalize($cw,$args) ;

    require Tk::Menubutton;

    my $title =  delete $args->{'-title'} || 'display';

    $cw->{trace} = delete $args->{'-trace'};

    my $userMenu = delete $args->{-menu} ;

    unless (defined $userMenu)
      {
        $userMenu = $cw->Frame(-relief => 'raised', -borderwidth => 2);
        $userMenu->pack(-fill => 'x');
      }

    $cw->{menu}= $userMenu -> Menubutton (-text => $title) 
      -> pack(-side => 'left' );

    # add help menu on the right side
    $cw->{help}= $userMenu -> Menubutton (-text => 'Help') 
      -> pack(-side => 'right') ;
 
    # add global help if defined 
    my $help = delete $args->{'-help'} ||
      "If you read this text and if the help menu has no other entry ".
        "than 'global', it means that the user of Tk::Multi did not provide ".
          "any help for the application you're using. Shame on him.";

    $cw->addHelp('global', $help);

    #$cw->{slave} = Tie::IxHash -> new () ;
    my %sHash ;
    $cw->{tiedSlave} = tie %sHash,  'Tie::IxHash' ;
    $cw->{slave} = \%sHash ;

    #my $obj = $cw->{windowFrame} = $cw -> Frame(bg => 'red')
    #  ->pack(qw(-fill both));

    $cw->ConfigSpecs(DEFAULT => [$cw],
                    '-width' => ['SELF'],
                    '-height' => ['SELF'],
) ;
    #$cw->Delegates(DEFAULT => 'SELF' ) ;
    #print "args: ",keys %args,"\n";
    $cw->SUPER::Populate($args) ;
  }

# may add a new Note to the note book
# or create a separate sub-window to see windows side by side
# or move a Note to a separate window 
# and vice-versa ?
sub newSlave
  {
    my $cw = shift ;
    my %args = Tk::Multi::Any::normalize($cw,@_) ;

    my $title = $args{'-title'} ||= $cw->Class . "-" . $title_num++ ;

    my $slaveType = delete $args{'-type'};
    croak("No type specified\n") unless defined $slaveType ;

    # add button if it doesn't exist
    if (defined $cw->{slave}{$title})
      {
        # display error message
        $cw->BackTrace("Window $title already exists\n");
      }
    elsif (defined $args{-before})
      {
        my $bef = delete $args{-before} ;
        my $idx = $cw->{tiedSlave}->Indices($bef);
        # create the new entry in the tied hash and place it before
        # $bef widget
        $cw->{tiedSlave}->Splice($idx,0,$title => {})
      }
    elsif (defined $args{-side} and delete $args{-side} eq 'top')
      {
        # create the new entry in the tied hash and put it on top
        $cw->{tiedSlave}->Unshift($title => {}) ; 
      } 
    else
      {
        # create the new entry in the tied hash and put it on bottom
        $cw->{tiedSlave}->Push($title => {}) ; 
      } 

    $cw->{slave}{$title}{show} = 1 ;

    if (defined $args{'-hidden'} )
      {
        $cw->{slave}{$title}{'show'} = 0 if $args{'-hidden'} == 1 ;
        delete $args{'-hidden'} ;
      }

    # add help button if help is defined 
    $cw->addHelp('on '.$title, delete $args{-help}) if defined $args{'-help'} ;

    # add control button
    my $topmenu = $cw->{menu}->menu ;
    $topmenu ->insert($cw->{tiedSlave}->Indices($title) + 1,
                                'cascade', -label => $title ) ;

    my $menu = $topmenu->Menu;
    $topmenu->entryconfigure($title, -menu => $menu);

    # checkButton does not work if I get the ref from inside the tied hash
    # hence the use of the intermediate reference
    my $var = $cw->{slave}{$title}{'show'} ;
    $cw->{slave}{$title}{'showRef'} = \$var ;
    $menu->checkbutton
      (
       -label => 'show', 
       -variable => \$var,
       -command => sub {$cw->updateVisi($title) ;}
      );

    $cw->{slave}{$title}{submenu} = $menu ;

    my $destroyable = delete $args{'-destroyable'} ;

    # add widget and adjuster
    my $wd = $cw->{slave}{$title}{widget} = 
      $cw -> $slaveType ('menu_button' => $menu, 
                            qw/-relief raised -borderwidth 4/,
                            %args);
    $cw->{slave}{$title}{adjuster} = $cw -> Adjuster (-widget => $wd);


    if (defined $destroyable and $destroyable)
      {
        $menu->command(-label=>'destroy', 
                       -command => sub{$cw->destroySlave($title);} );
      }

    # bottom slave must not use the packAdjust method
    $cw->updateVisi($title);

    return $cw->{slave}{$title}{widget} ;
  }

sub getSlave
  {
    my $cw = shift ;
    my $title = shift ;
    return defined $cw->{slave}{$title} ? $cw->{slave}{$title}{widget} : undef;
  }

sub addHelp
  {
    my $cw = shift ;
    my $label = shift ;
    my $help = shift ;
    
    my $sub = ref($help) eq 'CODE' ? $help :
      sub 
        {
          require Tk::Dialog ;
          $cw ->Dialog('-title'=> "$label help", -text => $help ) -> Show();
        } ;

    $cw->{'help'} -> command (-label => $label, -command => $sub);
  }

sub hide 
  {
    my $cw = shift ;
    my $title = shift ;
    $cw-> updateVisi($title,0) ;
  }

sub show 
  {
    my $cw = shift ;
    my $title = shift ;
    $cw-> updateVisi($title,1) ;
  }

sub updateVisi
  {
    my $cw = shift ;
    my $title = shift ;
    my $show = shift ;

    my $ref = $cw->{slave}{$title}{'showRef'};
    if (defined $show)
      {
        # update value used by the check Button
        $$ref = $cw->{slave}{$title}{'show'} = $show ;
      }
    else
      {
        $show = $cw->{slave}{$title}{'show'} = $$ref ;
      }


    my $slave = $cw->{slave}{$title} ;
    # NB tiedSlave and slave are a tied IxHash
    my $idx = $cw->{tiedSlave} -> Indices($title) ;
    my $nextShowed ;
    my $prevShowed ;
    my $l = $cw->{tiedSlave}->Length() ;
    print "$title index is $idx out of $l\n" if $cw->{trace} ;
    for (my $i=0; $i<$l; $i++)
      {
        my $item = $cw->{tiedSlave}-> Values($i) ;
        $prevShowed = $i if ($i<$idx && $item->{'show'}) ;
        if ($i>$idx && $item->{'show'})
          {
            $nextShowed = $i ;
            last ;
          }
      }
 
    print "$title show is $show\n" if $cw->{trace} ;
    print "$title previous showed is index $prevShowed\n" if $cw->{trace} ;
    print "$title next showed is index $nextShowed\n" if $cw->{trace} ;

    my @pargs = qw/-fill both -expand 1 -anchor n/;
    my $currentW = $cw->{slave}{$title}{widget};

    # so that the master window update its size when a slave is hidden
    # or shown
    $cw->packPropagate(1);

    if ($show)
      {
        if (defined $nextShowed)
          {
            print "$title uses packAdjust\n" if $cw->{trace} ;

            my $nextWidget = $cw->{tiedSlave}-> Values($nextShowed)->{widget} ;
            $currentW->pack(@pargs, -before => $nextWidget );
            $cw->{slave}{$title}{adjuster}-> packAfter($currentW );
          }
        else
          {
            print "$title uses pack\n" if $cw->{trace} ;
            if (defined $prevShowed)
              {
                print "index $prevShowed uses packAjust\n" if $cw->{trace} ;
                my $prevWidget = 
                  $cw->{tiedSlave}-> Values($prevShowed)->{widget} ;

                $cw->{tiedSlave}-> Values($prevShowed)->{adjuster}->
                  packAfter($prevWidget );
              }
            $currentW -> pack(@pargs) ;
          }
      }
    else
      {
        if (defined $prevShowed and not defined $nextShowed)
          {
            print "index $prevShowed uses pack\n" if $cw->{trace} ;
            my $w = $cw->{tiedSlave}-> Values($prevShowed)->{adjuster} ;
            $w->packForget(1);
            $cw->{tiedSlave}-> Values($prevShowed)->{widget}->
              pack(@pargs);
          }
        #hide it
        print "$title uses packForget\n" if $cw->{trace} ;
        $cw->{slave}{$title}{adjuster} -> packForget(1) ;
      }
  }

sub destroySlave
  {
    my $cw = shift ;
    my $title = shift ;

    die "Slave $title does not exist\n" 
      unless defined $cw->{slave}{$title}{widget} ;

    # first remove the display from the window
    $cw->updateVisi($title,0);

    # retrieve actual menu object from the MenuButtom
    my $cm = $cw->{menu} -> cget(-menu);

    $cw->{slave}{$title}{widget}->destroy;
    $cw->{slave}{$title}{submenu}->destroy;
    
    my $idx = $cw->{tiedSlave}->Indices($title);
    $cw->{tiedSlave}->Splice($idx,1);

    # delete the actual Menu entry from topmenu
    $cm -> delete($title) ;

    #delete $cw->{slave}{$title};
  }

1;

__END__


=head1 NAME

Tk::Multi::Manager - Tk composite widget managing Tk::Multi slaves

=head1 SYNOPSIS

 use Tk::Multi::Manager ;
 use Tk::Multi::Text ; # if you use MultiText as a slave

 my $manager = yourWindow -> MultiManager 
  (
   menu => $menu_ref , # optionnal
   title => "windows", # optionnal
   help => "Explain what your set of widget do" #optionnal
  ) -> pack ();

 # Don't pack it, the managet will do it
 my $w1 = $manager -> newSlave
  (
   'type' => 'MultiText', 
   'title' => 'a_label',
   help => "Explain what your slave widget does" #optionnal
  );

=head1 DESCRIPTION

The manager is a composite widget made of a menu cascade of check buttons 
and slaves which can be Tk::Multi::Text.

The user can add windows to the manager. Each window visibility is
controled by a check button in the menu cascade.  The check button
actually tells the packer to forget the window. note that the window
object is not destroyed.

The main menu bar will feature a 'Help' menu on the right. If the main
help which explain the purpose of the Multi::Manager and its slaves is
provided when creating the widget, the Help sub-menu will feature a
'global' label.

Each slave widget which is created with a help will have its own label
in the help menu.

=head1 Multi widgets

This package features the following Multi widgets:

=over 4

=item *

L<Tk::Multi::Text>

=item *

L<Tk::Multi::Canvas>

=item *

L<Tk::Multi::Frame>

=back

=head1 Constructor configuration options

=head2 menu

The widget may use a 'menu' argument which will be used to create a
menu item and releveant sub-menus to control the sub-window.  If not
provided, the widget will create a its own menu.

=head2 title

The optionnal title argument contains the title of the menu created by
the manager.

=head2 help

The argument may be a string or a sub reference.

When the help menu is invoked, either the help string will be
displayed in a L<Tk::Dialog> box or the sub will be run. In this case it
is the user's responsability to provide a readable help from the sub.

=cut

#'

=head1 Methods

=head2 newSlave(...) ;

Create a new slave to manager. Returns the slave widget object. Parameters
are:

=over 4

=item *

type: specifies the kind of Multi widget (e.g. MultiText).

=item *

title: specifies the title of the widget (mandatory).

=item *

before: specify that you want this new slave to be packed before
(well, above) another widget. This parameter will be set to the 'title' of 
this other widget.

=item *

side: when set to 'top', the widget will be packed on top of the others.
(default to 'bottom').

=item *

hidden: specifies whether the widget is to be packed right now or not
(default 0)

=item *

destroyable: a 'destroy' button is created if this parameter is
defined (default no).  Returns the slave widget reference.

=item *

help: This argument may be specified like the help parameter defined
above for the constructor.

=back

=head2 getSlave('name of the slave');

Return the slave widget or undef.

=head2 hide('name of the slave');

Hide the slave.

=head2 show('name of the slave');

Show the slave.

=head2 destroySlave( 'name of the slave') ;

Destroy the slave

=head1 AUTHOR

Dominique Dumont, domi@komarr.grenoble.hp.com

Copyright (c) 1997-1998,2004 Dominique Dumont. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), Tk(3), L<Tk::Multi::Text>, L<Tk::Multi::Canvas>,
L<Tk::Multi::Frame>, L<Tk::Multi::Toplevel>

=cut

