package Tk::ListboxDnD;


=for

    ListboxDnD - A Tk::Listbox widget with drag and drop capability.
    Copyright (C) 2002  Greg London

    This program is free software; you can redistribute it and/or modify
    it under the same terms as Perl 5 itself.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    Perl 5 License schemes for more details.

    contact the author via http://www.greglondon.com

=cut


use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '1.300';

use base  qw(Tk::Derived Tk::Listbox);
use Tk::widgets qw(Listbox );

Construct Tk::Widget 'ListboxDnD';

sub Populate
  {
    require Tk::Listbox;

    my($listbox, $args) = @_;

    $listbox->SUPER::Populate($args);

    $listbox->ConfigSpecs(
        -dragformat => [qw/PASSIVE dragFormat DragFormat/, '<- %s'],
    );

    my (@bindtags) = $listbox->bindtags;
    $listbox->bindtags([@bindtags[1, 0, 2, 3]]);

    ########################################################
    # use button  1 to drag and drop the order of selected entries.
    ########################################################

    my $dragging_text;

    my $moving_callback = sub {return};
    my $marker_index;
    my $marker_text;
    my $have_moved;

    # pressing button 1 selects the nearest element
    $listbox->bind
      (       '<ButtonPress-1>' => 
	      sub
	      { 
		$marker_index = $listbox->nearest($Tk::event->y);
		$dragging_text = $listbox->get($marker_index);
		$marker_text = 
			sprintf( $listbox->cget(-dragformat), $dragging_text );
		
		$have_moved = 0;
		$moving_callback = sub 
		  {
		    my $current_index = $listbox->nearest($Tk::event->y);
		    return if ($current_index==$marker_index);
		
		    $listbox->delete($marker_index);
		    $listbox->insert($current_index, $marker_text);
		    $marker_index = $current_index;
		
		  };
	      }
      );

    # moving mouse while pressing button 1 shows where item will go
    # note: in extended mode, with multiple items <CTL>-selected,
    # dragging and dropping an item across selected items will
    # unselect them, UNLESS the Tk::break is called at end of callback.
    $listbox->bind
	( '<Motion>' => 
	sub { $have_moved = 1; &$moving_callback; Tk::break; } 
	);

    # releasing button 1 inserts the moving selection to the current index
    $listbox->bind
      (       '<ButtonRelease-1>' => 
	      sub
	      { 
		$moving_callback = sub {return;};
		return unless $have_moved;
		$listbox->delete($marker_index);
		$listbox->insert($marker_index, $marker_text);

		return unless(defined($dragging_text));
		$listbox->delete($marker_index);
		$listbox->insert($marker_index, $dragging_text);
		
		$marker_index = undef;
	      }
      );
  }


1;

__END__

=head1 NAME

    ListboxDnD - A Tk::Listbox widget with drag and drop capability.

=head1 DESCRIPTION

   The intent is to add Drag and Drop functionality to the Tk::Listbox
   widget. You can drag items within the listbox to another location 
   within the listbox by using <Button-1>.

   I would like some beta-testers to see if they can break
   this module or find any bugs with it.

=head2 EXPORT


=head1 INSTALLATION

   Just put this file in a directory called "Tk".
   Above that directory, create a test perl script with the following
   code in it: 

        use Tk;
        use Tk::ListboxDnD;
        my $top = MainWindow->new();
        my $listbox = $top->ListboxDnD(-dragformat=>"<%s>")->pack();
        $listbox->insert('end', qw/alpha bravo charlie delta echo fox/);
        MainLoop();


=head1 AUTHOR


    ListboxDnD - A Tk::Listbox widget with drag and drop capability.
    Copyright (C) 2002  Greg London

    This program is free software; you can redistribute it and/or modify
    it under the same terms as Perl 5 itself.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    Perl 5 License schemes for more details.

    contact the author via http://www.greglondon.com


=head1 SEE ALSO


=cut
