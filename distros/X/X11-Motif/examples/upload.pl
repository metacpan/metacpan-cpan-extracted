#!/ford/thishost/unix/div/ap/bin/xperl -w

#use blib;

use strict;
use Sys::Hostname;
use IO::Handle;
use File::Path;
use X11::Motif;
use Date::DateCalc;
use PDM;

use lib qw(.);

use Outline qw(:flags);
use CPSC;

STDERR->autoflush(1);

my @rwx = ( '---', '--x', '-w-', '-wx', 'r--', 'r-x', 'rw-', 'rwx' );
my %uid_to_name = ();
my %gid_to_name = ();

my @today = localtime(time);
		$today[5] += 1900;
		$today[4] += 1;

my @month_name = qw(error Jan Feb Mar Apr May Jun
		          Jul Aug Sep Oct Nov Dec);
my @weekday_name = qw(error Mon Tue Wed Thu Fri Sat Sun);

my %folder_type_name = ( 'a' => 'Acoustic',
			 'c' => 'CFD',
			 'd' => 'Fatigue',
			 'f' => 'NVH',
			 'g' => 'Design Parameters',
			 'k' => 'Kinematic',
			 'r' => 'Fracture Mechanics',
			 's' => 'Stress',
			 't' => 'Thermal',
			 'v' => 'VSA',
			 'p' => 'Performance' );

my $hostname = Sys::Hostname::hostname();
my @userinfo = getpwuid($<);

my $cp_prg = find_executable("cp");

my $metaphase_login;
my $metaphase_password;
my $metaphase_home_db;
my $metaphase_current_db;
my $metaphase_current_project;
my $metaphase_staging_path;
my $metaphase_staging_name;
my $metaphase_session;

my %class_type_long_name = ( 'MstrGeom' => 'Design Geometry',
			     'DrvdGeom' => 'Derived Geometry' );
my %class_type_short_name = ();
my %metaphase_class_info = ();

my %opposite_side = ( 'Left' => 'Right', 'Right' => 'Left' );
my %opposite_side_class = ( 'Left' => 'Class2', 'Right' => 'Class1' );

my $font_size = 180;

#my $font_family_v_r = '-*-lucida-medium-r';
#my $font_family_v_i = '-*-lucida-medium-i';
#my $font_family_f_r = '-*-lucidatypewriter-medium-r';

#my $font_family_v_r = '-*-new century schoolbook-medium-r';
#my $font_family_v_i = '-*-new century schoolbook-medium-i';
#my $font_family_f_r = '-*-courier-medium-r';

my $font_family_v_r = '-*-helvetica-medium-r';
my $font_family_v_i = '-*-helvetica-medium-o';
my $font_family_f_r = '-*-courier-medium-r';

my $menu_font =  "$font_family_v_i-*-*-*-$font_size-*-*-*-*-*-*";
my $label_font = "$font_family_v_r-*-*-*-$font_size-*-*-*-*-*-*";
my $input_font = "$font_family_f_r-*-*-*-$font_size-*-*-*-*-*-*";

my $toplevel = X::Toolkit::initialize('APDataManager');
change $toplevel -title => 'AP Data Manager';

$toplevel->set_inherited_resources("*fontList" => $label_font,
				   "*menubar*fontList" => $menu_font,
				   "*menupopup*fontList" => $menu_font,
				   "*XmTextField.fontList" => $input_font,
				   "*menubar*background" => '#d0d0d0',
				   "*background" => '#d0d0d0',
				   "*foreground" => '#000000');

my $form = give $toplevel -Form;

my $menubar = give $form -MenuBar, -name => 'menubar';
my $menu;
my $submenu;

$menu = give $menubar -Menu, -name => 'File';
	$submenu = give $menu -Menu, -text => 'Create New';
		   give $submenu -Button, -text => 'Folder', -command => \&do_create_new_folder;
		   give $submenu -Button, -text => 'File';
		   give $submenu -Button, -text => 'Note';
		   give $submenu -Separator;
		   give $submenu -Button, -text => 'Analysis';
	give $menu -Separator;
	give $menu -Button, -text => 'Check In', -command => \&do_check_in;
	give $menu -Button, -text => 'Check Out';
	give $menu -Button, -text => 'Delete';
	give $menu -Separator;
	give $menu -Button, -text => 'Login To Metaphase', -command => \&require_metaphase;
	give $menu -Button, -text => 'Switch Database';
	give $menu -Separator;
	give $menu -Button, -text => 'Print', -command => \&do_print;
	give $menu -Separator;
	give $menu -Button, -text => 'Exit', -command => \&do_exit;

$menu = give $menubar -Menu, -name => 'Options';
	give $menu -Button, -text => 'Data Filters ...', -command => \&do_filter;
	give $menu -Separator;
	give $menu -Button, -text => 'File Types ...';
	give $menu -Button, -text => 'Storage Locations ...';
	give $menu -Button, -text => 'Display ...';
	give $menu -Separator;
	give $menu -Button, -text => 'Save Current Options';

$menu = give $menubar -Menu, -name => 'Help';
	give $menu -Button, -text => 'Putting Files In';
	give $menu -Button, -text => 'Getting Files Out';
	give $menu -Button, -text => 'Sharing Files';
	give $menu -Separator;
	give $menu -Button, -text => 'Choosing What To View';
	give $menu -Separator;
	give $menu -Button, -text => 'About Metaphase';
	give $menu -Button, -text => 'About PTO Data Browser';

my $pane = give $form -Pane,
			-sashWidth => 16,
			-sashHeight => 8,
			-spacing => 12,
			-sashIndent => -20;

my $tspace_form = give $pane -Form;
my $tspace_title = give $tspace_form -Label,
			-background => '#b0b0b0',
			-text => 'Metaphase';
#						 L    V   T    D    S    O
my $tspace_outline = new Outline $tspace_form, [ 800, 50, 200, 200, 150, 150 ],
			-maxDisplayWidth => 900,
			-indentationIncr => 32,
			-font => $label_font,
			-visibleRows => 15,
			-colorAltRows => 3,
			-altBackground => '#e0e0e0';

load_initial_tspace($tspace_outline);

$menu = give {$tspace_outline->canvas} -PopupMenu, -name => 'menupopup';
	give $menu -Button, -text => 'Reload From Metaphase', -command => \&do_reload;
	give $menu -Separator;
	give $menu -Button, -text => 'Check Out';
	give $menu -Button, -text => 'Delete';
	give $menu -Separator;
	give $menu -Button, -text => 'Find Vault', -command => \&do_find_vault;
	give $menu -Button, -text => 'Dump Object', -command => \&do_dump_object;

$tspace_outline->register_popup_menu($menu);

constrain $tspace_title -top => -form, -left => -form, -right => -form;
constrain {$tspace_outline->window} -top => $tspace_title, -bottom => -form, -left => -form, -right => -form;

my $uspace_form = give $pane -Form;
my $uspace_title = give $uspace_form -Label,
			-background => '#b0b0b0',
			-text => "Files on $hostname";
#						 L    T    D    S    O    P
my $uspace_outline = new Outline $uspace_form, [ 850, 200, 200, 150, 150, 100 ],
			-maxDisplayWidth => 900,
			-indentationIncr => 32,
			-font => $label_font,
			-visibleRows => 10,
			-colorAltRows => 3,
			-altBackground => '#e0e0e0';

load_initial_uspace($uspace_outline);

$menu = give {$uspace_outline->canvas} -PopupMenu, -name => 'menupopup';
	give $menu -Button, -text => 'Locate In Metaphase', -command => \&do_open_standard_ci_location;
	give $menu -Separator;
	give $menu -Button, -text => 'Set Anchor', -command => \&do_place_anchor;
	give $menu -Separator;
	give $menu -Button, -text => 'Check In', -command => \&do_check_in;
	give $menu -Button, -text => 'Delete';

$uspace_outline->register_popup_menu($menu);

constrain $uspace_title -top => -form, -left => -form, -right => -form;
constrain {$uspace_outline->window} -top => $uspace_title, -bottom => -form, -left => -form, -right => -form;

X::Motif::XmAddTabGroup($uspace_form);
X::Motif::XmAddTabGroup($tspace_form);

constrain $menubar -top => -form, -left => -form, -right => -form;
constrain $pane -top => $menubar, -bottom => -form, -left => -form, -right => -form;

load_startup();

handle $toplevel;

# --------------------------------------------------------------------------------

sub load_initial_uspace {
    my($outline) = @_;

    my $fullname = $userinfo[5];
    $fullname =~ s/\s*\(.*//;

    my $home =  { -label => "~$userinfo[0] ($fullname)",
		  -path => $ENV{HOME},
		  -load => \&hook_load_path,
		  -flags => IS_FOLDER };

    $outline->add_toplevel($home,
			    { -label => "System $hostname",
			      -path => '/',
			      -load => \&hook_load_path,
			      -flags => IS_FOLDER | IS_FILTERED } );

    $outline->open_child($home);

    $outline->reformat();
}

sub load_initial_tspace {
    my($outline) = @_;

    $outline->add_toplevel( { -label => 'Product Data',
			      -children => CPSC::tree(),
			      -load => \&hook_load_cpsc,
			      -flags => IS_FOLDER | IS_OPENED | IS_CACHED },
			    { -label => 'Personal Storage',
			      -load => \&hook_load_personal_storage,
			      -flags => IS_FOLDER } );

    $outline->reformat();
}

sub load_startup() {
}

# --------------------------------------------------------------------------------

sub hook_load_path {
    my($outline, $element) = @_;
    my $path = $element->{-path};

    return unless (defined($path) && chdir($path));

    if (opendir(DIR, '.')) {
	my @dirs = ();
	my @files = ();

	foreach (readdir(DIR)) {
	    next if ($_ eq '.' or $_ eq '..');
	    next if ($_ =~ /^\./);

	    if (-d $_) {
		push @dirs, $_;
	    }
	    else {
		push @files, $_;
	    }
	}

	closedir(DIR);
	my $child;

	foreach (sort @dirs) {
	    $child = { -label => "$_/",
		       -path => "$path/$_",
		       -flags => IS_FOLDER };

	    # this needs to be generalized - FIXME
	    if ($_ eq 'duct') {
		$child->{-autosel} = \&hook_autosel_duct_files;
	    }

	    $outline->add_child($element, $child);
	}

	foreach (sort @files) {
	    my @info = lstat($_);

	    $child = { -label => $_,							# L
		       -path => "$path/$_",
		       -desc => [ canonical_file_type($info[2], $_),			# T
				  canonical_file_date($info[9]),			# D
				  canonical_file_size($info[2], $info[3], $info[7]),	# S
				  canonical_file_owner($info[4], $info[5]),		# O
				  canonical_file_permissions($info[2]) ],		# P
		       -flags => 0 };

	    # generalize this too
	    if ($_ =~ /.tar$/) {
		$child->{-load} = \&hook_load_tar_file;
		$child->{-flags} |= IS_FOLDER;
	    }

	    $outline->add_child($element, $child);
	}
    }
}

sub hook_load_tar_file {
    my($outline, $element) = @_;
    my $path = $element->{-path};

    return unless (defined($path) && -r $path);

    if (open(TAR, "tar tf $path |")) {
	my @files = ();

	while (<TAR>) {
	    chomp $_;
	    push @files, $_;
	}

	close(TAR);
	my $child;

	foreach (sort @files) {
	    $child = { -label => $_,
		       -flags => 0 };

	    $outline->add_child($element, $child);
	}
    }
}

sub hook_autosel_duct_files {
    my($outline, $element) = @_;
    my %duct_file = ();
    my $version;

    # clear the parent directory
    $element->{-flags} &= ~IS_SELECTED;

    if ($element->{-label} eq 'duct/') {
	$element->{-flags} |= IS_ANCHOR;
    }

    foreach my $child (@{$element->{-children}}) {
	# for every duct input file

	if ($child->{-label} =~ /^([a-z]+\d*)([a-z]?).DuctInp$/) {
	    $version = (defined $2) ? $2 : '';
	    if (defined $duct_file{$1}) {
		# find the highest version

		if ($version gt $duct_file{$1}[0]) {
		    $duct_file{$1}[0] = $version;
		    $duct_file{$1}[1] = $child;
		}
	    }
	    else {
		# or the only version

		$duct_file{$1} = [ $version, $child ];
	    }
	}
    }

    foreach my $child (values %duct_file) {
	# and automatically select it.

	$child->[1]{-flags} |= IS_SELECTED;
    }
}

# --------------------------------------------------------------------------------

sub encode_key_props {
    my $prop = (ref $_[0] eq 'HASH') ? shift : { @_ };
    my $str = '';

    foreach my $key (sort keys %{$prop}) {
	$str .= ',' if ($str ne '');
	$str .= "$key=$prop->{$key}";
    }

    'K!'.$str;
}

sub decode_key_props {
    my($str, $prop) = @_;

    if (defined($str) && $str =~ s/^K!//) {
	my @seq = split(/,/, $str);
	my $val;
	$prop = { } if (!defined $prop);

	while (@seq) {
	    $val = shift @seq;
	    if ($val =~ s/^([^=]+)=//) {
		$prop->{$1} = $val;
	    }
	}
    }

    $prop;
}

sub encode_props {
    my $prop = (ref $_[0] eq 'HASH') ? shift : { @_ };
    my $str = '';
    my $val;

    foreach my $key (sort keys %{$prop}) {
	$str .= "\n\@\n" if ($str ne '');

	$val = $prop->{$key};
	$val =~ s/\@/\@\@/sg;

	$str .= "$key=$val";
    }

    $str;
}

sub decode_props {
    my($str, $prop) = @_;

    if (defined $str) {
	my @seq = split(/\n\@\n/, $str);
	my $key;
	my $val;
	$prop = { } if (!defined $prop);

	while (@seq) {
	    $val = shift @seq;

	    if ($val =~ s/^(\w+)=//) {
		$key = $1;
		$val =~ s/\@\@/\@/sg;

		$prop->{$key} = $val;
	    }
	}
    }

    $prop;
}

sub get_all_props {
    my($class, $obj, $element) = @_;

    if (!exists $element->{-props}) {
	my $props;

	if (exists $metaphase_class_info{$class}{'DataItemDesc'}) {
	    $props = decode_key_props($metaphase_session->GetAttribute($obj, 'DataItemDesc'));
	}
	if (exists $metaphase_class_info{$class}{'NoteData'}) {
	    $props = decode_props($metaphase_session->GetAttribute($obj, 'NoteData'), $props);
	}

	$element->{-props} = $props;
    }

    $element->{-props};
}

# --------------------------------------------------------------------------------

sub load_metaphase_class_info {
    my($class) = @_;

    foreach my $attr ($metaphase_session->GetAttributeNames($class)) {
	++$metaphase_class_info{$class}{$attr};
    }
}

sub decode_folder_type {
    my($element, $type_str) = @_;

    if (!defined($type_str) || $type_str eq '') {
	return 'Generic';
    }
    else {
	my $type = $element->{-foldertype};
	if (!defined $type) {
	    $type = [ split(//, $type_str) ];
	    $element->{-foldertype} = $type;
	}

	$type_str = '';
	foreach my $type_code (@{$type}) {
	    $type_str .= '/' if ($type_str ne '');
	    $type_str .= $folder_type_name{$type_code}
	}

	return $type_str;
    }
}

sub finish_element_from_obj {
    my($class, $obj, $element) = @_;

    my $label = '';
    my $short_label = '';
    my $long_label = '';
    my $hook;

    if (exists $metaphase_class_info{$class}{'PartNumber'}) {
	$short_label = $metaphase_session->GetAttribute($obj, 'PartNumber');

	if (exists $metaphase_class_info{$class}{'Nomenclature'}) {
	    $long_label = $metaphase_session->GetAttribute($obj, 'Nomenclature');
	}

	$hook = \&hook_load_part;
    }
    elsif (exists $metaphase_class_info{$class}{'a2zFordPartNum'}) {
	$short_label = $metaphase_session->GetAttribute($obj, 'a2zFordPartNum');

	if (exists $metaphase_class_info{$class}{'a2zName'}) {
	    $long_label = $metaphase_session->GetAttribute($obj, 'a2zName');
	}
    }
    elsif (exists $metaphase_class_info{$class}{'WorkingRelativePath'}) {
	$short_label = $metaphase_session->GetAttribute($obj, 'WorkingRelativePath');
	if (length($short_label) > 50) {
	    $short_label = '... '.substr($short_label, -50);
	}
    }
    elsif ($class eq 'Note') {
	my $props = get_all_props($class, $obj, $element);
	if (defined $props) {
	    if (defined($props->{'type_desc'}) && $props->{'type_desc'} ne '') {
		$short_label = $props->{'type_desc'};
	    }
	    else {
		$short_label = decode_folder_type($element, $props->{'t'});
	    }

	    if (defined $props->{'desc'}) {
		$long_label = $props->{'desc'};
	    }

	    $hook = \&hook_load_PTO_annotation;
	}
	else {
	    $short_label = $metaphase_session->GetAttribute($obj, 'NoteTitle');
	    $long_label = $metaphase_session->GetAttribute($obj, 'DataItemDesc');
	    $hook = \&hook_load_generic_item;
	}
    }
    elsif (exists $metaphase_class_info{$class}{'DocumentName'}) {
	$short_label = $class_type_long_name{$class};
	if (!defined $short_label) {
	    $short_label = $metaphase_session->GetAttribute($obj, 'DocumentName');
	    if ($short_label eq '') {
		$short_label = $metaphase_session->GetAttribute($obj, 'DocumentTitle');
	    }
	    else {
		$long_label = $metaphase_session->GetAttribute($obj, 'DocumentTitle');
	    }
	    if ($long_label eq '') {
		$long_label = $metaphase_session->GetAttribute($obj, 'DocumentDescription');
	    }
	}

	if ($class eq 'MstrGeom') {
	    $hook = \&hook_load_design_geom;
	}
	else {
	    $hook = \&hook_load_generic_item;
	}
    }
    elsif (exists $metaphase_class_info{$class}{'LastName'}) {
	my $l_name = $metaphase_session->GetAttribute($obj, 'LastName');
	my $f_name = $metaphase_session->GetAttribute($obj, 'FirstName');

	if ($l_name && $f_name) {
	    $short_label = "$l_name, $f_name";
	}
	else {
	    $short_label = $metaphase_session->GetAttribute($obj, 'Participant');
	}

	$hook = \&hook_load_person;
    }
    else {
	$short_label = $class;
	$long_label = "ID=".$metaphase_session->GetAttribute($obj, 'OBID');
    }

    if ($long_label eq '' || $short_label eq $long_label) {
	$label = $short_label;
    }
    else {
	if (length($long_label) > 50) {
	    substr($long_label, 50) = ' ...';
	}
	$label = "$short_label, $long_label";
    }

    $element->{-label} = $label;

    $element->{-desc} =
	[ canonical_version($class, $obj, $element),			# Version
	  canonical_type($class, $obj, $element),			# Type
	  canonical_date($class, $obj, $element, 'LastUpdate'),		# Date
	  canonical_size($class, $obj, $element),			# Size
	  canonical_owner($class, $obj, $element, 'OwnerName') ];	# Owner

    if (defined $hook) {
	$element->{-load} = $hook;
	$element->{-flags} |= IS_FOLDER;
    }
}

sub make_element_from_obj {
    my($obj) = @_;

    my $class = $metaphase_session->GetAttribute($obj, 'Class');

    if (!exists $metaphase_class_info{$class}) {
	load_metaphase_class_info($class)
    }

    my $element =  { -label => '',
		     -desc => '',
		     -obj => $obj,
		     -class => $class,
		     -obid => $metaphase_session->GetAttribute($obj, 'OBID'),
		     -db => $metaphase_session->GetAttribute($obj, 'CurDbName'),
		     -project => $metaphase_session->GetAttribute($obj, 'ProjectName'),
		     -flags => 0 };

    finish_element_from_obj($class, $obj, $element);

    $element;
}

sub load_objects_via_relation {
    my($obid, $relation, $opposite_side) = @_;

    my $side = ($opposite_side) ? 'Right' : 'Left';
    my %group = ();
    my %relation = ();

    foreach my $rel ($metaphase_session->FindRelations($relation, qq{$side = '$obid'})) {
	my $obid = $metaphase_session->GetAttribute($rel, $opposite_side{$side});
	my $class = $metaphase_session->GetAttribute($rel, $opposite_side_class{$side});

	$relation{$obid} = $rel;
	push @{$group{$class}}, $obid;
    }

    my @objects = ();

    foreach my $class (keys %group) {
	foreach my $query (query_many_objects_by_id($group{$class})) {
	    foreach my $obj ($metaphase_session->FindObjects($class, $query)) {
		my $child = make_element_from_obj($obj);
		$child->{-rel} = $relation{$child->{-obid}};
		push @objects, $child;
	    }
	}
    }

    @objects;
}

sub hook_load_cpsc {
    my($outline, $element) = @_;
    my $obid = $element->{-cpsc_obid};

    return unless defined($obid);
    return unless require_metaphase();

    my @children = load_objects_via_relation($obid, 'SysPart');

    foreach my $child (sort { $a->{-label} cmp $b->{-label} } @children) {
	$outline->add_child($element, $child);
    }
}

sub load_PTO_annotations {
    my($obid) = @_;

    my @children = ();

    print "*** Looking for annotations: NoteTitle = '$obid'\n";
    foreach my $obj ($metaphase_session->FindObjects('Note', qq{NoteTitle = '$obid'})) {
	push @children, make_element_from_obj($obj);
    }

    @children;
}

sub hook_load_PTO_annotation {
    my($outline, $element) = @_;
    my $obid = $element->{-obid};

    return unless defined($obid);
    return unless require_metaphase();

    my @children = ();
    push @children, load_objects_via_relation($obid, 'AdHocDep');
    push @children, load_PTO_annotations($obid);

    foreach my $child (sort { $a->{-label} cmp $b->{-label} } @children) {
	$outline->add_child($element, $child);
    }
}

sub hook_load_part {
    my($outline, $element) = @_;
    my $obid = $element->{-obid};

    return unless defined($obid);
    return unless require_metaphase();

    my @children = ();
    push @children, load_objects_via_relation($obid, 'PartDoc');
    push @children, load_PTO_annotations($obid);

    foreach my $child (sort { $a->{-label} cmp $b->{-label} } @children) {
	$outline->add_child($element, $child);
    }
}

sub hook_load_design_geom {
    my($outline, $element) = @_;
    my $obid = $element->{-obid};

    return unless defined($obid);
    return unless require_metaphase();

    my @children = ();
    push @children, load_objects_via_relation($obid, 'Attach');
    push @children, load_PTO_annotations($obid);

    foreach my $child (sort { $a->{-label} cmp $b->{-label} } @children) {
	$outline->add_child($element, $child);
    }
}

sub hook_load_generic_item {
    my($outline, $element) = @_;
    my $obid = $element->{-obid};

    return unless defined($obid);
    return unless require_metaphase();

    my $parent = $element->{-parent};
    my $parent_obid = (defined $parent) ? $parent->{-obid} : '';

    my @children = ();
    push @children, load_objects_via_relation($obid, 'Relation');
    push @children, load_objects_via_relation($obid, 'Relation', 1);
    push @children, load_PTO_annotations($obid);

    foreach my $child (sort { $a->{-label} cmp $b->{-label} } @children) {
	next if ($parent_obid eq $child->{-obid});
	$outline->add_child($element, $child);
    }
}

sub hook_load_personal_storage {
    my($outline, $element) = @_;

    return unless require_metaphase();

    my @children = ();

    foreach my $child ($metaphase_session->FindObjects('Usr', qq(Dept like 'N406%'))) {
	push @children, make_element_from_obj($child);
    }

    foreach my $child (sort { $a->{-label} cmp $b->{-label} } @children) {
	$outline->add_child($element, $child);
    }
}

sub hook_load_person {
    my($outline, $element) = @_;
    my $obj = $element->{-obj};

    return unless defined($obj);
    return unless require_metaphase();

    my @children = ();

    my $user = $metaphase_session->GetAttribute($obj, 'Participant');

    foreach my $child ($metaphase_session->FindObjects('Note', qq(Creator = '$user'))) {
	push @children, make_element_from_obj($child);
    }

    foreach my $child (sort { $a->{-label} cmp $b->{-label} } @children) {
	$outline->add_child($element, $child);
    }

    my $misc = { -label => 'All Owned Items',
		 -desc => '',
		 -obj => $obj,
		 -user => $user,
		 -obid => $element->{-obid},
		 -load => \&do_load_owned_items,
		 -flags => IS_FOLDER };

    $outline->add_child($element, $misc);

    $misc =    { -label => 'All Related Items',
		 -desc => '',
		 -obj => $obj,
		 -user => $user,
		 -obid => $element->{-obid},
		 -load => \&do_load_related_items,
		 -flags => IS_FOLDER };

    $outline->add_child($element, $misc);
}

sub do_load_owned_items {
    my($outline, $element) = @_;
    my $user = $element->{-user};

    return unless defined($user);
    return unless require_metaphase();

    my @children = ();

    foreach my $child ($metaphase_session->FindObjects('OwnedItm', qq(OwnerName = '$user'))) {
	push @children, make_element_from_obj($child);
    }

    foreach my $child (sort { $a->{-label} cmp $b->{-label} } @children) {
	$outline->add_child($element, $child);
    }
}

sub do_load_related_items {
    my($outline, $element) = @_;
    my $obid = $element->{-obid};

    return unless defined($obid);
    return unless require_metaphase();

    my @children = ();
    push @children, load_objects_via_relation($obid, 'Relation');
    push @children, load_objects_via_relation($obid, 'Relation', 1);

    foreach my $child (sort { $a->{-label} cmp $b->{-label} } @children) {
	$outline->add_child($element, $child);
    }
}

sub query_many_objects_by_id {
    my($raw_obid_list) = @_;
    my @queries = ();

    if (defined($raw_obid_list) && ref($raw_obid_list) eq 'ARRAY') {
	my $max_size = 20;
	my $i = 0;
	my $query = '';

	foreach my $obid (@{$raw_obid_list}) {
	    $query .= ' or ' if ($query ne '');
	    $query .= qq(OBID = '$obid');

	    ++$i;

	    if ($i >= $max_size) {
		push @queries, $query;
		$i = 0;
		$query = '';
	    }
	}

	if ($query ne '') {
	    push @queries, $query;
	}
    }

    return @queries;
}

sub canonical_file_type {
    my($mode, $filename) = @_;
    my $type;

    if (($mode & 0xF000) == 0x4000) {
	$type = 'directory';
    }
    else {
	$type = 'file';
    }

    $type;
}


sub canonical_file_date {
    my $then = shift;
    my @time = localtime($then);

    if ($then > time - 7776000) {
	my $hour = $time[2];
	my $tod;

	if    ($hour >= 12) { $hour -= 12; $tod = 'pm' }
	else                { $tod = 'am' }
	if    ($hour == 0)  { $hour = 12 }

	"$weekday_name[$time[6]+1] $month_name[$time[4]+1] $time[3], $hour:$time[1] $tod";
    }
    else {
	"$month_name[$time[4]+1] $time[3], ".(1900+$time[5]);
    }
}

sub canonical_file_size {
    my($mode, $links, $size) = @_;

    if (($mode & 0xF000) == 0x4000) {
	$size = '';
    }
    else {
	$size = sprintf('%.2f K', $size / 1024);
	while ($size =~ s/^(-?\d+)(\d{3})/$1,$2/) { }
    }

    $size;
}

sub canonical_file_owner {
    my($uid, $gid) = @_;

    if (!exists $uid_to_name{$uid}) {
	my @info = getpwuid($uid);
	$uid_to_name{$uid} = $info[0];
    }
    $uid = $uid_to_name{$uid};

    if (!exists $gid_to_name{$gid}) {
	my @info = getgrgid($gid);
	$gid_to_name{$gid} = $info[0];
    }
    $gid = $gid_to_name{$gid};

    "$uid/$gid";
}

sub canonical_file_permissions {
    my($mode) = @_;

    my $perms = $rwx[$mode & 7];
    $mode >>= 3;
    $perms = $rwx[$mode & 7] . $perms;
    $mode >>= 3;
    $perms = $rwx[$mode & 7] . $perms;

    $perms;
}

sub canonical_version {
    my($class, $obj, $element) = @_;

    my $ver = $metaphase_session->GetAttribute($obj, 'Sequence');

    if (exists $metaphase_class_info{$class}{'Revision'}) {
	$ver = $metaphase_session->GetAttribute($obj, 'Revision') . '/' . $ver;
    }

    $ver;
}

sub canonical_type {
    my($class, $obj, $element) = @_;

    my $type = $class_type_short_name{$class};

    if (!defined $type) {
	if (exists $metaphase_class_info{$class}{'WorkingRelativePath'}) {
	    my $props = get_all_props($class, $obj, $element);
	    if ($props) {
		$type = $props->{'T'};
		if (defined $type) {
		    $type .= '/'.$props->{'S'};
		}
		else {
		    $type = 'data';
		}
		if (defined $type && defined($props->{'V'})) {
		    $type .= ';'.$props->{'V'};
		}
	    }
	    else {
		$type = $class . ':' . $metaphase_session->GetAttribute($obj, 'm0MIMEType');
		if (defined $type) {
		    $type .= '/'.$metaphase_session->GetAttribute($obj, 'm0MIMESubType');
		}
		else {
		    #$type = $class;
		}
	    }
	}
	else {
	    $type = $class;
	}
    }

    $type;
}

sub canonical_date {
    my($class, $obj, $element, $attr) = @_;
    my $date = $metaphase_session->GetAttribute($obj, $attr);

    my($year, $month, $day, $hour, $min) = ($date =~ m|^(\d+)/0*(\d+)/0*(\d+)-0*(\d+):0*(\d+)|);
    my $sec = 0;

    ($year, $month, $day,
     $hour, $min, $sec) = Date::DateCalc::calc_new_date_time($year, $month, $day,
							     $hour, $min, $sec,
							     0, -4, 0, 0);

    if (($today[5] - $year) * 12 + $today[4] - $month < 3) {
	my $tod;

	if    ($hour >= 12) { $hour -= 12; $tod = 'pm' }
	else                { $tod = 'am' }
	if    ($hour == 0)  { $hour = 12 }

	my $weekday = Date::DateCalc::day_of_week($year, $month, $day);
	$min = sprintf("%02d", $min);

	"$weekday_name[$weekday] $month_name[$month] $day, $hour:$min $tod";
    }
    else {
	"$month_name[$month] $day, $year";
    }
}

sub canonical_size {
    my($class, $obj, $element) = @_;

    my $size = '';
    if (exists $metaphase_class_info{$class}{'WorkingRelativePath'}) {
	$size = '? K';
    }

    $size;
}

sub canonical_owner {
    my($class, $obj, $element, $attr) = @_;

    $metaphase_session->GetAttribute($obj, $attr);
}

# --------------------------------------------------------------------------------

sub do_exit {
    my($w) = @_;

    if ($metaphase_session) {
	$metaphase_session->Logout;
	PDM::DumpCallProfile();
    }

    exit;
}

# --------------------------------------------------------------------------------

sub _filter_items {
    my($parent, $child) = @_;

    my $path = $child->{-path};
    my $label = $child->{-label};

    #if (defined $path && ($label =~ /^\./ || $label =~ /^#/)) {

    if (defined $path && !($label =~ /^[A-Z]/ || $label =~ /\./)) {
	$child->{-flags} |= IS_FILTERED;
    }

    $child->{-flags} &= ~IS_SELECTED;
}

sub do_filter {
}

# --------------------------------------------------------------------------------

sub do_print {
}

sub find_vault {
    my($item) = @_;
    my($vault, $vault_loc, $project);
    my($db, $cpsc, $chunk, $t);

    # might want more information on the item?  stash the actual vault
    # used by the business items?  stash the vault and vault loc that
    # were used previously?  (actually, it should only be necessary to
    # figure out the vault and vault loc when transferring ownership.
    # check in should be able to figure out where things came from.)

    while ($item) {
	$t = $item->{-project};
	if (!defined($project) && defined($t) && $t ne '') {
	    $project = $t;
	}

	$t = $item->{-db};
	if (!defined($db) && defined($t) && $t ne '') {
	    $db = $t;
	}

	$t = $item->{-cpsc};
	if (!defined($cpsc) && defined($t) && $t ne '') {
	    $cpsc = $t;
	}

	$t = $item->{-chunk};
	if (!defined($chunk) && defined($t) && $t ne '') {
	    $chunk = $t;
	}

	$item = $item->{-parent};
    }

    if (!defined $project) {
	$project = $metaphase_current_project;
    }

    if (!defined $db) {
	if ($project =~ /^(\w+)-/) {
	    $db = $1;
	}
	else {
	    $db = $metaphase_current_db;
	}
    }

    if (defined $cpsc && $cpsc =~ /^(..)\.(..)/) {
	$vault = "$db $1-";
	$vault_loc = "$db $1$2-";
    }
    elsif (defined $chunk && $chunk =~ /^(\d\d)(\d\d)/) {
	$vault = "$db $1-";
	$vault_loc = "$db $1$2-";
    }
    else {
	# what location should be used if nothing else can be figured out?!?
	# should the transfer be aborted?

	$vault = "$db 00-";
	$vault_loc = "$db 0000-";
    }

    return ($vault, $vault_loc, $project);
}

sub do_reload {
    foreach my $item ($tspace_outline->selection) {
	$tspace_outline->forget_cache($item);
	$tspace_outline->open_child($item, 1);
    }
    $tspace_outline->reformat();
}

sub do_find_vault {
    return unless require_metaphase();

    foreach my $item ($tspace_outline->selection) {
	my($vault, $vault_loc, $project) = find_vault($item);

	print "items under '$item->{-label}' go into vault=$vault, loc=$vault_loc, project=$project\n";
	print "  user=$metaphase_login\n";
	print "  home-db=$metaphase_home_db\n";
	print "  current-db=$metaphase_current_db\n";
	print "  current-project=$metaphase_current_project\n";
	print "  staging=$metaphase_staging_path ($metaphase_staging_name)\n";
    }
}

sub do_dump_object {
    return unless require_metaphase();

    foreach my $item ($tspace_outline->selection) {
	if (exists $item->{-rel}) {
	    print "*** RELATION:\n";
	    $metaphase_session->Dump($item->{-rel});
	}
	if (exists $item->{-obj}) {
	    print "*** OBJECT:\n";
	    $metaphase_session->Inflate($item->{-obj});
	    $metaphase_session->Dump($item->{-obj});
	}
    }
}

# --------------------------------------------------------------------------------

sub do_place_anchor {
    my @uspace_items = $uspace_outline->selection;

    if (@uspace_items == 0) {
	popup_error("You must select at least one item\nto set as the anchor.");
	return;
    }

    foreach my $item (@uspace_items) {
	if ($item->{-flags} & IS_ANCHOR) {
	    $item->{-flags} &= ~IS_ANCHOR;
	}
	else {
	    $item->{-flags} |= IS_ANCHOR;
	}
    }

    $uspace_outline->redraw;
}

sub do_check_in {
    return unless require_metaphase();

    my @uspace_items = $uspace_outline->selection;
    my @tspace_items = $tspace_outline->selection;

    if (@tspace_items != 1) {
	my $mess = "You must select one location for your items to be\nchecked into.";
	if (@tspace_items == 0) {
	    $mess .= "  You haven't selected any.";
	}
	else {
	    $mess .= "  You've selected too many.";
	}
	popup_error($mess);
	return;
    }

    if (@uspace_items == 0) {
	popup_error("You must select at least one item to check in.");
	return;
    }

    foreach my $item (@uspace_items) {
	check_in_file($item, $tspace_items[0]);
    }

    $tspace_outline->reformat();
}

# --------------------------------------------------------------------------------

sub do_destroy_self {
    my($w) = @_;

    $w->XtDestroyWidget();
}

sub do_destroy_shell {
    my($w) = @_;

    $w = $w->XtShell();
    $w->XtDestroyWidget();
}

sub do_destroy_shell_and_return {
    my($w) = @_;

    $w = $w->XtShell();
    $w->XtDestroyWidget();

    X::Toolkit::Widget::return_from_handler;
}

sub popup_error {
    my($message) = @_;

    give $toplevel -Dialog,
		-type => -information,
		-title => 'Need a location',
		-ok => \&do_destroy_self,
		-message => $message;
}

sub create_new_folder_dialog {
    my($title, $proc) = @_;

    my $shell = give $toplevel -Transient,
			-resizable => X::True,
			-title => $title;

    my $form = give $shell -Form,
			-managed => X::False,
			-name => 'top_form',
			-resizePolicy => X::Motif::XmRESIZE_GROW,
			-horizontalSpacing => 5,
			-verticalSpacing => 5;

    $form->set_inherited_resources("*fname.width" => 150);

    my $name_label = give $form -Label,
			-name => 'fname',
			-text => 'Name: ',
			-alignment => X::Motif::XmALIGNMENT_END;

    my $name = give $form -Field,
			-name => 'name';

    my $purpose_label = give $form -Label,
			-name => 'fname',
			-text => 'Purpose: ',
			-alignment => X::Motif::XmALIGNMENT_END;

    my $purpose = give $form -RowColumn,
			-name => 'purpose',
			-packing => X::Motif::XmPACK_COLUMN,
			-numColumns => 2;

    foreach my $analysis_type (sort { $a->[1] cmp $b->[1] }
			       map { [ $_, $folder_type_name{$_} ] } keys %folder_type_name)
    {
	give $purpose -Toggle,
			-name => $analysis_type->[0],
			-text => $analysis_type->[1];
    }

    my $line_1 = give $form -Separator;

    my $year_label = give $form -Label,
			-name => 'fname',
			-text => 'Model Year: ',
			-alignment => X::Motif::XmALIGNMENT_END;

    my $year = give $form -Field,
			-name => 'year';

    my $line_2 = give $form -Spacer;

    my $spacer = give $form -Spacer;

    my $ok = give $form -Button,
			-text => 'OK',
			-command => sub {
			    my($w) = @_;
			    &{$proc}($form);
			    do_destroy_shell($w)
			};

    my $cancel = give $form -Button,
			-text => 'Cancel',
			-command => \&do_destroy_shell;

    constrain $name_label -top => -form, -left => -form;
    constrain $name -top => -form, -left => $name_label, -right => -form;

    constrain $purpose_label -top => $name, -left => -form;
    constrain $purpose -top => $name, -left => $purpose_label, -right => -form;

    constrain $line_1 -top => $purpose, -left => -form, -right => -form;

    constrain $year_label -top => $line_1, -left => -form;
    constrain $year -top => $line_1, -left => $year_label, -right => -form;

    constrain $line_2 -top => $year, -bottom => $ok, -left => -form, -right => -form;

    constrain $cancel -right => -form, -bottom => -form;
    constrain $ok -right => $cancel, -bottom => -form;
    constrain $spacer -left => -form, -right => $ok;

    $form->ManageChild();
    $shell->Popup(X::Toolkit::GrabNonexclusive);
}

sub do_create_new_folder {
    return unless require_metaphase();

    my @tspace_items = $tspace_outline->selection;

    if (@tspace_items != 1) {
	popup_error("You must select a location in\nMetaphase for your folder.");
    }
    else {
	my $parent = $tspace_items[0];

	$tspace_outline->open_child($parent, 1);
	$tspace_outline->reformat();

	create_new_folder_dialog("New Folder", sub { create_new_folder($parent, @_) });
    }
}

sub create_new_folder {
    my($parent, $form) = @_;

    my $name_widget = X::Toolkit::search_from_parent($form, "name");
    my $name = X::Motif::XmTextFieldGetString($name_widget);

    $name =~ s/^\s+//;
    $name =~ s/\s+$//;
    $name =~ s/\s+/ /g;

    my $year_widget = X::Toolkit::search_from_parent($form, "year");
    my $year = X::Motif::XmTextFieldGetString($year_widget);

    $year =~ s/^\s+//;
    $year =~ s/\s+$//;
    $year =~ s/\s+/ /g;

    $year = $year - 1990;

    my @folder_type;
    my $purpose_widget = X::Toolkit::search_from_parent($form, "purpose");
    foreach my $toggle ($purpose_widget->Children) {
	if (query $toggle -set) {
	    push @folder_type, $toggle->Name;
	}
    }

    my $parent_class = (defined $parent->{-class}) ? $parent->{-class} : '*';
    my $parent_obid = (defined $parent->{-obid}) ? $parent->{-obid} : '*';
    my $parent_label = $parent->{-label};

    my $key_props = encode_key_props('t' => join('', sort @folder_type), 'Y' => $year);
    my $props = encode_props('desc' => $name,
			     'parent' => "$parent_class,$parent_obid,$parent_label");

    my $obj = $metaphase_session->CreateObject('Note',
				     'NoteTitle' => $parent_obid,
				     'DataItemDesc' => $key_props,
				     'NoteData' => $props);

    my $child = make_element_from_obj($obj);
    $child->{-flags} |= (IS_CACHED | IS_OPENED);

    $tspace_outline->clear_selection();
    $tspace_outline->add_child($parent, $child);
    $tspace_outline->select_child($child);

    $tspace_outline->reformat($child);
}

sub open_cpsc_folder {
    my($cpsc) = @_;

    if ($cpsc =~ /^(..)\.(..)\./) {
	$tspace_outline->open_path_from_root("Product Data", "$1 - ", "$1.$2 - ", "$cpsc - ");
    }
}

sub do_open_standard_ci_location {
    return unless require_metaphase();

    my @uspace_items = $uspace_outline->selection;

    if (@uspace_items != 1) {
	popup_error("You must select exactly one item to locate.");
	return;
    }

    my $path = $uspace_items[0]->{-path};

    if (defined $path) {
	my $top_child;

	if ($path =~ m|/duct/([^/]+)|) {
	    my $pn = uc $1;
	    my @pn = split(/-/, $pn);

	    if (@pn == 3) {
		my $cpsc = CPSC::find_cpsc_for_part_base($pn[1]);

		if (defined $cpsc) {
		    my $folder = open_cpsc_folder($cpsc);

		    if (defined $folder) {
			$tspace_outline->clear_selection();
			$top_child = $tspace_outline->open_child_by_name($pn);

			if ($top_child) {
			    $folder = $tspace_outline->select_child_by_name('Design Parameters');
			    unless ($folder) {
				$tspace_outline->select_child($top_child);
			    }
			}
		    }
		}
		else {
		    popup_error("What CPSC does the part number base '$pn[1]' belong to?");
		}
	    }
	}

	$tspace_outline->reformat($top_child);
    }
}

sub do_fetch_login_info {
    my($w) = @_;

    my $form = $w->Parent();

    my $name_widget = X::Toolkit::search_from_parent($form, "name");
    $metaphase_login = X::Motif::XmTextFieldGetString($name_widget);

    my $password_widget = X::Toolkit::search_from_parent($form, "password");
    $metaphase_password = X::Motif::XmTextFieldGetString($password_widget);

    do_destroy_shell_and_return($w);
}

sub popup_metaphase_login_dialog {
    my $shell = give $toplevel -Transient,
			-resizable => X::False,
			-title => 'Metaphase Login';

    my $form = give $shell -Form,
			-managed => X::False,
			-name => 'top_form',
			-resizePolicy => X::Motif::XmRESIZE_NONE,
			-horizontalSpacing => 5,
			-verticalSpacing => 5;

    $form->set_inherited_resources("*fname.width" => 150);

    my $name_label = give $form -Label,
			-name => 'fname',
			-text => 'Name: ',
			-alignment => X::Motif::XmALIGNMENT_END;

    my $name = give $form -Field,
			-name => 'name';

    my $password_label = give $form -Label,
			-name => 'fname',
			-text => 'Password: ',
			-alignment => X::Motif::XmALIGNMENT_END;

    my $password = give $form -Field,
			-name => 'password';

    my $spacer_1 = give $form -Spacer;
    my $spacer_2 = give $form -Spacer;

    my $ok = give $form -Button,
			-text => 'OK',
			-command => \&do_fetch_login_info;

    my $cancel = give $form -Button,
			-text => 'Cancel',
			-command => \&do_destroy_shell_and_return;

    constrain $name_label -top => -form, -left => -form;
    constrain $name -top => -form, -left => $name_label, -right => -form;

    constrain $password_label -top => $name, -left => -form;
    constrain $password -top => $name, -left => $password_label, -right => -form;

    constrain $spacer_2 -left => -form, -right => -form, -top => $password, -bottom => $cancel;

    constrain $cancel -right => -form, -bottom => -form;
    constrain $ok -right => $cancel, -bottom => -form;
    constrain $spacer_2 -left => -form, -right => $ok;

    $form->ManageChild();
    $shell->Popup(X::Toolkit::GrabNonexclusive);

    print "going into nested handler...\n";
    handle $shell;
    print "returned from nested handler...\n";
}

sub require_metaphase {
    if (!$metaphase_session) {
	popup_metaphase_login_dialog();
	initialize_metaphase();
    }

    ($metaphase_session) ? 1 : 0;
}

sub initialize_metaphase {
    if (!$metaphase_session) {
	PDM::SetLoggingLevel(100);
	PDM::SetLoggingFile("log");

	$metaphase_session = PDM::Login($metaphase_login, $metaphase_password);
	return if (!$metaphase_session);
    }

    PDM::SetQueryScope($metaphase_session, "-", qw(PTO_DRBN));

    my $owner_dir;
    my @owner_dir = ( "APSA: $hostname",
		      "TAPSA: $hostname" );

    my $dir;
    my @dir =	    ( "$ENV{'HOME'}/.ap/$hostname-staging-$metaphase_login",
		      "/tmp/$metaphase_login/.ap/$hostname-staging" );

    while (defined($dir = shift @dir)) {
	$owner_dir = shift @owner_dir;

	next if ($dir eq '/' || $dir =~ m|/tmp/|);
	if (-d $dir || mkpath($dir, 0, 0755)) {
	    last if (-w $dir || chmod(0755, $dir));
	}
    }

    # This should disable check-in/check-out.  FIXME

    return if (!defined $dir);

    my($obj) = $metaphase_session->FindObjects('WorkSDir',
				     qq(OwnerName = '$metaphase_login' and OwnerDirName = '$owner_dir'));

    if (!defined $obj) {
	print "No AP file transfer area on host $hostname!  Creating one...\n";

	$obj = $metaphase_session->CreateObject('WorkSDir',
				      'OwnerDirName', $owner_dir,
				      'FullPath', $dir,
				      'AcceptFSItemOption', '-',
				      'OwnD', '+', 'GrpD', '-', 'OthD', '-', 'SysD', '-',
				      'OwnR', '+', 'GrpR', '+', 'OthR', '+', 'SysR', '+',
				      'OwnS', '+', 'GrpS', '+', 'OthS', '+', 'SysS', '+',
				      'OwnW', '+', 'GrpW', '+', 'OthW', '-', 'SysW', '-',
				      'OwnX', '+', 'GrpX', '+', 'OthX', '+', 'SysX', '+');
    }

    if ($obj) {
	$metaphase_session->Inflate($obj);

	$metaphase_home_db = $metaphase_session->GetAttribute($obj, 'CurDbName');
	$metaphase_staging_path = $metaphase_session->GetAttribute($obj, 'FullPath');
	$metaphase_staging_name = $metaphase_session->GetAttribute($obj, 'OwnerDirName');

	# This needs to be configurable!  FIXME

	$metaphase_current_db = $metaphase_home_db;
	if ($metaphase_current_db eq 'PTO_DRBN') {
	    $metaphase_current_project = 'PTO_DRBN-Engine';
	}
	elsif ($metaphase_current_db eq 'PTO_LIV') {
	    $metaphase_current_project = 'PTO_LIV-Transmission';
	}
    }

    $obj;
}

sub find_anchor {
    my($item) = @_;
    my $parent = $item->{-parent};

    while (defined $parent->{-path} && !($item->{-flags} & IS_ANCHOR)) {
	$item = $parent;
	$parent = $item->{-parent};
    }

    $item;
}

sub check_in_file {
    my($src, $dst) = @_;

    my $src_path = $src->{-path};
    if (! -f $src_path) {
	print STDERR "no source file!\n";
	return;
    }

    my $dst_obj = $dst->{-obj};
    if (!defined $dst_obj) {
	print STDERR "no destination folder!\n";
	return;
    }

    my($vault, $vault_loc, $project) = find_vault($dst);

    my $anchor = find_anchor($src);
    my $anchor_path = $anchor->{-path};

    my $dst_relative_path = $src_path;
    $dst_relative_path =~ s|^$anchor_path/||;
    my $dst_path = "$metaphase_staging_path/$dst_relative_path";

    print STDERR "Checking '$src_path' into <$vault/$vault_loc> as '$dst_relative_path'\n";

    my $dst_dir = $dst_path;
    $dst_dir =~ s|/[^/]+$||;

    mkpath($dst_dir, 0, 0755);

    print STDERR "  1. Registering file... ";

    my $src_obj = $metaphase_session->CreateObject('OsDepBin',
					     'RelDirPath' => $dst_relative_path,
					     'OwnerDirName' => $metaphase_staging_name,
					     'DataItemDesc' => 'K!T=text,S=ascii,D=this is a test',
					   # 'ProjectName' => $project,
					     'RegisterInDB' => '+');

    print STDERR "  done\n";
    print STDERR "  2. Copying file to staging area... ";

    unlink($dst_path);
    link_or_copy_file($src_path, $dst_path);

    print STDERR "  done\n";
    print STDERR "  3. Connecting to folder... ";

    my $rel = $metaphase_session->CreateRelation('AdHocDep', $dst_obj, $src_obj);

    print STDERR "  done\n";
    print STDERR "  4. Uploading to Metaphase... ";

    $metaphase_session->TransferOwnership($src_obj, $vault, $vault_loc, 1);

    print STDERR "  done\n";

    my $child = make_element_from_obj($src_obj);
    $tspace_outline->add_child($dst, $child);

    print STDERR "  Check-in complete.\n";
}

sub link_or_copy_file {
    my($src_path, $dst_path) = @_;

    if (!link($src_path, $dst_path)) {
	if (defined $cp_prg) {
	    system("$cp_prg '$src_path' '$dst_path'");
	}
	else {
	    if (open(OUT, "> $dst_path")) {
		if (open(IN, "< $src_path")) {
		    while (<IN>) {
			print OUT;
		    }
		    close IN;
		}
		close OUT;
	    }
	}
    }
}

sub find_executable {
    my($prg) = @_;

    foreach my $dir (split(/:/, $ENV{'PATH'})) {
	my $fullname = "$dir/$prg";
	if (-x $fullname) {
	    return $fullname;
	}
    }
}
