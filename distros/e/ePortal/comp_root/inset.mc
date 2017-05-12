%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#
%#----------------------------------------------------------------------------
%# Arguments:
%#
%#   page => ID of inset. Default is $ENV{SCRIPT_NAME}
%#
%#   number => number of inset on the page.
%#
%#----------------------------------------------------------------------------
<%perl>
	$ARGS{number} = 1 unless $ARGS{number};
	$ARGS{page} = $ENV{SCRIPT_NAME} unless $ARGS{page};

	my $inset_id = "inset$ARGS{number}_$ARGS{page}";
  if ($ePortal->isAdmin and ! $ePortal->UserConfig('hideinsets')) {
    $m->print( img(
      src => "/images/ePortal/html.gif",
      href => href("/admin/inset_edit.htm", number => $ARGS{number}, page=>$ARGS{page}),
			title => pick_lang(
				rus => "Нажмите сюда, чтобы изменить кусок HTML в этом месте",
				eng => "Click here to insert HTML code right here"))
		);
	}

	my $inset = $ePortal->Config($inset_id);
</%perl><% $inset %>\
