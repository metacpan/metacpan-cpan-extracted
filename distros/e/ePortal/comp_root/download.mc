%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%# Arguments:
%#  download => 1  - force download dialog on client
%#  att => ePortal::Attachment object
%#  att_id => Attachment ID to download
%#  objtype objid => owner of single! attachment type and ID
%#  object => owner of single! attachment 
%#
%# May throw
%#  ePortal::Exception::ObjectNotFound - When attachment not found
%#  ePortal::Exception::Abort - at the end of download
%#
%#----------------------------------------------------------------------------
<%perl>
  my $att = $ARGS{att};
  my $att_id = $ARGS{att_id};

  # possible create new Attachment object
  if ( ! UNIVERSAL::isa($att, 'ePortal::Attachment') ) {
    $att = new ePortal::Attachment;
  }

  # restore object
  if ( $att_id ) {
    $att->restore_or_throw($att_id);

  } elsif (ref($ARGS{object})) {
    $att->restore_where(obj => $ARGS{object});
    throw ePortal::Exception::ObjectNotFound(-object => $ARGS{object})
      if ! $att->restore_next;

  } elsif ( $ARGS{objtype} and $ARGS{objid} ) {
    $att->restore_where( object_id => $ARGS{objtype} .'='. $ARGS{objid});
    throw ePortal::Exception::ObjectNotFound(-value => "$ARGS{objtype}=$ARGS{objid}")
      if ! $att->restore_next;
  }
  throw ePortal::Exception::ObjectNotFound()  if ! $att->check_id;

    # Determine mime type

  # Prepare HTTP headers
  my $content_type = $m->comp('SELF:mime_type', filename => $att->filename);
  my $last_modified = $att->LastModified;

  $m->clear_buffer;
  $r->content_type($content_type);
  $r->header_out('Content-Disposition' => 
    ($ARGS{download} ? 'attachment' : 'inline') . 
    "; filename=".$att->filename);
  $r->header_out( "Content-Length" => $att->filesize );
  $r->set_last_modified($last_modified) if defined $last_modified;
  $r->send_http_header;
  throw ePortal::Exception::Abort if $r->header_only;

  # Send the content
  $att->get_first_chunk;
  while(my $buffer = $att->get_next_chunk) {
    last if $r->connection->aborted;
    $m->print($buffer);
    $m->flush_buffer;
  }
  throw ePortal::Exception::Abort;
</%perl>





%#=== @METAGS mime_type ====================================================
<%method mime_type><%perl>
  if ( $ePortal::DEBUG ) {
    %ARGS = Params::Validate::validate(@_, {
      filename => { type => SCALAR },
    });  
  }

  my $f = lc($ARGS{filename});
  $f =~ s/^.*\.//go;  # get extension only from filename

  my $content_type = $known_mime_types{$f};
  if ( ! $content_type ) {
    logline('warn', "subrequesting Apache for mime type of file " . $ARGS{filename});
    my $subr = $r->lookup_uri('/' . escape_uri($ARGS{filename}));
    $content_type = $subr ? $subr->content_type : undef;
  }
  $content_type = "application/octet-stream" unless $content_type;
  
  if ( $ePortal::DEBUG ) {
    logline('debug', "/download.mc:mime_type: " . $ARGS{filename} . " is $content_type");
  }

  return $content_type;
</%perl></%method>


%#=== @METAGS once =========================================================
<%once>
  my %known_mime_types = (
    asc => 'text/plain',
    avi => 'video/x-msvideo',
    bmp => 'image/bmp',
    chm => 'application/mshelp',
    class => 'application/octet-stream',
    css => 'text/css',
    csv => 'application/vnd.ms-excel',
    dll => 'application/octet-stream',
    doc => 'application/msword',
    exe => 'application/octet-stream',
    gif => 'image/gif',
    gz => 'application/x-gzip',
    hlp => 'application/mshelp',
    htm => 'text/html',
    html => 'text/html',
    jpeg => 'image/jpeg',
    jpg => 'image/jpeg',
    js => 'application/x-javascript',
    kar => 'audio/midi',
    m3u => 'audio/x-mpegurl',
    mid => 'audio/midi',
    midi => 'audio/midi',
    mp3 => 'audio/mpeg',
    mpeg => 'video/mpeg',
    mpg => 'video/mpeg',
    pdf => 'application/pdf',
    png => 'image/png',
    rar => 'application/rar',
    rtf => 'text/rtf',
    tgz => 'application/x-gzip',
    tif => 'image/tiff',
    tiff => 'image/tiff',
    txt => 'text/plain',
    xls => 'application/vnd.ms-excel',
    xlw => 'application/vnd.ms-excel',
    zip => 'application/zip',
  );
</%once>
