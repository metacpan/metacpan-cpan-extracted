package Test::Portability::Files;
$Test::Portability::Files::VERSION = '0.07';
# ABSTRACT: Check file names portability
use strict;
use warnings;
use ExtUtils::Manifest qw(maniread);
use File::Basename;
use File::Find;
use File::Spec;
use Test::Builder;
require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(&options &run_tests);
our @EXPORT_OK = @EXPORT;

my $Test = Test::Builder->new;

sub import {
    my $self   = shift;
    my $caller = caller;

    {
        ## no critic
        no strict 'refs';
        *{ $caller . '::options' }   = \&options;
        *{ $caller . '::run_tests' } = \&run_tests;
        ## use critic
    }

    $Test->exported_to($caller);
    $Test->plan( tests => 1 ) unless $Test->has_plan;
}

my %options = ( use_file_find => 0, );

my %tests = (
    ansi_chars    => 1,
    one_dot       => 1,
    dir_noext     => 1,
    special_chars => 1,
    space         => 1,
    mac_length    => 0,
    amiga_length  => 0,
    vms_length    => 1,
    dos_length    => 0,
    case          => 1,
    'symlink'     => 1,
);

my %errors_text =
    (    # wrap the text at this column --------------------------------> |
    ansi_chars =>
        "These files does not respect the portable filename characters\n"
        . "as defined by ANSI C and perlport:\n",

    one_dot => "These files contain more than one dot in their name:\n",

    dir_noext => "These directories have an extension in their name:\n",

    special_chars =>
        "These files contain special characters that may break on\n"
        . "several systems, please correct:\n",

    space => "These files contain space in their name, which is not well\n"
        . "handled on several systems:\n",

    mac_length =>
        "These files have a name more than 31 characters long, which\n"
        . "will be truncated on Mac OS Classic and old AmigaOS:\n",

    amiga_length =>
        "These files have a name more than 107 characters long, which\n"
        . "will be truncated on recent AmigaOS:\n",

    vms_length =>
        "These files have a name or extension too long for VMS (both\n"
        . "are limited to 39 characters):\n",

    dos_length =>
        "These files have a name too long for MS-DOS and compatible\n"
        . "systems:\n",

    case => "The name of these files differ only by the case, which can\n"
        . "cause real problems on case-insensitive filesystems:",

    'symlink' => "The following files are symbolic links, which are not\n"
        . "supported on several operating systems:",
    );

my %bad_names = ();
my %lc_names  = ();


sub options {
    my %opts = @_;
    for my $test ( keys %tests ) {
        $tests{$test} = $opts{"test_$test"} if exists $opts{"test_$test"};
    }
    for my $opt ( keys %options ) {
        $options{$opt} = $opts{$opt} if exists $opts{$opt};
    }
    @tests{ keys %tests } = ( $opts{all_tests} ) x ( keys %tests )
        if exists $opts{all_tests};
}


sub test_name_portability {
    my ( $file, $file_name, $file_path, $file_ext );

    # extract path, base name and extension
    if ( $options{use_file_find} ) {    # using Find::File
                                        # skip generated files
        return if $_ eq File::Spec->curdir or $_ eq 'pm_to_blib';
        my $firstdir = (
            File::Spec->splitdir( File::Spec->canonpath($File::Find::name) ) )
            [0];
        return if $firstdir eq 'blib' or $firstdir eq '_build';

        $file = $File::Find::name;
        ( $file_name, $file_path, $file_ext ) =
            fileparse( $file, '\\.[^.]+?' );

    }
    else {                              # only check against MANIFEST
        $file = shift;
        ( $file_name, $file_path, $file_ext ) =
            fileparse( $file, '\\.[^.]+?' );

      #for my $dir (File::Spec->splitdir(File::Spec->canonpath($file_path))) {
      #    test_name_portability($dir)
      #}

        $_ = $file_name . $file_ext;
    }

#print STDERR "file $file\t=> path='$file_path', name='$file_name', ext='$file_ext'\n";

# After this point, the following variables are expected to hold these semantics
#   $file must contain the path to the file (t/00load.t)
#   $_ must contain the full name of the file (00load.t)
#   $file_name must contain the base name of the file (00load)
#   $file_path must contain the path to the directory containing the file (t/)
#   $file_ext must contain the extension (if any) of the file (.t)

# check if the name only uses portable filename characters, as defined by ANSI C
    if ( $tests{ansi_chars} ) {
        /^[A-Za-z0-9._][A-Za-z0-9._-]*$/ or $bad_names{$file} .= 'ansi_chars,';
    }

    # check if the name contains more than one dot
    if ( $tests{one_dot} ) {
        tr/.// > 1 and $bad_names{$file} .= 'one_dot,';
    }

    # check if the name contains special chars
    if ( $tests{special_chars} ) {
        m-[!"#\$%&'\(\)\*\+/:;<>\?@\[\\\]^`\{\|\}~]-
            and $bad_names{$file} .= 'special_chars,';
    }

    # check if the name contains a space char
    if ( $tests{space} ) {
        m/ / and $bad_names{$file} .= 'space,';
    }

    # check the length of the name, compared to Mac OS Classic max length
    if ( $tests{mac_length} ) {
        length > 31 and $bad_names{$file} .= 'mac_length,';
    }

    # check the length of the name, compared to AmigaOS max length
    if ( $tests{amiga_length} ) {
        length > 107 and $bad_names{$file} .= 'amiga_length,';
    }

    # check the length of the name, compared to VMS max length
    if ( $tests{vms_length} ) {
        ( length($file_name) <= 39 and length($file_ext) <= 40 )
            or $bad_names{$file} .= 'vms_length,';
    }

    # check the length of the name, compared to DOS max length
    if ( $tests{dos_length} ) {
        ( length($file_name) <= 8 and length($file_ext) <= 4 )
            or $bad_names{$file} .= 'dos_length,';
    }

    # check if the name is unique on case-insensitive filesystems
    if ( $tests{case} ) {
        if ( not $lc_names{$file} and $lc_names{ lc $file } ) {
            $bad_names{$file} .= 'case,';
            $bad_names{ $lc_names{ lc $file } } .= 'case,';
        }
        else {
            $lc_names{ lc $file } = $file;
        }
    }

    # check if the file is a symbolic link
    if ( $tests{'symlink'} ) {
        -l $file and $bad_names{$file} .= 'symlink,';
    }

    # if it's a directory, check that it has no extension
    if ( $tests{'dir_noext'} ) {
        -d $file and tr/.// > 0 and $bad_names{$file} .= 'dir_noext,';
    }
}


sub run_tests {
    fileparse_set_fstype('Unix');

    if ( $options{use_file_find} ) {

        # check all files found using File::Find
        find( \&test_name_portability, File::Spec->curdir );

    }
    else {
        # check only against files listed in MANIFEST
        my $manifest = maniread();
        map { test_name_portability($_) } keys %$manifest;
    }

    # check the results
    if ( keys %bad_names ) {
        $Test->ok( 0, "File names portability" );

        my %errors_list = ();
        for my $file ( keys %bad_names ) {
            for my $error ( split ',', $bad_names{$file} ) {
                $errors_list{$error} = [] if not ref $errors_list{$error};
                push @{ $errors_list{$error} }, $file;
            }
        }

        for my $error ( sort keys %errors_list ) {
            $Test->diag( $errors_text{$error} );

            for my $file ( sort @{ $errors_list{$error} } ) {
                $Test->diag("   $file");
            }

            $Test->diag(' ');
        }
    }
    else {
        $Test->ok( 1, "File names portability" );
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Portability::Files - Check file names portability

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    use Test::More;

    plan skip_all => "Only for the module maintainer" unless $ENV{AUTHOR_TESTS};
    plan skip_all => "Test::Portability::Files required for testing filenames portability"
        unless eval "use Test::Portability::Files; 1";

    options(all_tests => 1);  # to be hyper-strict
    run_tests();

=head1 DESCRIPTION

This module is used to check the portability across operating systems
of the names of the files present in the distribution of a module.
The tests use the advices given in L<perlport/"Files and Filesystems">.
The author of a distribution can select which tests to execute.

To use this module, simply copy the code from the synopsis in a test
file named F<t/portfs.t> for example, and add it to your F<MANIFEST>.
You can delete the call to C<options()> to enable only most common tests.

By default, not all tests are enabled because some are judged too cumbersome
to be practical, especially since some of the most limited platforms (like
MS-DOS) seem to be no longer supported.
Here are the default options:

=over 4

=item *

C<use_file_find> is I<not> enabled (check only the names as listed
in F<MANIFEST>)

=item *

C<test_amiga_length> is I<not> enabled

=item *

C<test_ansi_chars> is enabled

=item *

C<test_case> is enabled

=item *

C<test_dos_length> is I<not> enabled

=item *

C<test_mac_length> is I<not> enabled

=item *

C<test_one_dot> is enabled

=item *

C<test_space> is enabled

=item *

C<test_special_chars> is enabled

=item *

C<test_symlink> is enabled

=item *

C<test_vms_length> is enabled

=back

To change any option, please see C<options()>.

=head1 EXPORT

The following functions are exported:

=over 4

=item *

C<options()>

=item *

C<run_tests()>

=back

=head1 FUNCTIONS

=over 4

=item C<options()>

Set the module options, in particular, select which tests to execute.
Expects a hash.

B<General options>

=over 4

=item *

C<use_file_find> - set to 1 to check all the files in the current
hierarchy using C<File::Find> instead of only checking files listed
in F<MANIFEST>.

=back

B<Tests>

=over 4

=item *

C<all_tests> - select all tests.

=item *

C<test_amiga_length> - check that the name fits within AmigaOS name length
limitations (107 characters).

=item *

C<test_ansi_chars> - check that the name only uses the portable filename
characters as defined by S<ANSI C> and recommended by L<perlport>.

=item *

C<test_case> - check that the name of the file does not clash with
the name of another file on case-insensitive filesystems.

=item *

C<test_dir_noext> - check that the directory has no extension.

=item *

C<test_dos_length> - check that the name fits within DOS name length limitations
(8 characters max for the base name, 3 characters max for the extension).

=item *

C<test_mac_length> - check that the name fits within Mac OS Classic name length
limitations (31 characters).

=item *

C<test_one_dot> - check that the name only has one dot.

=item *

C<test_space> - check that the name has nos space.

=item *

C<test_special_chars> - check that the name does not use special characters.

=item *

C<test_symlink> - check that the file is not a symbolic link.

=item *

C<test_vms_length> - check that the name fits within VMS name length limitations
(39 characters max for the base name, 39 characters max for the extension).

=back

B<Example>

    options(use_file_find => 1, all_tests => 1);

selects all tests and runs them against all files found using C<File::Find>.

=item C<test_name_portability()>

Test the portability of the given file name.

=item C<run_tests()>

Execute the tests selected by C<options()>.

=back

=head1 SEE ALSO

L<perlport>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-portability-files@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 AUTHORS

=over 4

=item *

Sébastien Aperghis-Tramoni <sebastien@aperghis.net>

=item *

Alexander Hartmaier <abraxxa@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Sébastien Aperghis-Tramoni, Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
