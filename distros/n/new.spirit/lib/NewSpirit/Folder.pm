# $Id: Folder.pm,v 1.9 2001/07/24 15:35:26 joern Exp $

package NewSpirit::Folder;

#=============================================================================
# Object attributes:
# ------------------
#	folder			Folder relative path
#	folder_url		URL to nph-folder.cgi with all necessary par.
#	folder_dir		Absolute folder path
#	folder_name		Folder name in dotted notation
#	folder_history_dir	Directory with history files for this folder
#	project			Name of the project this folder belongs to
#	project_info		Project info hash (from etc/projects/*.conf)
#	project_root_dir	Project root directory, absolute
#	project_src_dir		Project source base directory, absolute
#	project_prod_dir	Project prod base directory, absolute
#	q			CGI query object
#	event			actual folder event
#	ticket			ticket of the session which accesses the object
#	username		user who accesses the session
#=============================================================================

use strict;
use Carp;

use NewSpirit;
use NewSpirit::Object;
use File::Path;
use File::Basename;

sub new {
	my $type = shift;
	my ($q, $folder_orig) = @_;
	
	my $project = $q->param('project')
		or croak "NewSpirit::Folder: missing project";

	$folder_orig ||= $q->param('folder');
	my $folder = $folder_orig;

	$folder = '' unless defined $folder;

	my $project_info = NewSpirit::get_project_info ($project);
	my $project_root_dir = $project_info->{root_dir};

	my $folder_dir = "$project_root_dir/src/$folder";

	my $event = $q->param('e');
	if ( $event ne 'create_folder' ) {
		croak "Folder '$folder_dir' does not exist"
			unless -d $folder_dir;
	}

	my $folder_name = $folder;
	$folder_name =~ s/\.[^\.]+$//;
	$folder_name =~ s!/!.!g;
	
	if ( $folder_name eq '' ) {
		$folder_name = $project;
	} else {
		$folder_name = "$project.$folder_name";
	}

	my $ticket = $q->param('ticket');
	
	my $folder_url = qq{$CFG::folder_url?ticket=$ticket&folder=$folder&}.
			 qq{project=$project};
	
	my $folder_history_dir = "$project_root_dir/history/$folder";
	$folder_history_dir =~ s!/+!/!g;

	if ( not -d $folder_history_dir ) {
		mkpath ( [$folder_history_dir], 0, 0775 )
			or croak "can't mkpath $folder_history_dir";
	}

	my $self = {
		q => $q,
		folder => $folder_orig,
		folder_url => $folder_url,
		folder_dir => $folder_dir,
		folder_name => $folder_name,
		folder_history_dir => $folder_history_dir,
		project => $project,
		project_info => $project_info,
		project_root_dir => $project_root_dir,
		project_src_dir	=> "$project_root_dir/src",
		project_prod_dir => "$project_root_dir/prod",
		event => $q->param('e'),
		ticket => $ticket,
		username => $q->param('username')
	};

	return bless $self, $type;
}

sub edit_ctrl {
	my $self = shift;
	
	# remove object lock
	NewSpirit::delete_lock ($self->{q});
	
	NewSpirit::std_header (
		page_title => "Folder: $self->{folder_name}"
	);

	my $ticket = $self->{ticket};
	
	my ($type_popup, $ext_popup, $cipp_idx) = $self->type_and_ext_popup;

	NewSpirit::js_open_window($self->{q});

	my $folder = $self->{folder};
	$folder .= '/' if $folder ne '';

	print <<__HTML;
<script>
  function execute (event) {
    var f=document.cipp_folder;
    f.e.value=event;

    if ( event == 'create' ) {
      f.action = '$CFG::object_url';
      f.object.value =
      	'$folder'+
	f.object_filename.value+
	'.'+
	f.object_ext.options[f.object_ext.selectedIndex].value;
    } else {
      f.action = '$CFG::folder_url';
      f.folder.value = '$folder'+f.new_folder.value;
    }
    
    var exec_win = open_window (
      '', 'cipp_save_window$ticket',
      $CFG::SAVE_WIN_WIDTH, $CFG::SAVE_WIN_HEIGHT,
      $CFG::SAVE_WIN_POSX, $CFG::SAVE_WIN_POSY,
      true
    );
    exec_win.document.write(
      '<html><script>'+
      'window.opener.document.cipp_folder.submit()'+
      '</'+'script></html>'
    );
    exec_win.document.close();
  }

  function reset_object_form (f) {
    f.object_filename.value='';
    f.description.value='';
    f.object_type.selectedIndex = $cipp_idx;
    set_object_ext(
      f.object_type,
      f.object_ext, $cipp_idx
    );
  }

  function reset_folder_form (f) {
    f.new_folder.value='';
  }

  function object_create_submit (f) {
    var filename = f.object_filename.value;
    if ( filename == '' ) {
      alert ('Object name is missing!');
      return;
    }
    
    var i;
    for ( i=0; i<filename.length; ++i ) {
      if ( filename.substr(i,1) == '.' ||
           filename.substr(i,1) == '/' ) {
        alert ("Don't use . or / in object names");
	return;
      }
    }

    execute('create');
  }
</script>

<FORM NAME="cipp_folder" ACTION="$CFG::folder_url" METHOD="POST"
      TARGET="cipp_save_window$ticket">
<INPUT TYPE=HIDDEN NAME="ticket" VALUE="$self->{ticket}">
<INPUT TYPE=HIDDEN NAME="project" VALUE="$self->{project}">
<INPUT TYPE=HIDDEN NAME="e" VALUE="">
<INPUT TYPE=HIDDEN NAME="object" VALUE="">
<INPUT TYPE=HIDDEN NAME="folder" VALUE="$folder">
<p>
$CFG::FONT_BIG<b>Create New Object</b></FONT>
<table BORDER=0 BGCOLOR="$CFG::TABLE_FRAME_COLOR" CELLSPACING=0 CELLPADDING=1>
<tr><td>
  <table $CFG::TABLE_OPTS width="100%">

  <tr><td width="90">
    $CFG::FONT<b>Name</b></FONT>
  </td><td valign="top">
    $CFG::FONT
    <INPUT TYPE="text" SIZE=60 MAXLENGTH=80 NAME=object_filename>
    </FONT>
  </td></tr>

  <tr><td>
    $CFG::FONT<b>Description</b></FONT>
  </td><td valign="top">
    $CFG::FONT
    <TEXTAREA NAME=description COLS="56" ROWS="5" WRAP="virtual"></TEXTAREA>
    </FONT>
  </td></tr>

  <tr><td>
    $CFG::FONT<b>Type</b></FONT>
  </td><td valign="top">
    $CFG::FONT
    $type_popup
    </FONT>
  </td></tr>

  <tr><td>
    $CFG::FONT<b>Source File Extension</b></FONT>
  </td><td valign="top">
    $CFG::FONT
    $ext_popup
    </FONT>
  </td></tr>

  </table>

</td></tr>
<tr><td>

  <table $CFG::TABLE_OPTS width="100%">
  <tr><td>
    $CFG::FONT
    <INPUT TYPE=BUTTON VALUE=" Reset Form "
    	   onClick="reset_object_form(this.form)">
    </FONT>
  </td><td align="right">
    $CFG::FONT
    <INPUT TYPE=BUTTON VALUE=" Create Object "
           onClick="object_create_submit(this.form)">
    </FONT>
  </td></tr>
  </table>

</td></tr>
</table>

<p><br>
$CFG::FONT_BIG<b>Create New Folder</b></FONT>
<table BORDER=0 BGCOLOR="#555555" CELLSPACING=0 CELLPADDING=1>
<tr><td>
  <table $CFG::TABLE_OPTS width="100%">
  <tr><td width="90">
    $CFG::FONT<b>Name</b></FONT>
  </td><td valign="top">
    $CFG::FONT
    <INPUT TYPE="text" SIZE=60 MAXLENGTH=80 NAME=new_folder>
    </FONT>
  </td></tr>
  </table>
</td></tr>
<tr><td>
  <table $CFG::TABLE_OPTS width="100%">
  <tr><td>
    $CFG::FONT
    <INPUT TYPE=BUTTON VALUE=" Reset Form "
           onClick="reset_folder_form(this.form)">
    </FONT>
  </td><td align="right">
    $CFG::FONT
    <INPUT TYPE=BUTTON VALUE=" Create Folder "
           onClick="if ( this.form.new_folder.value != '' ) { execute('create_folder') }
	            else { alert ('Folder name is missing!') }">
    </FONT>
  </td></tr>
  </table>
  </td></tr>
</table>

<!--
<p><br>
$CFG::FONT_BIG<b>Folder Functions</b></FONT>
<table BORDER=0 BGCOLOR="#555555" CELLSPACING=0 CELLPADDING=1>
<tr><td>
  <table $CFG::TABLE_OPTS width="100%">
  <tr><td width="90">
    $CFG::FONT<b>Function</b></FONT>
  </td><td valign="top">
    $CFG::FONT
    <select name=function>
    <option value=1>Folder Functions
    </select>
    </FONT>
  </td></tr>
  </table>
</td></tr>
<tr><td>
  <table $CFG::TABLE_OPTS width="100%">
  <tr><td>
    $CFG::FONT
    <INPUT TYPE=BUTTON VALUE=" Execute " onClick="execute('execute_function')">
    </FONT>
  </td></tr>
  </table>
  </td></tr>
</table>
-->

</FORM>
__HTML

	NewSpirit::end_page();
}

sub type_and_ext_popup {
	my $self = shift;
	
	my $type_popup = <<__HTML;
<script>
  function set_object_ext (obj_type, obj_ext, idx) {
    var i;
    if ( idx == null ) {
      idx = obj_type.selectedIndex;
    }
    var type_val = obj_type.options[idx].value;
    
    var ext = type_val.split(',');

    // cleanup ext popup
    for (i=obj_ext.length - 1; i >= 0 ; --i) {
      obj_ext.options[i] = null;
    }
    
    // build new ext popup
    // (first entry of ext array is the object type, we skip it)
    for (i=1; i < ext.length - 1; ++i) {
      obj_ext.options[i-1] = new Option;
      obj_ext.options[i-1].value = ext[i];
      obj_ext.options[i-1].text  = '.'+ext[i];
    }
    obj_ext.selectedIndex = ext[i];
  }
</script>
__HTML

	$type_popup .= qq{<select name=object_type }.
		       qq{onchange="set_object_ext(this.form.object_type, }.
		       qq{this.form.object_ext)">\n};
	
	# first build a hash which maps object types to
	# lists of extensions, assigned to this type
	my %type2ext;
	my ($ext, $type);
	while ( ($ext, $type) = each %{$NewSpirit::Object::extensions} ) {
		push @{$type2ext{$type}}, $ext;
	}

	# now produce HTML code for $type_popup
	my $object_types = $NewSpirit::Object::object_types;
	my $i = 0;
	my $cipp_idx;	# needed for 'reset form' to select this entry
	
	foreach $type ( sort { $object_types->{$a}->{name}
	                       cmp
			       $object_types->{$b}->{name} }
	                keys %{$object_types} ) {
		# default and depend-all typed objects cannot be created here
		next if $type eq 'depend-all';
		$cipp_idx = $i if $type eq 'cipp';
		my $selected = $type eq 'cipp' ? 'selected' : '';
		my $ext_list = join (",", sort @{$type2ext{$type}});
		
		# calc index of the default entry
		my $sel_idx = 0;
		my $default_ext = $object_types->{$type}->{default_extension};
		foreach my $ext ( sort @{$type2ext{$type}} ) {
			last if $ext eq $default_ext;
			++$sel_idx;
		}
		$ext_list .= ",$sel_idx";

		# now build option value
		$type_popup .= qq{<option value="$type,$ext_list" $selected>\n};
		$type_popup .= $object_types->{$type}->{name}."\n</option>\n";
		++$i;
	}

	$type_popup .= "</select>";

	# extension popup holds initially only the 'cipp' extension
	my $ext_popup = "<select name=object_ext>";

	$ext_popup .= qq{<option value="cipp">.cipp};

	$ext_popup .= "</select>";

	return ($type_popup, $ext_popup, $cipp_idx);
}

sub create {
	my $self = shift;
	
	my $q = $self->{q};

	NewSpirit::std_header (
		page_title => "Create Folder: $self->{folder_name}"
	);

	my $create_error;
	my $new_folder_dir = $self->{folder_dir};
	my $folder = $self->{folder};

	my $check_lref = NewSpirit::filename_glob (
		dir => dirname($new_folder_dir),
		regex => "^".basename($new_folder_dir).'\..*'
	);

	if ( @{$check_lref} or -e $new_folder_dir ) {
		$create_error = "Folder or object with same name already exists!";
	} else {
		if ( not mkdir $new_folder_dir, 0775 ) {
			$create_error = $!;
		}
	}

	if ( $create_error ) {
		print qq{<table cellpadding=2 cellspacing=0 bgcolor="$CFG::ERROR_BG_COLOR">};
		print qq{<tr><td>$CFG::FONT_ERROR<b>Error creating Folder '$new_folder_dir' };
		print qq{</b><p>Error message:<br><b>$create_error</b></FONT><p>\n};
		print qq{</td></tr></table>\n};
	} else {
		print qq{$CFG::FONT Folder has been successfully created}.
		      qq{</b></FONT><p>\n};

		print qq[<script>function open_editor () {],
		      qq[window.opener.document.location.href=],
		      qq['$self->{folder_url}&e=edit'; }</script>];

		print qq{<a href="javascript:open_editor()">},
		      qq{$CFG::FONT<b>[ EDIT FOLDER ]</b></FONT>},
		      qq{</a>\n};

		print qq{<script>},
		      qq{window.opener.parent.CONTROL.PBTREE.location.href=},
		      qq{'$CFG::pbrowser_url?project=$self->{project}&},
		      qq{ticket=$self->{ticket}&e=open&dir=$self->{project}/$folder#jump';},
		      qq{</script>\n};
	}

	NewSpirit::end_page;
}

1;
