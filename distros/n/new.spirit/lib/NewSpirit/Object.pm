package NewSpirit::Object;

# for i in $(find . -type d -a -name NEWSPIRIT); do (echo $i; cd $i; mv *.m ..); done

#=============================================================================
# Class methods:
# --------------
# convert_from_spirit1		Convert old spirit object files
# set_lock			Try to set a lock (optional force the lock)
# unsset_lock			Removes the lock from the current object
# unlock_ctrl			CGI event handler for the 'unlock' event
# editor_header			HTML code for the editor header section
# editor_footer			HTML code for the editor footer section
# editor_function_block		HTML code for the editor function section
# editor_function_popup		HTML code for the editor function popup
# editor_read_access_function_popup	Produces HTML code for locked objects
# properties_ctrl		CGI event handler for the 'properties' event
# properties_table		Print table of object properties
# type_specific_properties	Print type specific property table rows
# input_widget			Generic creation of a input widget
#				(comes from NewSpirit::Widget)
# get_data			Generic method to retrieve the content of a object
# print				Print the object file content to STDOUT
# get_meta_data			Return the meta data of this object
# save_ctrl			CGI event handler for the 'save' event
# object_header			prints std. HTML code for the object header
# save				Controls object saving, including generation of history file
# save_file			Saves the object to a file
# save_not_possible		Check if somebody stole our lock
# save_properties_ctrl		CGI event handler for the 'save_properties' event
# save_meta_version		Saves the version part of the object meta data
# save_meta_data		Saves the given meta data of this object
# create_history_file		Creates the history file from the acutal object
# history_ctrl			CGI event handler for the 'history' event
# history_file_entry		Printing a single history file entry row
# get_history_files		Return names of history filenames of this object
# view_header			HTML header for the object viewer (history restore)
# view_footer			HTML footer for the object viewer (history restore)
# restore_ctrl			CGI event handler for the 'restore' event
# restore			Restores a history object version
# delete_versions_ctrl		CGI event handler for the 'delete_versions' event
# download_ctrl			CGI event handler for the 'download' event
# download_prod_file_ctrl	CGI event handler for the 'download_prod_file' event
# get_databases			Returns a hash of databases definition objects
# refresh_db_popup		Creates a new database hash file
# refresh_base_configs_popup	Creates a new base configs hash file
# get_base_configs		Returns a hash of base config objects
# get_default_database		Returns the default database object
# rename			Rename a object file (stay in same directory)
# make_install_path		Creates the install path if necessary
# install			Controls installation of a object into the prod tree
# install_file			Installs the file into the prod tree
# dependency_installation_needed	Checks is a dep installation is necessary
# print_install_errors		Print installation errors
# update_dependencies		Updates the dependencies for this object
# dependencies_ctrl		CGI event handler for the 'dependencies' event
# print_dependencies		Recursive method for printing dependencies
# get_depend_object		Returns a NewSpirit::Depend object
# clear_depend_object		Clears internal cache for Depend object
# get_dependant_objects		Returns a hashref with all dependant objects
# create_ctrl			Create a new object
# delete_ask_ctrl		Confirm object deletion dialog
# delete_ask_info		Print object deleteion information (e.g. dep)
# delete_ctrl			Delete a object
# delete 			Delete a object
# get_show_dependency_key	returns key for dependency browser
# get_object_type		returns type of this object
# canonify_object_name 		returns canonfied object name (replaces
#				project part of name with project of this
#				object)
# check_properties		checks if user edited properties are ok
# get_object_src_file		returns the source file to a given object name
# download_filename		Filename for download
# is_uptodate			checks if prod file is newer than src file
#
# Stub methods, to be overloaded:
# -------------------------------
# init				Initialization method for subclassed modules
# convert_meta_from_spirit1	Convert old spirit meta data
# convert_data_from_spirit1	Convert old spirit object data
# edit_ctrl			CGI event handler for the 'edit' event
# view_ctrl			CGI event handler for the 'view' event
# get_install_filename		Returns the filename for installation in prod
# print_pre_install_message	Prints progress message for installation
# print_post_install_message	Prints progress message after installation
#=============================================================================

#=============================================================================
# Object attributes:
# ------------------
#	object			Object relative filename
#	object_wo_ext		Object relative filename without extension
#	object_url		URL to nph-object.cgi with all necessary par.
#	object_file		Object filename, absolute
#	object_name		Object name in dotted notation
#	object_basename		Object filename, without directory prefix
#	object_dir		Directory where object file resides, absoulte
#	object_rel_dir		Directory part of the object filename, relative
#	object_type		new.spirit object type
#	object_ext		Object file extension
#	object_type_config	Object type config hash (from objecttypes.conf)
#	object_meta_dir		Object meta directory, absolute
#	object_meta_file	Object meta filename, absolute
#	object_version_file	Object version information filename, absolute
#	object_history_dir	Directory with history files for this object
#	project			Name of the project this object belongs to
#	project_info		Project info hash (from etc/projects/*.conf)
#	project_root_dir	Project root directory, absolute
#	project_src_dir		Project source base directory, absolute
#	project_prod_dir	Project prod base directory, absolute
#	project_cgi_base_dir	Project cgi-bin base directory, absolute
#	project_htdocs_base_dir	Project htdocs base directory, absolute
#	project_lib_dir		Project lib base directory, absolute
#	project_inc_dir		Project include base directory, absolute
#	project_cgi_dir		Project cgi-bin base + project directory, absolute
#	project_htdocs_dir	Project htdocs base + project directory, absolute
#	project_config_dir	Project config base directory, absolute
#	project_log_dir		Project log base directory, absolute
#	project_log_file	Default Project CIPP log file
#	project_sql_dir		Project prod sql base_dir
#	project_databases_file	Filename of project databases file
#	project_modules_file	Filename of the modules file
#	project_base_configs_file  Filename of project base configs file
#	project_base_config_data   Data of used base config
#	project_depend_dir	Directory where dependency files reside
#	project_meta_dir	Directory where object meta data reside
#	q			CGI query object
#	event			actual object event
#	ticket			ticket of the session which accesses the object
#	username		user of this session
#	write_access		boolean, whether user may modify this object
#	window			boolean, whether the actual session runs in
#				a window or not
#	install_errors		lref of installation errors
#	dependency_installation	indicates that this object is in a 
#				dependency installation state. This controls
#				level of output.
#	__default_db		Cached value of the default database
#	no_dependency_ \	The install method initiates no
#	  installation	
#					installation of dependent objects
#	no_child_dependency_ \	All childs will be installed,
#	  installation		but not their dependent obj.
#=============================================================================

@ISA = qw( NewSpirit::Widget );

use strict;
use Carp;

use NewSpirit;
use NewSpirit::DataFile;
use NewSpirit::Lock;
use NewSpirit::Depend;
use NewSpirit::Widget;
use NewSpirit::Session;

use FileHandle;
use File::Copy;
use File::Path;
use File::Find;
use File::Basename;

sub new {
	my $type = shift;
	my %par = @_;

	# todo: take all paremters here from %par
	
	my $set_lock = $par{set_lock};
	
	my $q 		= $par{q};
	my $object_orig = $par{object};
	my $base_conf 	= $par{base_config_object} ||
			  $CFG::default_base_conf;

	# in command line mode object names are passed in dotted
	# notation
	my ($project, $project_info);
	my $command_line_mode = $q->param('command_line_mode');
	if ( $command_line_mode == 1 ) {
		my $object = $q->param('object');
		# strip off project
		$object =~ /^([^\.]+)/;
		$project = $1;
		$q->param('project',$project);
		
		# resolve dotted object name to relative file
		$project_info = NewSpirit::get_project_info ($project);
		my $project_src = $project_info->{root_dir}."/src";
		my $object_file = $type->get_object_src_file (
			$object, $project_src
		);
		$object_file =~ s!^$project_src/!!;
		$q->param('object', $object_file);
		
		# the same for a given base_conf
		if ( $par{base_config_object} ) {
			$base_conf = $type->get_object_src_file (
				$par{base_config_object}, $project_src
			);
			$base_conf =~ s!^$project_src/!!;
		}
		
		# we reset the command_line_mode flag here, because
		# more objects may be initialized with this query.
		# this query is completely converted into non-
		# command-line mode, so subsequent conversions would
		# fail.
		$q->param('command_line_mode',0);

	} else {
		$project = $q->param('project')
			or croak "NewSpirit::Object: missing project";
		$project_info = NewSpirit::get_project_info ($project);
	}

	$object_orig ||= $q->param('object');
	
	my $object = $object_orig;

	croak "NewSpirit::Object: missing object" unless $object;

	$object =~ m!\.([^\.]+)$!;
	my $ext = $1;
	my $object_type = $NewSpirit::Object::extensions->{lc($ext)};

	$object_type ||= 'generic';

	my $object_type_config =
		$NewSpirit::Object::object_types->{$object_type};
	my $module = $object_type_config->{module};

	my $project_root_dir = $project_info->{root_dir};

	my $object_file = "$project_root_dir/src/$object";

	my $object_name = $object;
	$object_name =~ s/\.[^\.]+$//;
	$object_name =~ s!/!.!g;
	$object_name = "$project.$object_name";

	my $event = $q->param('e');
	if ( $event ne 'create' and $object_type ne 'depend-all' ) {
		# the depend-all object type is virtual type,
		# no file exists for this type, so file checking is
		# disabled for depend-all.
		confess "object_does_not_exist\t$object_name\tObject file '$object_file' does not exist"
			unless -r $object_file;
	}

	my $object_dir = $object;
	$object_dir =~ s!/?([^/]+)$!!;
	my $filename = $1;

	my $object_src_dir = "$project_root_dir/src/$object_dir";
	$object_src_dir =~ s!/$!!;

	my $project_meta_dir = "$project_root_dir/meta";
	if ( not -d $project_meta_dir ) {
		mkpath ( [$project_meta_dir], 0, 0775 )
			or croak "can't mkpath $project_meta_dir";
	}
	
	# Ok, the naming here is clumsy. The $object_meta_dir means
	# the directory tree for additional non CVSable data, eg.
	# dependencies, database index files and object last modified
	# information.
	#
	# The $object_meta_file is the file, where object properties
	# are stored. THIS FILE LIVES INSIDE THE SRC TREE, and not
	# in the $object_meta_dir !!!

	my $object_meta_dir = "$project_meta_dir/$object_dir";
	if ( not -d $object_meta_dir ) {
		mkpath ( [$object_meta_dir], 0, 0775 )
			or croak "can't mkpath $object_meta_dir";
	}

	my $meta_file    = "$object_src_dir/$filename.m";
	my $version_file = "$object_meta_dir/##$filename.v";

	my $ticket = $q->param('ticket');
	$object = $object_orig;
	
	my $object_url = qq{$CFG::object_url?ticket=$ticket&object=$object&}.
			 qq{project=$project};
	
	my $object_history_dir = "$project_root_dir/history/$object_dir/$filename";
	$object_history_dir =~ s!/+!/!g;

	if ( not -d $object_history_dir ) {
		mkpath ( [$object_history_dir], 0, 0775 )
			or croak "can't mkpath $object_history_dir";
	}

	my $project_depend_dir = "$project_root_dir/meta";
	my $project_meta_dir   = $project_depend_dir;
	if ( not -d $project_depend_dir ) {
		mkpath ( [$project_depend_dir], 0, 0775 )
			or croak "can't mkpath $project_depend_dir";
	}

	my $project_modules_file = "$project_depend_dir/##modules";

	my $object_wo_ext = $object;
	$object_wo_ext =~ s/\.[^\.]+$//;

	my $prod_dir = "$project_root_dir/prod";
	
	# load base config data if we are not instantiating
	# the base config object (this would result in
	# an endless loop)

	my $base_config_data;
	if ( $object ne $CFG::default_base_conf ) {
		my $base_config_object = new NewSpirit::Object (
			q => $q,
			object => $base_conf
		);
		$base_config_data = $base_config_object->get_data;
	}
	
	# if we are not using the default base configuration
	# we must determine the prod-directory out of the
	# actual base configuration object

	if ( $base_conf ne $CFG::default_base_conf ) {
		$prod_dir = "$project_root_dir/$base_config_data->{base_install_dir}/prod";
	}

	my $self = {
		q => $q,
		object => $object,
		object_wo_ext => $object_wo_ext,
		object_name => $object_name,
		object_dir => "$project_root_dir/src/$object_dir",
		object_rel_dir => $object_dir,
		object_type => $object_type,
		object_ext => $ext,
		object_file => $object_file,
		object_type_config => $object_type_config,
		object_basename => $filename,
		object_meta_dir => $object_meta_dir,
		object_meta_file => $meta_file,
		object_version_file => $version_file,
		object_url => $object_url,
		object_history_dir => $object_history_dir,
		project => $project,
		project_info => $project_info,
		project_root_dir => $project_root_dir,
		project_src_dir => "$project_root_dir/src",
		project_prod_dir => $prod_dir,
		project_template_dir => "$project_root_dir/src/tmpl",
		project_cgi_base_dir => "$prod_dir/cgi-bin",
		project_htdocs_base_dir => "$prod_dir/htdocs",
		project_cgi_dir => "$prod_dir/cgi-bin/$project",
		project_htdocs_dir => "$prod_dir/htdocs/$project",
		project_config_dir => "$prod_dir/config",
		project_lib_dir => "$prod_dir/lib",
		project_inc_dir => "$prod_dir/inc",
		project_sql_dir => "$prod_dir/sql",
		project_log_dir => "$prod_dir/logs",
		project_log_file => "$prod_dir/logs/cipp.log",
		project_modules_file => $project_modules_file,
		project_depend_dir => $project_depend_dir,
		project_meta_dir => $project_meta_dir,
		project_databases_file => "$project_meta_dir/$CFG::databases_file",
		project_base_configs_file => "$project_meta_dir/$CFG::base_configs_file",
		project_base_conf => $base_conf,
		project_base_config_data => $base_config_data,
		ticket => $ticket,
		username => $q->param('username'),
		event => $event,
		window => $q->param('window'),
		install_errors => [],
		command_line_mode => $command_line_mode,
	};

	eval "use $module";
	croak "can't load NewSpirit Module '$module' for object type '$object_type': $@" if $@;
	
	$self = bless $self, $module;

	$self->{project_base_config_data} ||= $self->get_data;

	$self->set_lock if $set_lock;
	$self->convert_from_spirit1;
	
	# OK, we switch to the history object file, if we are
	# in restore view mode

	if ( $self->{event} eq 'view' or $q->param('history_warp') == 1 ) {
		my $version = $q->param('version');
		$self->{object_file} = "$object_history_dir/$version";
		$self->{object_meta_file} = "$object_history_dir/$version.m";
		$self->{object_version_file} = "$object_history_dir/$version.m";
	}

	# this is a hook for Object type classes where they can
	# define some initialization code

	$self->init;

	return $self;
}

#---------------------------------------------------------------------
# get_object_type - returns type of this object
#---------------------------------------------------------------------
# SYNOPSIS:
#	$object_type = $self->get_object_type ($object_file)
#
# DESCRIPTION:
#	This method returns the object type of a given object file.
#---------------------------------------------------------------------

sub get_object_type {
	my $self = shift;
	
	my ($object_file) = @_;

	$object_file =~ m!\.([^\.]+)$!;
	my $ext = $1;

	my $object_type = $NewSpirit::Object::extensions->{$ext};

	$object_type ||= 'generic';

#	print STDERR "object_file=$object_file object_type=$object_type\n";

	return $object_type;
}

#---------------------------------------------------------------------
# convert_from_spirit1 - Convert old spirit object files
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->convert_from_spirit1
#
# DESCRIPTION:
#	This method is called from the constructor, just after the
#	object instance is created.
#	It checks if the object file has the old spirit format and
#	converts it, if so, otherwise it returns immediately.
#	It calls
#
#		$self->convert_meta_from_spirit1
#		$self->convert_data_from_spirit1
#
#	which should be implemented by subclasses to do object
#	type specifiy conversions.
#---------------------------------------------------------------------

sub convert_from_spirit1 {
	my $self = shift;
	
	my $object_file = $self->{object_file};
	return if not -r $object_file;
	
	my $fh = new FileHandle;
	binmode $fh;

	open ($fh, $object_file) or return;
	my $magic = <$fh>;
	$magic =~ s/\s+$//;
	
	if ( $magic eq '# IDE_HEADER' ) {
		my %meta;
		# read header with meta data
		while (<$fh>) {
			s/\s+$//;
			last if $_ eq '# IDE_HEADER_END';
			m/^#\$([^:]+):\s+(.*) \$$/;
			$meta{$1} = $2;
		}
		
		# copy body of object to new file
		my $out_fh = new FileHandle;
		my $out_file = "$self->{object_dir}/##$self->{object_basename}tmp$$";
		open ($out_fh, "> $out_file")
			or croak "can't write $out_file";
		binmode $out_fh;
		while (<$fh>) {
			print $out_fh $_;
		}
		close $out_fh;
		
		# create version file
		my $version_file = $self->{object_version_file};
		my $df = new NewSpirit::DataFile ($version_file);
		my %hash = (
			last_modify_date => $meta{LAST_MODIFY_DATE},
			last_modify_user => $meta{LAST_MODIFY_BY},
			version		 => 1,
		);
		$df->write (\%hash);
		$df = undef;
		
		
		# create meta file
		my $meta_file = $self->{object_meta_file};
		$df = new NewSpirit::DataFile ($meta_file);
		%hash = (
			description      => $meta{DESCRIPTION}
		);
		
		# now we convert the data object specific
		$self->convert_data_from_spirit1 ($out_file);

		# now we convert object specifiy meta properties
		$self->convert_meta_from_spirit1 (\%meta, \%hash);
		
		$df->write (\%hash);
		$df = undef;

		# move new file over the old
		move ($out_file, $object_file)
			or croak "can't move $out_file to $object_file";
	}
	
	close $fh;
}

#---------------------------------------------------------------------
# dotted_notation - Converts a relative object path to dotted notation
#---------------------------------------------------------------------
# SYNOPSIS:
#	$dotted_object = $self->dotted_notation ($object)
#
# DESCRIPTION:
#	This method returns the dotted noation of the given relative
#	object path.
#---------------------------------------------------------------------

sub dotted_notation {
	my $self = shift;
	
	my ($object) = @_;
	
	$object =~ s!\.[^\.]+$!!;
	$object =~ s!/!.!g;
	return "$self->{project}.$object";
}

#---------------------------------------------------------------------
# set_lock - Try to set a lock (optional force the lock)
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->set_lock
#
# DESCRIPTION:
#	This method tries to set a lock on its object. It sets
#
#	  $self->{write_access}
#
#	to the corresponding value, depending on the success of
#	setting the lock.
#
#	The lock is forced, if the event of this object is 'unlock'.
#---------------------------------------------------------------------

sub set_lock {
	my $self = shift;

	my $ticket = $self->{ticket};
	
	my $lock = new NewSpirit::Lock (
		project_meta_dir => $self->{project_meta_dir},
		username         => $self->{username},
		ticket           => $ticket
	);
	
	$self->{lock_info} = $lock->set (
		$self->{object},
		$self->{event} eq 'unlock'
	);
	
	if ( $self->{lock_info}->{ticket} eq $ticket ) {
		$self->{write_access} = 1;
	} else {
		# Ok, it seems we are not able to lock this object.
		# If the ticket of this lock has gone away, we
		# lock the object anyhow!
		my $sh = new NewSpirit::Session;
		$self->{write_access} =
			not $sh->ticket_exists ($self->{lock_info}->{ticket});
	}
	
	1;
}

#---------------------------------------------------------------------
# unset_lock - Unlocks the current object
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->unset_lock
#
# DESCRIPTION:
#	Removes the lock of the current object.
#---------------------------------------------------------------------

sub unset_lock {
	my $self = shift;

	my $ticket = $self->{ticket};
	
	my $lock = new NewSpirit::Lock (
		project_meta_dir  => $self->{project_meta_dir},
		username          => $self->{username},
		ticket            => $ticket
	);
	
	$lock->delete;
	
	1;
}

#---------------------------------------------------------------------
# unlock_ctrl - CGI event handler for the 'unlock' event
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->unlock_ctrl
#
# DESCRIPTION:
#	This method simply calls the object editor $self->edit
#	after setting $self->{event} to 'edit', because unlocking
#	was already done by $self->set_lock.
#---------------------------------------------------------------------

sub unlock_ctrl {
	my $self = shift;
	
	# unlocking was already done by $self->set_lock,
	# called by the constructor.
	# we redefine the event and simply call the editor here
	
	$self->{event} = 'edit';
	$self->edit_ctrl;
}

#---------------------------------------------------------------------
# editor_header - HTML code for the editor header section
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->editor_header ($operation [, $modification_tag] )
#
#	  $operation		Textstring, for which operation is
#				this page, used for a title
#	  $modification_tag	Default value for the modification
#				tag text field
#
# DESCRIPTION:
#	This method produces the HTML code for the object editor
#	header section, includung the HTML <FORM> with the basic
#	parameters.
#---------------------------------------------------------------------

sub editor_header {
	my $self = shift;
	my ($operation, $modification_tag) = @_;

	NewSpirit::start_page (
		title => "$self->{object_name} ($operation)",
		link_style => 'plain',
		marginwidth => 5,
		marginheight => 5,
	);
	
	NewSpirit::js_open_window($self->{q});

	my $meta_href = $self->get_meta_data;
	
	my $object_type_name = $self->{object_type_config}->{name};
	$object_type_name =~ s/\s/&nbsp;/g;

	my $description = substr (
		$meta_href->{description},
		0,
		$CFG::DESC_CUT
	);

	my $ticket = $self->{ticket};
	my $project = $self->{project};
	my $object = $self->{object};

	my $last_modify_date = NewSpirit::format_timestamp
		( $meta_href->{last_modify_date} );

	my $function_block = $self->editor_function_block;
	my $function_popup = $self->editor_function_popup;
	
	my $object_url = $self->{object_url};
	my $download_filename = $self->download_filename;
	$object_url =~ s!\?!/$download_filename?!;
	$object_url .= "&__download_filename=foo/$download_filename";
	
	my $enctype = ($self->{event} eq 'edit' and
	              $self->{object_type_config}->{file_upload}) ?
		"multipart/form-data" : "application/x-www-form-urlencoded";

	my $close_window_table;
	if ( $self->{window} ) {
		$close_window_table = <<__HTML;
<table width="100%" border=0 cellpadding=0 cellspacing=0>
<tr><td align="right">
  <table border=0 cellpadding=2 cellspacing=0 bgcolor="$CFG::ERROR_BG_COLOR">
  <tr><td>
  <a href="javascript:close_window()"
    >${CFG::FONT_ERROR}<b>CLOSE WINDOW</b></FONT></a></td>
  </tr>
  </table>
</td></tr>
</table>
__HTML
	}

	my $save_window_name = "cipp_save_window$ticket";
	my $dep_window_name  = "cipp_dep_window$ticket";
	my $cgi_window_name  = "cipp_cgi_window$ticket";

	my $exec_url;
	if ( ($self->{object_type} eq 'cipp' or $self->{object_type} eq 'cipp-html')
	     and $self->{event} !~ /restore|view/ ) {
		my $base_config_object = new NewSpirit::Object (
			q => $self->{q},
			object => $CFG::default_base_conf 
		);
		my $base_config_data = $base_config_object->get_data;
		$base_config_object = undef;

		my $install_file = $self->get_install_filename;

		my $base_dir = $self->{object_type} eq 'cipp' ?
			$self->{project_cgi_dir} :
			$self->{project_htdocs_dir};

		$base_dir =~ s!/$!!;
		$install_file =~ s!^$base_dir/!!;

		if ( $base_config_data->{base_server_name} ) {
		  $base_config_data->{base_server_name} =~ s!http://!!;
		  $base_config_data->{base_server_name} =~ s!/$!!;

		  $exec_url =
			"http://$base_config_data->{base_server_name}".
			($self->{object_type} eq 'cipp' ?
				$base_config_data->{base_cgi_url} :
				$base_config_data->{base_doc_url}).
			"/".
			$self->{project}."/".
			$install_file;
		}
	}


	# the history is displayed in the main frame, all other
	# events target a window
	my $target_is_a_window = $self->{event} eq 'history' ? 0 : 1;

	print <<__HTML;
<script language="JavaScript">
  function save_object () {
    if ( document.cipp_object.func[document.cipp_object.func.selectedIndex].value == 'none' ) {
      return;
    }
    document.cipp_object.e.value=
    	document.cipp_object.func[document.cipp_object.func.selectedIndex].value;

    if ( document.cipp_object.e.value == 'execute_cgi_program' ) {
        if ( '$exec_url' == '' ) {
	  alert ('You first have to configure a server name in $self->{project}.configuration.');
	  return;
	}
        var url = '$exec_url';
	if ( document.cipp_object.modification_tag.value != '' ) {
	  url += '?' + document.cipp_object.modification_tag.value;
	}
	if ( !top.$cgi_window_name || top.$cgi_window_name.closed ) {
          var exec_win = open_window (
            url, '$cgi_window_name',
            $CFG::TEST_WIN_WIDTH, $CFG::TEST_WIN_HEIGHT,
            $CFG::TEST_WIN_POSX, $CFG::TEST_WIN_POSY,
            true, true
          );
	  top.$cgi_window_name = exec_win;
	} else {
	  top.$cgi_window_name.document.location.href = url;
	  top.$cgi_window_name.focus();
	}
	
        return;
    }

    document.cipp_object.target  = '$save_window_name';

    if ( !top.$save_window_name || top.$save_window_name.closed ) {

      var exec_win = open_window (
        '', '$save_window_name',
        $CFG::SAVE_WIN_WIDTH, $CFG::SAVE_WIN_HEIGHT,
        $CFG::SAVE_WIN_POSX, $CFG::SAVE_WIN_POSY,
        true
      );
      top.$save_window_name = exec_win;
    }
    
    top.$save_window_name.document.write(
      '<html><script>'+
      'window.opener.document.cipp_object.submit()'+
      '</'+'script></html>'
    );
    top.$save_window_name.document.close();
    top.$save_window_name.focus();
    reset_modified_indicator();
  }
  
  function get_checked_version () {
    if ( document.cipp_object.no_versions.value == 1 ) {
      return -1;
    }

    var i;
    var version = -1;
    if ( ! document.cipp_object.version.length ) {
      return document.cipp_object.version.value;
    }

    for (i=0; version == -1 && i < document.cipp_object.version.length; ++i) {
      if ( document.cipp_object.version[i].checked ) {
        version = document.cipp_object.version[i].value;
      }
    }
    return version;
  }
  
  function view_object () {
    var version = get_checked_version();
    if ( version == -1 ) {
      return;
    }
    document.cipp_object.e.value=
      document.cipp_object.func[document.cipp_object.func.selectedIndex].value;

    document.cipp_object.target = 'ACTION';
    document.cipp_object.submit();
  }
  
  function delete_versions () {
    var i;
    var version;
    for (i=0; i < document.cipp_object.version.length; ++i) {
      if ( document.cipp_object.version[i].checked ) {
        version = document.cipp_object.version[i].value;
      }
    }

    if ( confirm ('Do you really want to delete all versions prior version '+version+'?') ) {
      document.cipp_object.target = 'ACTION';
      document.cipp_object.e.value='delete_versions';
      document.cipp_object.submit();
    }
  }
  
  function close_window () {
    document.cipp_object.action = '$CFG::admin_url?e=close_window&ticket=$ticket';
    document.cipp_object.e.value = 'close_window';
    document.cipp_object.target = '';
    document.cipp_object.submit();
  }
  
  function open_depend_window () {
    var url='$self->{object_url}&e=dependencies&window=1';
     
    if ( !top.$dep_window_name || top.$dep_window_name.closed ) {
      var dep_win = open_window (
         url, '$dep_window_name',
         $CFG::SAVE_WIN_WIDTH, $CFG::SAVE_WIN_HEIGHT,
	 0, 0,
	 true
      );
      top.$dep_window_name = dep_win;
    } else {
      top.$dep_window_name.location.href = url;
    }
    top.$dep_window_name.focus();
  }
</script>

<form name="cipp_object" METHOD=POST ENCTYPE="$enctype"
      ACTION="$CFG::object_url" onSubmit="return false;">
<input type="hidden" name="ticket" value="$ticket">
<input type="hidden" name="project" value="$project">
<input type="hidden" name="object" value="$object">
<input type="hidden" name="window" value="$target_is_a_window">
<input type="hidden" name="e" value="">
<input type="hidden" name="f" value="">

$close_window_table

<table $CFG::BG_TABLE_OPTS width="100%"><tr><td>
<table $CFG::TABLE_OPTS width="100%">
<tr><td valign="top">
  <table $CFG::INNER_TABLE_OPTS width="100%">
  <tr><td valign="top">
    $CFG::TABLE_FONT
    <b>Object:</b>
    </FONT>
  </td><td valign="top" colspan=2>
    $CFG::TABLE_FONT<b>
    <a href="$object_url&e=download&no_http_header=1">$self->{object_name}</a>
    </b></FONT>
  </td></tr>
  <tr><td valign="top">
    $CFG::TABLE_FONT
    <b>Description:</b>
    </FONT>
  </td><td valign="top" colspan=2>
    $CFG::TABLE_FONT
    $description
    </FONT>
  </td></tr>
  <tr><td valign="top">
    $CFG::TABLE_FONT
    <b>Type:</b>
    </FONT>
  </td><td valign="top">
    $CFG::TABLE_FONT
    $object_type_name
    </FONT>
  </td><td valign="top" align="right">
    $CFG::TABLE_FONT
    <b>Modification:</b>
    $last_modify_date&nbsp;by&nbsp;$meta_href->{last_modify_user}
    </FONT>
  </td></tr>
  </table>
</td><td valign="top">
  $function_block
</td></tr>
<tr><td colspan="2">
  <table cellpadding=0 cellspacing=0 width="100%">
  <tr><td valign="center">
    $CFG::FONT
    <INPUT TYPE=TEXT NAME="modification_tag" SIZE=$CFG::MOD_COLS
           VALUE="$modification_tag">
    </FONT>
    <a href="javascript:nop()"><img name="status_image" 
       src="$CFG::icon_url/status_original.gif"
       alt="Modified Indicator" border="0"></a>
  </td><td align="right">
    $CFG::FONT
    $function_popup
    </FONT>
  </td></tr>
  </table>
</td></tr>
</table>
</td></tr></table>

<script language="JavaScript">
  function object_was_modified () {
    if ( document.status_image ) {
      document.status_image.src='$CFG::icon_url/status_modified.gif';
    }
  }
  function reset_modified_indicator () {
    if ( document.status_image ) {
      document.status_image.src='$CFG::icon_url/status_original.gif';
    }
  }
  function nop () {
  }
</script>
__HTML
}

#---------------------------------------------------------------------
# download_filename - Name for file download
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->download_filename 
#
# DESCRIPTION:
#	This method returns the name for downloading the file. By
#	default this is the basename of the object file. But this
# 	may be overidden by object type classes.
#---------------------------------------------------------------------

sub download_filename {
	my $self = shift;
	
	return $self->{object_basename};
}

#---------------------------------------------------------------------
# editor_footer - HTML code for the editor footer section
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->editor_footer 
#
# DESCRIPTION:
#	This method produces the HTML code for the object editor
#	footer section, includung the HTML </FORM> to close the
#	object form.
#---------------------------------------------------------------------

sub editor_footer {
	my $self = shift;

	print "</FORM>\n";

	NewSpirit::end_page();
}

#---------------------------------------------------------------------
# editor_function_block - HTML code for the editor function section
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->editor_function_popup 
#
# DESCRIPTION:
#	This method produces the HTML code for the object editor
#	function section. This is the section with the six main
#	function links 'HISTORY', 'HELP', 'PROPERTIES', 'DELETE',
#	'DEPENDENCIES' and 'EDIT'.
#---------------------------------------------------------------------

sub editor_function_block {
	my $self = shift;
	
	my $event = $self->{event};
	my $ticket = $self->{ticket};
	my $object = $self->{object};
	my $object_type = $self->{object_type};

	my ($history_link, $properties_link, $edit_link, $delete_link) = (1, 1, 1, 1);
	my ($history_color, $properties_color, $edit_color, $delete_color);
	
	if ( $event eq 'edit' ) {
		$edit_link = 0;
		$edit_color = "bgcolor=$CFG::INACTIVE_COLOR";
	} elsif ( $event =~ /^delete/ ) {
		$delete_link = 0;
		$delete_color = "bgcolor=$CFG::INACTIVE_COLOR";
	} elsif ( $event eq 'history' ) {
		$history_link = 0;
		$history_color = "bgcolor=$CFG::INACTIVE_COLOR";
	} elsif ( $event eq 'properties' ) {
		$properties_link = 0;
		$properties_color = "bgcolor=$CFG::INACTIVE_COLOR";
	}

	$delete_link = 0 if $self->{object} eq 'configuration.cipp-base-config';

	# table start

	my $html = "<table $CFG::INNER_TABLE_OPTS width=100%>\n";

	# history
	
	$html .= qq{<tr><td valign=top $history_color>$CFG::FONT};

	$html .= qq{<a href="$self->{object_url}&e=history">} if $history_link;
	$html .= qq{<b>HISTORY</b>};
	$html .= qq{</a>} if $history_link;
	
	$html .= qq{</td><td>$CFG::FONT&nbsp;</FONT></td>\n};

	# help

	$html .= qq{<td valign=top>$CFG::FONT};

#	$html .= qq{<a href="$CFG::help_url?ticket=$ticket&e=$event&}.
#	         qq{object_type=$object_type">};
	$html .= qq{<font color="#999999">};
	$html .= qq{<b>HELP</b>};
	$html .= qq{</font>};
+#	$html .= qq{</a>};
	$html .= qq{</td></tr>\n};
	
	# properties
	
	$html .= qq{<tr><td valign=top $properties_color>$CFG::FONT};
	$html .= qq{<a href="$self->{object_url}&e=properties&}.
	         qq{object_type=$object_type">} if $properties_link;
	$html .= qq{<b>PROPERTIES</b>};
	$html .= qq{</a>} if $properties_link;

	$html .= qq{</td><td>$CFG::FONT&nbsp;</FONT></td>\n};

	# delete
	
	$html .= qq{<td valign=top $delete_color>$CFG::FONT};

	$html .= qq{<a href="$self->{object_url}&e=delete_ask">} if $delete_link;
	$html .= qq{<b>DELETE</b>};
	$html .= qq{</a>} if $delete_link;
	$html .= qq{</td></tr>\n};
	
	# dependencies

	$html .= qq{<tr><td valign=top colspan="2">$CFG::FONT};
	$html .= qq{<a href="javascript:open_depend_window()">};
	$html .= qq{<b>DEPENDENCIES</b>};
	$html .= qq{</a>} if $edit_link;
	$html .= qq{</td>\n};
	
	# edit

	$html .= qq{<td valign=top $edit_color>$CFG::FONT};
	$html .= qq{<a href="$self->{object_url}&e=edit">} if $edit_link;
	$html .= qq{<b>EDIT</b>};
	$html .= qq{</a>} if $edit_link;
	$html .= qq{</td></tr>\n};
	
	# table end

	$html .= "</table>\n";

	return $html;
}

#---------------------------------------------------------------------
# editor_function_popup - HTML code for the editor function popup
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->editor_function_popup
#
# DESCRIPTION:
#	This method produces the HTML code for the object editor
#	function popup, which contains min. the 'Save' entry.
#	The content of the popup depends on the actually processed
#	function ('HISTORY', 'PROPERTIES' etc.)
#---------------------------------------------------------------------

sub editor_function_popup {
	my $self = shift;

	return $self->editor_read_access_function_popup
		unless $self->{write_access};

	my $event = $self->{event};
	my $ticket = $self->{ticket};
	my $object = $self->{object};
	my $object_type = $self->{object_type};

	my ($save_event, $save_text, $onclick);

	$save_text = 'Save';
	$onclick = 'save_object()';

	my $html;
	
	my $add_no_dep_entry;
	if ( $event eq 'edit' ) {
		$save_event = 'save_object';
		$add_no_dep_entry = 1;
	} elsif ( $event eq 'properties' ) {
		$save_event = 'save_properties';
		$add_no_dep_entry = 1;
	} elsif ( $event eq 'history' ) {
		$save_event = 'view';
		$save_text  = 'View';
		$onclick = 'view_object()';
	} elsif ( $event eq 'view' ) {
		$save_event = 'restore';
		$save_text  = 'Restore';
		my $version = $self->{q}->param('version');
		$html .= qq{<INPUT TYPE=HIDDEN NAME=version VALUE="$version">\n};
		$add_no_dep_entry = 1;
	} else {
		$save_event = 'unknown save event';
	}

	$html .= qq{<SELECT NAME="func">};
	
	if ( $CFG::SAVE_POPUP_UNSELECTED and $event eq 'edit' ) {
		$html .= qq{<OPTION VALUE="none">---</OPTION>};
	}
	
	$html .= qq{<OPTION VALUE="$save_event">$save_text</OPTION>};
	$add_no_dep_entry and
		$html .= qq{<OPTION VALUE="${save_event}_without_dep">$save_text w/o Dep.</OPTION>};
	
	if ( $self->{event} ne "view" ) {
		$html .= qq{<OPTION VALUE="install_last_saved_object">Install (edited external)</OPTION>};
	}

	if ( ($self->{object_type} eq 'cipp' or $self->{object_type} eq 'cipp-html')
	     and $self->{event} ne "view" ) {
		$html .= qq{<OPTION VALUE="execute_cgi_program">Execute Object</OPTION>};
	}
	
	$html .= qq{</SELECT>};
	$html .= qq{<b><INPUT TYPE=BUTTON VALUE=" Submit " }.
		 qq{onClick="$onclick"></b>};
	
	return $html;
}

#---------------------------------------------------------------------
# editor_read_access_function_popup - Produces HTML code for locked objects
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->editor_read_access_function_popup
#
# DESCRIPTION:
#	This method produces the HTML code for the object editor
#	function popup, if the object is in read only mode due
#	to a lock. It replaces the output of editor_function_popup().
#---------------------------------------------------------------------

sub editor_read_access_function_popup {
	my $self = shift;

	my $lock_info = $self->{lock_info};
	my $timestamp = NewSpirit::format_timestamp($lock_info->{time});
	my $html;
	$html = <<__HTML;
<table bgcolor="$CFG::ERROR_BG_COLOR" cellpadding=2 cellspacing=0 width=100%>
<tr><td>
  $CFG::FONT_ERROR<b>
  Object is currently locked
  by user $lock_info->{username} since $timestamp
  <div align="right">
  <a href="$self->{object_url}&e=unlock"><FONT
  COLOR="$CFG::ERROR_FONT_COLOR"><U>UNLOCK</U></FONT></a>
  </div>
  </b></FONT>
</td></tr>
</table>
__HTML
}

#---------------------------------------------------------------------
# properties_ctrl - CGI event handler for the 'properties' event
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->properties_ctrl
#
# DESCRIPTION:
#	This method prints the editor page for properties.
#---------------------------------------------------------------------

sub properties_ctrl {
	my $self = shift;
	
	$self->editor_header ('properties');
	
	$self->properties_table;
	
	$self->editor_footer;
}

#---------------------------------------------------------------------
# properties_table - Print table of object properties
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->properties_table ($no_form_elements)
#
#	  $no_form_elements	Print form elements or only view
#				elements (for history restore)
#
# DESCRIPTION:
#	This method is called by $self->properties and creates
#	the HTML code for the properties table, either for
#	the editor ($no_form_elements is false) or for the history
#	viewer ($no_form_elements is true).
#---------------------------------------------------------------------

sub properties_table {
	my $self = shift;

	my ($no_form_elements) = @_;

	print <<__HTML;
<p>
$CFG::FONT_BIG<b>Properties</b></FONT>
<table $CFG::BG_TABLE_OPTS>
<tr><td>
  <table $CFG::TABLE_OPTS width="100%">
__HTML

	my $meta_data = $self->get_meta_data;

	$self->input_widget (
		read_only => $no_form_elements,
		name      => "description",
		info_href => {
			description => "Description",
			default => "",
			type => "textarea"
		},
		data_href => $meta_data
	);

	$self->input_widget (
		read_only => $no_form_elements,
		name      => "save_filter_cmd",
		info_href => {
			description => "Save trigger command",
			default => "",
			type => "text"
		},
		data_href => $meta_data
	);

	$self->type_specific_properties ($no_form_elements);

	print <<__HTML;
  </table>
  </td></tr>
</table>
__HTML
	1;
}
	
#---------------------------------------------------------------------
# type_specific_properties - Print type specific property table rows
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->type_specific_properties ($no_form_elements)
#
#	  $no_form_elements	Print form elements or only view
#				elements (for history restore)
#
# DESCRIPTION:
#	This method is called by $self->properties_table and creates
#	the HTML code for the object type specific properties.
#---------------------------------------------------------------------

sub type_specific_properties {
	my $self = shift;

	my ($no_form_elements) = @_;

	my $property_order_lref =
		$self->{object_type_config}->{property_order};

	my $properties_href =
		$self->{object_type_config}->{properties};
	
	foreach my $property (@{$property_order_lref}) {
		my $info = $properties_href->{$property};
		$self->input_widget (
			read_only => $no_form_elements,
			name      => $property,
			info_href => $info,
			data_href => $self->get_meta_data
		);
	}
}

#---------------------------------------------------------------------
# get_data - Generic method to retrieve the content of a object
#---------------------------------------------------------------------
# SYNOPSIS:
#	$object_sref = $self->get_data
#
# DESCRIPTION:
#	This method returns the content of the object data file
#	as a scalar reference. It should be overloaded by subclasses,
#	if the structure of the object data is more complex and
#	needs special handling (e.g. NewSpirit::Object::Record).
#---------------------------------------------------------------------

sub get_data {
	my $self = shift;

	my $fh = new FileHandle;
	binmode $fh;

	my $data;
	if ( open ($fh, $self->{object_file} ) ) {
		$data = join ('', <$fh>);
		close $fh;
	}
	
	return \$data;
}

#---------------------------------------------------------------------
# print - Print the object file content to STDOUT
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->print
#
# DESCRIPTION:
#	The content of the object file is printed without modifications
#	to STDOUT, using binmode.
#---------------------------------------------------------------------

sub print {
	my $self = shift;

	my $fh = new FileHandle;

	binmode STDOUT;

	if ( open ($fh, $self->{object_file} ) ) {
		binmode $fh;
		while ( <$fh> ) {
			print;
		}
		close $fh;
	}
}

#---------------------------------------------------------------------
# get_meta_data - Return the meta data of this object
#---------------------------------------------------------------------
# SYNOPSIS:
#	$meta_href = $self->get_meta_data
#
# DESCRIPTION:
#	Returns a hash reference of meta data for this object. The
#	following entries are mandatory and will be loaded with default
#	values, if not found in the corresponding object meta files.
#
#	  description
#	  last_modify_date
#	  last_modify_user
#
#	Loaded meta data is cached in the object instance. So
#	subsequent calls will not load the meta data from file again.
#---------------------------------------------------------------------

sub get_meta_data {
	my $self = shift;
	
	return $self->{_meta_data} if defined $self->{_meta_data};
	
	my $meta_filename = $self->{object_meta_file};
	my $version_filename = $self->{object_version_file};

	# read object properties (or set default values)

	if ( not -r $meta_filename ) {
		# if the meta file does not exist, we create some
		# default meta data
		$self->{_meta_data} = {
			description => 'unknown',
		};

		# set defaults from object type configuration
		my $properties = $self->{object_type_config}->{properties};
		foreach my $prop ( keys %{$properties} ) {
			$self->{_meta_data}->{$prop} = $properties->{$prop}->{default}
				if defined $properties->{$prop}->{default};
		}
		
	} else {
		my $df = new NewSpirit::DataFile ($meta_filename);
		$self->{_meta_data} = $df->read;
		$df = undef;
	}
	
	# read object version information (or set default values)
	
	if ( not -r $version_filename ) {
		# if the version file does not exist, we create
		# some default data
		$self->{_meta_data}->{last_modify_date} = '0000.00.00-00:00:00';
		$self->{_meta_data}->{last_modify_user} = 'unknown';
	} else {
		my $df = new NewSpirit::DataFile ($version_filename);
		my $meta = $df->read;	

		$self->{_meta_data}->{last_modify_date} =
			$meta->{last_modify_date} || 'unknown';
		$self->{_meta_data}->{last_modify_user} =
			$meta->{last_modify_user} || 'unknown';
	}
	
	return $self->{_meta_data};
}

#---------------------------------------------------------------------
# save_ctrl - CGI event handler for the 'save' event
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->save_ctrl
#
# DESCRIPTION:
#	This method saves and installs the object and produces the
#	corresponding HTML output for the save window.
#---------------------------------------------------------------------

sub save_ctrl {
	my $self = shift;

	return if $self->save_not_possible;
	
	my $browser_update;
	eval {
		$browser_update = $self->save;
	};
	my $save_error = NewSpirit::strip_exception($@);
	
	$self->object_header ('save object');

	if ( $save_error ) {
		print qq{<table cellpadding=2 cellspacing=0 bgcolor="$CFG::ERROR_BG_COLOR">};
		print qq{<tr><td>$CFG::FONT_ERROR<b>Error saving file to };
		print qq{$self->{object_file}!</b><p>Error message:<br><b>$save_error</b></FONT><p>\n};
		print qq{</td></tr></table>\n};
	} else {
		print qq{$CFG::FONT Successfully saved to<br><b>$self->{object_file}</b></FONT><p>\n};

		$self->install;

		if ( $self->{object_type_config}->{file_upload} ) {
			print <<__HTML;
<script language="JavaScript">
opener.document.location.href='$self->{object_url}&e=edit';
</script>
__HTML
		}
	}

	# do we need to reload the project browser?
	if ( $browser_update ) {
		print <<__HTML;
<script language="JavaScript">
  var url = opener.parent.CONTROL.PBTREE.document.location.href;
  opener.parent.CONTROL.PBTREE.document.location.href = url;
</script>
__HTML
	}

	NewSpirit::end_page();
	
}


#---------------------------------------------------------------------
# execute_save_filter - executes a save filter command, if configured
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->execute_save_filter
#
# DESCRIPTION:
#	If a save filter command is configured for this object,
#	it is executed here. Output is given to STDOUT.
#---------------------------------------------------------------------

sub execute_save_filter {
	my $self = shift;
	
	my $meta = $self->get_meta_data;
	
	return if not $meta->{save_filter_cmd};

	print "$CFG::FONT\n";

	my $cmd = $meta->{save_filter_cmd};
	
	$cmd = sprintf ($cmd, $self->{object_file});
	
	print "<p>Executing save filter command...<p>\n";

	my ($file) = split (/\s+/, $cmd, 2);
	if ( not -f $file ) {
		print "<p><b>Error</b>: can't find $file<p>\n";
		print "</font>\n";
		return;
	}
	if ( not -x $file ) {
		print "<p><b>Error</b>: can't execute $file<p>\n";
		print "</font>\n";
		return;
	}
	
	open (IN, "$cmd < $self->{object_file} 2>&1 |")
		or die "can't fork process for save filter $cmd";
	print "<font face=courier><blockquote><pre>\n";
	while (<IN>) {
		print $_;
	}
	print "</pre></blockquote></font>\n";

	if ( not close IN ) {
		print "<b>Warning</b>: program exists with error status!<p>\n";
	}

	print "</font>\n";

	1;
}


#---------------------------------------------------------------------
# install_last_saved_ctrl - CGI event handler for the
#				'install_last_saved_object' event
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->install_last_saved_ctrl
#
# DESCRIPTION:
#	This method installs the last saved version (resp. the
#	current actual version in filesystem, which may be modified
#	by an external editor)
#---------------------------------------------------------------------

sub install_last_saved_ctrl {
	my $self = shift;

	return if $self->save_not_possible;
	
	$self->object_header ('install last saved object');

	if ( not $self->{command_line_mode} ) {
		print <<__HTML;
$CFG::FONT<font color="red">
<b>WARNING:</b><br>
This procedure installs the file directly from the source<br>
directory. Any changes made in the new.spirit object editor<br>
are discarded!
</font></font>
<p>
__HTML
	}

	$self->create_history_file;
	$self->install;
	$self->set_last_modified;

	if ( $self->{object_type_config}->{file_upload} ) {
		print <<__HTML;
<script language="JavaScript">
opener.document.location.href='$self->{object_url}&e=edit';
</script>
__HTML
	}

	NewSpirit::end_page();
	
}

#---------------------------------------------------------------------
# object_header - prints std. HTML code for the object header
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->object_header ($what)
#
#	  $what		text string for the window title
#
# DESCRIPTION:
#	This method produces the HTML code for the header section
#	of a object related window or frame.
#---------------------------------------------------------------------

sub object_header {
	my $self = shift;
	
	my ($what) = @_;
	
	NewSpirit::std_header (
		page_title => $self->{object_name},
		window_title => "$self->{object_name} ($what)",
		close => $self->{window}
	);
}

#---------------------------------------------------------------------
# save - Controls object saving, including generation of history file
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->save
#
# DESCRIPTION:
#	This method calls
#
#	  $self->save_file
#	  $self->set_last_modified
#	  $self->create_history_file
#
#	and encapsulates the whole process of saving a new.spirit
#	object this way.
#---------------------------------------------------------------------

sub save {
	my $self = shift;
	
	my $browser_update = $self->save_file;
	$self->set_last_modified;
	$self->create_history_file;

	return $browser_update;
}

#---------------------------------------------------------------------
# set_last_modified - Sets last modified information
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->set_last_modified
#
# DESCRIPTION:
#	This method sets the last modified information for
#	this object.
#---------------------------------------------------------------------

sub set_last_modified {
	my $self = shift;
	
	$self->save_meta_version ({
		last_modify_user => $self->{username},
		last_modify_date => NewSpirit::get_timestamp()
	});
}

#---------------------------------------------------------------------
# save_not_possible - Check if somebody stole our lock
#---------------------------------------------------------------------
# SYNOPSIS:
#	$boolean = $self->save_not_possible
#
# DESCRIPTION:
#	This method is called by methods which want to save object
#	data. It checks if we have write access on the object.
#	If not a corresponding error message is printed and 1 is
#	returned. Otherwise false is returned without any output.
#---------------------------------------------------------------------

sub save_not_possible {
	my $self = shift;
	
	return if $self->{write_access};
	
	$self->object_header('save error');
	
	my $lock_user = $self->{lock_info}->{username};
	my $lock_time = NewSpirit::format_timestamp($self->{lock_info}->{time});
	print qq{<table cellpadding=2 cellspacing=0 bgcolor="$CFG::ERROR_BG_COLOR">};
	print qq{<tr><td>$CFG::FONT_ERROR<b>Error: File could not be saved</b><p>};
	print qq{Object is locked by <b>$lock_user</b> since <b>$lock_time</b>!};
	print qq{</FONT></td></tr></table>\n};
	
	1;
}

#---------------------------------------------------------------------
# save_properties_ctrl - CGI event handler for the 'save_properties' event
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->save_properties_ctrl
#
# DESCRIPTION:
#	This method saves the properties and produces the
#	corresponding HTML code for the save window.
#---------------------------------------------------------------------

sub save_properties_ctrl {
	my $self = shift;

	return if $self->save_not_possible;
	
	$self->object_header ('save properties');

	# first, we load the old properties
	my $meta_href = $self->get_meta_data;
	
	# and update the modified fields
	$meta_href->{last_modify_user} = $self->{username};
	$meta_href->{last_modify_date} = NewSpirit::get_timestamp();

	# now we catch the property values from the CGI
	# query object
	my $q = $self->{q};
	my $properties = $self->{object_type_config}->{properties};
	
	foreach my $k ( keys %{$properties}, 'description', 'save_filter_cmd' ) {
		$meta_href->{$k} = $q->param($k);
	}
	
	my $error = $self->check_properties ($meta_href);

	if ( not $error ) {
		$self->save_meta_data ($meta_href);

		print <<__HTML;
$CFG::FONT
<b>Properties succesfully saved.</b>
</FONT>
<p>
__HTML
		$self->create_history_file;
		$self->install;
	} else {
		print <<__HTML;
$CFG::FONT
<b>ERROR:</b><br>
$error
<p>
<b><font color="red">Properties not saved</font>. Please correct errors first.</b>
</FONT>
<p>
__HTML
	}
	
	NewSpirit::end_page();
}

#---------------------------------------------------------------------
# save_meta_version - Saves the version part of the object meta data
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->save_meta_version ($meta_href)
#
#	  $meta_href		Hash ref of the meta data
#
# DESCRIPTION:
#	Only the following keys of $meta_href are recognized
#
#	  last_modify_date
#	  last_modify_user
#
#	and stored to the object version meta file. The internal
#	meta data cache will be updated with the passed values,
#	but only if it is already set up.
#---------------------------------------------------------------------

sub save_meta_version {
	my $self = shift;
	
	my ($meta_href) = @_;
	
	# maybe there are more keys in the href, we fetch
	# only the version keys from the hash
	my %hash = (
		last_modify_date => $meta_href->{last_modify_date},
		last_modify_user => $meta_href->{last_modify_user}
	);

	# if the internal meta cache exists, we update it
	if ( defined $self->{_meta_data} ) {
		$self->{_meta_data}->{last_modify_date} = $hash{last_modify_date};
		$self->{_meta_data}->{last_modify_user} = $hash{last_modify_user};
	}

	# store the hash to the version file
	my $version_filename = $self->{object_version_file};
	my $df = new NewSpirit::DataFile ($version_filename);
	$df->write (\%hash);
	$df = undef;
	
	1;	
}

#---------------------------------------------------------------------
# save_meta_data - Saves the given meta data of this object
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->save_meta_data ($meta_href)
#
#	  $meta_href		Hash ref of the meta data
#
# DESCRIPTION:
#	Only the keys defined in the object type configuration
#	are recognized and saved to the object meta files,
#	(splitted into two files, for version and property
#	information. The version information is ignored by
#	CVS, because they will always produce conflicts).
#
#	The internal meta data cache is updated with the passed
#	meta data.
#---------------------------------------------------------------------

sub save_meta_data {
	my $self = shift;
	
	my ($meta_href) = @_;

	my $meta_filename = $self->{object_meta_file};

	# first we write the version information
	$self->save_meta_version ($meta_href);

	# this will store *all* keys, real properties plus
	# version information, for storing in $self->{_meta_data}
	my %hash = (
		last_modify_date => $meta_href->{last_modify_date},
		last_modify_user => $meta_href->{last_modify_user}
	);

	# now the property information, the fields defined in
	# objectypes.conf, plus the 'description' field
	
	my %meta;	# this is the hash for the .m file

	my $properties = $self->{object_type_config}->{properties};
	foreach my $k ( keys %{$properties}, 'description', 'save_filter_cmd' ) {
		$meta{$k} = $meta_href->{$k};
		$hash{$k} = $meta_href->{$k};
	}

	my $df = new NewSpirit::DataFile ($meta_filename);
	$df->write (\%meta);
	$df = undef;

	$self->{_meta_data} = \%hash;

	1;
}

#---------------------------------------------------------------------
# create_history_file - Creates the history file from the acutal object
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->create_history_file
#
# DESCRIPTION:
#	A new history file is created from the actual version of
#	this object. Object data and meta data are saved to
#	the history folder.
#---------------------------------------------------------------------

sub create_history_file {
	my $self = shift;
	
	my $history_dir = $self->{object_history_dir};
	
	my $files_lref = $self->get_history_files;
	
	my $last_number = $files_lref->[@{$files_lref}-1] || 0;
	++$last_number;

	my $object_file = $self->{object_file};
	my $history_object_file = "$history_dir/$last_number";
	my $history_meta_file   = "$history_dir/$last_number.m";
	my $history_tag_file    = "$history_dir/$last_number.t";
	
	copy ($object_file, $history_object_file);
	my $meta_href = $self->get_meta_data;
	
	my $df = new NewSpirit::DataFile ($history_meta_file);
	$df->write ($meta_href);
	$df = undef;
	
	my $q = $self->{q};
	my $modification_tag = $q->param('modification_tag');
	if ( $modification_tag ne '' ) {
		my $fh = new FileHandle;
		open ($fh, "> $history_tag_file")
			or croak "can't write $history_tag_file";
		print $fh "$modification_tag\n";
		close $fh;
	}
	
	# now check if maximum history size is reached

	my $o = new NewSpirit::Object (
		q => $self->{q},
		object => $CFG::default_base_conf,
	);
	my $data = $o->get_data;

	my $max = $data->{base_history_size} || $CFG::default_history_size;
	
	if ( @{$files_lref}+1 > $max ) {
		# ok, too much stuff here
		splice (@{$files_lref}, -$max+1);
		foreach my $f ( @{$files_lref} ) {
			unlink "$history_dir/$f";
			unlink "$history_dir/$f.m";
			unlink "$history_dir/$f.t";
		}
	}
	
	1;
}

#---------------------------------------------------------------------
# history_ctrl - CGI event handler for the 'history' event
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->history_ctrl
#
# DESCRIPTION:
#	This produces the history overview page.
#---------------------------------------------------------------------

sub history_ctrl {
	my $self = shift;
	
	$self->editor_header ('history');
	
	my $page_length = 10;

	my $files_lref = $self->get_history_files;
	my $cnt = @{$files_lref};
	my $max_page = int(($cnt-1)/$page_length);

	my $page = $self->{q}->param('page');
	$page = $max_page if not defined $page or
		$page > $max_page or $page < 0;

	my $no_radio_button;
	$no_radio_button = $files_lref->[$cnt-1] if $cnt > 0;

	my $from = $page*$page_length;
	my $to = $from+$page_length-1;
	$to = $cnt - 1 if $to > $cnt - 1;
	
	my @files = @{$files_lref}[$from..$to];

	# the last entry shown is checked by default
	my $default = $files[@files-1] if @files > 0;
	
	# the fore last entry is checked, if the last shown
	# entry is the last entry of the whole stuff
	if ( $default == $no_radio_button ) {
		$default = $files[@files-2] if @files > 1;
	}

	my $object_url = $self->{object_url};
	my ($next_page, $previous_page, $delete) =
		('Next Page', 'Previous Page', 'Delete Previous Versions');

	if ( $page > 0 ) {
		$previous_page = "<a href=$object_url&e=history&page=".
				 ($page-1).">$previous_page</a>";
	}
	
	if ( $page < $max_page ) {
		$next_page = "<a href=$object_url&e=history&page=".
			     ($page+1).">$next_page</a>";
	}

	if ( $to - $from > 1 ) {
		$delete = qq{<a href="javascript:delete_versions()">$delete</a>};
	}

	print <<__HTML;
<p>
$CFG::FONT_BIG<b>History</b></FONT>
__HTML

	my $no_versions = @files > 1 ? 0 : 1;
	print qq{<input type=hidden name=no_versions value="$no_versions">};

	if ( @files ) {
		print <<__HTML;
<table $CFG::INNER_TABLE_OPTS>
<tr><td colspan="2">

<table $CFG::BG_TABLE_OPTS>
<tr><td>
  <table $CFG::TABLE_OPTS width="100%">
  <tr BGCOLOR="$CFG::INACTIVE_COLOR">
    <td>$CFG::FONT<b>&nbsp;Version&nbsp;</b></FONT></td>
    <td>$CFG::FONT<b>&nbsp;Date&nbsp;</b></FONT></td>
    <td>$CFG::FONT<b>&nbsp;Username&nbsp;</b></FONT></td>
    <td>$CFG::FONT<b>&nbsp;Version-Description&nbsp;</b></FONT></td>
    <td>$CFG::FONT<b>&nbsp;Choose&nbsp;</b></FONT></td>
  </tr>
__HTML

		foreach my $file (@files) {
			$self->history_file_entry (
				$file,
				$file == $no_radio_button,
				$file == $default
			);
		}
	
		print <<__HTML;
  </table>
  </td></tr>
</table>

</td></tr>
<tr><td>
  $CFG::FONT
  <b>
  [ $previous_page ]
  [ $next_page ]
  </b>
  </FONT>
</td><td align="right">
  $CFG::FONT
  <b>
  [ $delete ]</b></FONT></td>
</tr>
</table>  
__HTML
	} else {
		print <<__HTML;
<p>
$CFG::FONT
The history for this object is empty.
</FONT>
__HTML
	}

	$self->editor_footer;
}

#---------------------------------------------------------------------
# history_file_entry - Printing a single history file entry row
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->history_file_entry ($file, $last, $pre_last)
#
#	  $file		filename of the history file
#	  $last		name of the last history file (no radio
#			button is printed for this)
#	  $pre_last	name of the fore last history_file (the
#			button of this file is checked by default)
#
# DESCRIPTION:
#	This produces the HTML table row for the corresponding
#	history file entry.
#---------------------------------------------------------------------

sub history_file_entry {
	my $self = shift;
	
	my ($file, $last, $pre_last) = @_;
	my $history_dir = $self->{object_history_dir};

	my $df = new NewSpirit::DataFile ("$history_dir/$file.m");
	my $meta_href = $df->read;
	$df = undef;
	
	my $tag_file = "$history_dir/$file.t";
	my $tag = "&nbsp;";

	if ( -r $tag_file ) {
		my $fh = new FileHandle;
		open ($fh, $tag_file) or croak "can't read $tag_file";
		$tag = join ('', <$fh>);
		close $fh;
	}
	my $date = NewSpirit::format_timestamp ($meta_href->{last_modify_date});
	my $checked = $pre_last ? "CHECKED" : "";

	my $radio = qq{<INPUT TYPE=RADIO NAME=version VALUE="$file" $checked>};
	$radio = "" if $last;

	print <<__HTML;
  <tr>
    <td align="center">$CFG::FONT &nbsp;$file</FONT></td>
    <td>$CFG::FONT &nbsp;$date</FONT></td>
    <td>$CFG::FONT &nbsp;$meta_href->{last_modify_user}</FONT></td>
    <td>$CFG::FONT &nbsp;$tag</FONT></td>
    <td align="center">$CFG::FONT_SMALL &nbsp;$radio</FONT></td>
  </tr>
__HTML
}

#---------------------------------------------------------------------
# get_history_files - Return names of history filenames of this object
#---------------------------------------------------------------------
# SYNOPSIS:
#	$files_lref = $self->get_history_files
#
# DESCRIPTION:
#	The filename prefixes of all object history files are returned
#	as a list reference. The suffixes .m and .v are ommitted.
#---------------------------------------------------------------------

sub get_history_files {
	my $self = shift;

	return $self->{_history_files} if defined $self->{_history_files};

	my $history_dir = $self->{object_history_dir};
	
	my $dh = new FileHandle;

	opendir ($dh, $history_dir) or croak "can't open dir $history_dir";
	my @files = sort { $a <=> $b } grep (/^\d+$/, readdir($dh));
	closedir $dh;

	$self->{_history_files} = \@files;

	return \@files;
}

#---------------------------------------------------------------------
# view_header - HTML header for the object viewer (history restore)
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->view_header
#
# DESCRIPTION:
#	This produces the HTML code for the header of the history
#	restore version view page.
#---------------------------------------------------------------------

sub view_header {
	my $self = shift;

	my $q = $self->{q};
	my $version = $q->param('version');

	$self->editor_header ('view', "Restore from version $version");
	
	print <<__HTML;
<p>
$CFG::FONT_BIG<b>View object before restore</b></FONT>
__HTML

	$self->properties_table ( 1 );

	print <<__HTML;
<p>
$CFG::FONT_BIG<b>Object</b></FONT>
__HTML

	1;
}

#---------------------------------------------------------------------
# view_footer - HTML footer for the object viewer (history restore)
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->view_footer
#
# DESCRIPTION:
#	This produces the HTML code for the footer of the history
#	restore version view page.
#---------------------------------------------------------------------

sub view_footer {
	my $self = shift;

	$self->editor_footer;
}

#---------------------------------------------------------------------
# restore_ctrl - CGI event handler for the 'restore' event
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->restore_ctrl
#
# DESCRIPTION:
#	This restores a selected object version and produces
#	the corresponding HTML output for the save window.
#---------------------------------------------------------------------

sub restore_ctrl {
	my $self = shift;
	
	return if $self->save_not_possible;
	
	# restore the old file
	my $q = $self->{q};
	my $version = $q->param('version');

	my $browser_update = $self->restore ($version);

	# now print a nice page
	$self->object_header ('restore');

	print qq{$CFG::FONT Successfully restored version $version to<br><b>$self->{object_file}</b></FONT><p>\n};

	$self->create_history_file;

	# now initiate a reload of the editor page
	print <<__HTML;
<script language="JavaScript">
opener.document.location.href='$self->{object_url}&e=edit';
</script>
__HTML

	# do we need to reload the project browser?
	if ( $browser_update ) {
		print <<__HTML;
<script language="JavaScript">
  var url = opener.parent.CONTROL.PBTREE.document.location.href;
  opener.parent.CONTROL.PBTREE.document.location.href = url;
</script>
__HTML
	}

	$self->install;

	NewSpirit::end_page();
}

#---------------------------------------------------------------------
# restore - Restores a history object version
#---------------------------------------------------------------------
# SYNOPSIS:
#	$browser_update = $self->restore ($version)
#
#	  $browser_update	Boolean set to true, if the project
#				browser needs a reload
#
# DESCRIPTION:
#	This restores the specified version of the object from
#	the history.
#---------------------------------------------------------------------

sub restore {
	my $self = shift;

	my ($version) = @_;
	
	die "version missing" unless $version;

	# determine file names
	my $version_file = "$self->{object_history_dir}/$version";
	my $version_meta_file = "$version_file.m";
	
	# first the object data
	copy ($version_file, $self->{object_file})
		or croak "can't copy $version_file to $self->{object_file}";

	# then the meta data
	my $df = new NewSpirit::DataFile ($version_meta_file);
	my $meta_href = $df->read;
	$df = undef;

	$self->save_meta_data ($meta_href);

	0;
}

#---------------------------------------------------------------------
# delete_versions_ctrl - CGI event handler for the 'delete_versions' event
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->delete_versions_ctrl
#
# DESCRIPTION:
#	This deletes all object versions prior to the version
#	passed via the 'version' CGI parameter. The the
#	$self->history_ctrl method is called to print the history
#	overview page again.
#---------------------------------------------------------------------

sub delete_versions_ctrl {
	my $self = shift;
	
	my $version = $self->{q}->param('version');
	
	my $files_lref = $self->get_history_files;
	my $history_dir = $self->{object_history_dir};

	foreach my $v (@{$files_lref}) {
		if ( $v < $version ) {
			unlink (
				"$history_dir/$v",
				"$history_dir/$v.m",
				"$history_dir/$v.t"
			);
		}
	}
	
	$self->{_history_files} = undef;
	
	$self->{event} = 'history';
	$self->history_ctrl;
}

#---------------------------------------------------------------------
# download_ctrl - CGI event handler for the 'download' event
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->download_ctrl ([$mime_type])
#
#	  $mime_type		MIME TYPE to use. If ommited this value
#				is taken from §self->{object_type_config}
#
# DESCRIPTION:
#	Sends a HTTP header with the object type corresponding
#	MIME TYPE and then calls $self->print to print the object
#	data.
#---------------------------------------------------------------------

sub download_ctrl {
	my $self = shift;
	
	my ($mime_type ) = @_;
	
	$mime_type ||= $self->{object_type_config}->{mime_type};
	my $q = $self->{q};
	
	print $q->header(
		-nph => 1,
		-type => $mime_type,
		-Pragma => 'no-cache',
		-Expires => 'now'
	);

	$self->print;
}

#---------------------------------------------------------------------
# download_prod_file_ctrl - CGI event handler for the 'download_prod_file' event
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->download_prod_file_ctrl
#
# DESCRIPTION:
#	Sends a HTTP header with the object type corresponding
#	MIME TYPE and then prints the corresponding prod file of
#	this object.
#---------------------------------------------------------------------

sub download_prod_file_ctrl {
	my $self = shift;
	
	my $mime_type = $self->{object_type_config}->{mime_type};
	my $q = $self->{q};

	print $q->header(
		-nph => 1,
		-type => $mime_type,
		-Pragma => 'no-cache',
		-Expires => 'now'
	);

	my $prod_file = $self->get_install_filename;
	
	my $fh = new FileHandle;
	if ( open ($fh, $prod_file) ) {
		print STDOUT <$fh>;
		close $fh;
	} else {
		print "$prod_file not found!\n";
	}
	
	1;
}

#---------------------------------------------------------------------
# download_prod_err_file_ctrl - CGI event handler for the 'download_prod_err_file' event
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->download_prod_err_file_ctrl
#
# DESCRIPTION:
#	Sends a HTTP header with the object type corresponding
#	MIME TYPE and then prints the corresponding error prod file of
#	this object. (object filename with ext .err )
#---------------------------------------------------------------------

sub download_prod_err_file_ctrl {
	my $self = shift;
	
	my $mime_type = $self->{object_type_config}->{mime_type};
	my $q = $self->{q};

	print $q->header(
		-nph => 1,
		-type => $mime_type,
		-Pragma => 'no-cache',
		-Expires => 'now'
	);

	my $prod_file = $self->get_install_filename.".err";
	
	my $fh = new FileHandle;
	if ( open ($fh, $prod_file) ) {
		print STDOUT <$fh>;
		close $fh;
	} else {
		print "$prod_file not found!\n";
	}
	
	1;
}

#---------------------------------------------------------------------
# get_databases - Returns a hash of databases definition objects
#---------------------------------------------------------------------
# SYNOPSIS:
#	$db_href = $self->get_databases
#
# DESCRIPTION:
#	This method returns a hash of database object names defined
#	in this project. This hash ist stored in a project specific
#	file. If this file does not exist, the information will
#	be gathered from the filesystem and stored to the file.
#
#	If databases objects are created or deleted this file must
#	be updated.
#---------------------------------------------------------------------

sub get_databases {
	my $self = shift;
	
	my $databases_file = $self->{project_databases_file};
	
	if ( not -f $databases_file ) {
		# uh oh, not there yet, we must scan the source
		# tree for cipp-db files
		
		my %db_files;
		my $src_dir = $self->{project_src_dir};
		find (
			sub {
				return 1 if /^\./;
				if ( /\.cipp-db$/ ) {
					my $filename = "$File::Find::dir/$_";
					$filename =~ s!^$src_dir/!!;
					$db_files{$filename} = 'CIPP::DB_DBI';
				}
				1;
			},
			$src_dir
		);
		
		my $df = new NewSpirit::DataFile ($databases_file);
		$df->write (\%db_files);
		$df = undef;
		
		return \%db_files;
	} else {
		my $df = new NewSpirit::DataFile ($databases_file);
		return $df->read;
	}
}

#---------------------------------------------------------------------
# refresh_db_popup - Creates a new database hash file
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->refresh_db_popup
#
# DESCRIPTION:
#	The database hash file will be recreated. Then the to
#	$q->param('next_e') corresponding _ctrl method ist called.
#---------------------------------------------------------------------

sub refresh_db_popup {
	my $self = shift;
	
	my $databases_file = $self->{project_databases_file};
	unlink $databases_file;
	
	$self->get_databases;

	my $e = $self->{q}->param('next_e');
	my $method = "${e}_ctrl";

	$self->{event} = $e;
	$self->$method();
}

#---------------------------------------------------------------------
# refresh_base_configs_popup - Creates a new base configs hash file
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->refresh_base_configs_popup
#
# DESCRIPTION:
#	The base_configs hash file will be recreated. Then the to
#	$q->param('next_e') corresponding _ctrl method ist called.
#---------------------------------------------------------------------

sub refresh_base_config_popup {
	my $self = shift;
	
	my $base_configs_file = $self->{project_base_configs_file};
	unlink $base_configs_file;
	
	$self->get_base_configs;

	my $e = $self->{q}->param('next_e');
	my $method = "${e}_ctrl";

	$self->{event} = $e;
	$self->$method();
}

#---------------------------------------------------------------------
# get_base_configs - Returns a hash of base config objects
#---------------------------------------------------------------------
# SYNOPSIS:
#	$db_href = $self->get_base_configs
#
# DESCRIPTION:
#	This method returns a hash of base config object names defined
#	in this project. This hash ist stored in a project specific
#	file. If this file does not exist, the information will
#	be gathered from the filesystem and stored to the file.
#
#	If base config objects are created or deleted this file must
#	be updated.
#---------------------------------------------------------------------

sub get_base_configs {
	my $self = shift;
	
	my $base_configs_file = $self->{project_base_configs_file};
	
	if ( not -f $base_configs_file ) {
		# uh oh, not there yet, we must scan the source
		# tree for cipp-db files
		
		my %db_files;
		my $src_dir = $self->{project_src_dir};
		find (
			sub {
				return 1 if /^\./;
				if ( /\.cipp-base-config$/ ) {
					my $filename = "$File::Find::dir/$_";
					$filename =~ s!^$src_dir/!!;
					$db_files{$filename} = 1;
				}
				1;
			},
			$src_dir
		);
		
		my $df = new NewSpirit::DataFile ($base_configs_file);
		$df->write (\%db_files);
		$df = undef;
		
		return \%db_files;
	} else {
		my $df = new NewSpirit::DataFile ($base_configs_file);
		return $df->read;
	}
}

#---------------------------------------------------------------------
# get_default_database - Returns the default database object filename
#---------------------------------------------------------------------
# SYNOPSIS:
#	$default_db = $self->get_default_database
#
# DESCRIPTION:
#	This method determines the default database for this project
#	and returns the relative object filename.
#
#	The result is cached in the Object instance, so subsequent
#	calls are much faster.
#---------------------------------------------------------------------

sub get_default_database {
	my $self = shift;
	
	return $self->{__default_db} if $self->{__default_db};

	my $base_conf_object = $self->{project_base_conf};
	
	my $o = new NewSpirit::Object (
		q => $self->{q},
		object => $base_conf_object,
		base_config_object => $self->{project_base_conf}
	);
	my $data = $o->get_data;
	
	$self->{__default_db} = $data->{base_default_db};
}	

#---------------------------------------------------------------------
# rename - Rename a object
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->rename ($new_basename)
#
# DESCRIPTION:
#	This method renames the object's basename (moving to another
#	directory is actually unsupported).
#
#	All appropriate files are renamed (also the corresponding
#	install file in the prod tree), the object instance itself
#	reflects the new name after execution.
#---------------------------------------------------------------------

sub rename {
	my $self = shift;
	
	my ($new_basename) = @_;
	
	# we create a new NewSpirit::Object with the new object name
	my $new_object = $self->{object};
	my $new_object_file = $self->{object_file};
	my $old_basename = $self->{object_basename};

	$new_object =~ s/$old_basename$/$new_basename/;
	$new_object_file =~ s/$old_basename$/$new_basename/;

	# first touch the new object_file, otherwise we cannot
	# create a NewSpirit::Object for this
	
	my $fh = new FileHandle;
	open ($fh, "> $new_object_file")
		or croak "can't write $new_object_file";
	close $fh;

	# now create a object instance for the new filename
	my $new_self = new NewSpirit::Object (
		q => $self->{q},
		object => $new_object,
		base_config_object => $self->{project_base_conf}
	);

	# read old meta, store to the new object
	my $old_meta = $self->get_meta_data;
	$new_self->save_meta_data($old_meta);

	# rename history directory
	move (
		$self->{object_history_dir},
		$new_self->{object_history_dir}
	) or croak "can't move $self->{object_history_dir} to ".
		   $new_self->{object_history_dir};
		
	# move the old object file to the new object file
	move ($self->{object_file}, $new_object_file)
		or croak "can't move $self->{object_file} to $new_object_file";

	# delete old meta files
	unlink ($self->{object_meta_file})
		or croak "can't delete $self->{object_meta_file}";
	unlink ($self->{object_version_file})
		or croak "can't delete $self->{object_version_file}";

	# get old and new install filenames
	my $old_install_filename = $self->get_install_filename;
	my $new_install_filename = $new_self->get_install_filename;

	# rename the file, if one exists
	if ( $old_install_filename and $new_install_filename and
	     -f $old_install_filename ) {
		move ($old_install_filename, $new_install_filename)
			or croak "can't move $old_install_filename to ".
				 "$new_install_filename";
	}

	# reinit old instance hash from the new object hash,
	# so all subsequent operations on this object handle
	# operate with the new object
	%{$self} = %{$new_self};

	1;	
}

#---------------------------------------------------------------------
# make_install_path - Create the install path if necessary
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->make_install_path
#
# DESCRIPTION:
#	This method creates the directory for installation of the
#	object, if it not exists already.
#---------------------------------------------------------------------

sub make_install_path {
	my $self = shift;
	
	my $filename = $self->get_install_filename;
	return if not $filename;

	my $dirname = dirname $filename;
	
	return if -d $dirname;
	
	mkpath ( [$dirname], 0, 0775 )
		or croak "can't create directory '$dirname'";

	1;
}

#---------------------------------------------------------------------
# install - Controls object installation
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->install
#
# DESCRIPTION:
#	This method controls the installation process and produces
#	some status output for the save window.
#	It calls $self->install_file for the real installation stuff.
#
#	If the $self->{dependency_installation} flag is false
#	or non existant, the following methods are called to
#	create some progress output:
#	
#		$self->print_pre_install_message
#		$self->print_install_errors
#		$self->print_post_install_message
#---------------------------------------------------------------------

sub install {
	my $self = shift;
	
	my $verbose = not $self->{dependency_installation};
#	$verbose = 0 if $self->{command_line_mode};

	$verbose && $self->print_pre_install_message;

	# create cached Depend object, to be reused by several methods
	$self->get_depend_object (1);

	$self->make_install_path;
	my $ok = $self->install_file;

	if ( not $ok ) {
		$verbose && $self->print_install_errors;

	} elsif ( $self->dependency_installation_needed ) {

		$verbose && $self->print_post_install_message;

		if ( $self->{q}->param('e') !~ /without_dep$/ and
		     $NewSpirit::Object::object_types
		       ->{$self->{object_type}}
		       ->{depend_install_object_types} ) {
		
			$verbose && $self->print_depend_install_message;

			$verbose && print "$CFG::FONT_FIXED<BLOCKQUOTE>\n";

			my $successful = $self->install_dependant_objects;
		
			$verbose && print "</FONT></BLOCKQUOTE>\n";

			if ( $verbose and $self->{dependency_installation_errors} ) {
				print "$CFG::FONT<FONT COLOR=red>",
				      "<b>Some objects have errors</b>",
				      "</FONT><p>";
	
				foreach my $object (
				    sort keys
				    %{$self->{dependency_installation_errors}} ) {
					print "<p>$CFG::FONT<b>",
					      $self->dotted_notation ($object),
					      "</b></FONT><br>\n";
					$self->print_install_errors (
						$self->{dependency_installation_errors}
						     ->{$object}
					);
				}
			}
			
			if ( $verbose and not $self->{dependency_installation_errors}
			     and $successful) {
				print "$CFG::FONT",
				      "<b>Congratulations. All objects installed OK!</b>",
				      "</FONT><p>";
			}
			
			if ( not $successful ) {
				print "$CFG::FONT<font color=red>",
				      "<b>Some objects have errors</b>",
				      "</font></FONT><p>";
			}
			
			if ( $verbose ) {
				print "<script>self.window.scroll(0,5000000)</script>\n";
				print "<script>self.window.scroll(0,5000000)</script>\n";
			}
		}

		$self->execute_save_filter;

	} else {
		$verbose && $self->print_post_install_message;
	}

	# delete cached Depend object
	$self->clear_depend_object;

	return $ok;
}

#---------------------------------------------------------------------
# install_file - Install a object file into the prod tree
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->dependency_installation_needed
#
# DESCRIPTION:
#	This method checks, if a dependency installation is needed
#	or not. This implementation returns always true, but derived
#	classes may override this behaviour.
#
#---------------------------------------------------------------------

sub dependency_installation_needed {
	return 1;
}

#---------------------------------------------------------------------
# install_file - Install a object file into the prod tree
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->install_file
#
# DESCRIPTION:
#	This method could be defined by the subclasses. It does
#	all necessary things to install a object into the prod tree.
#	This default method copies the source file without changes
#	to the corresponding prod file destination.
#---------------------------------------------------------------------

sub install_file {
	my $self = shift;

	return 2 if $self->is_uptodate;
	$self->{install_errors} = [];

	my $from_file = $self->{object_file};
	my $to_file = $self->get_install_filename;
	
	return 1 if not $to_file;

	copy ($from_file, $to_file)
		or push @{$self->{install_errors}},
		   "Can't copy '$from_file' to '$to_file': $!";

	return @{$self->{install_errors}} == 0;
}

#---------------------------------------------------------------------
# print_install_errors - Print installation errors
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->print_install_errors ( [$errors} )
#
# DESCRIPTION:
#	This method prints installation errors HTML formatted.
#	It presumes that $self->{install_errors} is list ref
#	of scalars which are printed without special formatting.
#
#	If $errors is given it is used instead of
#	$self->{install_errors}.
#---------------------------------------------------------------------

sub print_install_errors {
	my $self = shift;

	# HINT:    this method is overwritten by NewSpirit::CIPP::Prep.
	#          so look there, if you search error output of CIPP
	#	   objects or dependency installation

	my ($errors) = @_;
	$errors ||= $self->{install_errors};

	print <<__HTML;
$CFG::FONT<FONT COLOR="red">
<b>There are installation errors:</b>
</FONT></FONT>
<p>
__HTML
	print qq{<FONT SIZE="$CFG::FONT_SIZE"><pre>\n};
	foreach my $err ( @{$errors} ) {
		print "$err\n";
	}
	print "</pre></FONT>\n";

	1;
}

#---------------------------------------------------------------------
# install_dependant_objects - Installs objects that depend on this object
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->install_dependant_objects
#
# DESCRIPTION:
#	This method installs all objects that depend on this object.
#---------------------------------------------------------------------

sub install_dependant_objects {
	my $self = shift;
	
	return 1 if $self->{no_dependency_installation};
	
	# determine all dependant objects (with resolving of
	# hierarchical dependency structures)

#	my $dep_href = $self->get_dependant_objects ( resolved => 1 );
	
	my $dep_href = $self->get_compile_dependant_objects;

#	NewSpirit::dump($dep_href);
	
	# first reorder the dependency list by type
	my %dep_by_type;
	foreach my $ot (keys %{$dep_href}) {
		# only 'true' entries are processed. The 'false'
		# one are entries, where the recursion walked through,
		# but these objects need not to be installed!
		next if not $dep_href->{$ot};
		my ($object, $type) = split (':', $ot, 2);
		push @{$dep_by_type{$type}}, $object;
	}

#	use Data::Dumper; print "<pre>",Dumper(\%dep_by_type),"</pre>\n";
#	exit;

#	NewSpirit::dump(\%dep_by_type);

	# this is the list of object types which are known
	# to be relevant for dependency installation
	my $depend_type_list = 	$NewSpirit::Object::object_types
				->{$self->{object_type}}
				->{depend_install_object_types};

	# make a copy
	my @depend_type_list = @{$depend_type_list};

	# Now calculate the number of objects to install
	# Our dependency hash lists all objects, which depend on us,
	# but not all of them need to be installed (e.g. if an
	# Include depends on an Include)
	my $object_cnt = 0;
	
	foreach my $type ( @depend_type_list ) {
		next if not $dep_by_type{$type};
		$object_cnt += @{$dep_by_type{$type}};
	}

	# now iterate over the depend_install_object_types
	# list of our object type

	my $nr = 0;
	my $some_dependent_objects_has_errors = 0;

	my $last_scrolling_time = time;

	my $successful = 1;

	foreach my $type ( @depend_type_list ) {
		next if not $dep_by_type{$type};
		
		print "<p><b>",
		      $NewSpirit::Object::object_types
		      	->{$type}
			->{name},
		      "</b><br>";
		
		foreach my $object ( sort @{$dep_by_type{$type}} ) {
			++$nr;
			my $nr_str = "$nr/$object_cnt&nbsp;";
			print $nr_str, ("." x (16-length($nr_str))), "&nbsp;";
			
			# create NewSpirit::Object instance for this object
			my $o;
			eval {
				$o = new NewSpirit::Object (
					q => $self->{q},
					object => $object,
					base_config_object => $self->{project_base_conf}
				);
			};
			my $exc = $@;

			# this is for progress output
			my $print_object = $self->dotted_notation ($object);

			# catch "object does not exist" exception
			if ( $exc =~ /^object_does_not_exist\t(.*)/ ) {
				print "<FONT COLOR=red><B>NOT&nbsp;OK</B></FONT>&nbsp;&nbsp;$print_object<BR>\n";
				$self->{dependency_installation_errors}->{$object}
				     ->{formatted} = \"$1";
				next;
			} else {
				die $@ if $@;
			}
			
			if ( $self->{no_child_dependency_installation} ) {
				# ok, our childs should initiate no
				# dependency installation themself
				$o->{no_dependency_installation} = 1;
			}


			$o->{no_dependency_installation} = 1;

		
			# transfer the cached Depend object to the new
			# NewSpirit::Object instance
			$o->{Depend} = $self->{Depend};

			# set object into dependency_install state
			# (this mutes verbosity of the subsequent
			#  installation procedures)
			$o->{dependency_installation} = 1;

			my $ok = $o->install;
		
			# if this object did not installed ok, record its errors
			# in our dependency_installation_errors hash
			if ( not $ok ) {
				$self->{dependency_installation_errors}->{$object}
					= $o->{install_errors};
				$some_dependent_objects_has_errors = 1;
			}
		
			# now we copy all dependency errors of our child
			# to our dependency_installation_errors hash
			my ($k,$v);
			while ( ($k, $v) =
			  each %{$o->{dependency_installation_errors}} ) {
				$self->{dependency_installation_errors}->{$k}
					= $v;
			}
		
			# progress information
			if ( $ok == 1) {
				print "<FONT COLOR=green><B>OK</B></FONT>&nbsp;......&nbsp;$print_object<br>\n";
			} elsif ( $ok == 2 ) {
				print "<FONT COLOR=green><B>CACHED</B></FONT>&nbsp;..&nbsp;$print_object<br>\n";
			} elsif ( $ok == -1 ) {
				print "<FONT COLOR=orange><B>INC&nbsp;ERR</B></FONT>&nbsp;.&nbsp;$print_object<br>\n";
			} else {
				print "<FONT COLOR=red><B>NOT&nbsp;OK&nbsp;</B></FONT>..&nbsp;$print_object<br>\n";
			}

			$successful = 0 if $ok != 1 and $ok != 2;

			if ( time - $last_scrolling_time > 1 ) {
				$last_scrolling_time = time;
				print "<script>self.window.scroll(0,5000000)</script>\n";
				print "<script>self.window.scroll(0,5000000)</script>\n";
			}

		}
	}
	
	return $successful;
}


#---------------------------------------------------------------------
# update_dependencies - Updates dependencies for this object
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->update_dependencies ( $depend_href )
#
# DESCRIPTION:
#	This updates the project wide dependency database.
#	$depend_href is a hash of object names, on which the
#	actual object depends on.
#
#	If the instance variable $self->{Depend} exists,
#	this is assumed to be an NewSpirit::Depend instance
#	for this project. In this case no new instance is created.
#---------------------------------------------------------------------

sub update_dependencies {
	my $self = shift;
	
	my ($depend_href) = @_;

	my $depend = $self->get_depend_object;
	
	$depend->update (
		"$self->{object}:$self->{object_type}",
		$depend_href
	);

	1;
}


#---------------------------------------------------------------------
# dependencies_ctrl - CGI event handler for the 'dependencies' event
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->dependencies_ctrl
#
# DESCRIPTION:
#	This Method controls the output of the dependencies
#	known for this object.
#
#---------------------------------------------------------------------

sub dependencies_ctrl {
	my $self = shift;
	
	my $q = $self->{q};
	
	my $depends_on_level = $q->param('depends_on_level') || 1;
	my $dependants_level = $q->param('dependants_level') || 1;
	
	# header
	$self->object_header ('dependencies');
	
	# javascript for editor open
	print <<__HTML;
<script>
  function open_editor (obj) {
    window.opener.document.location.href=
    	'$CFG::object_url?ticket=$self->{ticket}&project=$self->{project}&'+
	'e=edit&object='+obj;
  }
</script>
__HTML

	# create NewSpirit::Depend instance
	my $depend = new NewSpirit::Depend (
		$self->{project_depend_dir}
	);

	# who am I? (object name + object type)
	my $me = $self->get_show_depend_key;

	# check whether I depend on something
	my $i_depend_on = $depend->get_depends_on ($me);

	if ( $i_depend_on ) {
		my $new_level = $depends_on_level + 1;
		print   "$CFG::FONT<b>This object requires:</b>\n";
		print "<br>\n";
		print qq{( <b><a href="$self->{object_url}&e=dependencies&window=1&depends_on_level=$new_level">INCREASE</a></b>\n};
		print "or\n";
		print qq{<b><a href="$self->{object_url}&e=dependencies&window=1&depends_on_level=1">RESET</a></b>\n};
		print qq{dependency level )};
		print   "<p></font>\n";

		print "<pre><font size=$CFG::FONT_SIZE><tt>";
		$self->print_dependencies (
			$depend,
			$me,
			'depends_on',
			'    ',	# start indent string
			{ $me => 1 },
			0,
			$depends_on_level
		);
		print "</pre>";
	}

	# check whether someone depends on me
	my $my_dependants = $depend->get_dependants ($me);

#	NewSpirit::dump ($my_dependants);

	if ( $my_dependants ) {
		my $new_level = $dependants_level + 1;
		print "$CFG::FONT<b>These objects require $self->{object_name}:</b>";
		print "<br>\n";
		print qq{( <b><a href="$self->{object_url}&e=dependencies&window=1&dependants_level=$new_level">INCREASE</a></b>\n};
		print "or\n";
		print qq{<b><a href="$self->{object_url}&e=dependencies&window=1&dependants_level=1">RESET</a></b>\n};
		print qq{dependency level )};
		print   "<p></font>\n";

		print "<pre><font size=$CFG::FONT_SIZE><tt>";
		$self->print_dependencies (
			$depend,
			$me,
			'dependants',
			'    ',	# start indent string
			{ $me => 1 },
			0,
			$dependants_level
		);
		print "</tt></font></pre>";
	}

	if ( not $i_depend_on and not $my_dependants ) {
		print "$CFG::FONT<b>There are no dependencies for ",
		      "this object.</b></FONT>\n";
	}

	# end page
	NewSpirit::end_page();
}

#---------------------------------------------------------------------
# get_show_dependency_key - returns key for dependency browser
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->get_show_dependency_key
#
# DESCRIPTION:
#	Returns the Key for the dependency browser of this
#	object. May be overridden by derived classes, for
#	special handling (e.g. default databases, see
#	NewSpirit::CIPP::DB).
#---------------------------------------------------------------------

sub get_show_depend_key {
	my $self = shift;
	return "$self->{object}:$self->{object_type}";
}

#---------------------------------------------------------------------
# print_dependencies - Recursive method for printing dependencies
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->print_dependencies
#
# DESCRIPTION:
#	This Method prints the dependencies for a specific object.
#	It calls itself recursively to resolve dependencies of
#	deeper objects.
#---------------------------------------------------------------------

sub print_dependencies {
	my $self = shift;
	
	my ($depend, $me, $dep_type, $indent, $visited,
	    $no_edit_links, $levels_left) = @_;

	--$levels_left;

	my $method = "get_$dep_type";
	my $dep = $depend->$method ($me);

	return if not $dep;

	# extract type from dependency entry and build a hash
	# assigning each object its type
	
	my %object;
	foreach my $ot (keys %{$dep}) {
#		next if $ot =~ m!^__!;
		next if $visited->{$ot};

		my ($object, $type) = split (":", $ot, 2);
		
		# special handling of the default database
		if ( $object eq '__default.cipp-db' ) {
			$object = $self->get_default_database
				|| " Default Database";
			# this blank before " Default ..." supresses
			# printing "project.Default Database" in the
			# dependency list
		}
		
		$object{$object} = $type;
	}
	
	# now print the objects sorted by name
	foreach my $o (sort { lc($a) cmp lc($b) } keys %object) {
		# determine real name of the object type

		my $type_text = $NewSpirit::Object::object_types
					->{$object{$o}}
					->{name};

		# first print the indent string
		print $indent;
		
		# now the object name followed be its type
		my $print_o = $o;
		$print_o =~ s/\.[^\.]+$//;

		# check for error
		my $err_file = $print_o;
		$err_file = "$self->{project_meta_dir}/##cipp_dep/$err_file.err";

		$print_o =~ s!/!.!g;
		$print_o = "$self->{project}.$print_o";

		if ( -f $err_file ) {
			$print_o = qq{<b><font color=red>$print_o</font></b>};
		}

		if ( $print_o =~ s/^\s+// ) {
			$print_o = qq{<b><font color=red>$print_o</font></b>};
		} else {
			$print_o = qq{<b>$print_o</b>};
			if ( not $no_edit_links ) {
				$print_o = qq{<a href="javascript:open_editor('$o')">}.
					   qq{$print_o</a>};
			}
		}
		
		print "$print_o ($type_text)\n";
		$visited->{"$o:$object{$o}"} = 1;

			
		# we go into recursion to resolve dependencies
		# for this object, as long as no_recursion is not set

		if ( $levels_left ) {
			$self->print_dependencies (
				$depend,
				"$o:$object{$o}",
				$dep_type,
				"$indent    ",
				$visited,
				$no_edit_links,
				$levels_left
			);
		}
#		delete $visited->{$me};
	}
}

#---------------------------------------------------------------------
# get_depend_object - Returns a NewSpirit::Depend object
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->get_depend_object ( $make_permanent )
#
# DESCRIPTION:
#	This method returns a reference to a NewSpirit::Depend
#	object for the objects project.
#
#	If $make_permanent is given, the instance is stored in
#	$self->{Depend} to make it permanent. Subsequent calls
#	to $self->get_depend_object will return this cached
#	instance instead of creating a new one.
#---------------------------------------------------------------------

sub get_depend_object {
	my $self = shift;

	my ($make_permanent) = @_;

	# we disable make_permanent here. otherwise the whole
	# project is locked while big compilations :(

	$make_permanent = 0;

	return $self->{Depend} if $self->{Depend};
	
	my $depend = new NewSpirit::Depend (
		$self->{project_depend_dir}
	);
	
	$self->{Depend} = $depend if $make_permanent;
	
	return $depend;
}

#---------------------------------------------------------------------
# clear_depend_object - Clears internal cache for Depend object
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->clear_depend_object
#
# DESCRIPTION:
#	This method clears the internal cache for a NewSpirit::Depend
#	created using $self->get_depend_object( $make_permanent = 1).
#---------------------------------------------------------------------

sub clear_depend_object {
	my $self = shift;
	
	$self->{Depend} = undef;
	
	1;
}

#---------------------------------------------------------------------
# get_dependant_objects - Returns a hashref with all dependant objects
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->get_dependant_objects
#
# DESCRIPTION:
#	This method returns a reference to a hash containing
#	all objects, which depend on this object.
#---------------------------------------------------------------------

sub get_dependant_objects {
	my $self = shift;

	my %par = @_;
	my $resolved = $par{resolved};

	my $depend = $self->get_depend_object;

	if ( $par{resolved} ) {
		my %hash;
		$depend->get_dependants_resolved (
			"$self->{object}:$self->{object_type}", \%hash
		);
		return \%hash;
	} else {		
		return $depend->get_dependants (
			"$self->{object}:$self->{object_type}"
		);
	}
}

#---------------------------------------------------------------------
# get_compile_dependant_objects - Returns a hashref with all objects
#		which must be compiled if this object changes
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->get_compile_dependant_objects
#
# DESCRIPTION:
#	This method returns a reference to a hash containing
#	all objects, which need to be compiled if this object
#	changes.
#---------------------------------------------------------------------

sub get_compile_dependant_objects {
	my $self = shift;

	my %par = @_;
	my $resolved = $par{resolved};

	my $depend = $self->get_depend_object;

	# first get direct dependent objects
	my $compile_objects = $depend->get_dependants (
		"$self->{object}:$self->{object_type}"
	);

	my @resolve_objects = keys %{$compile_objects};

	# now follow their dependencies, if this is needed
	my %seen; # prevent endless loop in case of recursive inclusion
	while ( @resolve_objects ) {
		my $object = pop @resolve_objects;
		my ($name, $type) = split (":", $object);

		# only includes needs to be analyzed --------------
		next if $type ne 'cipp-inc';
		next if $seen{$object};
		
		$seen{$object} = 1;
	
		# get dependants
		my $dependants = $depend->get_dependants ($object);
		
		# push them on our work list
		push @resolve_objects, keys %{$dependants};
		
		# add them to our %compile_objects hash
		foreach my $item ( keys %{$dependants} ) {
			$compile_objects->{$item} = 1;
		}
	}
	
	return $compile_objects;
}

#---------------------------------------------------------------------
# create_ctrl - Control creation of a new object
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->create_ctrl
#
# DESCRIPTION:
#	This method controls the creation of a new object. It calls
#	$self->create to do the real creation stuff, this method
#	must be implemented by subclasses.
#---------------------------------------------------------------------

sub create_ctrl {
	my $self = shift;
	
	$self->object_header ('create object');

	# first check, if an object with this name already exists

	my $create_error;
	my $object_wo_ext = "$self->{project_src_dir}/$self->{object_wo_ext}";

	my $check_lref = NewSpirit::filename_glob (
		dir => dirname($object_wo_ext),
		regex => "^".basename($object_wo_ext).'\..*'
	);
	
	# A .m file may exists already for this object (image objects
	# create a .m file very early through their init() method)
	if ( grep (!/\.m$/, @{$check_lref}) ) {
		$create_error = "Object or directory already exists!<br>";
	} else {
		# Ok, create the object using its create method.
		$create_error = $self->create;
	}

	if ( not $create_error ) {
		# chmod the file
		chmod 0664, $self->{object_file};
		
		# Now initialize meta data.
		
		# First read meta data, this will set the defaults,
		# if there is no meta data or loads the meta data
		# copied from an object type template, if there was one.
		my $meta_href = $self->get_meta_data;
		
		# set modifiy and description fields
		$meta_href->{last_modify_user} = $self->{username};
		$meta_href->{last_modify_date} = NewSpirit::get_timestamp();
		$meta_href->{description} = $self->{q}->param('description');
		
		# write meta data to file
		$self->save_meta_data ($meta_href);
	}

	if ( $create_error ) {
		# print error message
		print qq{<table cellpadding=2 cellspacing=0 bgcolor="$CFG::ERROR_BG_COLOR">};
		print qq{<tr><td>$CFG::FONT_ERROR<b>Error creating or saving file to };
		print qq{$self->{object_file}!</b><p>Error message:<br><b>$create_error</b></FONT><p>\n};
		print qq{</td></tr></table>\n};
	} else {
		# print success message and "edit" button
		print qq{$CFG::FONT Object has been successfully created and }.
		      qq{saved to<br><b>$self->{object_file}</b></FONT><p>\n};

		print qq[<script>function open_editor () {],
		      qq[window.opener.document.location.href=],
		      qq['$self->{object_url}&e=edit'; }</script>];

		print qq{<a href="javascript:open_editor()">},
		      qq{$CFG::FONT<b>[ EDIT OBJECT ]</b></FONT>},
		      qq{</a>\n};

		print qq{<script>},
		      qq{window.opener.parent.CONTROL.PBTREE.location.href=},
		      qq{'$CFG::pbrowser_url?project=$self->{project}&},
		      qq{ticket=$self->{ticket}&jump_object=$self->{object}#jump';},
		      qq{</script>\n};
	}

	NewSpirit::end_page();
}

#---------------------------------------------------------------------
# create - create new object from scratch or from a template
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->create
#
# DESCRIPTION:
#	This method creates the object files for a new object using
#	templates if existing.
#---------------------------------------------------------------------

sub create {
	my $self = shift;
	
	# create from template, if one exists for this object type

	# first: try a project specific templates
	my $template_file
		= "$self->{project_template_dir}/$self->{object_type}.$self->{object_type}";
	my $template_meta_file
		= "$self->{project_template_dir}/$self->{object_type}.$self->{object_type}.m";

	copy ($template_file, $self->{object_file})
		if -r $template_file;
	copy ($template_meta_file, $self->{object_meta_file})
		if -r $template_meta_file;

	return if -r $self->{object_file};
	
	# then system wide template
	$template_file
		= "$CFG::template_dir/$self->{object_type}.template";
	$template_meta_file
		= "$CFG::template_dir/$self->{object_type}.meta";
	
	copy ($template_file, $self->{object_file})
		if -r $template_file;
	copy ($template_meta_file, $self->{object_meta_file})
		if -r $template_meta_file;

	return if -r $self->{object_file};

	# otherwise create an empty file

	my $fh = new FileHandle;
	open ($fh, "> $self->{object_file}")
		or return "Can't create file '$self->{object_file}'";
	close $fh;

	return;
}

#---------------------------------------------------------------------
# delete_ask_ctrl - Control confirmation of object deletion
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->delete_ask_ctrl
#
# DESCRIPTION:
#	This method controls the creation the confirmation of
#	object deletion.
#---------------------------------------------------------------------

sub delete_ask_ctrl {
	my $self = shift;
	
	$self->editor_header;

	$self->delete_ask_info;

	print <<__HTML;
<p>
$CFG::FONT
<font color="red">
<b>Do you really want to delete this object?</b>
</font>
<b>
&nbsp;&nbsp;&nbsp;
<p>
<blockquote>
  <a href="$self->{object_url}&e=edit">NO - go back to the editor</a>
  <p>
  <a href="$self->{object_url}&e=delete">YES - but leave history files untouched</a>
  <p>
  <a href="$self->{object_url}&e=delete&with_history=1">YES - including history files</a>
</blockquote>
</b>
</font>
__HTML

	NewSpirit::end_page();
}

#---------------------------------------------------------------------
# delete_ask_info - Prints deletion confirmation info
#                   (e.g. dependencies)
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->delete_ask_info
#
# DESCRIPTION:
#	This method can be overloaded by subclasses to implement
#	object type specific behaviour.
#---------------------------------------------------------------------

sub delete_ask_info {
	my $self = shift;
	
	my $depend = new NewSpirit::Depend (
		$self->{project_depend_dir}
	);

	my $me = "$self->{object}:$self->{object_type}";

	# check whether someone depends on me
	my $my_dependants = $depend->get_dependants ($me);

	if ( $my_dependants ) {
		print "<p>$CFG::FONT<b>These objects depend on $self->{object_name}:",
		      "</b></FONT><p>\n";
		print "<pre><font size=$CFG::FONT_SIZE><tt>";
		$self->print_dependencies (
			$depend,
			$me,
			'dependants',
			'    ',	# start indent string
			{ $me => 1 },
			1,
			1
		);
		print "</tt></font></pre>\n";
	}
}

#---------------------------------------------------------------------
# delete_ctrl - Control object deletion
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->delete_ctrl
#
# DESCRIPTION:
#	This method controls object deletion. It calls $self->delete
#	to do the real stuff, so object type specific behaviour
#	can be implemented by overloading $self->delete.
#---------------------------------------------------------------------

sub delete_ctrl {
	my $self = shift;
	
	$self->object_header;
	$self->delete;

	my $r = rand(42000);

	print <<__HTML;
<br>
$CFG::FONT
<font color="red">
<b>Object deleted!</b>
</font>
</font>

<script language="JavaScript">
  parent.CONTROL.PBTREE.document.location.href =
  	'$CFG::pbrowser_url?project=$self->{project}&'+
	'ticket=$self->{ticket}&r=$r&'+
	'e=open&dir=$self->{project}/$self->{object_rel_dir}#jump';
</script>
__HTML


	NewSpirit::end_page();
}

#---------------------------------------------------------------------
# delete - Delete a object
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->delete
#
# DESCRIPTION:
#	Physical deletion of an object.
#---------------------------------------------------------------------

sub delete {
	my $self = shift;
	
	my $q = $self->{q};
	
	my $with_history = $q->param('with_history');
	
	print $CFG::FONT;

	print "updating dependency database...<br>\n";
	my $depend = $self->get_depend_object;
	$depend->delete_object ("$self->{object}:$self->{object_type}");
	$depend = undef;

	print "deleting source files...<br>\n";
	
	unlink $self->{object_file};
	unlink $self->{object_meta_file};
	unlink $self->{object_version_file};
	
	if ( $with_history ) {
		print "deleting history files...<br>\n";
		rmtree ( [$self->{object_history_dir}]);
	}

	print "deleting prod file...<br>\n";

	unlink $self->get_install_filename;
	
	$self->unset_lock;

	print "</font>\n";

	1;
}

#---------------------------------------------------------------------
# init - Stub - Initialization method for subclassed modules
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->init
#
# DESCRIPTION:
#	This method is called from the constructor, just after the
#	object instance is created. Subclasses can implement this
#	to perform additional initialization tasks, e.g. add new
#	variables to the object instance hash.
#---------------------------------------------------------------------

sub init {
	1;
}

#---------------------------------------------------------------------
# convert_meta_from_spirit1 - Stub - Convert old spirit meta data
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->convert_meta_from_spirit1 ($old_meta, $new_meta)
#
#	  $old_meta		source hash with old meta values
#	  $new_meta		target hash with new meta values
#
# DESCRIPTION:
#	This method should be implemented by subclasses to convert
#	object type specific meta data.
#---------------------------------------------------------------------

sub convert_meta_from_spirit1 {
	1;
}

#---------------------------------------------------------------------
# convert_data_from_spirit1 - Stub - Convert old spirit object data
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->convert_data_from_spirit1
#
# DESCRIPTION:
#	This method should be implemented by subclasses to convert
#	object type specific object data.
#---------------------------------------------------------------------

sub convert_data_from_spirit1 {
	1;
}

#---------------------------------------------------------------------
# edit_ctrl - Stub - CGI event handler for the 'edit' event
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->edit_ctrl
#
# DESCRIPTION:
#	This method should be defined by the subclasses. It does
#	all necessary things to produce a editor page for the object.
#---------------------------------------------------------------------

sub edit_ctrl {

	print "no editor defined";

	1;
}

#---------------------------------------------------------------------
# view_ctrl - Stub - CGI event handler for the 'view' event
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->view_ctrl
#
# DESCRIPTION:
#	This method should be defined by the subclasses. It does
#	all necessary things to produce a viewer page for the object.
#---------------------------------------------------------------------

sub view_ctrl {

	print "no viewer defined";

	1;
}

#---------------------------------------------------------------------
# get_install_filename - Stub - Returns prod filename of object
#---------------------------------------------------------------------
# SYNOPSIS:
#	$filename = $self->get_install_filename
#
# DESCRIPTION:
#	This method should be defined by the subclasses. It returns
#	the corresponding filename for installation in the prod tree.
#	It may explicitely return undef to indicate, that
#	installation of the file is undesired.
#---------------------------------------------------------------------

sub get_install_filename {
	croak "get_install_filename() not implemented!";
}

#---------------------------------------------------------------------
# print_pre_install_message - Stub - Print message befor installing
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->print_pre_install_message
#
# DESCRIPTION:
#	This method could be defined by the subclasses. It is called
#	before $self->install_file to print a message, that the
#	installation is in progress.
#---------------------------------------------------------------------

sub print_pre_install_message {
	print "$CFG::FONT Processing...</FONT><p>\n";
	
	1;
}

#---------------------------------------------------------------------
# print_post_install_message - Stub - Print message after installing
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->print_post_install_message
#
# DESCRIPTION:
#	This method could be defined by the subclasses. It is called
#	after $self->install_file to print a message, that the
#	installation was succesful.
#---------------------------------------------------------------------

sub print_post_install_message {
	my $self = shift;
	
	my $to_file = $self->get_install_filename;
	
	if ( $to_file ) {
		my $download_link =
			qq{<a href="$self->{object_url}&e=download_prod_file&}.
			qq{no_http_header=1">[DOWNLOAD]</a>};

		print "$CFG::FONT<p>",
		      "Successfully installed to<br><b>$to_file ",
		      "$download_link</b></FONT>\n";
	} else {
		print "$CFG::FONT<p>",
		      "<b>Object successfully processed.</b>",
		      "</FONT>\n";
	}

	1;
}

#---------------------------------------------------------------------
# print_depend_install_message - Stub - Print message before depend inst
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->print_post_install_message
#
# DESCRIPTION:
#	This method could be defined by the subclasses. It is called
#	after $self->install_file to print a message, that the
#	installation was succesful.
#---------------------------------------------------------------------

sub print_depend_install_message {
	my $self = shift;
	
	print "<p>$CFG::FONT<b>Dependency processing</b></FONT><p>";
}

#---------------------------------------------------------------------
# canonify_object_name - Canonifies dotted object name notation
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->canonify_object_name ($object_name)
#
# DESCRIPTION:
#	Replaces the project part of the given object name with
#	the project of this instance.
#---------------------------------------------------------------------

sub canonify_object_name {
	my $self = shift;
	
	my ($object) = @_;
	
	my $project = $self->{project};
	
	$object =~ s/^[^\.]+/$project/;
	
	return $object;
}

#---------------------------------------------------------------------
# check_properties - Checks if the given object properties are correct
#---------------------------------------------------------------------
# SYNOPSIS:
#	$error = $self->check_properties ( $meta_href )
#
# DESCRIPTION:
#	This method returns an error message, if the given property
#	data is not valid for this object. Returns nothing by default
#	and can be implemented by object type specifiy subclasses.
#---------------------------------------------------------------------

sub check_properties {
	my $self = shift;
	
	return;
}

#---------------------------------------------------------------------
# get_object_src_file - returns the source file to a given object name
#---------------------------------------------------------------------
# SYNOPSIS:
#	$object_src_file = $self->get_object_src_file (
#		$object_name [ , $project_src_dir ]
#	);
#
# DESCRIPTION:
#	The $object_name (dotted notation) is translated to the
#	object source file. If the object does not exist, undef
#	will be returned.
#
#	If $project_src_dir is not passed, $self->{project_src_dir}
#	ist used.
#---------------------------------------------------------------------

sub get_object_src_file {
	my $thing = shift;
	
	my ($object_name, $project_src_dir) = @_;

	my $src_file = $object_name;

	$src_file =~ s/^[^\.]+\.//;
	$src_file =~ s!\.!/!g;
	
	$project_src_dir ||= $thing->{project_src_dir};
	$src_file = "$project_src_dir/$src_file";
	
	my $dir  = dirname $src_file;
	my $file = basename $src_file;

#	print "object=$object_name dir=$dir file=$file<p>\n";
	
	my $filenames_lref = NewSpirit::filename_glob (
		dir => $dir,
		regex => "^$file\\.[^\.]+\$",
	);
	
#	NewSpirit::dump($filenames_lref);
	
	if ( @{$filenames_lref} > 1 ) {
		die "object name '$object_name' is ambigious";
	} elsif ( not @{$filenames_lref} ) {
		return;
	}
	
	return $filenames_lref->[0];
}

#---------------------------------------------------------------------
# is_uptodate - checks if prod file is newer than src file
#---------------------------------------------------------------------
# SYNOPSIS:
#	$ok = $self->is_uptodate
#
# DESCRIPTION:
#	Returns true if the prod file is newer than src file.
#
#---------------------------------------------------------------------

sub is_uptodate {
	my $self = shift;
	
	my $src_file  = $self->{object_file};
	my $prod_file = $self->get_install_filename;
	
	return 1 if (stat($src_file))[9] < (stat($prod_file))[9];
	return;
}

sub dump {
	my $self = shift;
	my @par = @_;
	
	if ( @par ) {
		print "<pre>",Dumper(@par),"</pre>\n";
	} else {
		print "<pre>",Dumper($self),"</pre>\n";
	}
	
	1;
}

1;
