#!/usr/dim/perl/5.8/bin/perl

# $Id: pbrowser.cgi,v 1.27 2004/09/14 09:08:03 joern Exp $

use strict;

BEGIN {
	$0 =~ m!^(.*)[/\\][^/\\]+$!;    # Win32 Netscape Server Workaround
	chdir $1 if $1;
	require "../etc/default-user.conf";
	require "../etc/newspirit.conf"
}

require $CFG::objecttypes_conf_file;

use CGI;
use Carp;
use NewSpirit;

main: {
	# dieses globale Hash können Module nutzen, um request
	# spezifische Daten abzulegen
	%NEWSPIRIT::DATA_PER_REQUEST = ();
	
	my $q = new CGI;
	print $q->header(-type=>'text/html');

	eval { main($q) };
	NewSpirit::print_error ($@) if $@;

	%NEWSPIRIT::DATA_PER_REQUEST = ();
}

sub main {
	my $q = shift;
	my $sh = NewSpirit::check_session_and_init_request ($q);

	my $e = $q->param('e');
	
	NewSpirit::start_page(
		link_style => 'plain',
		bgcolor => $CFG::PB_BG_COLOR
	) unless $e eq 'frameset';

	if ( $e eq 'options' ) {
		pb_options($q);
	} elsif ( $e eq 'frameset' ) {
		pb_frameset($q, $sh);
	} else {
		my $changed = process_tree_event($q, $sh);

		menu_link($q);
		tree($q);

		if ( $changed ) {
			$sh->preserve_session_data;
		}
	}
	
	NewSpirit::end_page() unless $e eq 'frameset';
}

sub process_tree_event {
	my ($q, $sh) = @_;

	my $e = $q->param('e');
	return if not $e;
	
	my $dir = $q->param('dir');
	my $ticket = $q->param('ticket');
	
	my $sf = NewSpirit::open_session_file($ticket);

	my $changed;
	if ( $e eq 'open' ) {
		$sf->{hash}->{$dir} = 1;
		$changed = 1;
		$q->param('jump_folder', $dir);
	} elsif ( $e eq 'close' ) {
		delete $sf->{hash}->{$dir};
		$changed = 1;
		$q->param('jump_folder', $dir);
	} elsif ( $e eq 'close_all' ) {
		close_all_folders ($q, $sf);
		$changed = 1;
	} elsif ( $e eq 'open_all' ) {
		$changed = 1;
	} elsif ( $e eq 'select' ) {
		$sh->set_attrib ('project', $q->param('project'), $sf);
		$changed = 1;
	}
	$sf = undef;

	$sh->preserve_session_data;
	
	return $changed;
	
	1;
}

sub close_all_folders {
	my ($q, $sf) = @_;
	
	my $project = $q->param('project');
	
	my @delete;
	my ($k,$v);
	while ( ($k,$v) = each %{$sf->{hash}} ) {
		if ( $k =~ m!^$project/! ) {
			push @delete, $k;
		}
	}

	foreach $k (@delete) {
		delete $sf->{hash}->{$k};
	}
	
	1;
}

sub menu_link {
	my $q = shift;
	
	my $ticket = $q->param('ticket');
	my $project = $q->param('project');

	print <<__HTML;
<table cellpadding="1" cellspacing="2" border="0">
<tr bgcolor="#ffffff"><td>
  $CFG::FONT
  <a href="$CFG::admin_url?e=menu&ticket=$ticket&project=$project"
     target="ACTION"><b>MAIN</b></a>
  </font>
</td>
__HTML
	if ( $project ) {
		print <<__HTML;
<td>
  $CFG::FONT
  <a href="$CFG::admin_url?e=project_menu&ticket=$ticket&project=$project"
     target="ACTION"><b>PROJECT</b></a>
  </font>
</td>
__HTML
	}
	
	print <<__HTML;
<!-- <td width="100%">
  $CFG::FONT
  &nbsp;
  </font>
</td> -->
</tr>
</table>
<p>
__HTML
}

sub pb_frameset {
	my $q = shift;
	
	my ($sh) = @_;
	
	my $ticket = $q->param('ticket');
	my $project = $q->param('project');
	my $object = $q->param('object');

	$sh->set_attrib ('project', $project);
	$sh->preserve_session_data;

	my $pbrowser_url = "$CFG::pbrowser_url?project=$project&ticket=$ticket";
	my $pbopt_url    = "$CFG::pbrowser_url?project=$project&ticket=$ticket&e=options";
	
	print <<__HTML;
<html>
<head><title>$CFG::window_title</title></head>
<frameset rows="*,$CFG::PB_OPT_HEIGHT" border=0>
  <frame src="$pbrowser_url" name="PBTREE" frameborder=no>
  <frame src="$pbopt_url" name="PBOPT" frameborder=no scrolling=no>
</frameset>
</html>
__HTML
}
	
sub pb_options {
	my $q = shift;
	
	my $project = $q->param('project');
	my $ticket = $q->param('ticket');

	# if no project is selected, no menu is needed
	return if $project eq '';

	my $open_url  = "$CFG::pbrowser_url?ticket=$ticket&project=$project&e=open_all";
	my $close_url = "$CFG::pbrowser_url?ticket=$ticket&project=$project&e=close_all";
	
	
	print <<__HTML;
<TABLE CELLPADDING=0 CELLSPACING=0 BORDER=0>
<TR><TD VALIGN="top">
  <FORM NAME="pboptions">
  $CFG::FONT_SMALL
  <INPUT TYPE="CHECKBOX" NAME="in_window">
  </FONT>
</TD><TD>
  $CFG::FONT_SMALL
  icon click opens window
  </FONT>
</TD></TR>
<TR><TD VALIGN="top">
  $CFG::FONT_SMALL
  <INPUT TYPE="CHECKBOX" NAME="with_treeview">
  </FONT>
</TD><TD>
  $CFG::FONT_SMALL
  open window with treeview
  </FONT>
</TD></TR>
<TR><TD>&nbsp;</TD><TD>
  $CFG::FONT_SMALL
  <a href="$close_url" target="PBTREE">close</a> &nbsp;/&nbsp;
  <a href="$open_url" target="PBTREE">open</a>
  &nbsp;&nbsp; all folders
  </FONT>
</TD></TR>
</TABLE>
</FORM>
__HTML
}

sub js_open_editor_window {
	my $q = shift;

	my $ticket = $q->param('ticket');
	my $project = $q->param('project');

	NewSpirit::js_open_window($q);

	print <<__HTML;
<SCRIPT LANGUAGE="JavaScript">
  function replaceString(oldS,newS,fullS) {
    // Replaces oldS with newS in the string fullS
    for (var i=0; i<fullS.length; i++) {
      if (fullS.substring(i,i+oldS.length) == oldS) {
        fullS = fullS.substring(0,i)+newS+fullS.substring(i+oldS.length,fullS.length)
      }
    }
    return fullS
  }

  function open_editor_window (object_name) {
    if ( parent.PBOPT.document.pboptions.in_window.checked ) {
      var x,y;
      var name;
      parent.PBOPT.document.pboptions.in_window.checked = 0;

      if ( parent.PBOPT.document.pboptions.with_treeview.checked ) {
        var url = '$CFG::admin_url?e=clone_session&object='+object_name+
                  '&ticket=$ticket&project=$project';
        x = top.innerWidth;
        y = top.innerHeight;
        parent.PBOPT.document.pboptions.with_treeview.checked = 0;
	name = null;
      } else {
        var url = '$CFG::object_url?e=clone_session&object='+object_name+
                  '&ticket=$ticket&project=$project';
//		  +
//		  '&no_httpd_header=1';
        x = parent.parent.ACTION.innerWidth; // $CFG::EDITOR_WIDTH;
        y = parent.parent.ACTION.innerHeight; // $CFG::EDITOR_HEIGHT;

        object_name = replaceString ('/','_',object_name);
        object_name = replaceString ('.','_',object_name);
        object_name = replaceString ('-','_',object_name);

	name = '$ticket'+object_name;
      }
      open_window (url, name, x, y, null, null, false);
    } else {
      var url = '$CFG::object_url?e=edit&object='+object_name+
                '&ticket=$ticket&project=$project';
      parent.parent.ACTION.document.location.href=url;
    }
  }
</SCRIPT>
__HTML
}

sub tree {
	my $q = shift;
	
	js_open_editor_window($q);

	print qq{<nobr><font face="$CFG::FONT_FACE_TV" size="$CFG::FONT_SIZE_TV">\n};

	my $project = $q->param('project');
	my $ticket = $q->param('ticket');
	my $jump_folder = $q->param('jump_folder');
	my $jump_object = $q->param('jump_object');
	
	if ( not $project ) {
		print "<b>No project selected!</b><p>\n";
		print "</font>\n";
		return;
	}


	my $sf = NewSpirit::open_session_file ($ticket);
	$sf->{hash}->{__attr_project} = $project;

	my $open_folders = $sf->{hash};

	my (@tree);
	push @tree, $project."//";	# this marks the top of the tree

	my $project_info = NewSpirit::get_project_info ($project);

	my $state = {
		project => $project,
		project_src => "$project_info->{root_dir}/src",
		open_folders => $open_folders,
		tree => \@tree,
		open_all_folders => $q->param('e') eq 'open_all'
	};

	read_tree ($state, "");

	my $a = "align=top border=0";

	# Nun folgt die Ausgabe des Baumes

	my ($item, $last_item, $i, $n, $depth);
	$i = 0;
	$n = scalar @tree - 1;
	$depth = 0;
	$last_item = undef;

	my ($obj_icon, $pre_icon, $pre_href, $href, $object,
	    $obj_type, $obj_dir, $driver, @pre_images, $obj_text);

	foreach $item (@tree) {
		# A folder?
		if ( $item =~ /\/$/ ) {
			my $check = $item;
			$check =~ s/\/\/?$//;
			$check =~ s!/+!/!g;
			my $folder = $check;
			$folder =~ s!^[^/]+/?!!;
			$href="$CFG::folder_url?e=edit&folder=$folder";
			
			if ( $check eq $jump_folder ) {
				print "<A NAME=jump>\n";
			}
			
			# open or closed?
			my $self;
			if ( defined $state->{open_folders}->{$check} ) {
				$obj_icon = "icon_dir_open.gif";
				$pre_href="$CFG::pbrowser_url?e=close&dir=$check";
				# anything left in this folder?
				$check =~ s/\/.*$//;
				if ( $item !~ /\/\/$/ && $i != $n &&
				     ($tree[$i+1] =~ /^$check/) ) {
					$pre_icon="tree_minus_down.gif";
				} else {
					$pre_icon="tree_minus.gif";
				}
			} else {
				$obj_icon = "icon_dir_closed.gif";
				$pre_href="$CFG::pbrowser_url?e=open&dir=$check";
				# anything left in this folder?
				$check =~ s/\/.*$//;
				if ( $item !~ /\/\/$/ && $i != $n &&
				     ($tree[$i+1] =~ /^$check/) ) {
					$pre_icon="tree_plus_down.gif";
				} else {
					$pre_icon="tree_plus.gif";
				}
			}
		} else {
			# OK, an object

			my ($obj_ext);
			($obj_ext) = ( $item =~ /\.([^\.]*)$/ );
			$obj_icon = $NewSpirit::Object::object_types->{
				    	$NewSpirit::Object::extensions->{$obj_ext}
				    }->{icon};

			$object = $item;
			$object =~ s!/+!/!g;
			$object =~ s!^[^/]+/!!;
			$href = "$CFG::object_url?e=edit&object=$object";

			if ( $object eq $jump_object ) {
				print "<A NAME=jump>\n";
			}

			# something left in this folder?
			($obj_dir) = ( $item =~ /^(.*)\// );
			if ( $i != $n &&
			     $tree[$i+1] =~ /^$obj_dir\// ) {
				$pre_icon="tree_rline.gif";
			} else {
				$pre_icon="tree_eline.gif";
			}
			# das vorstehende Icon hat kein HREF
			$pre_href = "";
			
		}

		# Objekt Text aus Filename rauspopeln
		$obj_text = $item;
		$obj_text =~ s/\/\/?$//;
		$obj_text =~ /\/?([^\/]+)$/;
		$obj_text = $1;
		($obj_text) = $obj_text =~ /^([^\.]+)/;

		# OK, nun sind alle objektabhaengigen Variablen gesetzt,
		# jetzt kann der ganze Rotz ausgegeben werden

		# Einrueckungsarray poppen, falls wieder in einem uebergeordneten
		# Verzeichnis

		my $test_dirs = $item;
		$test_dirs =~ s!/+!/!g;
		$test_dirs =~ s/[^\/]+//g;

		$depth = length($test_dirs);

		if ( length($test_dirs) <= scalar (@pre_images) ) {
			if ( $item =~ /\/$/ ) {
				splice @pre_images, $depth-1;
			} else {
				splice @pre_images, $depth;
			}
		}

		# zunaechst mal Einruecken!
		my ($p, $first_skipped);
		foreach $p (@pre_images) {
			print "<img src=$CFG::icon_url/$p $a>" if ($first_skipped);
			$first_skipped = 1;
		}

		# Ticket und Project in die hrefs reinbauen
		$pre_href .= "&ticket=$ticket&project=$project" if $pre_href ne "";
		$href .= "&ticket=$ticket&project=$project";

		# nun das Pre-Icon, falls es nicht der Projektordner ist
		if ($i) {
			# Directory: jump Marker anhängen an pre_href anhängen
			$pre_href .= "#jump" if $pre_href ne '';
			print "<a href=$pre_href>" if $pre_href ne '';
			print "<img src=$CFG::icon_url/$pre_icon $a>";
			print "</a>" if $pre_href ne "";
		}

		if ( $item !~ /\/$/ ) {
			# OK, an object, so we build a window and a frame targeted link
			print qq|<a href="javascript:open_editor_window('$object')">|.
			      qq|<img src=$CFG::icon_url/$obj_icon $a></a>&nbsp;|;

			print qq|<a href=$href target=ACTION>$obj_text</a><br>\n|;
		} else {
			# folder links: always loaded in the frame
			print qq|<a href=$href target=ACTION>|.
			      qq|<img src=$CFG::icon_url/$obj_icon $a>|.
			      qq|&nbsp;$obj_text</a><br>\n|;
		}

#		print "<a href=$href target=ACTION><img src=$CFG::icon_url/$obj_icon $a>";
#		print "&nbsp;$obj_text</a><br>\n";

		# nun, das Einrueckungsarray updaten!
		if ( $item =~ /\/\/$/ ) {
			push @pre_images, "tree_empty.gif"
		} elsif ( $item =~ /\/$/ ) {
			push @pre_images, "tree_vline.gif";
		}

		++$i;
	}

	print "</font></nobr>\n";

	my $self;
	$self->{open_folders} = undef;
	$self->{object_sort} = undef;

	return;
}

sub read_tree {
	my ($state, $dir) = @_;

	my $fullpath = $state->{project_src};
	$fullpath .= "/".$dir if $dir;
	
	my $project  = $state->{project};

	my (@dir, %obj, $entry, $ext);
	opendir (DIR, "$fullpath") or croak "can't opendir $fullpath";

	# Das Verzeichnis wird nun eingelesen. Gefundene Verzeichnisse
	# werden nach @dir gepusht. Gefundene Objekte nach
	# @{$obj{$object_type}}.

	my $objects_in_dir = 0;

	while (defined ($entry = readdir (DIR)) ) {
		next if $entry =~ /\.m$/;	# skip property files
		next if $entry =~ /^\./;	# skip dot files
		next if $entry eq 'CVS';	# skip CVS directories
		next if $entry eq 'NEWSPIRIT';	# skip NEWSPIRIT directories

		($ext) = $entry =~ /.*\.(.*)$/; # extract extension

		# skip unknown files
		next if -f $entry and
		        not exists $NewSpirit::Object::extensions->{$ext};

		# Wenn es ein Verzeichnis ist, nach @dir pushen
		push @dir, "$dir/$entry" if -d "$fullpath/$entry";

		# Wenn es ein Objekt ist, in die entsprechende Liste fuer
		# diesen Objekttyp pushen. %obj ist ein Hash von Listen.
		if ( -f "$fullpath/$entry" ) {
			my $type = $NewSpirit::Object::extensions->{$ext};
			push @{$obj{$type}}, "$dir/$entry";
			$objects_in_dir = 1;
		}
	}		

	closedir DIR;

	my (@sort_dir, $d);
	@sort_dir = sort @dir;

	# Nun sind in @sort_dir alle gefundenen Unterverzeichnisse. Die
	# muessen in @{$tree} eingetragen werden und ggf. rekursiv
	# eingelesen werden, falls ein Eintrag in {open_folders} vorliegt.

	foreach $d (@sort_dir) {
		# war das der letzte Ordner in dem Verzeichnis?
		if ( $d eq $sort_dir[scalar @sort_dir - 1] &&
		     ! $objects_in_dir ) {
			push @{$state->{tree}}, "${project}/$d//";	# dann ein / mehr hinten dran
		} else {
			push @{$state->{tree}}, "${project}/$d/";	# nur ein / am Ende
		}

		if ( $state->{open_all_folders} ) {
			$state->{open_folders}->{$project.$d} = 1;
			read_tree ($state, $d);
		} elsif ( defined $state->{open_folders}->{$project.$d} ) {
			read_tree ($state, $d);
		}
	}

	# Nun sind die Objekte dran. Die Reihenfolge, in der das %obj
	# Hash nun abgearbeitet wird, steht ja in {object_sort}. Also
	# iterieren wir da drueber und holen uns die Eintraege dann
	# aus der entsprechenden Liste, die im %obj Hash referenziert
	# wird.

	my ($ot, $object);
	foreach $ot (@{$NewSpirit::Object::object_type_order}) {
	    if ( defined $obj{$ot} ) {
		foreach $object (sort(@{$obj{$ot}})) {
			push @{$state->{tree}}, "$project/$object";
		}
	    }
	}

	return 1;
}
