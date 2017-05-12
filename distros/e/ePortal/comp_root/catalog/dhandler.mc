%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#----------------------------------------------------------------------------
% if ($C->RecordType eq 'group') {
  <table width="100%" border=0>
  <tr><td>
    <& /catalog/group_ring.mc, group => $C->id &>
    <& /catalog/groups.mc, group => $C->id &>
    <& /catalog/links_ring.mc, group => $C->id &>
    <& /catalog/links.mc, group => $C->id &>
  </td><td width="10%">
    <& /catalog/admin.mc, catalog => $C &>
    <& /catalog/search_dialog.mc &>
    <& /empty_table.mc, height => 5 &>
    <& /catalog/mostpopular.mc &>
  </td></tr></table>

% } elsif ( $C->RecordType eq 'file' ) {
  <& /catalog/group_ring.mc, group => $C->id &>
  <table align="right"><tr><td>
      <& /catalog/admin.mc, catalog => $C &>
  </td></tr></table>
  <& /catalog/show_text.mc, catalog => $C &>
  <br clear="all">
  <& /catalog/show_common_info.mc, catalog => $C &>
  <& /catalog/show_attachments.mc, catalog => $C &>

% } elsif ( $C->RecordType eq 'composite' ) {
  <& /catalog/group_ring.mc, group => $C->id &>
  <& /catalog/composite.mc, catalog => $C &>
  <br clear="all">
  <& /catalog/show_common_info.mc, catalog => $C &>

% } else {
  <& /catalog/group_ring.mc, group => $C->id &>
  Don't know how to show <% $C->RecordType %> resource
% }


%#=== @metags onStartRequest ====================================================
<%method onStartRequest><& PARENT:onStartRequest, %ARGS &><%perl>
  try {  
    my $dh_args = $m->dhandler_arg;
    ($catid, $file) = split('/', $dh_args, 2);

    # A request to /catalog/num should be rewrited to /catalog/num/
    # It is possible to /catalog/num/?pageL=1&rowsL=10
    my $req_path = $ENV{SCRIPT_NAME} . $ENV{PATH_INFO};
    if ( $catid ne '' and $file eq '' and $req_path !~ m|/$|o ) {
      throw ePortal::Exception::Abort(-text => $catid . '/');
    }

    # request to objid == 0
    # redirect to index.htm
    if ( $catid == 0 and $catid =~ /^\d+$/o) {
      throw ePortal::Exception::Abort(-text => '/catalog/index.htm');
    }

    # restore top level Catalog object
    $C = new ePortal::Catalog;
    my $last_modified = undef;
    throw ePortal::Exception::FileNotFound( -file => "/catalog/" . $m->dhandler_arg)
      if ! $C->restore($catid) and ! $C->restore(cstocs('UTF8','WIN',$catid));

    # Using nickname as URL path is unsafe! Using ID 
    if ( $C->check_id and $C->id ne $catid and $file eq '' ) {
      throw ePortal::Exception::Abort(-text => '/catalog/'.$C->id.'/');
    }

    $C->ClickTheLink;          # Increment number of clicks
    $last_modified = $C->LastModified;

      # --------------------------------------------------------------------
      # The link requires us to redirect
    if ( $C->RecordType eq 'link' ) {
      throw ePortal::Exception::Abort(-text => $C->url);
  
      # --------------------------------------------------------------------
      # Download a file as attachment
    } elsif ( $C->RecordType eq 'file' and $file ne '' ) {
      my $att = new ePortal::Attachment;
      $att->restore_where(obj => $C, filename => $file);
      throw ePortal::Exception::FileNotFound(-file => '/catalog/' . $m->dhandler_arg)
        if ( ! $att->restore_next );

      $m->comp('/download.mc', att => $att, download => $ARGS{todisk});
  
      # --------------------------------------------------------------------
      # Special case. Request to resource with 1 file and without any text
    } elsif (  $C->RecordType eq 'file' and
          $file eq '' and
          $C->Text eq '' and
          $C->Attachments == 1 ) {
      my $att = new ePortal::Attachment;
      $att->restore_where(obj => $C);
      $att->restore_next;

      throw ePortal::Exception::Abort(-text => '/catalog/' . escape_uri($catid) . '/' . escape_uri($att->Filename));
  
    
      # --------------------------------------------------------------------
      # work with composite objects
    } elsif ( $C->RecordType eq 'composite' ) {
      $last_modified = undef;   # Dont know how to handle this !!!
                                # on TODO  
      $m->comp('/catalog/composite.mc:onStartRequest', %ARGS, catalog => $C);
    }

    $r->set_last_modified($last_modified) if $last_modified;
    $r->no_cache(1);

  } catch ePortal::Exception with {
    my $E = shift;
    $C = undef;                         # cleanup resources
    $E->throw;
  };
</%perl></%method>



%#=== @METAGS Title ====================================================
<%method Title><%perl>
  if ( ref($C) and $C->check_id ) {
    return pick_lang(rus => "Каталог: ", eng => "Catalogue: ") . $C->Title;
  } else {
    return pick_lang(rus => "Каталог ресурсов", eng => "Resources catalogue");
  }
</%perl></%method>


%#=== @METAGS shared =========================================================
<%once>
my($C, $catid, $file, $other);
</%once>
<%cleanup>
$C = undef;
</%cleanup>
