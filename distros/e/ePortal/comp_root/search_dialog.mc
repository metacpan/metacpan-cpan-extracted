%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#
%#----------------------------------------------------------------------------
%# Parameters to 'dialog' method:
%#  align => 'right'
%#       make a table around dialog to align it right
%#  vertical => 1
%#       make the dialog as narrow as possible
%#  extra => HTML
%#       extra HTML text to place inside left part of the table when dialog
%#       is aligned right
%#  focus => ''
%#       Do not focus text field of search dialog
%#
%#  The search result is stored in $session{_text}
%#
%#  search_dialog does not modifies any request parameters except set pageXXX to 1
%#
%#
%#  Methods:
%#   dialog - draw the dialog
%#   handle_request - get search text from URI
%#
%#----------------------------------------------------------------------------
<& SELF:handle_request, %ARGS &>
<& SELF:dialog, %ARGS &>

%#=== @metags handle_request ====================================================
<%method handle_request><%perl>
  my %args = $m->request_args;
  return $session{_text} = $args{sd_text};
</%perl></%method>


%#=== @METAGS dialog ====================================================
<%method dialog><%perl>
  $ARGS{align} ='right' if $ARGS{extra} and ! $ARGS{align};
  $ARGS{focus} = 'sd_text' if ! exists $ARGS{focus};
  $ARGS{show_all} = 1 if ! exists $ARGS{show_all};
  $ARGS{label} = pick_lang(rus => 'Текст:', eng => 'Text:') if ! exists $ARGS{label};

  my %Dparam = (
    method => 'GET',
    align => $ARGS{align}, 
    extra => $ARGS{extra},
    title => $ARGS{title} || pick_lang(rus => "Поиск", eng => 'Search'),
    width => '99%',
  );
  $Dparam{width} = 250 if ! $ARGS{vertical};

  my $separator;
  $separator = '<br>' if $ARGS{vertical};

  # Preserve all request arguments
  # Reset All page* arguments to 1 (this is for list.mc)
  my %args = $m->request_args;
  delete $args{sd_text};
  foreach (keys %args) {
    $args{$_} = 1 if /^page.+/ and $args{$_} > 1;
  }
</%perl>
<!-- search_dialog -->
<&| /dialog.mc, %Dparam &>
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
  <form name="sd" method="GET" action="<% $ARGS{action} || $ENV{SCRIPT_NAME} %>">
% foreach (keys %args) {
   <% CGI::hidden(-name => $_, -value => $args{$_}, -override => 1) %>
% }
    <tr><td align="<% $ARGS{vertical} ? 'right': 'left' %>">
% if ($ARGS{label}) {
      <b> <% pick_lang(rus => 'Текст:', eng => 'Text:') %></b>
      <% $separator %>
% }
      <% CGI::textfield(-name => 'sd_text', 
                        -value => $args{sd_text}, 
                        -size => $ARGS{vertical} ? 30: 18, 
                        -title => pick_lang(rus => "Текст для поиска", eng => "Text to search"),
                        -class => 'dlgfield') %>
      <% $separator %>
      <% CGI::submit(-name => '', -value => pick_lang(rus => "Искать!", eng => "Search!")) %>
    </td></tr>
% if ($ARGS{show_all}) {    
    <tr><td align="center">
      <% plink( {rus => "Показать все", eng => 'Show all'},
                          -href => href($ENV{SCRIPT_NAME}, %args)) %>
    </td></tr>
% }
  </form></table>
</&>
% if ($ARGS{focus}) {
  <script language="JavaScript">
  <!--
    document.sd.sd_text.focus();
  // -->
  </script>
% }
<!-- end of search_dialog -->
</%method>
