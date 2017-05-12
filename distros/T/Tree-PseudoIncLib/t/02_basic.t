#!perl -w
use strict;

# Very basic tests only:
# ======================
use Tree::PseudoIncLib;
use Log::Log4perl;
use Test::Simple tests => 39;

Log::Log4perl::init( 'data/log.config' );

# 01:
my $obj = Tree::PseudoIncLib->new();
	print STDERR "\n\tundefined default new() object\n" unless defined $obj;
ok(defined($obj) , 'new() default works' );
	print STDERR "\n\tdefault new() object has zerro reference\n" unless $obj;
ok($obj, 'new() default works fine' );
	my $right_class = 'Tree::PseudoIncLib';
	my $created_class = ref($obj);
	print STDERR "\n\tobject belongs to $created_class\n" unless $created_class eq $right_class;
ok($created_class eq $right_class, 'class is correct' );

# 04:
	my $right_tree_id = 'Default_Tree';
	my $created_tree_id = $obj->tree_id;
	print STDERR "\n\tget default tree_id returns $created_tree_id\n"
		unless $created_tree_id eq $right_tree_id;
ok($created_tree_id eq $right_tree_id, 'tree_id() get default works');
	my $tree_name = 'simple Tree';
	my $modified_tree_id = $obj->tree_id($tree_name);
	print STDERR "\n\ttree_id($tree_name) returns $modified_tree_id\n"
		unless $modified_tree_id eq $tree_name;
ok($modified_tree_id eq $tree_name, 'tree_id() putt works');

# 06:
	my $max_nodes_default = 15000;
	my $max_nodes_read = $obj->max_nodes;
	print STDERR "\n\tmax_nodes default = $max_nodes_read\n" unless $max_nodes_read eq $max_nodes_default;
ok($max_nodes_read eq $max_nodes_default, 'max_nodes() get works');
	my $a = 77; # valid value
	$max_nodes_read = $obj->max_nodes($a);
	print STDERR "\n\tmax_nodes($a) = $max_nodes_read\n" unless $max_nodes_read eq $a;
ok($max_nodes_read eq $a, 'max_nodes() put works');
	my $min_max_nodes_default = 15;
	my $b = 1; # invalid value
	my $g = $obj->max_nodes($b);
	print STDERR "\n\tmax_nodes($b) = $g\n" unless $g eq $min_max_nodes_default;
ok($g eq $min_max_nodes_default, 'max_nodes() put validation works');

ok($obj->rpm_type eq 'RPM', 'rpm_type() get works');

# 10:
ok($obj->rpm_active == 1, 'rpm_active() get works');
	my $name = 'old_foo'; # invalid value
ok($obj->rpm_type($name) eq $name, 'rpm_type() put works');
ok($obj->rpm_type('') eq '', 'rpm_type() put empty works');
ok($obj->rpm_active == 0, 'rpm_type() put empty works');
ok($obj->rpm_active(1) == 0, 'rpm_active() put validation works');

	$obj->rpm_type('RPM'); # restore value
# 15:
ok($obj->rpm_active(1) == 1, 'rpm_active() put active correctly works');
ok($obj->rpm_active(0) == 0, 'rpm_active() put inactive correctly works');

ok($obj->status_as_string, 'status_as_string() get works');

ok($obj->list_descript_keys, 'list_descript_keys() works');

	my $n_simple_keys_default = 14;
	my $ref_simple_keys = $obj->list_simple_keys;
	print STDERR "\n\tno reference to simple_keys\n" unless $ref_simple_keys;
ok($ref_simple_keys, 'list_simple_keys() returns valid reference');
	my $size_of_simple_keys = scalar @$ref_simple_keys;
	print STDERR "\n\tsize of simple_keys array = $size_of_simple_keys\n"
		unless $size_of_simple_keys eq $n_simple_keys_default;
ok($size_of_simple_keys eq $n_simple_keys_default, 'list_simple_keys() works');
# 21:
	my $n_pseudo_INC_default = 9;
	my $ref_pseudo_INC = $obj->pseudo_INC;
	print STDERR "\n\tno reference to pseudo_INC\n" unless $ref_pseudo_INC;
ok($ref_pseudo_INC, 'pseudo_INC() get default works');
	my $size_of_pseudo_INC = scalar @$ref_pseudo_INC;
	print STDERR "\n\tsize of pseudo_INC array = $size_of_pseudo_INC\n"
		unless $size_of_pseudo_INC eq $n_pseudo_INC_default;
ok($size_of_pseudo_INC eq $n_pseudo_INC_default, 'pseudo_INC() get default works');
	my @pseudo_inc = ( 'data/testlibs/lib1',);
ok(scalar(@{$obj->pseudo_INC(\@pseudo_inc)}) == 1, 'pseudo_INC() put works');

ok(scalar(@{$obj->allow_files}) == 4, 'allow_files() get works');
my $satur = [ { mask => '.*', icon => 'any_file.jpg'}, ];
ok(scalar(@{$obj->allow_files($satur)}) == 1, 'allow_files() put works');

ok($obj->skip_empty_dir, 'skip_empty_dir() get default works');
ok($obj->skip_empty_dir(0) == 0, 'skip_empty_dir(0) put works');
ok($obj->skip_empty_dir(1) == 1, 'skip_empty_dir(1) put works');

ok($obj->application_directory, 'application_directory() get default works');
	my $app_dir = '/some/path/';
ok($obj->application_directory($app_dir) eq $app_dir, 'application_directory() put works');

ok($obj->skip_mode() == 0, 'skip_mode get default works');
ok($obj->skip_mode(1) == 1, 'skip_mode(1) put works');
ok($obj->skip_mode(0) == 0, 'skip_mode(0) put works');

ok($obj->skip_owner() == 0, 'skip_user get default works');
ok($obj->skip_owner(1) == 1, 'skip_user(1) put works');
ok($obj->skip_owner(0) == 0, 'skip_user(0) put works');

ok($obj->skip_group() == 0, 'skip_group get default works');
ok($obj->skip_group(1) == 1, 'skip_group(1) put works');
ok($obj->skip_group(0) == 0, 'skip_group(0) put works');

