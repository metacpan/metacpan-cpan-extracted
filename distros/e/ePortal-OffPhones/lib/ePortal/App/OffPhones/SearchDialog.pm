#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2003 Sergey Rusakov.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
#
#----------------------------------------------------------------------------

package ePortal::App::OffPhones::SearchDialog;
    our $VERSION = '4.2';
	use base qw/ePortal::ThePersistent::Dual/;

	use ePortal::Global;
	use ePortal::Utils;		# import logline, pick_lang
	use ePortal::HTML::Dialog;

############################################################################
sub initialize	{	#05/31/00 8:50
############################################################################
	my $self = shift;
    $self->SUPER::initialize(Attributes => {
        name => {
                    label => {rus => 'Фамилия или номер', eng => 'Name to search'},
                    dtype => 'Varchar',
                    size => 18,
        },
    });

    $self->{dialog} = new ePortal::HTML::Dialog( delete_button => 0,
        title => pick_lang(rus => "Поиск в телефонном справочнике", eng => 'Search'),
        obj => $self,
        width=>"300",
        method=>"GET");
}##initialize


############################################################################
sub handle_request  {   #10/01/02 10:45
############################################################################
    my $self = shift;
    $self->{dialog}->handle_request(@_);
}##handle_request


############################################################################
sub draw_dialog	{	#11/22/01 12:23
############################################################################
	my $self = shift;
	my $list = shift;

	my @out;
	my $m = $HTML::Mason::Commands::m;

    my $d = $self->{dialog};

	push @out, $d->dialog_start;
	push @out, $d->field("name");
	push @out, $d->buttons( ok_label => pick_lang(rus => "Искать!", eng => "Search!"), cancel_button => 0);
	push @out, $d->dialog_end;

    # Clear internal data. Avoid memory leaks
    $self->{dialog} = undef;
    undef $d;

    # Return resulting HTML or output it directly to client
    defined wantarray ? join("\n", @out) : $m->print( join("\n", @out) );
}##draw_dialog

1;

