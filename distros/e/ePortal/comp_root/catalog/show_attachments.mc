%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software.
%#
%#----------------------------------------------------------------------------
<%perl>
  if ( $ePortal::DEBUG ) {
    %ARGS = Params::Validate::validate( @_, {
        catalog => {type => OBJECT, optional => 1},
        item => { type => OBJECT, optional => 1 },
        show_caption => { type => BOOLEAN, optional => 1},
        show_files => { type => BOOLEAN, optional => 1},
      });
  }
  my $catalog = $ARGS{catalog} || new ePortal::Catalog;
  my $item = $ARGS{item} || new ePortal::CtlgItem;

  # Possible this section is hidden
  my $extra_text;
  if ( $catalog->show_files == 0 and ! $catalog->xacl_check_update ) {
    return;

  } elsif ( $catalog->show_files == 0 ) {
    $extra_text = pick_lang(
        rus => "Этот раздел невидим для обычных пользователей",
        eng => "This section is hidden for users");
  }

  # Show the caption by default
  $ARGS{show_caption} = 1 if ! exists $ARGS{show_caption};
  $ARGS{show_upload}  = 1 if ! exists $ARGS{show_upload};

  my $base_url = '/catalog/' . $catalog->id . '/';
  my $att = new ePortal::Attachment;
  my $att_base_object = $catalog;

  if ( $item->check_id ) {
    $base_url .= $item->id . '/';
    $att_base_object = $item;
  }

  $att->restore_where(obj => $att_base_object);
</%perl>

%  if ($att->rows == 1) {
%    $att->restore_next;
  <p>
% if ($ARGS{show_caption}) {
  <& /item_caption.mc,
        extra => $extra_text,
        title => pick_lang(rus => "Прикрепленный файл", eng => "Attached file") &>
% }
  <div style="margin-left: 1cm;">
  <br><b><% pick_lang(rus => "Имя файла: ", eng => "File name: ") %></b>
      <% $att->Filename |h %>
  <br><b><% pick_lang(rus => "Размер файла: ", eng => "File size: ") %></b>
      <% $att->Filesize %> <% pick_lang(rus => "байт", eng => "bytes") %>
  <br><% plink(
      pick_lang(rus => "Просмотреть ", eng => "View ") . $att->Filename,
      -href => href($base_url . escape_uri($att->Filename))) %>
      <% plink(
      pick_lang(rus => "Загрузить ", eng => "Download ") . $att->Filename,
      -href => href($base_url . escape_uri($att->Filename), todisk=>1)) %>
  </div>

% } elsif ($att->rows > 1) {
  <p>
% if ($ARGS{show_caption}) {
  <& /item_caption.mc,
        extra => $extra_text,
        title => pick_lang(rus => "Все файлы данного ресурса", eng => "All files of this resource") &>
% }
  <div style="margin-left: 1cm;">
  <&| /list.mc, obj => $att, -width => '60%', rows => 10, no_footer => 2,
        restore_where => { obj => $att_base_object, order_by => 'id' }, order_by => 'filename' &>

   <&| /list.mc:row &>
    <& /list.mc:column_image &>
    <& /list.mc:column, id => 'filename',
          url => $base_url . escape_uri($_->Filename),
          title => pick_lang(rus => "Имя файла", eng => "File name") &>
    <& /list.mc:column, id => 'filesize', title => pick_lang(rus => "Размер файла", eng => "File size"), -align => 'center' &>
    <&| /list.mc:column &>
      <% plink(pick_lang(rus => "Загрузить", eng => "Download"),
        -href => href($base_url . escape_uri($_->Filename), todisk=>1)) %>
    </&>

% if ($catalog->xacl_check_update) {
     <& /list.mc:column_delete &>
% }
   </&>
  </&>
  </div>
% }

% if ($ARGS{show_upload} and $catalog->xacl_check_update) {
  <p>
  <& /item_caption.mc,
      extra => $extra_text,
      title => pick_lang(rus => 'Добавить файл', eng => "Attach a file") &>
  <p style="margin-left: 1cm;">
  <% CGI::start_multipart_form({-name => 'uploadForm', method => 'POST', action=>'/catalog/upload.htm'}) %>
  <% CGI::hidden({-name => 'objtype', -value => ref($att_base_object)}) %>
  <% CGI::hidden({-name => 'objid', -value => $att_base_object->id}) %>
  <% CGI::filefield({-name => 'upload_file'}) %>
  <% CGI::submit(-name => 'submit', -value => pick_lang(rus => 'Загрузить', eng => "Upload")) %>
  </form>
  </p>
% }

