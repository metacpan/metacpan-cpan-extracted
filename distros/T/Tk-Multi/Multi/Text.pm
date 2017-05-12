package Tk::Multi::Text ;

use strict;

use vars qw($printCmd $defaultPrintCmd $VERSION);

use base qw(Tk::Derived Tk::Frame Tk::Multi::Any);

$VERSION = sprintf "%d.%03d", q$Revision: 2.5 $ =~ /(\d+)\.(\d+)/;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

$printCmd = $defaultPrintCmd = 'lp -ol70 -otl66 -o12 -olm10' ;

Tk::Widget->Construct('MultiText');

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

sub Populate
  {
    my ($cw,$args) = @_ ;
    Tk::Multi::Any::normalize($cw,$args) ;

    require Tk::Label;
    require Tk::ROText;

    $cw->{_printCmdRef} = \$printCmd ;
    my $data = delete $args->{'-data'} ;

    my $title = $cw ->{'title'} = delete $args->{'-title'} || 'anonymous';

    my $menu = delete $args->{'-menu_button'};
    die "Multi window $title: missing menu_button argument\n" 
      unless defined $menu ;

    my $subref = sub {$menu->Popup(-popover => 'cursor', -popanchor => 'nw')};

    #$cw->bind ('<Button-3>', $subref);
    #$slaveWindow->bind ('<Button-3>', $subref);
    #Tk::bind($cw, '<Button-3>', $subref);

    my $titleLabel = $cw->Label(-text => $title.' display')-> pack(qw/-fill x/) ;
    $titleLabel -> bind('<Button-3>', $subref);

    $menu->command(-label=>'print...', -command => [$cw, 'print' ]) ;
    $menu->command(-label=>'clear', -command => [$cw, 'clear' ]);

    # print stuff
    $cw->{_printToFile} = 0;
    $cw->{_printFile} = '';

    my $slaveWindow = $cw -> Scrolled ('ROText')
      -> pack(qw/-fill both -expand 1/) ;

    $cw->Advertise('text' => $slaveWindow) ;

    $cw->ConfigSpecs(
                     '-relief' => [$cw],
                     '-borderwidth' => [$cw],
                     '-scrollbars'=> [$slaveWindow, undef, undef,'osoe'],
                     '-width' => [$slaveWindow, undef, undef, 80],
                     '-height' => [$slaveWindow, undef, undef, 5],
                     'DEFAULT' => [$slaveWindow]
                    ) ;
    $cw->Delegates('command' => $menu, 
                   'clear' => $cw,
                   DEFAULT => $slaveWindow) ;

    # needed to avoid geometry problems with packAdjuster
    #$cw->DoWhenIdle(sub{ $cw->packPropagate(0);}) ;
    $cw->SUPER::Populate($args);

    $cw-> insertText (@$data) if defined $data ;
    $cw->yview('moveto', 1) ; # move diplay to the end
  }

sub insertText
  {
    my $cw= shift ;

    foreach (@_)
      {
        $cw->insert('end',$_) ;
      }
    $cw->yview('moveto', 1) ;
  }


sub clear 
  {
    my $cw= shift ;
    
    $cw->delete('1.0','end') ;
  }

sub printableDump
  {
    my $cw= shift ;
    return $cw->get('0.0','end') ;
  }

1;
__END__


# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Tk::Multi::Text - Tk composite widget with a scroll window and more

=head1 SYNOPSIS

 use Tk::Multi::Manager;

 use Tk::Multi::Text ; 

 my $manager = yourWindow -> MultiManager 
  (
   menu => $menu_ref , # optionnal
   title => "windows" # optionnal
  ) -> pack ();

 # Don't pack it, the managet will do it
 my $w1 = $manager -> newSlave('type' => 'MultiText', 'title' => 'a_label');

=head1 DESCRIPTION

This composite widget features :

=over 4

=item *

a scrollable read-only text window (based on ROtext)

=item *

A print menu button (The shell print command may be modified by
setting $Tk::Multi::Text::printCmd to the appropriate shell
command. By default, it is set to 'lp -ol70 -otl66 -o12 -olm10')

=item *

a clear menu button.

=back

This widget will forward all unrecognize commands to the ROtext object.

Note that this widget should be created only by the Multi::Manager. 

=head1 WIDGET-SPECIFIC OPTIONS

=head2 title

Some text which will be displayed above the test window. 

=head2 menu_button

The log window feature a set of menu items which must be added in a menu.
This menu ref must be passed with the menu_button prameter 
to the object during its creation.

=head2 data

A string which will be displayed in the text window.

=head1 WIDGET-SPECIFIC METHODS

=head2 insertText($some_text)

Insert the passed string at the bottom of the text window

=head2 print

Will raise a popup window with an Entry to modify the actual print command,
a print button, a default button (to restore the default print command),
and a cancel button.

=head2 clear

Is just a delete('1.0','end') .

=head1 Delegated methods

By default all widget method are delegated to the Text widget. Excepted :

=head2 command(-label => 'some text', -command => sub {...} )

Delegated to the menu entry managed by Multi::Manager. Will add a new command
to the aforementionned menu.

=head1 TO DO

Defines ressources for the config options.

=head1 AUTHOR

Dominique Dumont, domi@komarr.grenoble.hp.com

Copyright (c) 1997-1998,2004 Dominique Dumont. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), Tk(3), Tk::Multi(3), Tk::Multi::Manager(3)

=cut
