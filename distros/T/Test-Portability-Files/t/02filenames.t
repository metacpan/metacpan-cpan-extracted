use strict;
use warnings;
use File::Temp qw/ tempfile tempdir /;
use Test::More;

use utf8;
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";

require Test::Portability::Files;
Test::Portability::Files::options(all_tests => 1);

expect_error('/home/user/foo.txt', undef);
expect_error('/home/user/Foo.txt', 'case');

expect_error('/home/user/ほげ.txt', 'ansi_chars');
#ansi C name can't start with dash
expect_error('/home/user/-foo.txt', 'ansi_chars');
expect_error('/home/user/foo.c.txt', 'one_dot');
expect_error('/home/user/foo;bar.txt', 'special_chars');
expect_error('/home/user/foo bar.txt', 'space');

expect_error('/home/user/thirty-one_characters_on_mac.txt', 'mac_length');
expect_error('/home/user/one_hundred_and_seven_characters_on_amgiga_but_this_is_just_ridiculous_just_dont_make_file_names_likthis.txt', 'mac_length');
#VMS gets 39 each for the base name and extension
expect_error('/home/user/thirty_nine_is_the_limit_for_files_onVMS.txt', 'vms_length');
expect_error('/home/user/foo.thirty_nine_is_the_limit_for_files_onVMS', 'vms_length');
#DOS is 8 for base name, 3 for extension
expect_error('/home/user/dos_eight.txt', 'dos_length');
expect_error('/home/user/dos_eight.txtx', 'dos_length');

# symlink and dir_noext tests actually use the file system, so they can only
# be tested on certain systems
my $tempdir;
eval { $tempdir = tempdir("foo.XXXX", CLEANUP => 1); };
if ( !$@ ) {
    expect_error($tempdir, 'dir_noext');
}

my $link_name = File::Temp::tempnam('.', 'symtest-');
my ($temp_fh, $temp_filename) = tempfile();
# only test if symlink doesn't throw error or return 0
if ( eval { symlink($link_name, $temp_filename); } ) {
    expect_error($link_name, 'symlink');
    unlink $link_name;
}

done_testing;

sub expect_error {
    my ($file_name, $error) = @_;
    Test::Portability::Files::test_name_portability($file_name);
    my $errors = Test::Portability::Files::_bad_names();
    # print Dumper $errors;
    if ( !defined $error ) {
        ok(!exists $errors->{$file_name}, "no error for $file_name")
            or diag "incorrect error for $file_name: $errors->{$file_name}";
    } else {
        my @errors = split ',', $errors->{$file_name};
        ok((grep {$_ eq $error} @errors), "$file_name gives error '$error'")
            or diag "incorrect error(s) for $file_name: " .
            ((join ',', @errors) || 'undef');
    }
}
