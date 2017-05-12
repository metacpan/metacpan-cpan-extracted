package Tree::PseudoIncLib;

# This package is developed primarily as a part of Apache::App::PerlLibTree web application.
# It encapsulates the object of description of perl library defined by @INC array.
# Internal description of the library exists in the form of internal array of hashes.
# It can be exported as either XML or DHTML files.
# A reference to the internal description can be exported too.

# Description instance can be created "from scratch" only,

# Logging information:
# --------------------
# I use full-scale Log::Log4perl. Log configurattion file is storied in data directory.

use 5.006;
use strict;
use warnings;
use File::Listing;
use File::Basename;
use File::chdir;
use POSIX qw(strftime);
use Cwd;
use UNIVERSAL qw(isa);
use Log::Log4perl;

use vars qw($VERSION);
$VERSION = "0.05";

use constant APPLICATION_DIRECTORY => '/app/pltree/'; # URL mask from the Apache Document_Root
use constant TREE_ID_DEFAULT  => 'Default_Tree';
use constant LIB_INDEX_PREFIX => 'lib'; # default prefix for root library name
use constant MIN_LIMIT_NODES  => 15;   # min value for max_nodes setting validation
use constant LIMIT_NODES      => 15000;# default for max_nodes
use constant RPM_TYPE         => 'RPM';# default type of packaging system, debian for instance is different
use constant NO_RPM_OWNER     => undef; # '-' is not that convenient...
use constant SKIP_EMPTY_DIR_DEFAULT => 1; # true
use constant SKIP_MODE_DEFAULT      => 0; # false
use constant SKIP_OWNER_DEFAULT     => 0; # false
use constant SKIP_GROUP_DEFAULT     => 0; # false

sub new { # class/instance constructor, ready for sub-classing
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};
	bless ($self, $class);

	# instance identification should include:
	$self->{tree_id} = TREE_ID_DEFAULT; # to display user-friendly
	$self->{application_directory} = APPLICATION_DIRECTORY; # default

	$self->{max_nodes} = LIMIT_NODES; # to decrement foreach documented node
	$self->{skip_empty_dir} = SKIP_EMPTY_DIR_DEFAULT;
	$self->{skip_mode} = SKIP_MODE_DEFAULT;
	$self->{skip_owner} = SKIP_OWNER_DEFAULT;
	$self->{skip_group} = SKIP_GROUP_DEFAULT;

	$self->{descript} = undef; # a reference to the array of hashes finally...

	# all simple keys have to be defined in order to be restorable from DBI when necessary...
	$self->{descript_internal_start_time} = undef;
	$self->{descript_internal_finish_time} = undef;
	$self->{descript_start_time_text} = undef;
	$self->{descript_finish_time_text} = undef;

	$self->{rpm_type} = RPM_TYPE;
	$self->{rpm_active} = 1; # TRUE might be for known RPM types only...
	$self->{lib_index_prefix} = LIB_INDEX_PREFIX; # default for internal names

	# default @INC comes from my old development machine:
	$self->{p_INC} = [
		'/usr/lib/perl5/5.6.1/i386-linux',
		'/usr/lib/perl5/5.6.1',
		'/usr/lib/perl5/site_perl/5.6.1/i386-linux',
		'/usr/lib/perl5/site_perl/5.6.1',
		'/usr/lib/perl5/site_perl/5.6.0',
		'/usr/lib/perl5/site_perl',
		'/usr/lib/perl5/vendor_perl/5.6.1/i386-linux',
		'/usr/lib/perl5/vendor_perl/5.6.1',
		'/usr/lib/perl5/vendor_perl'
	];

	# default array of allowed for keeping files:
	$self->{allow_files} = [
		{ mask => '.pm$',	icon => 'file.gif',
			name_on_click_action => 'source',
			icon_on_click_action => 'pod2html',
			name_mouse_over_prompt => 'source',
			icon_mouse_over_prompt => 'documentation',},
		{ mask => '.pod$',	icon => 'file_note.gif',
			name_on_click_action => 'source',
			icon_on_click_action => 'pod2html',
			name_mouse_over_prompt => 'source',
			icon_mouse_over_prompt => 'document',},
		{ mask => '.html$',	icon => 'file_html.gif',
			name_on_click_action => 'source',
			icon_on_click_action => 'source',
			name_mouse_over_prompt => 'no prompt',
			icon_mouse_over_prompt => 'no prompt',},
		{ mask => '.htm$',	icon => 'htm_file.jpg',
			name_on_click_action => 'source',
			icon_on_click_action => 'source',
			name_mouse_over_prompt => 'no prompt',
			icon_mouse_over_prompt => 'no prompt',},
	];

	$self->{plog} = Log::Log4perl->get_logger(); # __PACKAGE__ might be featured in log

	# optional parameters:
	my $parm = { @_ }; # a reference to the hash
	if ( $parm ) {
		$self->application_directory ($parm->{application_directory}) if defined $parm->{application_directory};
		$self->tree_id ($parm->{tree_id})		if defined $parm->{tree_id};
		$self->max_nodes ($parm->{max_nodes})		if defined $parm->{max_nodes};
		$self->pseudo_INC ($parm->{p_INC})		if defined $parm->{p_INC};
		$self->skip_empty_dir ($parm->{skip_empty_dir})	if defined $parm->{skip_empty_dir};
		$self->skip_mode ($parm->{skip_mode})		if defined $parm->{skip_mode};
		$self->skip_owner ($parm->{skip_owner})		if defined $parm->{skip_owner};
		$self->skip_group ($parm->{skip_group})		if defined $parm->{skip_group};
		$self->allow_files ($parm->{allow_files})	if defined $parm->{allow_files};

		# a group of RPM settings is not quite independent:
		$self->rpm_type ($parm->{rpm_type})		if defined $parm->{rpm_type}; # even empty
		$self->rpm_active ($parm->{rpm_active})		if defined $parm->{rpm_active}; # overwrite
	}

	# log if/what necessary:
	my $incoming_parameters = join("\n\t",map{$_.' => '.$parm->{$_}}(sort keys %{$parm}));
	$incoming_parameters = "\n\t".$incoming_parameters if $incoming_parameters;
	my $message = "( $incoming_parameters ); an instance of $class is created.\n";
	$self->{plog}->debug($message.$self->status_as_string);
	return $self;
}

sub status_as_string { # internal data
	my $self = shift;
	my $simple_key_data = 'Internals:'."\n";
	# I got tied over here to fight with
	# map { $simple_key_data .= "\t".$_.' => '.eval{$self->{$_}}."\n" } @{$self->list_simple_keys};
	# that complained about the
	# Use of uninitialized value in concatenation (.) or string at
	# blib/lib/Apache/App/ModPerlLibTree/AppLib/OneLibInitialDescription.pm line 141.
	foreach (@{$self->list_simple_keys}){
		if (!defined $self->{$_}){
			$simple_key_data .= "\t".$_.' => undef'."\n";
		} else {
			$simple_key_data .= "\t".$_.' => '.$self->{$_}."\n";
		}
	}
	my $current_inc = 'Pseudo-@INC:'."\n";
	map { $current_inc .= "\t".$_."\n" } @{ $self->{p_INC} };
	my $curr_allow = 'Allowed for Storage Files:';
	map {my $i=$_; $curr_allow.= "\n\tmask => $_->{mask}\t".join "\t",
        	map {if($_ eq 'mask'){} else {"$_ => $i->{$_}"}} sort keys %$_ } @{$self->{allow_files}};
	return $simple_key_data.$current_inc.$curr_allow;
}

sub allow_files {
	my $self = shift;
	my $p_r = shift; # a reference to a new version of array of hashes
	if ($p_r) {
		unless (isa($p_r, 'ARRAY')){
			$self->{plog}->error("($p_r); parameter must be a reference to ARRAY\n");
			return undef;
		}
		$self->{allow_files} = $p_r;
		my $message = "($p_r); internal reference is updated.\n";
		my $curr_allow = 'Allowed for Storage Files:';
		map {my $i=$_; $curr_allow.= "\n\tmask => $_->{mask}\t".join "\t",
        	map {if($_ eq 'mask'){} else {"$_ => $i->{$_}"}} sort keys %$_ } @{$self->{allow_files}};
		$self->{plog}->debug($message.$curr_allow);
	}
	return $self->{allow_files};
}

sub application_directory {
	my $self = shift;
	my $pr = shift;
	if ($pr) {
		$self->{application_directory} = $pr;
		$self->{plog}->debug("($pr); value is updated\n");
	}
	return $self->{application_directory};
}

sub tree_id {
	my $self = shift;
	my $pr = shift; # a new value for ID 
	if ($pr) {
		$self->{tree_id} = $pr;
		$self->{plog}->debug("($pr); value is updated\n");
	}
	return $self->{tree_id};
}

sub pseudo_INC {
	my $self = shift;
	my $p_r = shift; # a reference to a new version of pseudo_INC array
	if ($p_r) {
		unless (isa($p_r, 'ARRAY')){
			$self->{plog}->error("($p_r); parameter must be a reference to ARRAY\n");
			return undef;
		}
		$self->{p_INC} = $p_r;
		my $current_inc = 'Pseudo-@INC:'."\n";
		map { $current_inc .= "\t".$_."\n" } @{ $self->{p_INC} };
		$self->{plog}->debug("($p_r); internal reference is updated. $current_inc");
	}
	return $self->{p_INC};
}

sub rpm_type { # one optional parameter:
	my $self = shift;
	my $val = shift;
	if ( defined $val ){ # might be empty string
		$self->{rpm_type} = $val;
		$self->{plog}->debug("($val); rpm_type is changed to $self->{rpm_type}\n");
		unless ($self->{rpm_type}){
			$self->{rpm_active} = 0;
			$self->{plog}->debug('rpm_type disables the rpm_active'."\n");
		}
	}
	return $self->{rpm_type};
}

sub rpm_active { # one optional parameter:
	my $self = shift;
	my $val = shift;
	if ( defined $val ){ # might be 0
		if ( !$self->{rpm_type} && $val ){ # error
			$self->{plog}->error("($val); unable to set up rpm_active for unknown rpm_type\n");
			$self->{rpm_active} = 0;
			return 0;
		}
		$self->{rpm_active} = $val;
		$self->{plog}->debug("($val); rpm_active is changed to $self->{rpm_active}\n");
	}
	return $self->{rpm_active};
}

sub skip_empty_dir { # one optional parameter:
	my $self = shift;
	my $val = shift;
	if ( defined $val ){ # might be 0
		$self->{skip_empty_dir} = $val;
		$self->{plog}->debug("( $val ); skip_empty_dir is changed to $self->{skip_empty_dir}\n");
	}
	return $self->{skip_empty_dir};
}

sub skip_mode { # one optional parameter:
	my $self = shift;
	my $val = shift;
	if ( defined $val ){ # might be 0
		$self->{skip_mode} = $val;
		$self->{plog}->debug("( $val ); skip_mode is changed to $self->{skip_mode}\n");
	}
	return $self->{skip_mode};
}

sub skip_owner { # one optional parameter:
	my $self = shift;
	my $val = shift;
	if ( defined $val ){ # might be 0
		$self->{skip_owner} = $val;
		$self->{plog}->debug("($val); skip_owner is changed to $self->{skip_owner}\n");
	}
	return $self->{skip_owner};
}

sub skip_group { # one optional parameter:
	my $self = shift;
	my $val = shift;
	if ( defined $val ){ # might be 0
		$self->{skip_group} = $val;
		$self->{plog}->debug("($val); skip_group is changed to $self->{skip_group}\n");
	}
	return $self->{skip_group};
}

sub max_nodes { # one optional parameter:
	my $self = shift;
	my $val = shift;
	# max_nodes value has to be integer > 1 if defined
	if ( $val ){
		if ( $val < MIN_LIMIT_NODES ){ # error?
			$self->{plog}->warn("($val); must be not less than ".MIN_LIMIT_NODES."\n");
			$val = MIN_LIMIT_NODES;
		}
		$self->{max_nodes} = $val;
		$self->{plog}->debug("($val); max_nodes is changed to $self->{max_nodes}\n");
	}
	return $self->{max_nodes};
}

sub _dir_description {
# This member-function is used by from_scratch member function in order to
# create a primary description of so-called 'root directory' using recursion.
# The result is a pretty complicated structure of arrays and hashes. 
# Primarily, it is an array of hashes, where some keys might reference another (child)
# arrays of hashes, and so on... Upon success _dir_description returns a reference to the array of hashes.

# Every file/directory/symlink is described with the hash using the following set of keys:
#
# {type} - can be 'd', 'l', or 'f' (stand for 'directory', 'link', or 'file');
# {inode} - associated with the item;
# {permissions_octal_text} - like '0755'
# {size} - in bytes
# {owner} - name of the owner;
# {group} - name of the group;
# {level} - depth in the tree (since 1 for the names listed in @INC);
# {name} - local name of the file/link/directory (inside the parent directory);
# {full_name} - absolute path-and-name like /full/path/to/the/file
# {pseudo_cpan_name} - makes sense for the .pm file only; indeed is generated recursively;
# {last_mod_time_text} - date/time of last modification in format "%B %d, %Y at %H:%M"
# {parent_index} - unique name of the parent node/object;
# {self_index} - unique name for the self node/object;
# {child_dir_list} - a reference to the array of children descriptions;
# {rpm_package_name} - for real files only;
# {allow_index} - for real files only;

# all children in every array are sorted by the name alphabetically.

# Input hash keys:
#
# {root_dir} - absolute name of the directory to explore (the trailing slash / might be skipped);
# {pseudo_cpan_root_name} - estimation of the CPAN name for root_dir;
# {parent_index} - unique object name for the root_dir;
# {parent_depth_level} - depth level of root_dir inside the result tree;
# {prior_libs} - a reference to the array of prior library names those should not be repeated again;
# {inc_lib} - name of current library in @INC;
# {allow_masks} - a reference to the array of masks for allow-files
	my $self = shift;
	# and input parameters:
	my $params = { @_ }; # a reference to the hash
	# real parameters of the call are important for debug:
	my $message = '(';
	my $incoming_parameters = join("\n\t",map{$_.' => '.$params->{$_}}(sort keys %{$params}));
	$incoming_parameters = "\n\t".$incoming_parameters if $incoming_parameters;
	$message .= $incoming_parameters.'); started'."\n";
	$self->{plog}->debug($message);

	# incoming data validation...
	unless ( defined $params->{root_dir} && $params->{root_dir} ){
		$self->{plog}->error('no incoming root_dir'."\n");
		return undef;
	}
	my $dir_path = $params->{root_dir};
	unless ( defined $params->{pseudo_cpan_root_name} ){
		$self->{plog}->error('undefined incoming pseudo_cpan_root_name'."\n");
		return undef;
	}
	my $pseudo_cpan_root_name = $params->{pseudo_cpan_root_name};
	unless ( defined $params->{parent_index} && $params->{parent_index} ){
		$self->{plog}->error('no incoming parent_index'."\n");
		return undef;
	}
	my $parent_index = $params->{parent_index}; # unique part of parent js object
	unless ( defined $params->{parent_depth_level} ){
		$self->{plog}->error('undefined incoming parent_depth_level'."\n");
		return undef;
	}
	my $depth_level = $params->{parent_depth_level} + 1;
	unless ( defined $params->{prior_libs} && $params->{prior_libs} ){
		$self->{plog}->error('no incoming prior_libs'."\n");
		return undef;
	}
	my $prior_libs = $params->{prior_libs};
	unless (isa($prior_libs, 'ARRAY')){
		$self->{plog}->error('prior_libs must be a reference to ARRAY'."\n");
		return undef;
	}
	unless ( defined $params->{inc_lib} && $params->{inc_lib} ){
		$self->{plog}->error('no incoming inc_lib'."\n");
		return undef;
	}
	my $inc_lib = $params->{inc_lib};
	unless ( defined $params->{allow_masks} && $params->{allow_masks} ){
		$self->{plog}->error('no incoming allow_masks'."\n");
		return undef;
	}
	my $allow_masks = $params->{allow_masks};
	unless (isa($allow_masks, 'ARRAY')){
		$self->{plog}->error('allow_masks must be a reference to ARRAY'."\n");
		return undef;
	}

	# check for repeatition:
	foreach ( @{$prior_libs} ){
		if ( $_ eq $dir_path ) {
			# this should not be considered an error or abnormal anyway...
			$self->{plog}->debug('skipping the repeatition of '.$_."\n");
			return undef;
		}
	}
	# make sure the $dir_path is referencing the directory:
	$dir_path .= '/' unless $dir_path =~ /\/$/;

	my $common_array = []; # to store the result
	my $internal_index = 0;
	for (parse_dir(`ls -l $dir_path`)) {
		$internal_index += 1; # nodes in one diredtory ???

		my $row = {}; # hash to store the description of one file/sub-directory

		$row->{parent_index} = $parent_index;
		$row->{inc_lib} = $inc_lib; # the same for all levels
		$row->{level} = $depth_level;

		# rule to create {self_index} in string form:
		my $self_index = $parent_index.'_'.$internal_index;
		$row->{self_index} = $self_index;

		my ($name, $type, $size, $m_mtime, $m_mode) = @$_;
		# on this stage the $size is undefined for sub-directory...
		$row->{name} = $name;

		# It was a warning over here:  Use of uninitialized value in join or string at
		#     /usr/lib/perl5/site_perl/5.6.1/Apache/App/ModPerlLibTree.pm line 175.
		# for the initial operator:
		#     my $pseudo_cpan_name = join ('::', $pseudo_cpan_root_name, $name);
		#
		# I made this working:
		my $pseudo_cpan_name = $pseudo_cpan_root_name;
		if ( $pseudo_cpan_root_name ) {
			$pseudo_cpan_name .= '::'.$name;
		} else {
			$pseudo_cpan_name = $name;
		}
		$row->{pseudo_cpan_name} = $pseudo_cpan_name;

		$row->{type} = $type;

		my $now_string = strftime "%B %d, %Y at %H:%M", localtime ($m_mtime);
		$row->{last_mod_time_text} = $now_string;

		unless ($self->{skip_mode}){
			my $permissions = sprintf "%04o", $m_mode & 07777;
			$row->{permissions_octal_text} = $permissions;
		}

		my $full_file_name = $dir_path.$name;
		$row->{full_name} = $full_file_name;

		# retrieve the rest of details from the stat:
		my (	$dev,     # device number of filesystem
			$ino,     # inode number
			$mode,    # file mode  (type and permissions)
			$nlink,   # number of (hard) links to the file
			$uid,     # numeric user ID of file's owner
			$gid,     # numeric group ID of file's owner
			$rdev,    # the device identifier (special files only)
			$size_2,  # total size of file, in bytes
			$atime,   # last access time in seconds since the epoch
			$mtime,   # last modify time in seconds since the epoch
			$ctime,   # inode change time (NOT creation time!) in seconds since the epoch
			$blksize, # preferred block size for file system I/O
			$blocks   # actual number of blocks allocated
				) = stat ($full_file_name);

		# on this stage the sub-directory has some (fictive in my understanding) size...
		$row->{size} = $size_2;
		$row->{inode} = $ino;
		$row->{owner} = getpwuid($uid) unless $self->{skip_owner};
		$row->{group} = getgrgid($gid) unless $self->{skip_group};

		if ($type eq 'd') {
			# one directory might have multiple rpm-owners like:
			#    [slava@PBC110 slava]$ rpm -qf /usr/lib/perl5/5.6.1/i386-linux
			#    perl-5.6.1-34.99.6
			#    perl-DBI-1.21-1
			#    perl-DBD-Pg-1.01-8
			#    perl-DBD-MySQL-1.2219-6
			# I care about the rpm-owners of particular files only:

			# recursion into the sub-directory:

			my $child  = $self->_dir_description (
					root_dir => $full_file_name,
					prior_libs => $prior_libs,
					pseudo_cpan_root_name => $pseudo_cpan_name,
					parent_index => $self_index,
					inc_lib => $inc_lib,
					parent_depth_level => $depth_level,
					allow_masks => $allow_masks );

			if ( $child && scalar(@{$child}) ){ # successfully created

				$row->{child_dir_list} = $child;	# a reference to the array
									# of child's description
				push @{$common_array}, $row;
				$self->{max_nodes} -= 1;
				last if $self->{max_nodes} < 1;

			} elsif ( !$self->{skip_empty_dir} ) { # keep it storied

				push @{$common_array}, $row;
				$self->{max_nodes} -= 1;
				last if $self->{max_nodes} < 1;

			} else {
				# skip empty directory (with no children) but log this...
				$self->{plog}->debug("skips empty directory $full_file_name\n");
			}

		} elsif ($type eq 'f') {

			# I limit files to be stored by the rule of 'allowed only':
			my $keepit = 0; # false initially
			my $allow_index = 0;
			foreach (@{$self->{allow_files}}){
				my $mask = $_->{mask};
				if ( $name =~ /$mask/i ){
					$row->{allow_index} = $allow_index; # to get the action later
					$keepit = 1;
					last; # the first allowed is a right one
				}
				$allow_index++;
			}
			if ($keepit) {
				# no child reference for the file:
				$row->{child_dir_list} = undef;

				# determine the rpm package when appropriate:
				if ( $self->{rpm_active} ) {
					# I have Red Hat RPM only: rpm --version
					# RPM version 4.0.4
					my $rpm_name = `rpm -qf $full_file_name`;
					# as an example, in my tests I get initially on Red Hat:
					# file /some/real/full/name/file_1.pm is not owned by any package
					# I use simple mask: /^file \// to recognize no-rpm right away
					# in order to save some storage memory:
					#	my $no_rpm_mask = '^file /';
					chomp $rpm_name;
					$row->{rpm_package_name} = ($rpm_name =~ /^file \//o)
						? NO_RPM_OWNER : $rpm_name; # =~ m/(\S.*\S)/;
				}

				push @{$common_array}, $row;
				$self->{max_nodes} -= 1;
				last if $self->{max_nodes} < 1;
			} else {
				# I skip all other files but log this...
				my $message = 'skips '.$full_file_name." due to unknown type\n";
				$self->{plog}->debug($message);
			}

		} else {
			# this is supposed to be a link:

			# In my test for real symlink I have for example:
			# type=>l file_3.txt
			# name=>file_4.htm
			# on Red Hat Linux 9.0 after:
			# ln -s file_3.txt file_4.htm
			# having:
			# lrwxrwxrwx  1 slava group  10 Aug  7 09:08 file_4.htm -> file_3.txt

			$row->{child_dir_list} = undef;
			$row->{link_target} = substr($type, 2); # check this for other platforms!
			$row->{type} = 'l'; # make it clear for the further use

			# I don't follow symlinks in order to avoid loops

			$self->{plog}->debug('has a link called '.$name."\n");
			push @{$common_array}, $row;
			$self->{max_nodes} -= 1;
			last if $self->{max_nodes} < 1;
		}
	}
	# common_array is created.

	@{$common_array} = sort { $a->{name} cmp $b->{name} } @{$common_array};

	$self->{plog}->debug('done on level='.$depth_level.' in '.$dir_path."\n");
	return $common_array;
}

sub from_scratch {
	# A member function that creates the discription of perl-library defined by {p_INC} reference.
	# no incoming parameters
	# The result reference is stored internally in {descript} and is returned upon success.
	my $self = shift;

	my $internal_start_time = time;
	# this time will be assigned as a time of the creation of description
	$self->{descript_internal_start_time} = $internal_start_time;
	my $now_string = strftime "%A, %B %e, %Y at %H:%M:%S", localtime($internal_start_time);
	$self->{descript_start_time_text} = $now_string;

	$self->{plog}->info('started on '.$now_string."\n");

	# I need to create this array ones for all nested calls:
	my $allow_masks = []; # to select files
	map { push @{$allow_masks},$_->{mask} } @{$self->{allow_files}};

	my $depth_level = 1;	# to control the depth of the tree,
				# I have the list of @INC names on level 1...
	my $lib_list_ref = [];  # a reference to the array of hashes; every hash describes one library:

# {parent_index} - unique name of the parent node/object;
# {self_index} - unique name for the self node/object;
# {name} - name of the file/link/directory;
# {pseudo_cpan_name} - makes sense for the .pm file only; indeed is generated recursively;
# {type} - can be 'd', 'l', or 'f'; However, see features of 'l'...
# {last_mod_time_text} - date/time of last modification in format "%B %d, %Y at %H:%M"
# {permissions_octal_text} - like '0755'
# {full_name} - absolute name like /full/path/to/the/file
# {size} - in bytes
# {owner} - name of the owner;
# {group} - name of the group;
# {child_dir_list} - a reference to the array of children descriptions;
# {inode} - associated with the item;
# {level} - depth in the tree (=1 for the names listed in @INC);

	# I don't want to have stupid repititions in the tree structure.
	# For example, in Red Hat distribution 7.3 you might have:
	#
	# @INC = 
	# /usr/lib/perl5/5.6.1/i386-linux
	# /usr/lib/perl5/5.6.1
	# /usr/lib/perl5/site_perl/5.6.1/i386-linux
	# /usr/lib/perl5/site_perl/5.6.1
	# /usr/lib/perl5/site_perl/5.6.0
	# /usr/lib/perl5/site_perl
	# /usr/lib/perl5/vendor_perl/5.6.1/i386-linux
	# /usr/lib/perl5/vendor_perl/5.6.1
	# /usr/lib/perl5/vendor_perl
	# .                        !!! This is '/' for mod_perl !!!
	# /etc/httpd/              !!! Loop is here !!!
	# /etc/httpd/lib/perl      !!! Does not exist on my machine !!!
	#
	# It is not supposed to make a real sence in terms of pseudo-cpan names...

	my $prior_libs = []; # a reference to the array of already explored libraries

	my $local_index = 0; # to create unique names

	foreach (@{ $self->{p_INC} }) {

		$local_index += 1;
		my $lib_descr = {};
		$lib_descr->{level} = $depth_level;

		my $lib_index_name = $self->{lib_index_prefix}.'_'.$local_index;
		$lib_descr->{self_index} = $lib_index_name;
		$lib_descr->{parent_index} = undef;
		my $dir = $_;

		my $message = 'serves $INC['.$local_index.'] = '.$dir." named $lib_index_name\n";
		$self->{plog}->debug($message);

		$lib_descr->{name} = $dir;
		$lib_descr->{type} = 'd'; # always directory in @INC
		# retrieve the rest of details from the stat:
		my $dir_path = $dir;
		$dir_path .= '/' unless $dir =~ /\/$/;
		my (	$dev,     # device number of filesystem
			$ino,     # inode number
			$mode,    # file mode  (type and permissions)
			$nlink,   # number of (hard) links to the file
			$uid,     # numeric user ID of file's owner
			$gid,     # numeric group ID of file's owner
			$rdev,    # the device identifier (special files only)
			$size_2,  # total size of file, in bytes
			$atime,   # last access time in seconds since the epoch
			$mtime,   # last modify time in seconds since the epoch
			$ctime,   # inode change time (NOT creation time!) in seconds since the epoch
			$blksize, # preferred block size for file system I/O
			$blocks   # actual number of blocks allocated
				) = stat ($dir_path);
		# on this stage the sub-directory has some (fictive in my understanding) size...
		$lib_descr->{size} = $size_2;

		my $now_string = strftime "%B %d, %Y at %H:%M", localtime ($mtime);
		$lib_descr->{last_mod_time_text} = $now_string;

		$lib_descr->{full_name} = $dir;

		unless ($self->{skip_mode}){
			my $permissions = sprintf "%04o", $mode & 07777;
			$lib_descr->{permissions_octal_text} = $permissions;
		}

		$lib_descr->{owner} = getpwuid($uid) unless $self->{skip_owner};
		$lib_descr->{group} = getgrgid($gid) unless $self->{skip_group};
		$lib_descr->{inode} = $ino;

		$lib_descr->{child_dir_list} = $self->_dir_description (
			root_dir		=> $dir,
			prior_libs		=> $prior_libs,
			pseudo_cpan_root_name	=> '', # it warns in debug when I use undef over here
			parent_index		=> $lib_index_name,
			inc_lib			=> $dir,
			parent_depth_level	=> $depth_level,
			allow_masks		=> $allow_masks );

		# never skip the root (level 1) directory, even empty...

		# when the limit on global number of nodes is exceeded in _dir_description
		# it can return undef. This should be safe for the following push...
		if ( defined($lib_descr->{child_dir_list})
				&& scalar( @{$lib_descr->{child_dir_list}} ) eq 0 ){
			$lib_descr->{child_dir_list} = undef;
		}
		push @{$lib_list_ref}, $lib_descr;
		$self->{max_nodes} -= 1;
		last if $self->{max_nodes} < 1;
		push @{$prior_libs}, $dir;
	}
	# time stamp of the finish:
	my $internal_finish_time = time;
	my $now_finish_string = strftime "%A, %B %e, %Y at %H:%M:%S", localtime($internal_finish_time);
	$self->{descript_internal_finish_time} = $internal_finish_time;
	$self->{descript_finish_time_text} = $now_finish_string;

	# create a simple list of all accumulated items:

	$self->{descript} = $self->_object_list ($lib_list_ref);
	$self->_mark_shaded_names();

	if ( $self->{max_nodes} < 1 ){ # ERROR
		# terminating this late, I keep the accumulated result viewable
		$self->{plog}->error('ERROR termination: max_nodes exceeded'."\n");
		return undef;
	}
	my $duration = $internal_finish_time - $internal_start_time;

	# I will clean up the following mess later...
	my $hh = int($duration/3600);
	my $mm = int(($duration - 3600 * $hh)/60);
	my $ss = $duration - 60 * $mm - 3600 * $hh;
	my $duration_text = sprintf "%02d:%02d:%02d", $hh,$mm,$ss;

	$self->{plog}->info('done on '.$now_finish_string." duration=$duration_text\n");
	return scalar(@{$self->{descript}});
}

sub _object_list {
	# transforms the description tree structure
	# to the simple (regular) array of simple hashes:

	my $self = shift;
	my $source = shift; # a reference to the array of dir descriptions
	# source data validation:
	#
	# I can take an empty incoming array when the directory is empty;
	# that's fine, I will respond with the reference to an empty array then...
	# The problem could appear if the $source is udefined,
	# or is referencing something that is not an array...
	unless (isa($source, 'ARRAY')){
		$self->{plog}->error('incoming parameter must be a reference to ARRAY'."\n");
		return undef;
	}
	my $result = []; # a reference to return

	# 09/10/04: a bug appears over here: $source->[0]->{level} is undef ocasionaly.
	my $in_size = scalar @{$source};
	unless ( defined $source->[0]->{level} ){
		$self->{plog}->warn("undefined level value when the size=$in_size\n");
		return $result; # empty...
	}
	my $dbg_nodes = []; # to drill into the bug

	my $current_level = $source->[0]->{level};
	$self->{plog}->debug("start level=$current_level size=$in_size\n");

	foreach ( @{$source} ) {

		my $lib_descr = {}; # my very simple hash for one row

		# this is not a full list of incoming keys:

		$lib_descr->{pseudo_cpan_name}		= $_->{pseudo_cpan_name};
		$lib_descr->{level}			= $_->{level};
		$lib_descr->{inc_lib}			= $_->{inc_lib};
		$lib_descr->{parent_obj_name}		= $_->{parent_index};
		$lib_descr->{self_obj_name}		= $_->{self_index};
		$lib_descr->{name}			= $_->{name};
		$lib_descr->{type}			= $_->{type};
		$lib_descr->{size}			= $_->{size};
		$lib_descr->{last_mod_time_text}	= $_->{last_mod_time_text};
		$lib_descr->{full_name}			= $_->{full_name};
		$lib_descr->{inode}			= $_->{inode};
		$lib_descr->{permissions_octal_text}=$_->{permissions_octal_text} if $_->{permissions_octal_text};
		$lib_descr->{owner}		= $_->{owner} if $_->{owner};
		$lib_descr->{group}		= $_->{group} if $_->{group};
		$lib_descr->{allow_index}	= $_->{allow_index} if defined $_->{allow_index};# files only
		$lib_descr->{rpm_package_name}	= $_->{rpm_package_name} if $_->{rpm_package_name};
		$lib_descr->{link_target}	= $_->{link_target} if $_->{link_target};

		push @{$result}, $lib_descr;
		push @{$dbg_nodes}, $_->{inode};

		if ( $_->{child_dir_list} ) {

			# this is a good place for <div or XML open for the child...

			# recursion inside the same namespace/class omly:
			my $subset = _object_list($self, $_->{child_dir_list});
			push @{$result}, @{$subset};

			# this is a good place for </div or XML close for the child...

			$_->{child_dir_list} = undef; # release the memory
		};
	}
	$self->{plog}->debug("done level=$current_level for nodes:\n\t"
			.join("\n\t",@{$dbg_nodes})."\n");
	return $result;
}

sub _mark_shaded_names {
	# creates extended descriptions for shaded .pm files.

	# Since Aug 13, 2004 I extend the same record with additional keys
	# (instead of referencing additional hash in previous versions)
	# in order to simplify the main data structure, XML representation,
	# and serialization/deserialization mechanism.

	# no parameters:
	my $self = shift;
	$self->{plog}->debug("start\n");

	my %first; # to store pseudo_cpan_name's
	foreach ( @{ $self->{descript} } ){

		next unless $_->{type} eq 'f' and lc $_->{name} =~ /\.pm$/;

		my $actual_file_name = $_->{pseudo_cpan_name};
		if ( $first{$actual_file_name} ){

			# this file is shaded
			$_->{shaded_by_lib}		= $first{$actual_file_name}->{lib};
			$_->{shaded_by_inode}		= $first{$actual_file_name}->{inode};
			$_->{shaded_by_last_modified}	= $first{$actual_file_name}->{last_modified};

		} else {
			my $details = {};
			$details->{lib}			= $_->{inc_lib};
			$details->{inode}		= $_->{inode};
			$details->{last_modified}	= $_->{last_mod_time_text};

			$first{$actual_file_name} = $details; # to check other files
		}
	}

	my $shaded_cpan_names = [];
	map {push @{$shaded_cpan_names},$_->{pseudo_cpan_name} if $_->{shaded_by_lib} } @{$self->{descript}};
	$self->{plog}->debug("Shaded Files:\n".join(', ', @{$shaded_cpan_names} ));

	$self->{plog}->debug('done'."\n");
	return $shaded_cpan_names;
}

sub list_simple_keys {
	# returns a reference to the array that contains a
	# sorted alphabetically set of names of simple keys of the object.
	my $self = shift;

	my $ref_keys = []; # final array of key names
	foreach (sort keys %{$self}){
		if (!defined $self->{$_}){
			push @{$ref_keys},$_;
		} elsif ($self->{$_}=~/HASH/ or $self->{$_}=~/ARRAY/){
			next;
		} else {
			push @{$ref_keys},$_;
		}
	}
	$self->{plog}->debug( "Outgoing List:\n\t".join("\n\t",@{$ref_keys})."\n" );

	return $ref_keys;
}

sub list_descript_keys {
	# returns a reference to the array that contains
	# sorted alphabetically names of keys used anywhere inside descriptions.
	my $self = shift;

	my $ref_descript_keys = []; # final array of all keys
	my %r; # to fill out with full set of available description keys (no duplications):
	map { map{ $r{$_} = 1 } keys %{$_} } @{$self->{descript}};
	# sorted list of all keys:
	map { push @{$ref_descript_keys},$_ } sort keys %r;
	$self->{plog}->debug( "Outgoing List:\n\t".join("\n\t",@{$ref_descript_keys})."\n" );

	return $ref_descript_keys;
}

######################### HTML ##################
sub w3c_doctype {
	my $self = shift;

	$self->{plog}->debug('started'."\n");

	my $parms = { @_ }; # a reference to the hash
	# 1 mandatory parameter:
	my $type = $parms->{type};
	$self->{plog}->error('has no incoming type') unless $type;
	return undef unless $type;

	my $res = ''; # to output
	if ( $type =~ /xhtml/i ){
		$res =<<TOP_PART;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/strict.dtd">
<html xmlns="http://www.w3.org/TR/xhtml1">
TOP_PART
	} elsif ( $type =~ /html/i ){
		$res =<<TOP_PART;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
TOP_PART
	} else {
		$self->{plog}->error('has unknown type: '.$type);
		return undef;
	}
	$self->{plog}->debug('done'."\n");
	return $res;
}

sub inline_CSS {
	# no parameters ?

	my $res =<<END;
<style type="text/css">
	body {
		background-color: #ffffff;
		color: #000000;
		font-family: helvetica, arial, verdana, sans-serif;
		/* font-size: 1.0em; */
		position: relative !important; /* needed for ie5*/
	}
	/* Default Text Appearance */
	* { font-family: Tahoma, Arial, Helvetica, Sans-Serif; font-size: 10pt; color: black; }

	/* Link Appearance */
	a { color: black; text-decoration: none; }
	a:hover { text-decoration: underline; color: #000080; }

	.headSell { background-color: #dddddd; }
	.r0 { background-color: #eeeeee; }
	.r1 { background-color: #ddffff; }
	table { border: 1}

	div { padding-top: 2px }

</style>
END
	return $res;
}

sub _html_head {
	my $self = shift;

	$self->{plog}->debug('started'."\n");

	my $parms = { @_ }; # a reference to the hash
	# 3 parameters:
	my $title = $parms->{title};
	my $jslib = $parms->{jslib};
	my $css = $parms->{css};
	my $overLib = $parms->{overLib};

	my $res =<<END;
<head>
	<title>$title</title>
END
	if ($css and ($css eq 'inline')){
		$res .= $self->inline_CSS;
	} elsif ($css) {
		$res .=<<END;
	<link rel="stylesheet" type="text/css" href="$css" />
END
	} # scip css otherwise...

	if ($jslib){
		$res .=<<END;
	<script type="text/javascript" src="$jslib"></script>
END
	}
	if ($overLib){
		$res .=<<END;
	<script langauge="JavaScript" src="$overLib"><!-- overLIB (c) Erik Bosrup --></script>
END
	}
	$res .=<<END;
</head>
END
	$self->{plog}->debug('done'."\n");
	return $res;
}

sub inc_html_table {
	# list content of pseudo-inc linking names to the main descripts
	# make human readable HTML format:
	my $self = shift;

	$self->{plog}->debug('started'."\n");

	my $parms = { @_ }; # a reference to the hash
	# 1 parameter:
	my $title = $parms->{title};
	my $res =<<END;
<table border="0">
	<tr class="headRow"><td class="headSell" align="center">$title</td></tr>
END
	my $loc_ind = 1;
	foreach ( @{$self->{p_INC}} ){
		my $link = $self->{lib_index_prefix}.'_'.$loc_ind; # create it here:
		$res .= "\t".'<tr><td><a href="#'.$link.'">'.$_.'</a></td></tr>'."\n";
		$loc_ind += 1;
	}
	$self->{plog}->debug('done'."\n");
	return $res.'</table>'."\n";
}

sub _descript_html_table_head_row {
	my $self = shift;
	$self->{plog}->debug('started'."\n");

	my $res = '<tr class="headRow">';
	# header row of the table:
	my @hdr_list;
	push @hdr_list, 'mode' unless $self->{skip_mode};
	push @hdr_list, 'owner' unless $self->{skip_owner};
	push @hdr_list, 'group' unless $self->{skip_group};
	push @hdr_list, 'inode', 'tree', 'size', 'last_modified', 'use_model';
	push @hdr_list, 'package' if $self->{rpm_active};
	map {$res .= '<td class="headSell" align="center">'.$_.'</td>'} @hdr_list;
	$self->{plog}->debug('done'."\n");
	return $res.'</tr>'."\n";
}

sub export_to_DHTML {
	# create a multi-string of dynamic HTML page
	my $self = shift;
	$self->{plog}->debug('started'."\n");

	my $parm = { @_ }; # a reference to the hash
	my $title = $parm->{title};
	# all following parameters should be object properties?..
	my $image_dir = $parm->{'image_dir'};
	unless ( $image_dir ){
		$self->{plog}->error('has no image_dir'."\n");
		return undef;
	}
	my $icon_shaded = $parm->{'icon_shaded'};
	unless ( $icon_shaded ){
		$self->{plog}->error('has no icon_shaded'."\n");
		return undef;
	}
	my $icon_folder_opened = $parm->{'icon_folder_opened'};
	unless ( $icon_folder_opened ){
		$self->{plog}->error('has no icon_folder_opened'."\n");
		return undef;
	}
	my $icon_symlink =$parm->{'icon_symlink'};
	unless ( $icon_symlink ){
		$self->{plog}->error('has no icon_symlink'."\n");
		return undef;
	}
	my $tree_intend = $parm->{'tree_intend'};
	$self->{plog}->warn('has undefined tree_intend'."\n") unless defined $tree_intend;
	my $row_class = $parm->{'row_class'} || 'r0';

	my $css =$parm->{'css'} || 'inline';
	my $jslib =$parm->{'jslib'} || '';
	my $overlib =$parm->{'overlib'};
	unless ( $overlib ){
		$self->{plog}->error('has no overlib'."\n");
		return undef;
	}

	my $res = $self->w3c_doctype( type => 'html' );
	$res .=<<END;
<html>
END
	$res .= $self->_html_head(
		title	=> $title,
		css	=> $css,
		jslib	=> $jslib,
		overLib	=> $overlib,
	);
	$res .=<<END;
<body>
	<div id="overDiv" style="position:absolute; visibility:hidden; z-index:1000;"></div>
END
	my $start = $self->{descript_start_time_text};
	my $v = $^V ? sprintf "v%vd", $^V : $];
	$res .=<<END;
<H1>Perl $v<br>$self->{tree_id}<br>created on $start</H1>
<H1>INC array:</H1>
END
	$res .= $self->inc_html_table(title => 'Library');
	$res .=<<END;
<H1>Tree of Libraries:</H1>
<table border="0">
END
	$res .= $self->_descript_html_table_head_row();
	# list all descriptions:
	$self->{lib_index} = 1; # to link pseudo_INC list to right rows of description
	foreach ( @{$self->{descript}} ) {
		# 11/19/03: need to make a flexible input for the _data_row_HTML:
		$res .= $self->_data_row_HTML(
			current_row_description	=> $_,
			image_dir		=> $image_dir,
			icon_shaded		=> $icon_shaded,
			icon_folder_opened	=> $icon_folder_opened,
			icon_symlink		=> $icon_symlink,
			tree_intend		=> $tree_intend,
			row_class		=> $row_class,
		)."\n";
	}
	$self->{lib_index} = undef; # release this temporary key from possible saving operations
	$res .=<<REST;
</table>
<br><br><br><br>
</body>
</html>
REST
	$self->{plog}->debug('done'."\n");
	return $res;
}

sub _data_row_HTML {
	# this method creates one regular row only,
	# it does not serve the root (and I have no root row anymore...)
	my $self = shift;
	$self->{plog}->debug('started'."\n");

	my $parm = { @_ };
	my $source = $parm->{'current_row_description'};
	unless ( $source ){
		$self->{plog}->error('has no current_row_description'."\n");
		return undef;
	}

	# all following parameters should be object properties?..
	my $image_dir = $parm->{'image_dir'};
	unless ( $image_dir ){
		$self->{plog}->error('has no image_dir'."\n");
		return undef;
	}
	my $icon_shaded = $parm->{'icon_shaded'};
	unless ( $icon_shaded ){
		$self->{plog}->error('has no icon_shaded'."\n");
		return undef;
	}
	my $icon_folder_opened = $parm->{'icon_folder_opened'};
	unless ( $icon_folder_opened ){
		$self->{plog}->error('has no icon_folder_opened'."\n");
		return undef;
	}
	my $icon_symlink =$parm->{'icon_symlink'};
	unless ( $icon_symlink ){
		$self->{plog}->error('has no icon_symlink'."\n");
		return undef;
	}
	my $tree_intend = $parm->{'tree_intend'};
	$self->{plog}->warn('has undefined tree_intend'."\n") unless defined $tree_intend;
	my $row_class = $parm->{'row_class'} || 'r0';

	# a level==1 directory should be accomplished with a local link anchor:
	my $anchor = '';
	if ( $source->{level} eq 1 ) {
		$anchor = '<a name="'.$self->{lib_index_prefix}.'_'.$self->{lib_index}.'"></a>';
		$self->{lib_index} += 1;
	}
	my $result = '<tr class="'.$row_class.'">';
	unless ( $self->{skip_mode} ){
		$result .= '<td>'.$anchor.$source->{permissions_octal_text}.'</td>';
		$anchor = '';
	}
	unless ( $self->{skip_owner} ){
		$result .= '<td>'.$anchor.$source->{owner}.'</td>';
		$anchor = '';
	}
	unless ( $self->{skip_group} ){
		$result .= '<td>'.$anchor.$source->{group}.'</td>';
		$anchor = '';
	}
	$result .= '</td><td align="right">'.$anchor.$source->{inode}.'</td>'; # first mandatory tag

	# tree sell:
	$result .= '<td align="left"><table border="0" cellpadding="0" cellspacing="0"><tr>';
	if ( $source->{level} ) {
		$result .= '<td width="'.$tree_intend * ( $source->{level} - 1 ).'">&nbsp;</td>';
	}

	my $icon = $image_dir;
	if ( $source->{type} eq 'f'){
		$icon .= ($source->{shaded_by_lib}) ?
			$icon_shaded : $self->{allow_files}->[$source->{allow_index}]->{icon};
	} elsif ( $source->{type} eq 'd'){
		$icon .= $icon_folder_opened;
	} else { # $source->{type} eq 'l':
		$icon .= $icon_symlink;
	}

	my $application_directory = $self->{application_directory};

	if ( $source->{shaded_by_lib} ){
		# make the message to display by overLib on_mouse_over:
		my $ollibname = $source->{shaded_by_lib} || 'Unknown';
		my $olinode = $source->{shaded_by_inode};
		my $ollast_mod = $source->{shaded_by_last_modified};
		my $olMessage = 'Click to view this document<br>'
		.'shaded by:<br><table border=0><tr><td>library:</td><td nowrap=nowrap>'
		.$ollibname.'</td></tr>'
		.'<tr><td>inode:</td><td>'.$olinode.'&nbsp;</td></tr>'
		.'<tr><td>modified_on:</td><td nowrap=nowrap>'.$ollast_mod.'&nbsp;</td></tr></table>';
		my $allow_index = $source->{allow_index};
		$result .= '<td>'.$self->_link_icon_overLib (
			icon_src => $icon,
	#		on_click_href => '/display-document'.$source->{full_name},
			on_click_href => $application_directory.$self->{allow_files}->[$allow_index]->{icon_on_click_action}.$source->{full_name},
			on_mouse_over_message => $olMessage,
			hspace => 1,
			align => 'absmiddle',
			border => 0 ).'</td>';
	} else {
		if ( $source->{type} eq 'f' ){
			my $allow_index = $source->{allow_index};
			unless ( defined $allow_index ) { # zerro is fine
				$self->{plog}->error($source->{full_name}.' has no allow_index'."\n");
				return undef;
			}
			$result .= '<td>'.$self->_link_icon_overLib (
				icon_src => $icon,
				on_click_href => $application_directory.$self->{allow_files}->[$allow_index]->{icon_on_click_action}.$source->{full_name},
				on_mouse_over_message => $self->{allow_files}->[$allow_index]->{icon_mouse_over_prompt},
				hspace => 1,
				align => 'absmiddle',
				border => 0 ).'</td>';
		} else { # this is a directory or a link:
			$result .= '<td><img hspace="1" src="'.$icon.'" border="0" align="absmiddle"></td>';
		}
	}

	# short name for the item:
	if ( $source->{type} eq 'f' ){
		my $allow_index = $source->{allow_index};
		my $left_space = ''; # default for .pod icon that has own space...
		my $olMessage = $self->{allow_files}->[$allow_index]->{name_mouse_over_prompt};
		$left_space = '&nbsp;&nbsp;';
		$result .= '<td nowrap="nowrap">'.$left_space.$self->_link_text_overLib (
			text => $source->{name},
			href => $application_directory.$self->{allow_files}->[$allow_index]->{name_on_click_action}.$source->{full_name},
			on_mouse_over_message => $olMessage ).'</td>';
	} else {
		# no links for directory or symlink:
		$result .= '<td nowrap="nowrap">&nbsp;'.$source->{name}.'</td>';
	}
	$result .= '</tr></table></td>';

	# output the rest of the row:
	if ( $source->{type} eq 'f' ){
		$result .= '<td align="right">'.$source->{size}.'&nbsp;</td>'
		.'<td align="right" nowrap="nowrap">'.$source->{last_mod_time_text}.'&nbsp;</td>';
		if ( lc $source->{name} =~ /\.pm$/ ){
			my $real_name = substr($source->{pseudo_cpan_name}, 0, -3);
			$result .= '<td nowrap="nowrap" align="left">&nbsp;'.$real_name.'</td>';
		} else {
			$result .= '<td>&nbsp;</td>';
		}
	} elsif ( ($source->{type} eq 'd') and ($source->{level} eq 1 ) ) {
		$result .= '<td>&nbsp;</td>';
		$result .= '<td colspan="2" class="headSell">base-level-lib</td>';
	} elsif ( $source->{type} eq 'l' ) {
		$result .= '<td colspan="3">&nbsp;=&gt;&nbsp;'.$source->{link_target}.'&nbsp;</td>';
	} else {
		$result .= '<td colspan="3">&nbsp;</td>';
	}
	# one directory might have multiple rpm-owners like:
	#	[slava@PBC110 slava]$ rpm -qf /usr/lib/perl5/5.6.1/i386-linux
	#	perl-5.6.1-34.99.6
	#	perl-DBI-1.21-1
	#	perl-DBD-Pg-1.01-8
	#	perl-DBD-MySQL-1.2219-6
	# I care about the rpm-owners of particular files only:
	if ( $self->{rpm_active} ){
		my $rpm_package_name = $source->{rpm_package_name};
		$rpm_package_name = '-'
			if defined $rpm_package_name and $rpm_package_name =~ /^file \//; # make short output
		if ( $rpm_package_name ){
			$result .= '<td nowrap="nowrap">'.$rpm_package_name.'</td>';
		} else {
			$result .= '<td>&nbsp;</td>';
		}
	}
	$self->{plog}->debug('done'."\n");
	return $result.'</tr>';
}

sub _link_icon_overLib {
	my $self = shift;
	my $parm = { @_ };
	my $icon_src = $parm->{'icon_src'};
	unless ( $icon_src ){
		$self->{plog}->error("has no icon_src\n");
		return undef;
	}
	return '<a href="'.$parm->{'on_click_href'}.'" onmouseover="return overlib(\''
		.$parm->{'on_mouse_over_message'}.'\');" onmouseout="return nd();"><img src="'
		.$icon_src.'" hspace="'.$parm->{'hspace'}.'" border="'.$parm->{'border'}.'" align="'
		.$parm->{'align'}.'"></a>';
}

sub _link_text_overLib {
	my $self = shift;
	my $parm = { @_ };
	my $href = $parm->{'href'};
	unless ( $href ){
		$self->{plog}->error("has no href\n");
		return undef;
	}
	return '<a href="'.$href
		.'" onmouseover="return overlib(\''.$parm->{'on_mouse_over_message'}.'\');"'
		.' onmouseout="return nd();">'.$parm->{'text'}.'</a>';
}

1;
__END__

=head1 NAME

Tree::PseudoIncLib - Perl class encapsulating a description of pseudo-INC array.

=head1 ABSTRACT

This module encapsulates a perl-type library description data
and provides methods for manipulating that data.
It is in no way associated with any real @INC array on the system.
Instead, it works with so-called I<pseudo_INC> incoming array that might be, or might be not
directly associated with @INC defined for a particular user or a process on the system.

=head1 SYNOPSIS

 # make sure to configure the log system properly.
 #
  use Tree::PseudoIncLib;
 #
 # class default object:
 #
  my $tree_obj = Tree::PseudoIncLib->new();
 #
 # another instance:
 #
  my $sp_obj = $tree_obj->new (
	max_nodes => $my_max_nodes,	# limit number of nodes
	p_INC => $my_INC_copy_ref,
  );
  unless ( $sp_obj->from_scratch ) {
    # something went wrong:
    print ($sp_obj->status_as_string);
    die;
  }
 # we'we got a description inside the object.
 # we can export it to an appropriate form now...
 #
  my $src_html = $sp_obj->export_to_DHTML (
                title                   => 'Test-Debug',
                image_dir               => 'data/images/',
                icon_shaded             => 'file_x.gif',
                icon_folder_opened      => 'folder_opened.gif',
                icon_symlink            => 'hand.right.gif',
                tree_intend             => 18,
                row_class               => 'r0',
                css                     => '', # use 'inline' css
                jslib                   => '', # no jslib
                overlib                 => 'js/overlib.js',
  );
 # ... and deploy the document from $src_html then...

=head1 DESCRIPTION

Detailed description of Perl library on the system is extremely helpful for every perl developer.
It could be benefitial for the system administrator too
in order to ensure a proper structure of system libraries.

This module encapsulates the description data and provides methods for manipulating that data.
It was initially developed as an Apache incorporated tool for the mod_perl development.
The idea beside was pretty simple -- to provide developers with the tree of all available
perl modules installed on the system and make all sources and documents viewable on network.

As a side effect of the first developed prototype, it appeared to be usefull additionally
from the standpoint of proper configuration of @INC array on the system, particularly regarding
the fact that some perl modules could be shaded by other ones carrying the same CPAN class name.
It appears to be pretty easy to mark all shaded modules on the tree, providing helpful information
for the system administrator.

It was noticed additionally that the process of creation of the tree is extremely time consuming,
especially on busy web servers equiped with rich Perl libraries.
On the other hand, the content of the libraries remains unchanged usualy pretty long time
that is measured in days and weeks.
So far, the separation of the process of creation of the tree from the process of deployment
of the view to the client browser seems beneficial from the prospective of improvement of performance
on busy systems.
That was the main reason of creation of this module, making it possible to use the same API
from the command line script or one running under the cron control.

Despite the initial purpose, this version of the module is in no way associated
with any real @INC array on the system.
Instead, this module works with so-called I<pseudo_INC> incoming array that might be, or might be not
directly associated with current @INC for a particular user/process on the system.

=head2 Object Identification

It is sometimes required to keep several @INC descriptions on one system.
This mainly depends on the fact that @INC is often user-cpecific.
Apache::App::PerlLibTree is capable of managing several descriptions simultaniously
when every description has a unique name.

A part of the problem is addressed through the creation of unique file-names for the results
of C<export_to_DHTML> for every tree within the C<Apache::App::PerlLibTree>
(in associated cron scripts) and has nothing to do
with the class itself except the fact that we need to have a human-readable
identification of the tree inside the screen-view in order to make it clear for the user,
which tree is (s)he viewing.

This version of the module is using the following internal key for the object identification:

=over 4

=item tree_id

a string of identification that is dispayed on the screen for the end-user

=back

It is assumed that C<tree_id> will be containing sufficient information for the object
recognition by human user. It might contain blank spaces if necessary.
This data could be provided as an incoming parameter
for a I<new> method usually. A special public method exists to check/update C<tree_id>.

Note: This item is important for C<export_to_DHTML> only since the removal
of archive functionality.
The presence of this item in the area of the main object data is a subject of possible future changes...

=head2 Internal Object Data

Internal data of the object is basically a hash. However, some keys are referencing another
structured data like arrays, arrays of hashes, etc.

The full list of primary internal keys contains:

=over 4

=item tree_id

a string of identification that is dispayed on the screen for the human end-user

=item application_directory

a URL mask of the application from the C<Document Root> of web server

=item max_nodes

a watch-dog or down-counter of nodes represented in final document.
Terminates all further recursions when reaches the zerro value.

=item skip_empty_dir

boolen variable, means whether an empty directories should be skipped in final
tree representation, or not.

Note: Directory is considered empty when it does not contain any files of known types.
See C<allowed_files> for details.

=item skip_mode

boolen variable, means whether the information about permissions should be skipped in final
tree representation, or not.

=item skip_owner

boolen variable, means whether the information about the C<owner> should be skipped in final
tree representation, or not.

=item skip_group

boolen variable, means whether the information about the C<group> should be skipped in final
tree representation, or not.

=item descript

a reference to the array of hashes finally...

=item descript_internal_start_time

in internal date-time format

=item descript_internal_finish_time

in internal date-time format

=item descript_start_time_text

in text format: C<"%B %d, %Y at %H:%M">

=item descript_finish_time_text

in text format: C<"%B %d, %Y at %H:%M">

=item rpm_type

the type of packager used on the system

This version of the module recognizes only:

=over 4

=item RPM

=item dpkg

=back

Only RPM is supported currently.

=item rpm_active

boolen variable, means whether an RPM information should be presented in final document, or not.

Note: C<TRUE> might be for known RPM types only, C<FALSE> has no limits...

=item lib_index_prefix

for internal names

=item p_INC

a reference to array that contains the pathes representing pseudo-INC library

=item allow_files

a reference to the array of hashes, those describe allowed file types

=item plog

a reference to  C<Log::Log4perl> logger

=back

=head2 Watch-Dog

In order to prevent the program from the infinite loop during the creation of descriptions
I use one watch-dog inside the code:

=over 4

=item max_nodes

a global number of nodes those might be stored in a tree.

=back

All recursions are terminated upon the exhaust of C<max_nodes> counter.
The final return value of the method I<from_scratch> depends on exhaust of this counter.

=head2 Class Defaults

This version of the module provides the following defaults:

 APPLICATION_DIRECTORY => '/app/pltree/';# URL mask from the Apache Document_Root
 TREE_ID_DEFAULT  => 'Default_Tree';
 LIB_INDEX_PREFIX => 'lib';# default prefix for root library name
 MIN_LIMIT_NODES  => 15;   # min value for max_nodes setting validation
 LIMIT_NODES      => 15000;# default for max_nodes
 RPM_TYPE         => 'RPM';# default type of packaging system
 NO_RPM_OWNER     => undef;# '-' is not that convenient...
 SKIP_EMPTY_DIR_DEFAULT => 1; # true
 SKIP_MODE_DEFAULT      => 0; # false
 SKIP_OWNER_DEFAULT     => 0; # false
 SKIP_GROUP_DEFAULT     => 0; # false

=head2 Logging Policy

I use an open source C<Log::Log4perl> from CPAN in order to log information from my module.
It makes the logging system extremely flexible for the user.
This module logs C<error>, C<warn>, C<info>, and C<debug> messages.

I would recommend to use a global C<info> level of logging in routine jobs.
On this level module is logging two messages only:

=over 4

=item start_message

contains the identification of the object and the start time of the method I<from_scratch>

=item end_message

contains the end time of the method I<from_scratch> and a real-time duration of the process

=back

These C<info> messages could be helpful in order to identify description problems
originated from possible library update during the creation of description.

With C<Log::Log4perl> one can choose required log level on his own for each source method when necessary.
All log configurations are code-independent.
My log configuration file (for code testing) is available at C<data/log.config>
inside the distribution. It could be used as an example in order to create a quick start config.
Please see the documentation of C<Log::Log4perl> in order to configure
your logging system in accorance with your real needs.

=head2 Polymorphism

The class is polymorphism-ready. One can inherit everything with the simple declaration:

	package MyOwnTree;
		use Tree::PseudoIncLib;
		@ISA = ("Tree::PseudoIncLib");
	# do what you need...
	1;

=head1 PUBLIC METHODS

=head2 new

Creates the instance of the class. A I<new> instance can be created directly from the class like:

  my $tree_obj = Tree::PseudoIncLib->new();

or from another (existent) object of this class like:

  my $another_tree_object = $tree_obj->new();

It does not copy the content of the existent base instance in the last case.
Instead, it always creates the default class object when it is called with no incoming parameters.
Otherwise, icoming parameters have precedance over the class default values.
See method I<clone> for copy-constructor when necessary.

Method I<new> accepts a set of optional incoming parameters those should be represented as a hash:

=over 4

=item tree_id

a string of the tree identification that will be printed in view

=item application_directory

a string of the URL mask of the application

=item max_nodes

an integer number, big enough to count all nodes in the tree

=item p_INC

a reference to the array. See method for details.

=item skip_empty_dir

an integer, might be 0, or 1

=item skip_mode

an integer, might be 0, or 1

=item skip_owner

an integer, might be 0, or 1

=item skip_group

an integer, might be 0, or 1

=item allow_files

a reference to the array of hashes. See method for details.

=item rpm_type

a string

=item rpm_active

an integer, might be 0, or 1

=back

This method returns blessed object reference upon success.

Example of the use:

	my @pseudo_inc = ( $dir.'/data/testlibs/lib2',);
	# ...
	my $obj = Tree::PseudoIncLib->new(
		max_nodes  => 100,
		tree_id    => 'My Lovely Tree',
		p_INC => \@pseudo_inc,
	);

=head2 allow_files

This method provides access to the array of hashes
that defines the set of files those we wish to keep (and display)
within the tree of the library.
Technically, this method works with internal variable $self->{allow_files}
that keeps the reference to the mentioned array of hashes.
As an example of the structure, we can write:

	$self->{allow_files} = [
		{ mask => '.pm$',	icon => 'file.gif',
			name_on_click_action => 'source',
			icon_on_click_action => 'ps2html',
			name_mouse_over_prompt => 'view source',
			icon_mouse_over_prompt => 'view document',},
		{ mask => '.pod$',	icon => 'file_note.gif',
			name_on_click_action => 'source',
			icon_on_click_action => 'ps2html',
			name_mouse_over_prompt => 'view source',
			icon_mouse_over_prompt => 'view document',},
	];

This method takes one optional parameter -- a new reference to the array
of a similar structure.
It updates $self->{allow_files} when it is called with valid incoming value.
In this version an incoming data validation is pretty simple: it just checks
whether the incoming parameter is a reference to an C<ARRAY>.

This method returns the current value of $self->{allow_files} upon success.
Otherwise, it returns C<undef>.

Example of the use:

	my $obj = Tree::PseudoIncLib->new();
	my $target_files = [
		{ mask => '.pm$',	icon => 'file.gif',
			name_on_click_action => 'source',
			icon_on_click_action => 'ps2html',
			name_mouse_over_prompt => 'view source',
			icon_mouse_over_prompt => 'view document',},
		{ mask => '.pod$',	icon => 'file_note.gif',
			name_on_click_action => 'source',
			icon_on_click_action => 'ps2html',
			name_mouse_over_prompt => 'view source',
			icon_mouse_over_prompt => 'view document',},
	];
	$obj->allow_files( $target_files );

=head2 pseudo_INC

This method provides access to the array of paths, defining current pseudo_INC for the object.
Technically, this method works with internal variable $self->{p_INC}
that keeps the reference to the mentioned array.
The data structure is pretty simple and could be illustrated with the following example:

	$self->{p_INC} = [
		'/usr/lib/perl5/5.6.1/i386-linux',
		'/usr/lib/perl5/5.6.1',
		'/usr/lib/perl5/site_perl/5.6.1/i386-linux',
		'/usr/lib/perl5/site_perl/5.6.1',
		'/usr/lib/perl5/site_perl/5.6.0',
		'/usr/lib/perl5/site_perl',
		'/usr/lib/perl5/vendor_perl/5.6.1/i386-linux',
		'/usr/lib/perl5/vendor_perl/5.6.1',
		'/usr/lib/perl5/vendor_perl'
	];

This method takes one optional parameter -- a new reference to the array
of a similar structure.
It updates $self->{p_INC} when it is called with valid incoming value.
In this version an incoming data validation is pretty simple: it just checks
whether the incoming parameter is a reference to an C<ARRAY>.

This method always returns the current value of $self->{p_INC}.

Example of the use:

	my $obj = Tree::PseudoIncLib->new();
	my $target_dirs = [
		'/usr/lib/perl5/5.6.1/i386-linux',
		'/usr/lib/perl5/site_perl/5.6.1/i386-linux',
		'/usr/lib/perl5/site_perl',
	];
	$obj->pseudo_INC( $target_dirs );

=head2 tree_id

Provides access to the internal variable $self->{tree_id}.
This method takes one optional parameter -- a new value for the $self->{tree_id}.
It updates $self->{tree_id} when it is called with any incoming value that could
be evaluated to C<TRUE>.

It always returns the current value of $self->{tree_id}.

=head2 application_directory

Provides access to the internal variable $self->{application_directory}
that stores the URL mask of the application.
This method takes one optional parameter -- a new value for the $self->{application_directory}.
It updates $self->{application_directory} when it is called with any incoming value that could
be evaluated to C<TRUE>.

It always returns the current value of $self->{application_directory}.

=head2 rpm_type

Provides access to the internal variable $self->{rpm_type}.
This method takes one optional parameter -- a new value for the $self->{rpm_type}.
It updates $self->{rpm_type} when it is called with C<defined> incoming value
(even when the value is an empty string).

Note: This method changes the value of $self->{rpm_active} to 0 additionally
when it is called with C<defined> empty string as an incoming parameter,
because unknown type of RPM can not be active.

It always returns the current value of $self->{rpm_type}.

=head2 rpm_active

Provides access to the internal boolen variable $self->{rpm_active}.
This method takes one optional parameter -- a new value for the $self->{rpm_active}.
It updates $self->{rpm_active} when it is called with C<defined> incoming value
(even the value is 0, means set RPM inactive).

Note: It is prohibited to set unknown RPM type to active.
Error message is logged in this case.

This method always returns the current value of $self->{rpm_active}.

=head2 skip_empty_dir

Provides access to the internal boolen variable $self->{skip_empty_dir}.
This method takes one optional parameter -- a new value for the $self->{skip_empty_dir}.
It updates $self->{skip_empty_dir} when it is called with C<defined> incoming value
(even the value is 0, means allow to store and display empty directories in a tree structure).

Example code of the use:

	$obj->skip_empty_dir(0); # keep empty dirs in description
	# ...
	$obj->skip_empty_dir(1); # skip empty dirs

This method always returns the current value of $self->{skip_empty_dir}.

=head2 skip_mode

Provides access to the internal boolen variable $self->{skip_mode}.
This method takes one optional parameter -- a new value for the $self->{skip_mode}.
It updates $self->{skip_mode} when it is called with C<defined> incoming value
(even the value is 0, means allow to store and display permissions in a tree structure).

=head2 skip_owner

Provides access to the internal boolen variable $self->{skip_owner}.
This method takes one optional parameter -- a new value for the $self->{skip_owner}.
It updates $self->{skip_owner} when it is called with C<defined> incoming value
(even the value is 0, means allow to store and display node owner name in a tree structure).

=head2 skip_group

Provides access to the internal boolen variable $self->{skip_group}.
This method takes one optional parameter -- a new value for the $self->{skip_group}.
It updates $self->{skip_group} when it is called with C<defined> incoming value
(even the value is 0, means allow to store and display node group name in a tree structure).

=head2 max_nodes

Provides access to the internal watch-dog variable $self->{max_nodes}.
This method takes one optional numeric parameter -- a new value for the $self->{max_nodes}.
It updates $self->{max_nodes} when it is called with valid incoming value.
It logs an error message when it is called with invalid (low) value and sets $self->{max_nodes}
to C<MIN_LIMIT_NODES> -- a constant defined by the class, that is equal to 15 in this version.

Example of the use:

	$obj->max_nodes(50); # should be sufficient for the test...

This method always returns the current value of $self->{max_nodes}.

=head2 from_scratch

Creates a primary discription of the perl-library defined by $self->{p_INC} reference.
The result is a reference to the array of hashes that is stored internally in $self->{descript}.

This method does not require any incoming parameters.
It returnes the number of ctreated records upon success, otherwise - undef.

=head2 export_to_DHTML

Creates a DHTML page-code of the tree.

This method returns the multi-string of the created page upon success, otherwise - undef.

Example of the use:

  # assume $obj->from_scratch() is done OK, then:
  #
  my $src_html = $obj->export_to_DHTML (
                title                   => 'Test-Debug',
                image_dir               => 'data/images/',
                icon_shaded             => 'file_x.gif',
                icon_folder_opened      => 'folder_opened.gif',
                icon_symlink            => 'hand.right.gif',
                tree_intend             => 18,
                row_class               => 'r0',
                css                     => '', # use 'inline' css
                jslib                   => '', # no jslib
                overlib                 => 'js/overlib.js',
  );

=head2 status_as_string

This method provides an internal status of the object.
It takes no parameters, and returns the human readable multi-string.
It might be helpful to trace/debug the application that uses this object:

	$message = "Internal Status:\n".$self->status_as_string;
	$self->{plog}->debug($message);

=head2 list_descript_keys

This method takes no parameters.
It returns a reference to the array that contains
sorted alphabetically names of keys used anywhere inside the descriptions.
Array is generated dynamically using the recent content of descriptions.

=head2 list_simple_keys

This method takes no parameters.
It returns a reference to the array that contains a
sorted alphabetically set of names of simple keys of the object.
The list does not contain any keys representing references to another
arrays or hashes.

=head2 w3c_doctype

Creates and returnes the string of W3C document type.
This method accepts one mandatory incoming hash parameter:

=over 4

=item type

defines C<XHTML> or C<HTML> type of the exported document

=back

This version of the module is using an C<HTML> document type only.

	my $self = shift;
	my $res = $self->w3c_doctype( type => 'html' );

=head2 inline_CSS

Creates and returnes a multi-string of DHTML code representing in-line CSS for the page.
This method does not require incoming parameters in this version.

=head2 inc_html_table

Creates and returnes a multi-string of DHTML code representing pseudo-INC array.
Every line of this table is a link to an appropriate row of the main tree table.
This method requires one mandatory incoming hash parameter

=over 4

=item title

of the table to display

=back

Example of the use:

  $res .= $self->inc_html_table ( title => 'Library' );

=head1 PRIVATE METHODS

Methods of this group are not supposed to be used in applications directly,
they are subject to change in future versions.
All private methods could be inherited automatically,
or overwritten within the child class if necessary.

=head2 _dir_description

This method is used by C<from_scratch> method in order to
create a very primary description of so-called 'root directory' using recursion
into every child directory.

This version of the module distinguish 3 types of nodes:

=over 4

=item f - regular file

=item l - symlink

=item d - directory

=back

This method takes a mandatory hash of incoming parameters:

=over 4

=item root_dir

absolute address of the directory to explore (the trailing slash / might be omitted);

=item pseudo_cpan_root_name

estimation of the CPAN name for root_dir;

=item parent_index

unique object name for the root_dir;

=item parent_depth_level

depth level of root_dir inside the result tree;

=item prior_libs

a reference to the array of priorly described  libraries
those should not be repeated in description again;

=item inc_lib

a name of the current library as it appears in @INC;

=back

The result of _dir_description is a pretty complicated structure of arrays and hashes. 
Primarily, it is an array of hashes, where some keys might reference another (child)
arrays of hashes, and so on...

Every file/directory/symlink is described with the hash using the following set of keys:

=over 4

=item type

can be 'd', 'f', or 'l' in first position (stand for 'directory', 'file', or 'link');

=item inode

associated with the item;

=item permissions_octal_text

like '0755';

=item size

in bytes;

=item owner

name of the owner;

=item group

name of the group;

=item level

depth in the tree (beginning with 1 for the names listed in @INC);

=item name

local name of the file/link/directory (inside the parent directory);

=item full_name

absolute address like /full/path/to/the/file

=item pseudo_cpan_name

makes sense for the .pm file only; indeed is generated for directories too recursively;

=item last_mod_time_text

date/time of last modification in format "%B %d, %Y at %H:%M"

=item parent_index

unique name of the parent node/object;

=item self_index

unique name for the self node/object;

=item child_dir_list

a reference to the array of children descriptions;

=item rpm_package_name

optional key is used for real files only;

C<Note:> One directory can belong to many packages.
Appropriate description features might be a matter of further improvement,
not actual at the moment.

=item link_target

optional key is used for symlinks only;

=back

All children in every array are sorted by the name alphabetically.

Upon success _dir_description returns a reference to the created array of hashes.

=head2 _object_list

Transforms the internal description of the tree to the simple (regular) array of simple hashes.
This method takes one mandatory incomming parameter -- a reference to the array
of primary tree description.

This method returns a reference to the array of hashes upon success. Otherwise, it returns undef.
Every hash contains (some of) the following keys:

=over 4

=item pseudo_cpan_name

=item level

=item inc_lib

=item parent_obj_name

  = $_->{parent_index};

=item self_obj_name

  = $_->{self_index};

=item name

  = $_->{name};

=item type

=item size

=item last_mod_time_text

=item full_name

including absolute path

=item permissions_octal_text

=item owner

=item group

=item inode

=item icon

  = $_->{icon} if $_->{icon}; # defined for files only

=item allow_index

  = $_->{allow_index} if defined $_->{allow_index}; # for files only

=item rpm_package_name

  = $_->{rpm_package_name} if $_->{rpm_package_name};

=item link_target

  = $_->{link_target} if $_->{link_target};

=back

Note: This is not a full list of incoming keys.

Example of the use:

	$self->{descript} = $self->_object_list ($lib_list_ref);

=head2 _mark_shaded_names

Creates extended descriptions for shaded .pm files indicating which module
will really be loaded (executed) for given CPAN name.
Every shaded module is accomplished additionally with the following keys:

=over 4

=item shaded_by_lib

=item shaded_by_inode

=item shaded_by_last_modified

=back

This method takes no incoming parameters.
It returns the the reference to the array that contains the list of shaded names
in CPAN representation.

=head2 _html_head

Creates and returnes the HTML code of the C<head> section of DHTML page.

Takes 3 incoming parameters in a hash:

=over 4

=item title

of the page

=item jslib

optional file of external JavaScript for the page (to serve collapsable branches of the tree)

=item css

Cascaded Style Sheet of the page. Might be an external file, or just C<inline>.

=item overLib

file of external JavaScript overLIB.

=back

=head2 _descript_html_table_head_row

Creates and returnes the string of the head-row of the main DHTML table of tree description.
Takes no incoming parameters.

=head2 _link_icon_overLib

Creates and returnes the string of DHTML providing C<overLib> call on client side.

Takes the hash of the following incoming parameters:

=over 4

=item icon_src

=item on_click_href

=item on_mouse_over_message

=item hspace

for the image

=item border

for the image

=item align

for the image

=back

=head2 _link_text_overLib

Creates and returnes the string of DHTML providing C<overLib> call on client side.

Takes the hash of the following incoming parameters:

=over 4

=item text

=item on_click_href

=item on_mouse_over_message

=back

=head2 _data_row_HTML

This method creates one regular row of DHTML description table,
It takes the hash of mandatory incoming parameters:

=over 4

=item current_row_description

a reference to the hash of internal description of the tree item

=item image_dir

might be an absolute or relative path to the directory containing all icons

=item icon_shaded

to mark shaded files

=item icon_folder_opened

=item icon_symlink

=item tree_intend

intend (in pixels) between levels of the tree

=back

Example of the use:

  foreach ( @{$self->{descript}} ) {
    $res .= $self->_data_row_HTML(
      current_row_description => $_,
      image_dir               => $image_dir,
      icon_shaded             => $icon_shaded,
      icon_folder_opened      => $icon_folder_opened,
      icon_symlink            => $icon_symlink,
      tree_intend             => $tree_intend,
      row_class               => $row_class,
    )."\n";
  }

=head1 AUTHOR

Slava Bizyayev E<lt>slava@cpan.orgE<gt> - Freelance Software Developer & Consultant.

=head1 COPYRIGHT AND LICENSE

I<Copyright (C) 2004 Slava Bizyayev. All rights reserved.>

This package is free software.
You can use it, redistribute it, and/or modify it under the same terms as Perl itself.

The latest version of this module can be found on CPAN.

=head1 SEE ALSO

C<Apache::App::PerlLibTree> - mod_perl web application.

C<overLIB 3.51> Copyright Erik Bosrup 1998-2002. All rights reserved.
Available at F<http://www.bosrup.com/web/overlib/>

=cut

