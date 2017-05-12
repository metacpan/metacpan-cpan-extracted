package Test::NoPlan;

use warnings;
use strict;

use version; our $VERSION = version->new('0.0.6');

use base 'Exporter';
use Test::Builder::Module;

use FindBin qw($Bin);
use Cwd;
use File::Spec;
use Carp;

our @EXPORT = qw( all_plans_ok );  ## no critic (ProhibitAutomaticExportation)
our @EXPORT_OK = qw( get_file_list check_file_for_no_plan );

{
    my $CLASS = __PACKAGE__;

    my @allowed_args
        = qw/ check_files recurse topdir _stdout _stderr method ignore_files /;

    sub all_plans_ok {
        my ($arg_ref) = @_;
        $arg_ref->{method} ||= 'create';
        _check_args($arg_ref);

        my @files = get_file_list($arg_ref);

        my $method = $arg_ref->{method};
        my $test   = Test::Builder->$method;
        if ( $arg_ref->{_stdout} ) {
            if ( ref $arg_ref->{_stdout} ne 'IO::Scalar' ) {
                croak '_stdout is not an IO::Scalar';
            }
            $test->output( $arg_ref->{_stdout} );
        }
        if ( $arg_ref->{_stderr} ) {
            if ( ref $arg_ref->{_stderr} ne 'IO::Scalar' ) {
                croak '_stderr is not an IO::Scalar';
            }
            $test->failure_output( $arg_ref->{_stderr} );
        }

        if ( $method eq 'create' ) {
            $test->plan( tests => scalar @files );
        }
        else {
            $test->no_ending();
        }

        foreach my $file (@files) {
            $test->ok( check_file_for_no_plan($file),
                "'$file' has 'no_plan' set" );
        }

        if ( $method ne 'create' ) {
            $test->reset_outputs();
        }

        return scalar @files;
    }

    sub _check_args {
        my ($arg_ref) = @_;
        if ( defined($arg_ref) && ref($arg_ref) ne 'HASH' ) {
            croak 'arguments do not seem to be a hash -> ', ref($arg_ref);
        }

        my @unknown_args;

        foreach my $arg ( sort( keys(%$arg_ref) ) ) {
            if ( !grep {/^$arg$/} @allowed_args ) {
                push @unknown_args, $arg;
            }
        }
        if (@unknown_args) {
            die 'Unknown arguments: ', join( ',', @unknown_args );
        }

        if ( $arg_ref->{method} ) {
            if (   $arg_ref->{method} ne 'create'
                && $arg_ref->{method} ne 'new' )
            {
                croak 'Method must be one of "create" or "new", not "',
                    $arg_ref->{method}, '"';
            }
        }
        return;
    }

    sub get_file_list {
        my ($arg_ref) = @_;

        _check_args($arg_ref);

        my $topdir = $Bin;
        if ( $arg_ref->{topdir} && $arg_ref->{topdir} ne '.' ) {
            $topdir = $arg_ref->{topdir};
        }
        if ( defined($topdir) && length $topdir && !-d $topdir ) {
            die( 'Invalid topdir provided: "' . $topdir . '"' );
        }
        my $cwd = getcwd();
        $topdir =~ s!$cwd/!!;

        my $check_files = qr/\.t$/xsm;
        if ( $arg_ref->{check_files} ) {
            $check_files = $arg_ref->{check_files};
        }
        if ( ref($check_files) ne 'Regexp' ) {
            die 'invalid check_files provided';
        }

        my $ignore_files = qr/^\..*/;
        if ( $arg_ref->{ignore_files} ) {
            $ignore_files = $arg_ref->{ignore_files};
        }

        my @files = ();
        opendir( my $topdir_dh, $topdir )
            or die 'Unable to read ', $topdir, ': ', $!;

        while ( my $dir_entry = readdir($topdir_dh) ) {
            next if ( $dir_entry =~ m/^\./xsm );

            my $resolved_entry = File::Spec->catfile( $topdir, $dir_entry );

            if ( -d $resolved_entry ) {
                if ( $arg_ref->{recurse} ) {
                    my %new_args = %$arg_ref;
                    $new_args{topdir} = $resolved_entry;
                    push @files, get_file_list( \%new_args );

                    #{ %{$arg_ref}, topdir => $resolved_entry, } );
                }
                next;
            }

            if ( $dir_entry =~ $check_files && $dir_entry !~ $ignore_files ) {
                push @files, $resolved_entry;
            }
        }

        closedir($topdir_dh) or die 'Unable to close ', $topdir, ': ', $!;

        return wantarray ? sort @files : "@files";
    }

    sub check_file_for_no_plan {
        my ($file) = @_;

        if ( !-s $file ) {
            croak "'$file' does not exist or is empty";
        }

        open( my $file_fh, '<', $file )
            or die 'Unable to read ' . $file . ': ', $!;
        my $file_contents;
        {
            local $/ = undef;
            $file_contents = <$file_fh>;
        }
        close($file_fh)
            or die 'Unable to close ' . $file . ': ', $!;

        # by default everything is ok, for those tests that do not use
        # Test::More directly
        my $return_code = 1;

        # look for uncommented lines containing Test::More or plan
        # followed by uncommented test keyword - these are ok
        if (   $file_contents =~ m/^[^#]*\bTest::More\b[^#]*\btests\b/xm
            || $file_contents =~ m/^[^#]*\bplan\b[^#]*\btests\b/xm )
        {
            $return_code = 1;
        }

        # look for uncommented lines containing Test::More or plan
        # followed by uncommented no_plan keyword - these are problems
        elsif ($file_contents =~ m/^[^#]*\bTest::More\b[^#]*\bno_plan\b/xm
            || $file_contents =~ m/^[^#]*\bplan\b[^#]*\bno_plan\b/xm )
        {
            $return_code = 0;
        }

        return $return_code;
    }
}

1;    # End of Test::NoPlan

__END__

=pod

=head1 NAME

Test::NoPlan - check perl test files for 'no_plan'

=head1 SYNOPSIS

It is a good idea to ensure you have defined how many tests should be run
within each test script - to catch cases where tests bomb out part way 
through so you know how many tests were not actually run.  This module
checks all your test plan files to ensure 'no_plan' is not used.

You can check one file:

    use Test::NoPlan qw/ check_file_for_no_plan /;
    use Test::More tests => 1;
    check_file_for_no_plan('t/test.t');

or check all files:

    use Test::NoPlan qw/ all_plans_ok /;
    all_plans_ok();

=head1 EXPORT

=head2 all_plans_ok({ options });

Searches for and checks *.t files within the current directory.  Options (with 
defaults shown) are:

=over

=item topdir => '.'

directory to begin search in - relative to the top directory in the project
(i.e. where the Makefile.PL or Build.PL file is located)

=item check_files => qr/\.t$/xsm

Regexp used to identify files to check - i.e. files ending in '.t' - note, this
just checks the basename of the files; the path is excluded.

=item ignore_files => qr/^\..*$/xsm

Regexp used to identify files to ignore - i.e. files starting with '.' - note, 
this just checks the basename of the files; the path is excluded.  

=item recurse => 0

Recurse into any subdirectories - not done by default.

=item method => '<create|new>' [default: create]

Amend the method by which the test object is created.  By default 'create' 
is used which is correct for tesst files containing only the 'all_plans_ok' 
test.  If multiple tests are held within the same tesst file then 'new' 
should be used so a single test object is created and shared

=back

=head2 get_file_list( { [ options ] } );

Return a list of files to be checked - uses same options as C<all_plans_ok>

=head2 check_file_for_no_plan( $filename );

Check the given file for instances of uncommented 'no_plan' usage.  Returns
0 for problem, 1 for no problem found.

=head1 AUTHOR

Duncan Ferguson, C<< < duncs@cpan.org > >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-test-noplan at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-NoPlan>.  I will be 
notified, and then you'll automatically be notified of progress on your bug 
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::NoPlan

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-NoPlan>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-NoPlan>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-NoPlan>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-NoPlan/>

=item * Source code repository at GitHub

L<http://github.com/duncs/perl-test-noplan>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2009 Duncan Ferguson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
