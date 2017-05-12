%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#
%#----------------------------------------------------------------------------

<%perl>
my $ctlg = new ePortal::Catalog;
$ctlg->HitTheLink($id);

if ( $image ) {
  $m->print( img(src => '/images/ePortal/statistics.gif',
    title => pick_lang(rus => "Статистика ресурса:", eng => "Rsource statistics:") .
      "\n" . pick_lang(rus => "Всего обращений:", eng => "Hits total:") . $ctlg->Hits .
      "\n" . pick_lang(rus => "Обращений сегодня:", eng => "Hits today:") . $ctlg->HitsToday .
      "\n" . pick_lang(rus => "Визиторов сегодня:", eng => "Visitors today:") . $ctlg->VisitorsToday,
    href => href('/catalog/statistics.htm', id => $id),
      ));
}
</%perl>

%#=== @METAGS args =========================================================
<%args>
$id
$image => 1
</%args>
