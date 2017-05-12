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
	# I serve requests only for directories
  if (! -d $r->filename) {
    throw ePortal::Exception::FileNotFound(-file => $r->filename);
  }

	# Due to location of dhandler at component root it inherits only base
	# attributes by default. I need to find first autohandler from the top
	# and use it for attributes

	my @path_parts = split "/", $r->uri;
	$attrib_comp = undef;
	while(@path_parts) {
		my $pretendent = join("/", @path_parts)."/" . $m->interp->autohandler_name;
		if ( $m->comp_exists($pretendent)) {
			$attrib_comp = $m->fetch_comp($pretendent);
			last;
		}
		pop @path_parts;
	}

	if (! $attrib_comp ) {
		$attrib_comp = $m->fetch_comp("/autohandler.mc");
	}

	if ( ! $attrib_comp->attr('dir_enabled') ) {
    throw ePortal::Exception::FileNotFound(-file => $r->filename);
    return;
	}
</%perl>

<& /dir.mc,
	exclude => $attrib_comp->attr('dir_exclude'),
	nobackurl => $attrib_comp->attr('dir_nobackurl'),
	sortcode => $attrib_comp->attr('dir_sortcode'),
	description => $attrib_comp->attr('dir_description'),
	columns => $attrib_comp->attr('dir_columns'),
	include => $attrib_comp->attr('dir_include'),
	title => $attrib_comp->attr('dir_title'),
&>


%#=== @METAGS onStartRequest ====================================================
<%method onStartRequest><%perl>
  # Check for existens of requested file in Catalog
  my ($nickname, $dummy) = split('/', $m->dhandler_arg, 2);
  my $nickname_utf8 = cstocs('UTF8', 'WIN', $nickname);

  my $C = new ePortal::Catalog;
  foreach ($nickname, $nickname_utf8) {
    $C->restore_where(where => "nickname=?", bind => [$_]);
    if ( $C->restore_next and $C->rows == 1 ) {
      throw ePortal::Exception::Abort( -text => '/catalog/' . $C->id . '/' );
    }
  }

  # check for existance of requested file
  if (! -d $r->filename and ! -f $r->filename) {
    throw ePortal::Exception::FileNotFound(-file => $ENV{REQUEST_URI});
    return;
  }
</%perl></%method>


%#=== @METAGS once =========================================================
<%once>
  my $attrib_comp;
</%once>
<%cleanup>
  $attrib_comp = undef;
</%cleanup>
