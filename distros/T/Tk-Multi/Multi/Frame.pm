# Copyright (c) 1997-1998 Dominique Dumont. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Tk::Multi::Frame ;

use strict;

use vars qw($printCmd $defaultPrintCmd $VERSION);

use base qw(Tk::Derived Tk::TFrame Tk::Multi::Any);

$VERSION = sprintf "%d.%03d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

$printCmd = $defaultPrintCmd = 'lp -ol70 -otl66 -o12 -olm10' ;

Tk::Widget->Construct('MultiFrame');

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

sub Populate
  {
    my ($cw,$args) = @_ ;
    Tk::Multi::Any::normalize($cw,$args) ;

    require Tk::Label;
    require Tk::Frame;

    $cw->{_printCmdRef} = \$printCmd ;

    my $title = $cw ->{'title'} = delete $args->{'-title'} || 'anonymous';
    $args->{-label} = [ -text => $title ]; # for TFrame;
    $cw->{printSub} = delete $args->{-print};

    my $menu = delete $args->{'-menu_button'};
    die "Multi window $title: missing menu_button argument\n" 
      unless defined $menu ;

    $menu->command(-label=>'print...', -command => [$cw, 'print' ]) 
      if defined $cw->{printSub};

    # print stuff
    $cw->{_printToFile} = 0;
    $cw->{_printFile} = '';

    my $subref = sub {$menu->Popup(-popover => 'cursor', -popanchor => 'nw')};

    $cw -> bind('<Button-3>', $subref);

    $cw->ConfigSpecs(
                     '-borderwidth' => [$cw, undef, undef, 2 ],
                     -relief => [$cw, undef, undef,'groove'],
                     'DEFAULT' => [$cw]
                    ) ;

    $cw->Delegates('-command' => $menu, 
                   DEFAULT => $cw) ;

    $cw->SUPER::Populate($args);
  }

sub resetPrintCmd
  {
    my $cw=shift ;
    $printCmd=$defaultPrintCmd ;
  }

sub printableDump
  {
    my $cw= shift ;
    return  &{$cw->{printSub}} ;
  }

1;
__END__


# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

  Tk::Multi::Frame - A TFrame widget managed by Tk::Multi

=head1 SYNOPSIS

 use Tk::Multi::Manager;

 use Tk::Multi::Frame ; 

 my $manager = $yourWindow -> MultiManager 
  (
   menu => $menu_ref , # optionnal
   printSub => $sub_ref ,  # optionnal
   title => "windows" # optionnal
  ) -> pack ();

 # Don't pack it, the manager will do it
 my $w1 = $manager -> newSlave('type' => 'MultiFrame', 
                               'title' => 'a_label');

=head1 DESCRIPTION

This composite widget features :

=over 4

=item *

a frame with a title (e.g. a L<Tk::TFrame>).

=item *

A print button (if the printSub parameter was provided)

(The shell print command may be modified by setting 
$Tk::Multi::Frame::printCmd to the appropriate shell command. By default, 
it is set to 'lp -opostscript') 

=back

This widget will forward all unrecognize commands to the Frame object.

Note that this widget should be created only by the Multi::Manager. 

=head1 WIDGET-SPECIFIC OPTIONS

=head2 title

The frame title (See L<Tk::TFrame>)

=head2 menu_button

The log window feature a set of menu items which must be added in a menu.
This menu ref must be passed with the menu_button prameter 
to the object during its instaciation

=head2 printSub

By itself, a frame cannot be printed. So if the user wants to print
some informations related to what's packed inside the frame, he must
provide a sub ref which will return a string. This string will be
printed as is by the widget.

=head1 WIDGET-SPECIFIC METHODS

=head2 print

Will raise a popup window with an Entry to modify the actual print command,
a print button, a default button (to restore the default print command),
and a cancel button.

=head2 doPrint

Print the label and the content of the text window. The print is invoked
by dumping the text content into a piped command.

You may want to set up a new command to print correctly on your machine.
You may do it by using the setPrintCmd method or by invoking the 
'print' method.

=head2 setPrintCmd('print command')

Will set the $printCmd class variable to the passed string. You may use this
method to set the appropriate print command on your machine. Note that 
using this method will affect all other Tk::Multi::Frame object since the
modified variable is not an instance variable but a class variable.

=head1 Delegated methods

By default all widget method are delegated to the TFrame widget. Excepted :

=head2 command(-label => 'some text', -command => sub {...} )

Delegated to the menu entry managed by Multi::Manager. Will add a new command
to the aforementionned menu.

=head1 NOTE

If you want to use a scrolled frame, you pack a Tk::Pane within the
frame provided by this widget. See L<Tk::Pane>.

=head1 TO DO

I'm not really satisfied with print management. May be one day, I'll write a 
print management composite widget which will look like Netscape's print 
window. But that's quite low on my priority list. Any volunteer ?

Defines ressources for the config options.

=head1 AUTHOR

Dominique Dumont, domi@komarr.grenoble.hp.com

 Copyright (c) 1997-1999,2002,2004 Dominique Dumont. All rights
 reserved.  This program is free software; you can redistribute it
 and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), L<Tk>, L<Tk::Multi>, L<Tk::Multi::Manager>, L<Tk::TFrame>,
L<Tk::Pane>

=cut
