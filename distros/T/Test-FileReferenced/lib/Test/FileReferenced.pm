# Copyright 2010, Bartłomiej Syguła (natanael@natanael.krakow.pl)
#
# This is free software. It is licensed, and can be distributed under the same terms as Perl itself.
#
# For more, see my website: http://natanael.krakow.pl/

package Test::FileReferenced;

use 5.005003;
use strict;
use base qw( Exporter );

our $VERSION = '0.02';
our @EXPORT = qw(
    is_referenced_ok
    is_referenced_in_file
);
our @EXPORT_OK = qw(
    set_serializer
    at_exit
);

use Carp qw( croak );
use Cwd qw( cwd );
use English qw( -no_match_vars );
use FindBin qw( $Bin );
use File::Basename;
use File::Spec;
use Test::More;
use YAML::Any qw( LoadFile DumpFile );

=encoding UTF-8

=head1 NAME

Test::FileReferenced - Test against reference data stored in file(s).

=head1 SYNOPSIS

 use Test::FileReferenced;
 
 # Optional:
 Test::FileReferenced::set_serializer('mydump', \&My::Dumper::Load, \&My::Dumper::Dump);
 
 is_referenced_ok( complex_data_structure(), "complex data structure" );
 
 is_referenced_in_file ( data_structure(), "data structure", "data_structure" );
 
 # Optional:
 Test::FileReferenced::at_exit();

=head1 DESCRIPTION

Test::FileReferenced helps testing routines returning complex data structures.
This is achieved by serializing test's output (using YAML::Any),
and allowing the Developer to compare it with reference data.

In case there are differences between reference and actual result,
comparison can be made using traditional UNIX diff-like (diff, vimdiff, gvimdiff, kdiff) utilities.

In such case, Test::FileReferenced - after the test completes - will ask the Developer to run diff on result and reference data.
If all differences ware intended, Developer may just replace reference data with actual test results.

=cut

my $serializer_ext = 'yaml';
my $serializer_load = \&LoadFile;
my $serializer_dump = \&DumpFile;

my $default_reference_filename;
my $default_results_filename;

# Data storeage:
my $reference = undef; # Becomes {} once initialized.
my $output    = {};

# Flags:
my $exited_cleanly = 0;
my $failure_count  = 0;

END {
    at_exit();
}

=head1 SUBROUTINES

=over

=item is_referenced_ok ( $data, $name, $comparator )

Compare C<$data> with reference stored under key C<$name> in default reference file.

If C<$comparator> is a CODE reference, it is used to compare results. If this parameter is not given, Test::More::is_deeply is used.

Returns:

Value returned by comparison routine. By default (when is_deeply is used)
it will be C<1> if the test passed, and C<0> if it failed.

=cut

sub is_referenced_ok { # {{{
    my ( $tested_data, $test_name, $comparator ) = @_;

    _init_if_you_need();

    _load_reference_if_you_need();

    # Test name is mandatory, since without it, it's hard to reliably
    # identify reference output in the reference file.
    if (not $test_name) {
        croak("Test name missing, but it is mandatory!");
    }

    # Check if the test name is unique.
    if ($output->{$test_name}) {
        croak("Test name: '$test_name' is not unique.");
    }

    if (not $comparator) {
        $comparator = \&is_deeply;
    }

    $output->{$test_name} = $tested_data;

    # Check if We have a reference data for given test.
    if (not exists $reference->{$test_name}) {
        diag("No reference for test '$test_name' found. Test will fail.");

        # Fixme: provide some more detailed information, what happened,
        # and how to react. But, display it only on first occurance.

        $failure_count++;

        return fail($test_name);
    }

    my $status;
    if (not $status = $comparator->($tested_data, $reference->{$test_name}, $test_name)) {
        $failure_count++;
    }

    return $status;
} # }}}

=item is_referenced_in_file ( $data, $file_basename, $name, $comparator )

Compare C<$data> with reference stored in custom file: F<$file_basename.yaml> (assuming the serializer is YAML::Any).

If C<$comparator> is a CODE reference, it is used to compare results. If this parameter is not given, Test::More::is_deeply is used.

Both C<$name> and C<$comparator> are optional parameters.

Returns:

Value returned by comparison routine. By default (when is_deeply is used)
it will be C<1> if the test passed, and C<0> if it failed.

=cut

sub is_referenced_in_file { # {{{
    my ( $tested_data, $reference_filename, $test_name, $comparator ) = @_;

    _init_if_you_need();

    if (not $comparator) {
        $comparator = \&is_deeply;
    }

    # Construct path to reference file.
    my ($reference_path, $output_path );
    if (File::Spec->file_name_is_absolute($reference_filename)) {
        $reference_path = $reference_filename . q{.}        . $serializer_ext;
        $output_path    = $reference_filename . q{-result.} . $serializer_ext;
    }
    else {
        $reference_path = File::Spec->catfile($Bin, $reference_filename . q{.}        . $serializer_ext);
        $output_path    = File::Spec->catfile($Bin, $reference_filename . q{-result.} . $serializer_ext);
    }

    # Load reference data.
    my $reference_data = _Load($reference_path);

    my $status;
    if (not $status = $comparator->($tested_data, $reference_data, $test_name)) {
        _Dump($output_path, $tested_data);

        # Test failed, display prompt....
        _display_failure_prompt($output_path, $reference_path);
    }
    else {
        # If there are output files from previous run - clear them up.
        if (-e $output_path) {
            unlink $output_path;
        }
    }

    return $status;
} # }}}

=item set_serializer ( $extension, $load_coderef, $dump_coderef )

Changes default serializing functions to ones provided by the Developer. C<$extension> must also be provided, so Test::FileReferenced can
automatically create the default reference file, if needed.

You do not need to use this function, if You are happy with YAML::Any usage.

Returns: undef

=cut

sub set_serializer { # {{{
    ( $serializer_ext, $serializer_load, $serializer_dump ) = @_;
    
    # Validate what was given to us.

    if (not $serializer_ext) {
        croak "Missing file extension!";
    }

    if (not $serializer_load) {
        croak "Missing de-serializer!";
    }
    if (ref $serializer_load ne 'CODE') {
        croak "De-serializer not a CODE-ref!";
    }
    
    if (not $serializer_dump) {
        croak "Missing serializer!";
    }
    if (ref $serializer_dump ne 'CODE') {
        croak "Serializer not a CODE-ref!";
    }

    return;
} # }}}

=item at_exit ()

If there ware failed tests, C<at_exit()> will dump results from the test in temporary file, and then prompt to inspect changes.

If there ware no failures, C<at_exit()> will check, if results file (from any previous run) exists, and if so - remove it.
Nothing will be printed in this case.

Normally this function does not need to be run explicitly, as Test::FileReferenced will run it from it's C<END {}> sections.

Returns: undef

=cut

sub at_exit { # {{{
    if ($exited_cleanly) {
        return;
    }

    # Ware there any failures?
    if ($failure_count > 0) {
        _Dump($default_results_filename, $output);
        
        _display_failure_prompt($default_results_filename, $default_reference_filename);
    }
    else {
        _clean_up();
    }

    $exited_cleanly = 1;

    return;
} # }}}

# Strictly internal routines.
#
# (please DO NOT use, for Your own comfort and safety)

sub _init_if_you_need { # {{{
    # Do We need to initialize anything?
    if ($default_results_filename) {
        # No, thank You.
        return;
    }

    # Prepare basename for the default files:
    my $basename = basename($PROGRAM_NAME, q{.t});

    $default_reference_filename = File::Spec->catfile($Bin, $basename . q{.} . $serializer_ext);
    $default_results_filename   = File::Spec->catfile($Bin, $basename . q{-result.} . $serializer_ext);
    
#    warn "Ref: ". $default_reference_filename;
#    warn "Res: ". $default_results_filename;

    return;
} # }}}

sub _clean_up { # {{{
    if ($default_results_filename and -f $default_results_filename) {
        unlink $default_results_filename;
    }

    return;
}  # }}}

=back

=head1 REFERENCE FILES

Reference files are data dumps using - by default - YAML::Any.

=over

=item Default reference file

Default reference file contains data for all C<is_referenced_ok> calls in the test.
Each test case has it's own key in the file. For the following example test:

 is_referenced_ok(\%ENV, 'env');
 is_referenced_ok(\@INC, 'inc');

...we have the following reference file:

 ---
 env:
   LANG: pl_PL
   LANGUAGE: pl_PL
   LC_ALL: pl_PL.UTF-8
 inc:
   /usr/lib/perl5/site_perl
   /usr/lib/perl5/vendor_perl/5.10.1
   /usr/lib/perl5/vendor_perl
   /usr/lib/perl5/5.10.1

Name for the reference file is based on the tests's filename, with I<.t> replaced with extension native to the used dumper.
Example: if default serializer (YAML::Any) is used, F<foo/bar.t> will use F<foo/bar.yaml>.

=cut

sub _load_reference_if_you_need { # {{{
    if ($reference) {
        # Reference already loaded or initialized.
        return $reference;
    }

    # Is there a reference file?
    if (not -f $default_reference_filename) {
        # Nope. Warn the User, but don't make a tragedy of it.
        diag("No reference file found. All calls to is_referenced_ok WILL fail.");

        return $reference = {};
    }

    return $reference = _Load($default_reference_filename);
} # }}}

=item Custom reference files

Custom reference files are used by C<is_referenced_in_file> function. Each file contains reference data
for single test case. For the following example test:

 is_referenced_in_file(\%ENV, 'env', 'environment');

...we have the following reference file, named F<environment.yaml>:

 ---
 LANG: pl_PL
 LANGUAGE: pl_PL
 LC_ALL: pl_PL.UTF-8

=back

=head1 TEST FAILURES

If there are differences between referenced, and actual data, at the end of the test prompt will be printed, similar to:

 Resulting and reference files differ. To see differences run one of:
       diff foo-results.yaml foo.yaml
   gvimdiff foo-results.yaml foo.yaml
 
 If the differences ware intended, reference data can be updated by running:
         mv foo-results.yaml foo.yaml

If there is no F<foo.yaml> yet (first test run, for example) then the message will be similar to:
 
 No reference file found. It'a a good idea to create one from scratch manually.
 To inspect current results run:
        cat foo-results.yaml

 If You trust Your test output, You can use it to initialize deference file, by running:
         mv foo-results.yaml foo.yaml

In this case, the first time is_referenced_ok is used, it will dump the following diagnostic message:

 No reference file found. All calls to is_referenced_ok WILL fail.

This is to ensure, that the User get's the idea, that something is not OK,
even if - for some reason - the END block does not run.

=cut

sub _display_failure_prompt { # {{{
    my ( $results_filename, $reference_filename ) = @_;

    if ($ENV{'FILE_REFERENCED_NO_PROMPT'}) {
        return;
    }

    # Try to make the paths a bit more Humar-readable.
    my $cwd = cwd();

    $results_filename   = File::Spec->abs2rel($results_filename, $cwd);
    $reference_filename = File::Spec->abs2rel($reference_filename, $cwd);

    # We basically have two use cases:
    #   1) reference exist, but there are changes.
    #   2) reference does not exist at all
    if (-f $reference_filename) {
        # First major use case: reference exist, but there are changes.

        my @shell_path = File::Spec->path();

        diag("Resulting and reference files differ. To see differences run one of:");
        diag(sprintf(q{%10s %s %s}, q{diff}, $results_filename, $reference_filename));
        foreach my $diff_command (qw( vimdiff gvimdiff kdiff )) {
            foreach my $path (@shell_path) {
                if (-x File::Spec->catfile($path, $diff_command)) {
                    diag(sprintf(q{%10s %s %s}, $diff_command, $results_filename, $reference_filename));
                    last;
                }
            }
        }
        diag("\n");
        diag("If the differences ware intended, reference data can be updated by running:");
        diag(sprintf(q{%10s %s %s}, q{mv}, $results_filename, $reference_filename));
    }
    else {
        # Second major use case: reference does not exist at all.
        diag("No reference file found. It'a a good idea to create one from scratch manually.");
        diag("To inspect current results run:");
        diag(sprintf(q{%10s %s}, "cat", $results_filename));
        diag("\n");
        diag("If You trust Your test output, You can use it to initialize deference file, by running:");
        diag(sprintf(q{%10s %s %s}, q{mv}, $results_filename, $reference_filename));
    }

    return;
} # }}}

# ToDo: describe custom serializer/deserializer usage.

sub _Load { # {{{
    my ( $path ) = @_;

    my $data = eval {
        return $serializer_load->($path);
    };
    if ($EVAL_ERROR) {
        croak("De-serializer error!\nUnable to load from:\n\t" . $path . "\nEval error:\n" . $EVAL_ERROR );
    }

    return $data;
} # }}}

sub _Dump { # {{{
    my ( $path, $data ) = @_;

    eval {
        $serializer_dump->($path, $data);
    };
    if ($EVAL_ERROR) {
        croak("Serializer error!\nUnable to dump to:\n\t" . $path . "\nEval error:\n" . $EVAL_ERROR );
    }

    return $data;
} # }}}

=head1 CUSTOM COMPARISON ROUTINES

For the moment, it's an undocumented, experimental feature. Use at Your own risk.

=head1 TDD

Test-driven development is possible with Test::FileReferenced. One of the ways, is to follow the following steps:

=over

=item Initialize reference files

To initialize the reference file(s), run a script similar to the example bellow:

 #!/usr/bin/perl -w
 use strict;
 use Test::More tests=>3;
 use Test::FileReferenced;

 is_referenced_ok(undef, "First test");
 is_referenced_ok(undef, "Second test");

 is_referenced_in_file(undef, "foo", "Second test");

This will allow You to create an empty default reference file for the test, and one ('foo.yaml') custom reference file.

=item Fill reference files

At this point, test should pass cleanly. Our goal is to write the data structures, that We expect to have, into reference files created above.

After doing this, test will no longer pass.

=item Generate test data

At this point, test fails because test script provides incorrect data: undef's have to be replaced with actual data - probably generated by calls to tested subroutines.

=item Implement tested code

At this point, test still fails. Tested subroutines have to be properly implemented. Once this is done, test should pass, and the process is completed.

=back

=cut

1;

__END__

=head1 CAVEATS

Most caveats listed here will - most probably - apply to any other Test module.
They have been listed for convenience, as they have been been found to be the most common issues a Developer might run into, while using Test::FileReferenced.

=over

=item Random ordering

Note, that Test::FileReferenced does not sort the data. If Your data is returned in random order (order is not actually important),
You should use the following:

 is_referenced_ok( [ sort @randomly_ordered_data ], "Test 01" )

=item Date and/or time

Your reference data is 'frozen' as it is in given time point. If results contain some elements derived from date/time,
they will be different each time You run the test. This will most likely create false negative results.

=item Host-based data

If Your test data contains some host-related data (URLs), tests will pass on Your host, but will probably fail on other machines.

=back

=head1 TODO

=over

=item Make result files as unique as possible

Result files should be unique (add PID? Timestamp?), so it is possible to run the same test in two copies at a time.
At the moment race conditions may happen. This does not seem to be a common use case, but still.

Will be fixed in next (0.02) version.

=item External tmp directory

At the moment, result files are written in the same directory as tests, which may not always be writable.
This should be solved by using '/tmp', or any other User-supplied directory.

Will be fixed in next (0.02) version.

=item Propose better commands

Currently, Test::FileReferenced assumes that the User has Unix-like commands, like F<diff>, F<mv> and F<cat>.

On systems, that do not have them, module should work fins, yet the usefulness of the prompt will be reduced.

I do not know how (if) this is important - if You need this to be improved, please let me know (patches welcomed).

=back

=head1 SEE ALSO

Test::More

Test::FileReferenced::Deep (WIP!)

Test::FileReferenced::Framework (WIP!)

=head1 COPYRIGHT

Copyright 2010, Bartłomiej Syguła (natanael@natanael.krakow.pl)

This is free software. It is licensed, and can be distributed under the same terms as Perl itself.

For more, see my website: http://natanael.krakow.pl/

=cut

# vim: fdm=marker
