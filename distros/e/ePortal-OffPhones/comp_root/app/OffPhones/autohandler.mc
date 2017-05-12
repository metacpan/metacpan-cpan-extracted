%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2003 Sergey Rusakov.  All rights reserved.
%# This program is free software; you can redistribute it
%# and/or modify it under the same terms as Perl itself.
%#
%#
%#----------------------------------------------------------------------------
<% $m->call_next %>

%#=== @metags onStartRequest ====================================================
<%method onStartRequest><%perl>
  my $app = $ePortal->Application('OffPhones');
  if ( $app->xacl_check_update ) {
    $session{AppOffPhones_EditMode} = exists $ARGS{edit_mode}
        ? $ARGS{edit_mode}
				: $session{AppOffPhones_EditMode}+0;
	} else {
		delete $session{AppOffPhones_EditMode};
	}
</%perl></%method>

%#=== @metags attr =========================================================
<%attr>
Title => {rus => "Служебные телефоны", eng => "Telephone directory"}
Application => 'OffPhones'
</%attr>
