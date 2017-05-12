%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#
%#----------------------------------------------------------------------------
%# Parameters:
%#    group=<id> display this group
%#
%#----------------------------------------------------------------------------

<& /inset.mc, page => '/catalog/links1', number => $ARGS{group} &>
<&| /list.mc, obj => new ePortal::Catalog,
          no_title => 1,
          submit => 1,
          restore_where => {
            parent_id => $ARGS{group},
            skip_attributes => [qw/ text setup_hash /],
            order_by => 'priority,title',
            where => "recordtype not in('group') AND state='ok'",
            $ePortal->isAdmin ? () : ( hidden => 0 ),
          } &>

 <&| /list.mc:row &>
  <& /list.mc:column_image, -width => '3%',
      src => $_->hidden 
        ? '/images/icons/key.gif'
        : $_->xacl_read eq 'everyone'
          ? '/images/ePortal/item.gif'
          : '/images/ePortal/private.gif' &>
  <&| /list.mc:column,
            id => 'title',
            url => '/catalog/'. $_->id . '/' &>
    <% $_->Title %>
  </&>

% if ($_->xacl_check_update) {
    <& /list.mc:column_edit,
        url => href(($_->recordtype eq 'link'
                    ? '/catalog/link_edit.htm'
                    : '/catalog/file_edit.htm'), objid => $_->id) &>
% } else {
    <& /list.mc:column, content => '&nbsp;' &>
% }


% if ($_->xacl_check_delete) {
    <& /list.mc:column_delete &>
% } else {
    <& /list.mc:column, content => '&nbsp;' &>
% }

 </&><!-- row -->

% if ( $_->Memo ) {
  <&| /list.mc:extra_row &>
  <& /htmlify.mc, class => 'memo', content => $_->Memo &>
  </&>
% }

 <& /list.mc:row_span, &>

 <&| /list.mc:nodata &>
  <div style="font-size: 8pt; color:red; text-indent: 20px;">
  <% img(src=> "/images/ePortal/item.gif") %>
  <% pick_lang(
      rus => "Нет ни одного ресурса в этом разделе.",
      eng => 'There is no resources in this group.' ) %>
  </div>
 </&>

</&><!-- end of list -->
<& /inset.mc, page => '/catalog/links2', number => $ARGS{group} &>

