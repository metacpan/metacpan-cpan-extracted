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
% my $Layout = $m->request_comp->attr('Layout');
% if ($Layout eq 'Normal') {
  <& navigator.mc &>
% }

% if ($session{_org_id} == 0 and $ENV{SCRIPT_NAME} !~ /org_edit.htm/) {
%  if ($ePortal->username) {
    <& /message.mc, ErrorMessage => pick_lang(
        rus => "Не удалось открыть Ваш Органайзер",
        eng => "Cannot find your Organizer") &>
%  } else {
    <& /message.mc, ErrorMessage => pick_lang(
        rus => "Анонимный пользователь не может иметь своего Органайзера",
        eng => "Anonymous cannot have an Organizer") &>
%  }
% } else {
  <% $m->call_next %>
% }

%#=== @metags attr =========================================================
<%attr>
Title => {rus => "Персональный органайзер", eng => "Personal organizer"}
Application => 'Organizer'
</%attr>

%#=== @METAGS htmlHead ====================================================
<%method HTMLhead>
<& PARENT:HTMLhead &>
<link rel="STYLESHEET" type="text/css" href="/styles/Organizer.css">
</%method>


%#=== @metags onStartRequest =================================================
<%method onStartRequest>
<& PARENT:onStartRequest, %ARGS &>
<%perl>
  my %args = $m->request_args;
  $session{_app} = $ePortal->Application('Organizer');
  $session{_organizer} = new ePortal::App::Organizer::Organizer;
  $session{_organizer}->restore( $args{org_id} );
  $session{_org_id} = $session{_organizer}->id + 0;


  # If user is registered and org_id==0 then redirect to private organizer
  if ( $ePortal->username and $session{_org_id} == 0 ) {
    # create a default organizer for registered user
    my $new_org_id = $m->comp('create_default_org.mc');
    if ( $new_org_id ) {
      $session{_organizer}->restore( $new_org_id );
      $session{_org_id} = $new_org_id;
    }
  }
</%perl></%method>
