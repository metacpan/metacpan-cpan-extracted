package NewSpirit::Object::Install;

#---------------------------------------------------------------------
# This special object class is for installing bunches of
# objects or installing the whole project.  The corresponding
# new.spirit object type 'depend-all' claims to be the
# mother of all installable objects, that means all installable
# objects are configured to be dependent from 'depend-all'.
#
# So $self->install_dependant_objects will do the work for us!
# We only have to implement the $self->get_dependant_objects
# that way, that the correct list of objects is returned.
#
# This class will never be called through nph-object.cgi. The
# special CGI program nph-install.cgi interfaces to this class
# instead. This way we can implement additional, non NewSpirit::Object
# methods, which are directly accessible through the corresponding
# CGI events, which are known by nph-install.cgi but not by
# nph-object.cgi.
#---------------------------------------------------------------------

$VERSION = "0.01";
@ISA = qw ( NewSpirit::CIPP::Prep );

use strict;
use Carp;

use NewSpirit::CIPP::Prep;
use File::Find;
use File::Path;
use File::Basename;
use File::Copy;
use Config;
use Cwd;

sub get_compile_dependant_objects {
	my $self = shift;
	$self->get_dependant_objects (@_);
}

sub get_dependant_objects {
	my $self = shift;
	
	# make a hash from the depend_install_object_types list
	my $ot_lref = $NewSpirit::Object::object_types
				->{'depend-all'}
				->{depend_install_object_types};
	my %dep_types;
	@dep_types{@{$ot_lref}} = (1) x @{$ot_lref};
	
	$dep_types{'cipp-inc'} = 1;
	#	if $self->{q}->param('depend_with_includes');
	# always turned on, otherwise dependencies are broken
	
	# Ok, now we build a hash of all accordingly file extensions
	my %ext;
	my ($ext, $type);
 	while ( ($ext, $type) = each %{$NewSpirit::Object::extensions} ) {
		# base config has special handling, see end of this method
		next if $type eq 'cipp-base-conf';
		$ext{$ext} = $type if defined $dep_types{$type};
	}

	# now %ext contains all file extensions we want to collect
	my $folder_dir = $self->{__folder_dir};
	my $project_src_dir = "$self->{project_src_dir}";
	my %all_files;

	find (
		sub {
			return if /^\./;
			return if not /\.([^\.]+)$/;
			my $ext = $1;
			return if not $ext{$ext};
			my $dir = $File::Find::dir;
			return if not -f "$dir/$_";
			$dir =~ s/$project_src_dir//;
			$dir =~ s!^/!!;
			$dir .= "/" if $dir;
			$all_files{"$dir$_:$ext{$ext}"} = 1;
			
		},
		$folder_dir
	);

	# Finally the base configuration object	
	$all_files{"$self->{project_base_conf}:cipp-base-conf"} = 1;

	# Now %all_files contains keys of the form
	#	$object:$type
	# Thats what is expected, lets return it!

	return \%all_files;
}

sub compile_project_ctrl {
	my $self = shift;
	
	my $q = $self->{q};

	# header
	NewSpirit::std_header (
		page_title => "Project Compilation: $self->{project}",
		close => 1
	);
	
	print "          \n" x 512;
	
	# take start time
	my $start_time = time;

	if ( $q->param('clear_prod_tree') == 1 ) {
		# lets delete the prod files first
		my $project = $self->{project};
		my $cgi_dir    = $self->{project_cgi_base_dir}."/$project";
		my $htdocs_dir = $self->{project_htdocs_base_dir}."/$project";
		my $conf_dir   = $self->{project_config_dir};
		my $lib_dir    = $self->{project_lib_dir};
		my $sql_dir    = $self->{project_sql_dir};
		my $inc_dir    = $self->{project_inc_dir};
                my $l10n_dir   = $self->{project_prod_dir}."/l10n";
		my $cipp_meta_dir = $self->{project_meta_dir}."/##cipp_dep";

		print "$CFG::FONT<b>",
		      "Deleting old production files...",
		      "</b>";
		
		print "<blockquote>\n";
		print "$cgi_dir<br>$htdocs_dir<br>$conf_dir<br>$sql_dir<br>$lib_dir<br>$inc_dir<br>$cipp_meta_dir<br>$l10n_dir<br>\n";
		print "</blockquote></FONT><p>\n";

		rmtree ( [ $cgi_dir, $htdocs_dir, $conf_dir, $sql_dir, $lib_dir, $inc_dir, $cipp_meta_dir, $l10n_dir ], 0, 0);
	}

	if ( $q->param('trunc_depend') == 1 ) {
		# OK, we delete the dependency database for
		# this project
		print "$CFG::FONT<b>",
		      "Truncating dependency database...",
		      "</b></FONT><p>\n";
		my $depend = new NewSpirit::Depend (
			$self->{project_depend_dir}
		);
		$depend->truncate;
		
		# delete modules hash
		unlink ($self->{project_modules_file});
	}

        # call cipp-l10n to scan files and create domains.conf
        # and .pot files
        print "$CFG::FONT<b>",
	      "Initializing l10n framework...",
	      "</b></FONT><p>\n";
        my $cmd = "cipp-l10n -n -c -d $self->{project_root_dir} && echo SUCCESS";
        my $output = qx[($cmd) 2>&1];
        if ( $output !~ /SUCCESS/ ) {
            print "<font color=red><b>ERROR</b></font><p>\n";
            print "<p>Command: $cmd</p><p>Output:</p><p>$output</p>\n";
            NewSpirit::end_page();
            return;
        }

	# this is the start folder for get_dependant_object()
	$self->{__folder_dir} = $self->{project_src_dir};

	my $prod_dir = $self->{project_prod_dir};

	print "$CFG::FONT<b>Project Compilation to '$prod_dir'</b></FONT><p>";

	# this internal variable indicates, that *no* dependency
	# installation should be done by our childs
	$self->{no_child_dependency_installation} = 1;

	# now we "install" ourself, this initiates the dependency
	# installation
	$self->install;
	
	# take end time
	my $end_time = time;
	
	# print duration
	my $duration = $end_time - $start_time;
	
	my $hours   = int ($duration/3600);
	my $minutes = int (($duration-$hours*3600)/60);
	my $seconds = $duration - $hours * 3600 - $minutes * 60;

	sprintf (
		"<p>$CFG::FONT Duration:<b>%02d:%02d:%02d</b></font>\n",
		$hours, $minutes, $seconds
	);
	
	NewSpirit::end_page();
}

sub install_project_ctrl {
	my $self = shift;
	
	my $q = $self->{q};
	my $base_config = $q->param('base_config');

	my $with_sql_prod_files = $q->param('with_sql_prod_files');
	my $build_src_tree      = $q->param('build_src_tree');
	
	# header
	NewSpirit::std_header (
		page_title => "Project Installation: $self->{project}",
		close => 1
	);

	print "          \n" x 512;

	my $install_dir = $self->{project_base_config_data}->{base_install_dir};

	if ( not $install_dir ) {
		print 	qq{$CFG::FONT<b><font color="red">},
			qq{Please configure a local install directory for this<br>\n},
			qq{base configuration!</font><p>Aborting.</b></font></font>\n};
		NewSpirit::end_page();
		return;
	}

	# This is the default base config. We need it for determining
	# the original source directories.
	my $default_base_conf = new NewSpirit::Object (
		q => $q,
		object => $CFG::default_base_conf,
	);

	# now define the directories for all subsequent operations

	my $project_root_dir = $default_base_conf->{project_root_dir};
	my $project_prod_dir = $default_base_conf->{project_prod_dir};
	my $project_src_dir  = $default_base_conf->{project_src_dir};
        my $project_l10n_dir = "$default_base_conf->{project_prod_dir}/l10n";

	my $install_root_dir = "$project_root_dir/$install_dir";
	my $install_prod_dir = "$install_root_dir/prod";
	my $install_src_dir  = "$install_root_dir/src";
	my $install_cgi_dir  = "$install_root_dir/prod/cgi-bin";
        my $install_l10n_dir = "$install_root_dir/prod/l10n";

	# print information text

	print "$CFG::FONT<b>Project Compilation to '$install_prod_dir'<br>",
	      "using base configuration '$base_config'</b></FONT><p>";

	print "$CFG::FONT\n";

	print "<b><font color=red>",
	      "Aware that your production tree should be up to date NOW,<br>",
	      "because this installation procedure makes a copy of your<br>",
	      "current production files! If they are not consistent, this<br>",
	      "installation won't be consistent either! To be sure, perform a<br>",
	      "'Project Compilation' first!",
	      "</font></b><p>\n";
	print "<p><b>Clone development production tree...</b><p>\n";

	# delete and create prod dir

	print "<BLOCKQUOTE>\n";

	print "deleting $install_root_dir...<br>\n";
	rmtree ([ $install_root_dir ], 0, 0 );
	
	print "creating $install_root_dir...<br>\n";
	mkpath ([ $install_root_dir ], 0, 0775 );
	
	# now do a complete copy of the prod directory,
	# omitting htdocs and logs
	
	print "<p>copying files from $project_prod_dir to $install_prod_dir...<p>\n";
	
	print "<script>self.window.scroll(0,5000000)</script>\n";
	print "<script>self.window.scroll(0,5000000)</script>\n";

	# create target directories, if not exist

	mkdir ($install_prod_dir, 0775) if not -d $install_prod_dir;
	mkdir ("$install_prod_dir/logs", 0775) if not -d "$install_prod_dir/logs";

	mkdir ("$install_prod_dir/cgi-bin", 0775) if not -d "$install_prod_dir/cgi-bin";
	NewSpirit::copy_tree (
		from_dir => "$project_prod_dir/cgi-bin",
		to_dir   => "$install_prod_dir/cgi-bin",
		verbose => 1
	);
	
	mkdir ("$install_prod_dir/lib", 0775) if not -d "$install_prod_dir/lib";
	NewSpirit::copy_tree (
		from_dir => "$project_prod_dir/lib",
		to_dir   => "$install_prod_dir/lib",
		verbose => 1
	);
	
	mkdir ("$install_prod_dir/inc", 0775) if not -d "$install_prod_dir/inc";
	NewSpirit::copy_tree (
		from_dir => "$project_prod_dir/inc",
		to_dir   => "$install_prod_dir/inc",
		verbose => 1
	);
	
	mkdir ("$install_prod_dir/config", 0775) if not -d "$install_prod_dir/config";
	NewSpirit::copy_tree (
		from_dir => "$project_prod_dir/config",
		to_dir   => "$install_prod_dir/config",
		verbose => 1
	);

	mkdir ("$install_prod_dir/htdocs", 0775) if not -d "$install_prod_dir/htdocs";
	NewSpirit::copy_tree (
		from_dir => "$project_prod_dir/htdocs",
		to_dir   => "$install_prod_dir/htdocs",
		verbose => 1
	);
	
        if ( -d $project_l10n_dir ) {
	    mkdir ($install_l10n_dir, 0775) if not -d $install_l10n_dir;
	    NewSpirit::copy_tree (
		from_dir => $project_l10n_dir,
		to_dir   => $install_l10n_dir,
		verbose => 1
	    );
	}

	if ( $with_sql_prod_files ) {
		mkdir ("$install_prod_dir/sql", 0775) if not -d "$install_prod_dir/sql";
		NewSpirit::copy_tree (
			from_dir => "$project_prod_dir/sql",
			to_dir   => "$install_prod_dir/sql",
			verbose => 1
		);
	}

	print "</blockquote>\n";

	if ( $build_src_tree ) {
		print "<p><b>Build src tree for SQL execution on production system...</b><p>\n";

		mkdir ($install_src_dir, 0775) if not -d $install_src_dir;

		print "<BLOCKQUOTE>\n";

		NewSpirit::copy_tree (
			from_dir => $project_src_dir,
			to_dir   => $install_src_dir,
			verbose  => 1,
			filter   => 'cipp-sql(\.m)?$|cipp-db(\.m)?$',
		);

		print "</BLOCKQUOTE>\n";

		# base config
		my $base_conf = new NewSpirit::Object (
			q => $q,
			object => $base_config,
		);
		my $source_file = $base_conf->{object_file};
		my $target_file = "$install_src_dir/configuration.cipp-base-config";
		copy ($source_file, $target_file);
	}

	# install base configuration
	print "<p><b>Install base configuration and set default database...</b><p>\n";
	my $base_o = new NewSpirit::Object (
		q => $q,
		object => $base_config,
		base_config_object => $base_config
	);
	$base_o->install_file;
	my $base_data = $base_o->get_data;
	
	if ( $base_data->{base_default_db} ) {
		# We now must explicitely install the default database
		# configuration, althogh the installation of the base
		# config object should do this for us. But the 
		# $db_o->installation_allowed method of NewSpirit::CIPP::DB,
		# resp. NewSpirit::CIPP:ProdReplace prevents installation,
		# because we have a non default base config but now
		# replace-action defined for our database config object.
		my $db_o = new NewSpirit::Object (
			q => $self->{q},
			object => $base_data->{base_default_db},
			base_config_object => $base_config,
		);
		
		# we can't use $db_o->install_file here, because it
		# uses installation_allowed(), which returns false
		# in this case (see above).
		
		$db_o->real_install_file (
			"$base_o->{project_config_dir}/default.db-conf",
			"default"
		);
	}

	# replace objects
	print "<p><b>Replace objects in production tree, where configured...</b><p>\n";

	print "<script>self.window.scroll(0,5000000)</script>\n";
	print "<script>self.window.scroll(0,5000000)</script>\n";

	chdir $project_src_dir;

	my @prod_replace_candidates;
	find (
		sub {
			return if /^\./;
			my $dir = $File::Find::dir;
			/([^\.]+)$/;
			my $ext = $1;
			if ( $NewSpirit::Object::prod_replace_extensions{$ext} ) {
				$dir .= "/";
				$dir =~ s!^./!!;
				push @prod_replace_candidates, "$dir$_";
			}
		},
		"."
	);

#	use Data::Dumper;print "<pre>", Dumper(\@prod_replace_candidates), "</pre>\n";
	
	print "$CFG::FONT_FIXED<BLOCKQUOTE>\n";
	my %replaced_objects;
	foreach my $candidate ( @prod_replace_candidates ) {

		my $o = new NewSpirit::Object (
			q => $q,
			object => $candidate,
			base_config_object => $base_config
		);
		my $target_object_name = $o->replace_target_prod_file;
		$o->install_file;

		if ( $target_object_name ) {
			if ( $replaced_objects{$target_object_name} ) {
				print "<font color=red><b>WARNING:<br>$target_object_name ",
				      "already replaced by ",
				      $replaced_objects{$target_object_name},
				      "</b></font><br>\n";
			} else {
				$replaced_objects{$target_object_name} = $candidate;
			}

			print "<script>self.window.scroll(0,5000000)</script>\n";
			print "<script>self.window.scroll(0,5000000)</script>\n";
		}
	}
	print "</BLOCKQUOTE></FONT>\n";

	# now install objects which depend on the base configuration
	print "<p><b>Install objects which depend on the base configuration</b><p>\n";

	# Lets get an default_base_conf object in the scope of our
	# user chosen $base_config. So dependency installation will
	# result in installing the prod files inside our use chosen
	# install-dir.
	my $mangled_default_base_conf = new NewSpirit::Object (
		q => $q,
		object => $CFG::default_base_conf,
		base_config_object => $base_config
		# this modifies the project_prod_dir to the install-dir
		# defined by the $base_config object, so installation
		# of objects will store files inside this alternate
		# prod dir
		#
		# NOTE: only the project_prod_dir is modified, not the
		# project_src_dir, because otherwise the original src
		# files cannot be found.
	);

	print "$CFG::FONT_FIXED<BLOCKQUOTE>\n";
	$mangled_default_base_conf->install_dependant_objects;
	print "</BLOCKQUOTE></FONT>\n";

	if ( $mangled_default_base_conf->{dependency_installation_errors} ) {
		print "$CFG::FONT<FONT COLOR=red>",
		      "<b>Some objects have errors</b>",
		      "</FONT><p>";

		foreach my $object (
		    sort keys
		    %{$mangled_default_base_conf->{dependency_installation_errors}} ) {
			print "<p>$CFG::FONT<b>",
			      $self->dotted_notation ($object),
			      "</b></FONT><br>\n";
			$self->print_install_errors (
				$mangled_default_base_conf->{dependency_installation_errors}
				     ->{$object}
			);
		}
	}

	# build static dbshell.pl

	$self->build_static_dbshell (
		target_file => "$install_prod_dir/dbshell.pl"
	);

	# shebang replace?
	if ( $self->{project_base_config_data}->{base_prod_shebang} or
	     $self->{project_base_config_data}->{base_prod_shebang_map} ) {
		print "<p><b>Replacing shebang line of programs in cgi-bin...</b><p>\n";

		print "<script>self.window.scroll(0,5000000)</script>\n";
		print "<script>self.window.scroll(0,5000000)</script>\n";

		$self->replace_shebang (
			shebang => $self->{project_base_config_data}->{base_prod_shebang},
			shebang_map => $self->{project_base_config_data}->{base_prod_shebang_map},
			dir     => $install_cgi_dir
		);
	}		

	print "<p><b>Installation complete!</b>\n";

	print "</font><br><br><br>\n";

	print "<script>self.window.scroll(0,5000000)</script>\n";
	print "<script>self.window.scroll(0,5000000)</script>\n";

	NewSpirit::end_page();
}

sub replace_shebang {
	my $self = shift;
	my %par = @_;
	my  ($shebang, $shebang_map, $dir) =
	@par{'shebang','shebang_map','dir'};

	$shebang ||= $Config{'perlpath'};

	$shebang = "#!$shebang" if $shebang !~ /^#!/;

	my %map;

	print "<blockquote>This is the shebang map:<br><font face=courier><pre>\n";
	if ( $shebang_map ) {
		foreach my $line ( split (/[\n\r]/, $shebang_map ) ) {
			my ($object, $shb) = split (/\s+/, $line, 2);
			next if not $object or not $shb;
			$object =~ s!^[^\.]+\.!$self->{project}.!;
			$object =~ tr!.!/!;
			$object = "$dir/$object";
			$object =~ s!/+!/!g;
			$shb = "#!$shb" if $shb !~ /^#!/;
			$map{$object} = $shb;
			
			$object =~ s!^$dir!\$CGI_DIR!;
			print "$object => $shb\n";
		}
	}
	print "</pre></font></blockquote>\n";

#print "<pre><font face=courier>\n";
#use Data::Dumper; print Dumper(\%map);

	my $default_shebang = $shebang;

	find (
		sub {
			my $dir  = $File::Find::dir;
			my $file = $_;
			return if $file !~ /\.(cgi|pl)$/;
			my $filename = "$dir/$file";
			
			open (IN, $filename)
				or die "can't read $filename";
			my $text = join '', <IN>;
			close IN;
			
			my ($atime, $mtime) = (stat $filename)[8,9];
			
			my $file_wo_ext = $filename;
			$file_wo_ext =~ s!\.[^\.]+$!!;

#print "\ncheck: dir=$dir\ncheck:file_wo_ext=$file_wo_ext\n";

			$shebang = $map{$dir} ||
				   $map{$file_wo_ext} ||
				   $default_shebang;

#print "$filename -> $shebang\n";

			$text =~ s/^#\!.*/$shebang/;
			
			open (OUT, ">$filename")
				or die "can't write $filename";
			print OUT $text;
			close OUT;
			
			utime $atime, $mtime, $filename;
		},
		$dir
	);

#print "</font></pre>\n";

	1;
}

sub build_static_dbshell {
	my $self = shift;
	
	my %par = @_;
	
	my $target_file = $par{target_file};

	my $dbshell_file        = "$CFG::bin_dir/dbshell.pl";
	
	open (IN, $dbshell_file) or die "can't read $dbshell_file";
	open (OUT, "> $target_file") or die "can't write $target_file";
	
	# copy dynamic dbshell.pl to the $target_file, substituting
	# the $STATIC variable to 1, do dbshell.pl knows, that it is
	# the static version.

	while (<IN>) {
		s/\$STATIC = 0/\$STATIC = 1/;
		print OUT $_;
	}
	
	close IN;
	
	# now we need to append the modules needed by dbshell.pl,
	# inside of a BEGIN{} block
	
	my $sql_shell_file      = "$CFG::lib_dir/NewSpirit/SqlShell.pm";
	my $sql_text_shell_file = "$CFG::lib_dir/NewSpirit/SqlShell/Text.pm";

	print OUT "BEGIN {\n";
	
	foreach my $file ( $sql_shell_file, $sql_text_shell_file ) {
		open (IN, $file) or die "can't read $file";
		while (<IN>) {
			next if /use NewSpirit::/;
			print OUT $_;
		}
		close IN;
	}
	
	print OUT "}\n";
	close OUT;

	# set dbshell.pl executable
	chmod 0755, $target_file;

	1;	
}

sub get_install_filename {
}

sub install_file {
	1;
}

sub print_pre_install_message {
}

sub print_post_install_message {
}

sub print_depend_install_message {
}

1;
