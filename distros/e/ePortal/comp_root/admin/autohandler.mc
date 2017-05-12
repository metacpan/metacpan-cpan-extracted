%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#
%#----------------------------------------------------------------------------
% my $Layout = $m->request_comp->attr('Layout');
% if ($Layout eq 'Normal') {
  <& navigator.mc &>
% }
<& /message.mc &>
<% $m->call_next %>


%#----------------------------------------------------------------------------
<%attr>
Title => {rus => "Раздел администратора", eng => "Administrators page"}
require_admin => 1
</%attr>


%#=== @metags setup_onStartRequest ====================================================
<%method setup_onStartRequest><%perl>
  my $obj = $ARGS{obj};

  # Handle Dialog events
  my $result = try {
    $m->comp('/dialog.mc:handle_request', objid => 1, obj=> $obj);

  } catch ePortal::Exception::DataNotValid with {
    my $E = shift;
    $session{ErrorMessage} = $E->text;

  } catch ePortal::Exception::DBI with {
    my $E = shift;
    $session{ErrorMessage} = pick_lang(
          rus => "Ошибка сервера баз данных", 
          eng => "Database server error") . "\n<!-- DB error\n" . $E->text . "-->\n";
  };

  return $result;
</%perl></%method>
