package NewSpirit::Project;

@ISA = qw( NewSpirit::Widget );

use strict;
use Carp;
use File::Basename;
use File::Path;
use File::Copy;
use NewSpirit::Object;
use NewSpirit::Widget;
use NewSpirit::Passwd;
use NewSpirit::DataFile;

sub new {
	my $type = shift;
	my ($q, $conf_dir) = @_;

	$conf_dir ||= $CFG::project_conf_dir;

	my $self = {
		q => $q,
		conf_dir => $conf_dir,
	};

	$self->{project} = $q->param('project') if $q;

	return bless $self, $type;
}

sub get_project_config {
	my $self = shift;
	
	my ($prj) = @_;
	
	my $project_file = "$self->{conf_dir}/$prj.conf";
	return if not -f $project_file or not -r $project_file;
	
	my $df = new NewSpirit::DataFile ($project_file);
	my $project_data = $df->read;
	$df = undef;
	
	return $project_data;
}

sub write_project_config {
	my $self = shift;
	
	my ($prj, $data) = @_;
	
	my $project_file = "$self->{conf_dir}/$prj.conf";
	
	my $df = new NewSpirit::DataFile ($project_file);
	my $project_data = $df->write ($data);
	$df = undef;
	
	1;
}

sub get_project_list {
	my $self = shift;
	
	my %par = @_;
	
	my $name2desc = $par{name2desc};
	
	my $conf_dir = $self->{conf_dir};
	
	my @list = <$conf_dir/*.conf>;
	
	my %projects;
	foreach my $prj ( @list ) {
		$prj = basename $prj;
		$prj =~ s/\.conf//;
		my $conf = $self->get_project_config ($prj);
		if ( $conf ) {
			if ( $name2desc ) {
				$projects{$prj} = $conf->{description};
			} else {
				$projects{$conf->{description}} = $prj;
			}
		}
	}

	return \%projects;
}

sub get_project_root_directories {
	my $self = shift;

	my $conf_dir = $self->{conf_dir};
	
	my @list = <$conf_dir/*.conf>;
	
	my %projects;
	foreach my $prj ( @list ) {
		$prj = basename $prj;
		$prj =~ s/\.conf//;
		my $conf = $self->get_project_config ($prj);
		$projects{$prj} = $conf->{root_dir} if $conf;
	}

	return \%projects;
}

sub delete {
	my $self = shift;
	
	my ($prj) = @_;
	
	my $login_username = $self->{q}->param('username');
	my $project_browser_needs_reload;
	
	my $project_file = "$self->{conf_dir}/$prj.conf";
	
	# read project config
	my $prj_config = $self->get_project_config ($prj);
	
	# first delete project configuration files
	unlink $project_file;
	my $lock_file = "$CFG::lock_dir/$prj";
	unlink "$lock_file";
	unlink "$lock_file.lck";

	# now revoke project rights from users
	my $ph = new NewSpirit::Passwd ( $self->{q} );
	my $user_lref = $ph->get_user_list;

	foreach my $username (@{$user_lref}) {
		my ($projects, $flags) = $ph->get_access_rights ($username);
		if ( defined $projects->{$prj} ) {
			delete $projects->{$prj};
			$ph->update ($username, undef, $flags, $projects);
		}
		
		# now remove default project entries from
		# user persistant session files for this project
		my $persist_file = "$CFG::user_conf_dir/$username.tree";

		my $lkdb = new NewSpirit::LKDB ($persist_file);

		if ( $lkdb->{hash}->{__attr_project} eq $prj ) {
			delete $lkdb->{hash}->{__attr_project};
			if ( $username eq $login_username ) {
				$project_browser_needs_reload = 1;
			}
		}
		$lkdb = undef;
	}
	
	$ph = undef;

	# also delete project files?
	if ( $self->{q}->param('delete_files') == 1 ) {
		rmtree ( [$prj_config->{root_dir}], 0, 0);
	}

	return $project_browser_needs_reload;	
}

# CGI stuff

sub main_menu {
	my $self = shift;
	my ($q, $project_href, $flags) = @_;

	my $ticket = $q->param('ticket');

	# first create hash of projects with descriptions
	my %projects;
	foreach my $prj ( keys %{$project_href} ) {
		my $conf = $self->get_project_config ($prj);
#		use Data::Dumper;print STDERR "$prj: ", Dumper($conf), "\n";
		if ( $conf ) {
			$projects{$prj} = $conf->{description};
		}
	}
	
	print <<__HTML;
<script>
  function prj_submit (f, event) {
    if ( (event == 'select' || event == 'delete_ask') &&
         f.project.selectedIndex == -1 ) {
      alert ('Please select a entry!');
      return;
    }
    
    if ( event == 'select' ) {
      f.action = '$CFG::pbrowser_url';
      f.target = 'CONTROL';
      f.e.value = 'frameset';
      f.submit();
      return;
    }
    
     if ( event == 'new' ) {
      f.action = '$CFG::admin_url';
      f.target = 'ACTION';
      f.e.value = 'project_new_ask';
      f.submit();
      return;
    }
   
     if ( event == 'delete_ask' ) {
      f.action = '$CFG::admin_url';
      f.target = 'ACTION';
      f.e.value = 'project_delete_ask';
      f.submit();
      return;
    }
   
  }
</script>

<form name="prj" action="$CFG::pbrowser_url" method="GET"
      target="PBTREE">
<input type="HIDDEN" name=ticket value="$ticket">
<input type="HIDDEN" name=e value="">

$CFG::FONT_BIG<b>Projects</b></FONT>
<table $CFG::BG_TABLE_OPTS width="100%">
<tr><td>
  <table $CFG::TABLE_OPTS width="100%">
  <tr><td>
    $CFG::FONT
    <select name="project" size=10 width=200>
__HTML
	my $selected = "SELECTED";
	foreach my $prj (sort {lc($a) cmp lc($b)} keys %projects) {
		print "<option value=$prj $selected>$prj: $projects{$prj}\n";
		$selected = '';
	}
	print <<__HTML;
    </select>
    <br>
    <a href="javascript:prj_submit(document.prj, 'select')"><b>SELECT PROJECT</b></a>
    <br>
    <a href="javascript:prj_submit(document.prj, 'new')"><b>NEW PROJECT</b></a>
    <br>
    <a href="javascript:prj_submit(document.prj, 'delete_ask')"><b>DELETE PROJECT</b></a>
    </FONT>
  </td></tr>
  </table>
  </td></tr>
</table>
</form>
__HTML

}

#-----------------------
# project data structure
#-----------------------

my %FIELD_DEFINITION = (
	project_name => {
		description => 'Name',
		type => 'text 20',
	},
	root_dir => {
		description => 'Project Root Directory',
		type => 'text',
	},
	description => {
		description => 'Description',
		type => 'textarea',
	},
	copyright => {
		description => 'Copyright Notice',
		type => 'text',
	},
	cvs_module => {
		description => 'CVS Module',
		type => 'text 20'
	}
);

my @FIELD_ORDER = (
	'project_name', 'root_dir', 'description',
	'copyright', 'cvs_module'
);

sub event_new_ask {
	my $self = shift;

	NewSpirit::std_header (
		page_title => "Create New Project"
	);

	$self->edit_form (
		'new' => 1
	);

	$self->back_to_main;

	NewSpirit::end_page();
}

sub edit_form {
	my $self = shift;

	my %par = @_;

	my $new_form  = $par{'new'};
	my $edit_form = $par{'edit'};

	my $q = $self->{q};
	my $ticket = $q->param('ticket');

	NewSpirit::js_open_window($q);

	my $next_event = $new_form ? 'project_new' : 'project_save';
	my $project    = $edit_form ? $q->param('project') : '';
	my $in_window  = $edit_form ? 0 : 1;

	print <<__HTML;
<script language="JavaScript">
  function new_project (f, in_window) {
        
    if ( f.root_dir.value == '' ||
         f.description.value == '' ||
         f.project_name.value == '' ) {
      alert ('Please provide Name, Project Root Directory and Description');
      return;
    }
    
    if ( f.root_dir.value.substring(0,1) != '/' &&
         f.root_dir.value.substring(1,2) != ':' ) {
      alert ('Project Root Directory must be a absolute path!');
      return;
    }

    if ( in_window ) {
      f.target  = 'cipp_save_window$ticket';

      var exec_win = open_window (
	'', 'cipp_save_window$ticket',
	$CFG::SAVE_WIN_WIDTH, $CFG::SAVE_WIN_HEIGHT,
	$CFG::SAVE_WIN_POSX, $CFG::SAVE_WIN_POSY,
	true
      );
      exec_win.document.write(
	'<html><script>'+
	'window.opener.document.new_project_form.submit()'+
	'</'+'script></html>'
      );
      exec_win.document.close();
    } else {
      f.submit();
    }
  }
  
  function reset_project_form (f) {
    f.project_name.value='';
    f.root_dir.value='';
    f.description.value='';
    f.copyright.value='';
    f.cvs_module.value='';
  }

</script>

<form name="new_project_form" method="POST" action="$CFG::admin_url">
<input type=hidden name=ticket value="$ticket">
<input type=hidden name=e value="$next_event">
<input type=hidden name=project value="$project">
<p>
$CFG::FONT_BIG<b>Project Information</b></FONT>
__HTML

	my $cancel_url = "$CFG::admin_url?ticket=$ticket&project=$project&e=project_menu";

	my $buttons;
	
	if ( $new_form ) {
		$buttons = <<__HTML;
<table $CFG::TABLE_OPTS width="100%">
<tr><td>
  $CFG::FONT
  <INPUT TYPE=BUTTON VALUE=" Reset Form "
         onClick="reset_project_form(this.form)">
  </FONT>
</td><td align="right">
  $CFG::FONT
  <INPUT TYPE=BUTTON VALUE=" Create Project "
         onClick="if (this.form.root_dir.value != '' &&
	 	      this.form.description.value != '' &&
	              this.form.project_name.value != '' ) {
	            new_project(this.form, $in_window);
		  } else {
		    alert ('Please provide Name, Project Root Directory and Description');
		  }">
  </FONT>
</td></tr>
</table>
__HTML
	} else {
		$buttons = <<__HTML;
<table $CFG::TABLE_OPTS width="100%">
<tr><td>
  $CFG::FONT
  <input type=button value=" Cancel " onClick="document.location.href='$cancel_url'">
  </font>
</td><td align="right">
  $CFG::FONT
  <INPUT TYPE=BUTTON VALUE=" Save "
         onClick="if (this.form.root_dir.value != '' &&
	 	      this.form.description.value != '' &&
	              this.form.project_name.value != '' ) {
	            new_project(this.form);
		  } else {
		    alert ('Please provide Name, Project Root Directory and Description');
		  }">
  </FONT>
</td></tr>
</table>
__HTML
	}
	my $data_href = $self->get_project_config ($q->param('project'))
		if $edit_form;
	my $read_only_href = { project_name => 1, root_dir => 1 }
		if $edit_form;

	$self->input_widget_factory (
		names_lref => \@FIELD_ORDER,
		info_href  => \%FIELD_DEFINITION,
		buttons    => $buttons,
		data_href  => $data_href,
		read_only_href => $read_only_href
	);
	
	print <<__HTML;
<table BORDER=0 BGCOLOR="#555555" CELLSPACING=0 CELLPADDING=1>
<tr><td>
</td></tr>
</table>

</form>
__HTML

	NewSpirit::end_page();
}

sub event_new {
	my $self = shift;
	
	my $q = $self->{q};
	my $force = $q->param('force');
	my $ticket = $q->param('ticket');
	my $username = $q->param('username');

	# first catch the form data
	my %data;
	my $data_hidden_fields;
	foreach my $key (@FIELD_ORDER) {
		$data{$key} = $q->param($key);
		$data_hidden_fields .= $q->hidden (
			-name => $key,
			-default => $data{$key}
		);
	}
	
	# remove multiple and trailing slashes
	$data{root_dir} =~ s!/+!/!g;
	$data{root_dir} =~ s!/$!!;
	
	NewSpirit::std_header (
		page_title => "Project Creation: '$data{project_name}'",
		close => 1
	);
	
	# check if a project configuration file exists already
	my $exists;
	if ( not $force ) {
		$exists = $self->get_project_config ($data{project_name});
	}
	
	if ( $exists ) {
		print <<__HTML;
	$CFG::FONT
	<b>A project with this name exists already.</b>
	<p>
	Do you want to force the project creation?
	<p>
	Only the project root configuration will be recreated, all<br>
	existing objects in the project source and production<br>
	directories will be preserved.
	<p>
	If you provided a CVS module name a 'cvs checkout' will be<br>
	executed anyway, so object source files may change through<br>
	this procedure.
	<p>
	<form method="POST" action="$CFG::admin_url">
	<input type=hidden name=ticket value=$ticket>
	<input type=hidden name=e value="project_new">
	<input type=hidden name=force value="1">
	$data_hidden_fields
	<b>
	<input type=button value=" Yes, force project creation "
	       onClick="this.form.submit()">
	</b>
        </form>
	</FONT>
__HTML
		NewSpirit::end_page();
		return;
	}

	# Ok, we are ready for the rest... ;)

	# create root directory
	print "$CFG::FONT Creating project root directory...</FONT><br>\n";

	my $path_ok = 1;
	my $error;
	if ( not -d $data{root_dir} ) {
		$path_ok = mkdir ($data{root_dir}, 0775);
		$error = $!;
	}
#	 else {
#		$path_ok = chmod 0775, $data{root_dir};
#		$error = $!;
#	}

	if ( $path_ok ) {
		mkdir ("$data{root_dir}/prod", 0775);
		mkdir ("$data{root_dir}/prod/htdocs", 0775);
		mkdir ("$data{root_dir}/prod/cgi-bin", 0775);
	}

	if ( not $path_ok ) {
		print qq{<p><table cellpadding=2 cellspacing=0 bgcolor="$CFG::ERROR_BG_COLOR">};
		print qq{<tr><td>$CFG::FONT_ERROR<b>Error creating directory };
		print qq{'$data{root_dir}'!<p>Error Message: $error</b>\n};
		print qq{</FONT></td></tr></table>\n};
		
		print <<__HTML;
	<p>
	$CFG::FONT
	Please check access rights and whether the parent directory<br>
	exists, correct the parameters in the <b>Project Information</b> formular<br>
	and submit your request again.
	</FONT>
__HTML
		NewSpirit::end_page();
		return;
	}

	# create project src dir, no error checking necessary
	if ( not -d "$data{root_dir}/src" ) {
		mkdir "$data{root_dir}/src", 0775;
	} else {
		chmod 02775, "$data{root_dir}/src";
	}

	# create project prod and logs dir, no error checking necessary
	if ( not -d "$data{root_dir}/prod" ) {
		mkdir "$data{root_dir}/prod", 0775;
		mkdir "$data{root_dir}/prod/logs", 0775;
	} else {
		chmod 02775, "$data{root_dir}/src";
		chmod 02775, "$data{root_dir}/prod/logs";
	}

	# create project meta dir, no error checking necessary
	if ( not -d "$data{root_dir}/meta" ) {
		mkdir "$data{root_dir}/meta", 0775;
	} else {
		chmod 02775, "$data{root_dir}/meta";
	}

	# Create project configuration
	print "$CFG::FONT Creating project configuration file...</FONT><br>\n";

	eval {
		$self->write_project_config (
			$data{project_name},
			\%data
		);
	};
	$error = NewSpirit::strip_exception($@);
	
	if ( $error ) {
		print qq{<p><table cellpadding=2 cellspacing=0 bgcolor="$CFG::ERROR_BG_COLOR">};
		print qq{<tr><td>$CFG::FONT_ERROR<b>Error creating configuration file };
		print qq{'$data{root_dir}'!<p>Error Message: $error</b>\n};
		print qq{</FONT></td></tr></table>\n};
		
		print <<__HTML;
	<p>
	$CFG::FONT
	Please check access rights of the new.spirit directory
	<p>
	$CFG::project_conf_dir.
	</FONT>
__HTML
	}
	
	# Grant access rights
	print "$CFG::FONT Granting access rights to user '$username'...</FONT>\n";

	my $ph = new NewSpirit::Passwd ($q);
	$ph->grant_project_access (
		username => $username,
		project_lref => [ $data{project_name} ]
	);

	# create base configuration, if not existant
	my $base_conf_file = "$data{root_dir}/src/$CFG::default_base_conf";
	if ( not -f $base_conf_file ) {
		my $template_file = "$CFG::user_template_dir/cipp-base-config.template";
		   $template_file = "$CFG::template_dir/cipp-base-config.template"
			if not -f $template_file;
		if ( not -f $template_file ) {
			open (BASE, "> $base_conf_file");
			close BASE;
		} else {
			copy ($template_file, $base_conf_file);
		}
	}

	chmod 0664, $base_conf_file;

	print qq[<script>function select_project () {],
	      qq[window.opener.parent.CONTROL.location.href=],
	      qq['$CFG::pbrowser_url?e=frameset&ticket=$ticket&project=$data{project_name}'; }</script>];

	print qq{<p><a href="javascript:select_project()">},
	      qq{$CFG::FONT<b>[ SELECT PROJECT ]</b></FONT>},
	      qq{</a>\n};

	NewSpirit::end_page();
}

sub event_delete_ask {
	my $self = shift;

	my $q = $self->{q};
	my $project = $q->param('project');

	NewSpirit::std_header (
		page_title => "Delete Project '$project'"
	);

	NewSpirit::js_open_window($q);

	my $ticket = $q->param('ticket');

	print <<__HTML;
<form action="$CFG::admin_url" method="POST">
<input type=hidden name=ticket value="$ticket">
<input type=hidden name=project value="$project">
<input type=hidden name=e value="project_delete">

<table BORDER=0 BGCOLOR="$CFG::TABLE_FRAME_COLOR" CELLSPACING=0 CELLPADDING=1>
<tr><td>
<table cellpadding=5 $CFG::TABLE_OPTS width="100%">
<tr><td>

$CFG::FONT
<b>Do you want me to delete all project files, too?</b>
</font>

<p>
<table>
<tr><td valign="top">
  $CFG::FONT
  <input type=radio name=delete_files value="1">
  </font>
</td><td valign="top">
  $CFG::FONT
  Yes, delete project files and internal<br>
  configuration information of this project.
  </font>
</td></tr>
<tr><td valign="top">
  $CFG::FONT
  <input type=radio name=delete_files value="0" checked>
  </font>
</td><td valign="top">
  $CFG::FONT
  No, delete only the internal<br>
  configuration information.
  </font>
  <br><br>
</td></tr>
</table>

</tr></td>
</table>

</tr></td>
<tr><td>

<table $CFG::TABLE_OPTS width="100%">
<tr><td align="right">
$CFG::FONT
<input type=button value=" Delete Project "
       onClick="this.form.submit()">
</font>
</td></tr>
</table>

</tr></td>
</table>

</form>
__HTML

	$self->back_to_main;

	NewSpirit::end_page();
}

sub event_delete {
	my $self = shift;
	
	my $q = $self->{q};

	my $ticket  = $q->param('ticket');
	my $project = $q->param('project');

	$self->delete ($project);
	
	NewSpirit::std_header (
		page_title => "Projekt '$project' deleted"
	);
	
	print <<__HTML;
$CFG::FONT
The project '$project' has been successfully deleted.
</font>

<script>
parent.CONTROL.location.href='$CFG::pbrowser_url?e=frameset&ticket=$ticket';
</script>
__HTML
	
	$self->back_to_main;
	
	NewSpirit::end_page();
}

sub back_to_main {
	my $self = shift;
	
	my $ticket = $self->{q}->param('ticket');

	print <<__HTML;
<p>
$CFG::FONT
<a href="$CFG::admin_url?ticket=$ticket&e=menu"><b>[ Go Back ]</b></a>
</font>
__HTML
}

sub event_menu {
	my $self = shift;
	
	my $q = $self->{q};
	
	my $ticket = $q->param('ticket');
	my $project = $q->param('project');
	
	NewSpirit::std_header (
		page_title => "Project Menu: '$project'"
	);
	
	NewSpirit::js_open_window($q);

	# Project Information

	print <<__HTML;
<form name="edit_project_form" method="POST" action="$CFG::admin_url">
<input type=hidden name=ticket value="$ticket">
<input type=hidden name=e value="project_edit">
<input type=hidden name=project value="$project">

$CFG::FONT_BIG<b>Project Information</b></FONT><br>
__HTML

	my $buttons = <<__HTML;
<table $CFG::TABLE_OPTS width="100%">
<tr><td align="right">
  $CFG::FONT
  <INPUT TYPE=BUTTON VALUE=" Edit "
         onClick="this.form.submit()">
  </FONT>
</td></tr>
</table>
__HTML

	$self->input_widget_factory (
		names_lref => \@FIELD_ORDER,
		info_href  => \%FIELD_DEFINITION,
		data_href  => $self->get_project_config ($q->param('project')),
		read_only_href => 1,
		buttons => $buttons
	);

	print "</form>\n";

	# Project Installation

	print <<__HTML;
<script language="JavaScript">
  function project_install(f) {
    if ( f.install_possible.value == 0 ) {
      alert ('To install a project into a different location\\n'+
	     'you must create additional base configurations first.');
      return;
    }
  
    f.target  = 'cipp_install_window$ticket';

    var exec_win = open_window (
      '', 'cipp_install_window$ticket',
      $CFG::SAVE_WIN_WIDTH, $CFG::SAVE_WIN_HEIGHT,
      $CFG::SAVE_WIN_POSX, $CFG::SAVE_WIN_POSY,
      true
    );
    exec_win.document.write(
      '<html><script>'+
      'window.opener.document.install_project_form.submit()'+
      '</'+'script></html>'
    );
    exec_win.document.close();
  }
</script>

<form name="install_project_form" method="POST" action="$CFG::install_url">
<input type=hidden name=ticket value="$ticket">
<input type=hidden name=e value="install_project">
<input type=hidden name=project value="$project">

$CFG::FONT_BIG<b>Project Installation</b></FONT><br>
__HTML

	my $buttons = <<__HTML;
<table $CFG::TABLE_OPTS width="100%">
<tr><td align="right">
  $CFG::FONT
  <INPUT TYPE=BUTTON VALUE=" Install "
         onClick="project_install(this.form)">
  </FONT>
</td></tr>
</table>
__HTML

	$self->input_widget_factory (
		names_lref => [ 'base_config', 'with_sql_prod_files', 'build_src_tree' ],
		info_href  => {
			base_config => {
				description => "Base Configuration",
				type => 'method'
			},
			with_sql_prod_files => {
				description => "Include prod directory SQL files",
				type => 'switch',
			},
			build_src_tree => {
				description => "Build a src tree for SQL execution",
				type => 'switch'
			},
		},
		data_href => {
			with_sql_prod_files => 1,
			build_src_tree      => 1,
		},
		buttons => $buttons
	);
	
	print "</form>\n";

	# Project Compilation

	print <<__HTML;
<script language="JavaScript">
  function project_compile(f) {
    f.target  = 'cipp_install_window$ticket';

    var exec_win = open_window (
      '', 'cipp_install_window$ticket',
      $CFG::SAVE_WIN_WIDTH, $CFG::SAVE_WIN_HEIGHT,
      $CFG::SAVE_WIN_POSX, $CFG::SAVE_WIN_POSY,
      true
    );
    exec_win.document.write(
      '<html><script>'+
      'window.opener.document.compile_project_form.submit()'+
      '</'+'script></html>'
    );
    exec_win.document.close();
  }
</script>

<form name="compile_project_form" method="POST" action="$CFG::install_url">
<input type=hidden name=ticket value="$ticket">
<input type=hidden name=e value="compile_project">
<input type=hidden name=project value="$project">

$CFG::FONT_BIG<b>Project Compilation</b></FONT><br>
__HTML

	my $buttons = <<__HTML;
<table $CFG::TABLE_OPTS width="100%">
<tr><td align="right">
  $CFG::FONT
  <INPUT TYPE=BUTTON VALUE=" Compile "
         onClick="project_compile(this.form)">
  </FONT>
</td></tr>
</table>
__HTML

	$self->input_widget_factory (
		names_lref => [ 'trunc_depend', 'clear_prod_tree', ],
		info_href  => {
			trunc_depend => {
				description => "Dependency database truncation...",
				type => 'switch'
			},
#			depend_with_includes => {
#				description => "Process Includes seperately for error checking...",
#				type => 'switch'
#			},
			clear_prod_tree => {
				description => "Delete production files first...",
				type => 'switch'
			},
		},
		data_href  => {
			trunc_depend => 1,
			clear_prod_tree => 1,
		},
		buttons => $buttons
	);
	
	print "</form>\n";
	NewSpirit::end_page();
}

sub event_edit {
	my $self = shift;

	my $project = $self->{q}->param('project');
	
	NewSpirit::std_header (
		page_title => "Edit Project Information: '$project'"
	);

	$self->edit_form (
		'edit' => 1
	);

	NewSpirit::end_page();
}

sub event_save {
	my $self = shift;
	
	my $q = $self->{q};
	
	# first catch the form data
	my %data;
	my $data_hidden_fields;
	foreach my $key (@FIELD_ORDER) {
		$data{$key} = $q->param($key);
		$data_hidden_fields .= $q->hidden (
			-name => $key,
			-default => $data{$key}
		);
	}
	
	$self->write_project_config (
		$data{project_name},
		\%data
	);

	$self->event_menu;
}

sub old_event_menu {
	my $self = shift;
	
	my $q = $self->{q};
	
	my $ticket = $q->param('ticket');
	my $project = $q->param('project');
	
	NewSpirit::std_header (
		page_title => "Project Menu: '$project'"
	);

	print <<__HTML;
$CFG::FONT_BIG<b>Project Installation</b></FONT>
<table $CFG::BG_TABLE_OPTS width="50%">
<tr><td>
  <table $CFG::TABLE_OPTS width="100%">
  <tr><td colspan="2">
    $CFG::FONT<b>
    <a href="$CFG::install_url?e=install_project&ticket=$ticket&project=$project"
      >Install (without dependency truncation)</a>
    </font></b>
  </td></tr>
  <tr><td>&nbsp;&nbsp;&nbsp;</td>
  <td width="100%">
    $CFG::FONT
    Use this installation method, if there are concurrent users
    working on this project. The dependency database will be updated
    incrementelly without truncation at the beginning of the installation
    process, so other users are not affected.
    <p>
    If you did major modifications from outside of new.spirit (e.g. through
    an extensive CVS update) this method may result in an inconsistent
    dependency database, but it usually should not! If you want to be sure:
    use the method beyond.
    </font>
  </td>
  </tr>
  
  <tr><td colspan="2">
    <br>
    $CFG::FONT<b>
    <a href="$CFG::install_url?e=install_project&ticket=$ticket&project=$project&trunc_depend=1"
      >Install (with dependency truncation)</a>
    </font></b>
  </td></tr>
  <tr><td>&nbsp;&nbsp;&nbsp;</td>
  <td>
    $CFG::FONT
    This method truncates the dependency database first - so other
    users will have an incorrect dependency behaviour, while your
    installation process has not finished.
    <p>
    If you feel, that the dependency database is inconsistent, use this
    method to clean up the database.
    </font>
  </td>
  </tr>
  </table>
  </td></tr>
</table>
__HTML
	
	NewSpirit::end_page();
}

sub property_widget_base_config {
	my $self = shift;
	
	my %par = @_;
	
	my $name = $par{name};
	my $data = $par{data_href};

	my $q = $self->{q};

	my $project = $q->param('project');
	my $ticket  = $q->param('ticket');

	my $o = new NewSpirit::Object (
		q => $q,
		object => 'configuration.cipp-base-config'
	);
	
	my $db_files = $o->get_base_configs;

	my @db_files = ();
	my %labels = ();

	foreach my $db (sort keys %{$db_files}) {
		my $tmp = $db;
		$tmp =~ s!/!.!g;			# slashes to dots
		$tmp =~ s!\.cipp-base-config$!!;	# cut off ext
		next if $tmp eq 'configuration';	# skip default base config
		push @db_files, $db;
		$labels{$db} = "$project.$tmp";
	}

	if ( @db_files ) {
		print qq{<input type="hidden" name="install_possible" value="1">\n};
		print $q->popup_menu (
			-name => $name,
			-values => [ @db_files ],
			-default => "configuration.cipp-base-config",
			-labels => \%labels
		);

	} else {
		print qq{<input type="hidden" name="install_possible" value="0">\n};
		print "No additional configuration objects found!<br>\n";
	}

	print qq{<a href="$CFG::admin_url?project=$project&ticket=$ticket&e=project_refresh_base_configs_popup"><b>Refresh Base Configs Popup</b></a>},
	
	1;	
}

sub event_refresh_base_configs_popup {
	my $self = shift;
	
	my $q = $self->{q};
	
	my $o = new NewSpirit::Object (
		q => $q,
		object => 'configuration.cipp-base-config'
	);

	my $base_configs_file = $o->{project_base_configs_file};
	unlink $base_configs_file;
	
	$o->get_base_configs;

	$self->event_menu;
}


1;
