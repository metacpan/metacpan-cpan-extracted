use strict;
use warnings;

# I realize that these tests are messy due to unicode file names and
# the optional Mac::PropertyList module.  My goal is to test
# as much functionality as possible, while still allowing the tests
# to pass as long as minimal functionality was present.

use File::Path qw(make_path remove_tree);
use File::Spec qw(catdir catfile);
use Module::Load::Conditional qw[check_install];
use Test::More;

BEGIN { use_ok('WebShortcutUtil::Write') };
require_ok('WebShortcutUtil::Write');

#########################

# The Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use WebShortcutUtil::Read qw(read_shortcut_file);

use WebShortcutUtil::Write qw(
    create_desktop_shortcut_filename
    create_url_shortcut_filename
    create_webloc_shortcut_filename
    write_desktop_shortcut_file
    write_url_shortcut_file
    write_webloc_binary_shortcut_file
    write_webloc_xml_shortcut_file
);

sub _test_write_shortcut {
    my ( $write_sub, $create_filename_sub, $path, $name, $url, $exception_check ) = @_;

    # Note that this routine will have problems if any characters are removed...
    my $created_filename = &{$create_filename_sub}($name);
    my $full_filename = File::Spec->catfile($path, $created_filename);
    ok(&{$write_sub}($full_filename, $name, $url), "Writing: $full_filename");

    my @result = read_shortcut_file($full_filename);
    my @expected_result = {
        "name", $name,
        "url", $url};
    is_deeply(\@result, \@expected_result, "Verifying: $full_filename");

    if($exception_check) {
        eval { &{$write_sub}($full_filename, $name, $url) };
        like ($@, qr/File .*/, "Already exists: $full_filename");
    }
}

sub _make_path_with_error_check {
    my ($path) = @_;

    make_path ($path) or die "Error creating directory ${path}: $!";
}


# Note that we check for errors using eval instead of dies_ok.
# This is to avoid having to add a dependency to Test:::Exception.


use utf8;

# Avoid "Wide character in print..." warnings (per http://perldoc.perl.org/Test/More.html)
my $builder = Test::More->builder;
binmode $builder->output, ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output, ":utf8";


my $test_output_dir = File::Spec->catdir ( "blib", "t", "output" );
if(-e $test_output_dir) {
    remove_tree ($test_output_dir) or die "Error removing directory ${test_output_dir}: $!";
}

is(create_desktop_shortcut_filename("file"), "file.desktop", "Generate desktop filename");
is(create_url_shortcut_filename("file"), "file.url", "Generate url filename");
is(create_webloc_shortcut_filename("file"), "file.webloc", "Generate webloc filename");
is(create_desktop_shortcut_filename("file", 9), "f.desktop", "Generate truncated filename");
is(create_desktop_shortcut_filename("12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"), "12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012.desktop", "Generate max truncated filename");
is(create_desktop_shortcut_filename(undef, 9), "_.desktop", "Generate minimum undef filename");
is(create_desktop_shortcut_filename("", 9), "_.desktop", "Generate minimum empty filename");
is(create_desktop_shortcut_filename(" !#\$&'()+,-.09;=\@AZ[]_`az{}~中"), " !#\$&'()+,-.09;=\@AZ[]_`az{}~中.desktop", "Generate filename allowed special characters");
is(create_desktop_shortcut_filename(" !\"#\$%&'()*+,-./09:;<=>?\@AZ[\]^_`az{|}~中"), " !#\$&'()+,-.09;=\@AZ[]_`az{}~中.desktop", "Generate filename all characters");




eval { create_desktop_shortcut_filename("file", 1) };
like ($@, qr/Length parameter must be greater than or equal.*/, "Minimum length");


diag("Test shortcuts are being written to directory \"${test_output_dir}\".  You can try opening the native shortcuts with a web browser to make sure they work properly.");

# .desktop tests
my $desktop_output_dir = File::Spec->catdir ( $test_output_dir, "desktop" );
_make_path_with_error_check($desktop_output_dir);
_test_write_shortcut(\&write_desktop_shortcut_file, \&create_desktop_shortcut_filename, $desktop_output_dir, "Google", "http://www.google.com", 1);
_test_write_shortcut(\&write_desktop_shortcut_file, \&create_desktop_shortcut_filename, $desktop_output_dir, "unicode", "http://导航.中国/", 0);

# .url tests
my $url_output_dir = File::Spec->catdir ( $test_output_dir, "url" );
_make_path_with_error_check($url_output_dir);
_test_write_shortcut(\&write_url_shortcut_file, \&create_url_shortcut_filename, $url_output_dir, "Google", "http://www.google.com", 1);
_test_write_shortcut(\&write_url_shortcut_file, \&create_url_shortcut_filename, $url_output_dir, "unicode", "http://导航.中国/", 0);

SKIP: {
    if(!defined(check_install( module => 'Mac::PropertyList' ))) {
        skip ("Mac::PropertyList not installed.  Cannot test webloc functionality unless this package is installed.", 0);
    }

    my $webloc_binary_output_dir = File::Spec->catdir ( $test_output_dir, "webloc", "binary" );
    _make_path_with_error_check($webloc_binary_output_dir);
    _test_write_shortcut(\&write_webloc_binary_shortcut_file, \&create_webloc_shortcut_filename, $webloc_binary_output_dir, "Google", "http://www.google.com", 0);

    my $webloc_xml_output_dir = File::Spec->catdir ( $test_output_dir, "webloc", "xml" );
    _make_path_with_error_check($webloc_xml_output_dir);
    _test_write_shortcut(\&write_webloc_xml_shortcut_file, \&create_webloc_shortcut_filename, $webloc_xml_output_dir, "Google", "http://www.google.com", 0);

    TODO: {
        local $TODO = "Need to explore webloc unicode functionality to understand the proper use cases.";

        eval {
            _test_write_shortcut(\&write_webloc_binary_shortcut_file, \&create_webloc_shortcut_filename, $webloc_binary_output_dir, "unicode", "http://导航.中国/", 0);
            _test_write_shortcut(\&write_webloc_xml_shortcut_file, \&create_webloc_shortcut_filename, $webloc_xml_output_dir, "unicode", "http://导航.中国/", 0);
        } or fail("Some tests died while accessing files named with unicode characters.");
    }
}

done_testing;
