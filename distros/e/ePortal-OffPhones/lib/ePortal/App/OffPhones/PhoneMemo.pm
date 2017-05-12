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


package ePortal::App::OffPhones::PhoneMemo;
	use base qw/ePortal::ThePersistent::Support/;
    our $VERSION = '4.2';

	use ePortal::Global;
	use ePortal::Utils;

############################################################################
sub initialize	{	#05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{DBISource} = 'OffPhones';

    $p{Attributes}{id} ||= {};
    $p{Attributes}{client_id} ||= {
            dtype => 'Number',
        };
    $p{Attributes}{dept_id} ||= {
            dtype => 'Number',
        };
    $p{Attributes}{user_name} ||= {
                    # username for private memos or
                    # tcpip address for common memos to admin
            dtype => 'Varchar',
            maxlength => 64,
        };
    $p{Attributes}{private} ||= {
            dtype => 'YesNo',
            default => 1,
        };
    $p{Attributes}{title} ||= {
            dtype => 'VarChar',
            fieldtype => 'textarea',
            label => {rus => 'Содержание заметки', eng => 'Memo content'},
            maxlength => 65000,
        };
    $p{Attributes}{ts} ||= {};


    $self->SUPER::initialize(%p);
}##initialize


############################################################################
sub validate	{	#07/06/00 2:35
############################################################################
	my $self = shift;
	my $beforeinsert = shift;

	unless ( $self->title ) {
		return pick_lang(rus => "Не указано наименование", eng => 'No name');
	}

    unless ($self->user_name) {
        if ($ePortal->username) {
            $self->user_name( $ePortal->username );
        } else {
            $self->user_name( $ePortal->r->get_remote_host);
        }
    }

	undef;
}##validate




1;

