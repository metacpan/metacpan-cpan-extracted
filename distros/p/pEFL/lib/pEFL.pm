package pEFL;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use pEFL ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.76';

require XSLoader;
XSLoader::load('pEFL', $VERSION);

# Preloaded methods go here.

our $Debug = 0;


1;
__END__


=head1 NAME

pEFL - Perl binding to the Enlightenment Foundation Libraries

=head1 SYNOPSIS

	use pEFL;
	use strict;
	use warnings;

	use pEFL::Elm;

	pEFL::Elm::init($#ARGV, \@ARGV);

	pEFL::Elm::policy_set(ELM_POLICY_QUIT, ELM_POLICY_QUIT_LAST_WINDOW_CLOSED);

	my $win = pEFL::Elm::Win->util_standard_add("hello", "Hello");
	$win->smart_callback_add("delete,request",\&on_done, undef);

	my $box = pEFL::Elm::Box->add($win);
	$box->horizontal_set(1);
	$win->resize_object_add($box);
	$box->show();

	my $lab = pEFL::Elm::Label->add($win);
	$lab->text_set("Hello out there, World\n");
	$box->pack_end($lab);
	$lab->show();

	my $btn = pEFL::Elm::Button->add($win);
	$btn->text_set("OK");
	$box->pack_end($btn);
	$btn->show();
	$btn->smart_callback_add("clicked", \&on_done, undef);

	$win->show();

	pEFL::Elm::run();

	pEFL::Elm::shutdown();

	sub on_done {
		print "Exiting \n";
		pEFL::Elm::exit();
	}

=head1 DESCRIPTION

This module provides a nice object-oriented interface to the L<Enlightenment Foundation Libraries (EFL)|https://www.enlightenment.org>. Apart from that the API is deliberately kept close to the Elementary C API. The Perl method names generally remove the prefix at the beginning of the C functions. Therefore applying the C documentation should be no problem. 

For the documentation in detail please study the single modules and the L<C documentation|https://www.enlightenment.org/docs/start>

=head1 SPECIFICS OF THE BINDING

=head2 Perl specific variants of methods (_pv, "Perl Value"-methods)

If a method returns an C<Eina_List> there usually is a version with the suffix C<_pv> (for Perl Value) that returns a Perl array (for example in L<pEFL::Elm::List> the method C<< items_get_pv() >>). It is recommended to use these Perl adjusted methods. If you find a method, where the adaption is missing, please open an issue on L<github|https://github.com/MaxPerl/Perl-EFL>.

Sometimes a method returns an C<EvasObject> which can be any Elm Widget Type (e.g. C<< $nav->item_pop() >>, C<< $object->content_get >>, C<< $object_item->content_get() >>). In this case there will be a "Perl Value"-version that tries to bless the returned variable to the appropriate Perl class, too (e.g. C<< $naviframe->item_pop_pv() >>, C<< $object->[part_]content_get_pv() >>, C<< $object_item->[part_]content_get_pv() >>).

=head2 Output Parameters

L<pEFL> sometimes uses output parameters. See for example C<< void elm_calendar_min_max_year_get(Evas_Object *obj,int *min,int *max) >>, where you have to pass in C a pointer to max and min. In Perl this is translated to C<< my ($min, $max) = $calendar->min_max_year_get() >>. Sometimes the C function returns a status or similar as in C<< Eina_Bool elm_entry_cursor_geometry_get(Evas_Object *obj,int *x,int *y,int *w,int *h) >>. In Perl this status variable is given, too. So the function C<< elm_entry_cursor_geometry_get >> for example is translated into C<< my ($status,$x,$y,$w,$h) = $entry->cursor_geometry_get >>.

=head1 FUNCTIONS IN EFL

The L<pEFL> module gives you the following functions:

=over 4

=item C<< pEFL::ev_info2s($event_info) >> 

if C<$event_info> contains the address to a C string, this function converts the addressed C void pointer to a Perl string.

=item C<< pEFL::ev_info2obj($event_info, "pEFL::Evas::Event::MouseUp") >>

if C<$event_info> contains the address to a C struct, this function converts the addressed void pointer to a Perl scalar, that is blessed to the given class. The Perl class gives the necessary methods to get the members of the struct. At the moment the following C structs are (among others) supported:

=over 8

=item * Elm_Entry_Anchor_Info (aka pEFL::Elm::EntryAnchorInfo)

=item * Elm_Entry_Change_Info (aka pEFL::Elm::EntryChangeInfo)

=item * Elm_Image_Progress (aka pEFL::Elm::ImageProgress)

=item * Elm_Panel_Scroll_Info (aka pEFL::Elm::PanelScrollInfo)

=item * Evas_Coord_Rectangle (aka pEFL::Evas::Coord::Rectangle)

=item * Evas_Event_Mouse_Down (aka pEFL::Evas::Event::MouseDown)

=item * Evas_Event_Mouse_Up (aka pEFL::Evas::Event::MouseUp)

=item * Evas_Event_Mouse_In (aka pEFL::Evas::Event::MouseIn)

=item * Evas_Event_Mouse_Out (aka pEFL::Evas::Event::MouseOut)

=item * Evas_Event_Mouse_Move (aka pEFL::Evas::Event::MouseMove)

=item * Evas_Event_Mouse_Wheel (aka pEFL::Evas::Event::MouseWheel)

=item * Ecore_Event_Key (aka pEFL::Ecore::Event::Key)

=item * Ecore_Event_MouseButton (aka pEFL::Ecore::Event::MouseButton)

=item * Ecore_Event_MouseMove (aka pEFL::Ecore::Event::MouseMove)

=item * Ecore_Event_MouseWheel (aka pEFL::Ecore::Event::MouseWheel)

=item * Ecore_Event_Signal_Exit (aka pEFL::Ecore::Event::SignalExit)

=item * Ecore_Event_Signal_Realtime (aka pEFL::Ecore::Event::SignalRealtime)

=item * Ecore_Event_Signal_User (aka pEFL::Ecore::Event::SignalUser)

=item * Evas_Textblock_Rectangle (aka pEFL::Evas::TextblockRectangle)

=back

=back

Some events pass an Elementary Widget or an Evas Object as C<$event_info>. Of course you can use C<< ev_info2obj() >> to convert these pointers to a appropiate blessed Perl scalar, too. See for instance examples/colorselector.pl, where the Elm Widget Item Elm_Colorselector_Palette_Item is passed as C<$event_info>. This must converted by C<< pEFL::ev_info2obj($ev_info, "pEFL::Elm::ColorselectorPaletteItem"); >> 

The provision of Perl classes for event_info C structs is work in progress. If you need a specific binding for a C struct that is not supported at the moment, please send an issue report.

=head1 STATE OF THE BINDING

The Perl binding is in an early development state. So things may change in the future and some functionalities are missing at the moment. Nevertheless especially the Elementary binding is very usable and complete.

If you miss something or find issues, please report it to L<Github|https://github.com/MaxPerl/Perl-EFL>. 

=head1 WHY THE NAME "pEFL"

Originally the name of the distribution was Efl. Unfortunately there was a conflict with the existing distribution EFL which isn't maintained any more and can't be compiled with newer versions of efl. Therefore the name pEFL was chosen whereby the "p" stands for "perl". 

=head1 SEE ALSO

L<Enlightenment Foundation Libraries|https://www.enlightenment.org/docs/start>

L<Perl-EFL Github Repository|https://github.com/MaxPerl/Perl-EFL>

L<Caecilia.pl - a ABC notation editor using pEFL|https://github.com/MaxPerl/Perl-EFL>

=head1 AUTHOR

Maximilian Lika (perlmax@cpan.org)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
