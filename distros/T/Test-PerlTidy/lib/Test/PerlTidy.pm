package Test::PerlTidy;

use strict;
use warnings;

use parent 'Exporter';

use vars qw( @EXPORT );    ## no critic (Modules::ProhibitAutomaticExportation)
@EXPORT = qw( run_tests );

use Carp;
use File::Finder;
use File::Slurp;
use File::Spec;
use IO::File;
use Perl::Tidy;
use Test::Builder;
use Text::Diff;

our $VERSION;
$VERSION = '20130104';

my $test = Test::Builder->new;

our $MUTE = 0;

sub run_tests {
    my %args = @_;

    # Skip all tests if instructed to.
    $test->skip_all('All tests skipped.') if $args{skip_all};

    $MUTE = $args{mute} if exists $args{mute};

    # Get files to work with and set the plan.
    my @files = list_files(%args);
    $test->plan( tests => scalar @files );

    # Check each file in turn.
    foreach my $file (@files) {
        $test->ok( is_file_tidy( $file, $args{perltidyrc} ), "'$file'" );
    }

    return;
}

sub is_file_tidy {
    my ( $file_to_tidy, $perltidyrc ) = @_;

    my $code_to_tidy = load_file($file_to_tidy);

    my $tidied_code = q{};
    my $logfile     = q{};
    my $errorfile   = q{};

    my $stderr_fh = IO::File->new_tmpfile or croak "IO::File->new_tmpfile: $!";
    $stderr_fh->autoflush(1);

    Perl::Tidy::perltidy(
        source      => \$code_to_tidy,
        destination => \$tidied_code,
        stderr      => $stderr_fh,
        logfile     => \$logfile,
        errorfile   => \$errorfile,
        perltidyrc  => $perltidyrc,
    );

    # If there were perltidy errors report them and return.
    $stderr_fh->seek( 0, 0 );
    my $stderr = read_file($stderr_fh);
    if ($stderr) {
        unless ($MUTE) {
            $test->diag("perltidy reported the following errors:\n");
            $test->diag($stderr);
        }
        return 0;
    }

    # Compare the pre and post tidy code and return result.
    # Do not worry about trailing newlines.
    #
    $code_to_tidy =~ s/[\r\n]+$//;
    $tidied_code =~ s/[\r\n]+$//;
    if ( $code_to_tidy eq $tidied_code ) {
        return 1;
    }
    else {
        unless ($MUTE) {
            $test->diag("The file '$file_to_tidy' is not tidy\n");
            $test->diag(
                diff( \$code_to_tidy, \$tidied_code, { STYLE => 'Table' } ) );
        }

        return 0;
    }
}

sub list_files {
    my (@args) = @_;

    my %args;
    my $path;

    # Expect either a hashref of args, or a single "path" argument:
    #
    # The only reason for allowing a single path argument is for
    # backward compatibility with Test::PerlTidy::list_files, on the
    # off chance that someone was calling it directly...
    #
    if ( @args > 1 ) {
        %args = @args;
        $path = $args{path};
    }
    else {
        %args = ();
        $path = $args[0];
    }

    $path ||= q{.};

    $test->BAIL_OUT('You need to specify which directory to scan') unless $path;

    $test->BAIL_OUT(qq{The directory "$path" does not exist}) unless -d $path;

    my $excludes = $args{exclude} || ['blib/'];    # exclude blib by default

    $test->BAIL_OUT('exclude should be an array')
      unless ref $excludes eq 'ARRAY';

    my $finder = File::Finder->type('f')->name(qr{[.](?:pl|pm|PL|t)$});
    $finder->{options}->{untaint} = 1;
    my @files = $finder->in($path);

    my %keep = map { File::Spec->canonpath($_) => 1 } @files;
    my @excluded = ();

    foreach my $file ( keys %keep ) {

        foreach my $exclude ( @{$excludes} ) {

            my $exclude_me =
              ref $exclude ? ( $file =~ $exclude ) : ( $file =~ /^$exclude/ );

            if ($exclude_me) {
                delete $keep{$file};
                push @excluded, $file if $args{debug};
                last;    # no need to check more exclusions...
            }
        }
    }

    # Sort the output so that it is repeatable
    @files = sort keys %keep;

    if ( $args{debug} ) {
        $test->diag( 'Files excluded: ', join( "\n\t", sort @excluded ), "\n" );
        $test->diag( 'Files remaining ', join( "\n\t", @files ),         "\n" );
    }

    return @files;
}

sub load_file {
    my $filename = shift;

    # If the file is not regular then return undef.
    return unless -f $filename;

    # Slurp the file.
    my $content = read_file($filename);
    return $content;
}

1;

__END__

=head1 NAME

Test::PerlTidy - check that all your files are tidy.

=head1 SYNOPSIS

    # In a file like 't/perltidy.t':

    use Test::PerlTidy;

    run_tests();

=head1 DESCRIPTION

This rather unflattering comment was made in a piece by Ken Arnold:

    "Perl is a vast swamp of lexical and syntactic swill and nobody
    knows how to format even their own code well, but it's the only
    major language I can think of (with the possible exception of the
    recent, yet very Java-like C#) that doesn't have at least one
    style that's good enough."
              http://www.artima.com/weblogs/viewpost.jsp?thread=74230

Hmmm... He is sort of right in a way. Then again the piece he wrote
was related to Python which is somewhat strict about formatting
itself.

Fear not though - now you too can have your very own formatting
gestapo in the form of Test::PerlTidy! Simply add a test file as
suggested above and any file ending in .pl, .pm, .t or .PL will cause
a test fail unless it is exactly as perltidy would like it to be.

=head1 REASONS TO DO THIS

If the style is mandated in tests then it will be adhered to.

If perltidy decides what is a good style then there should be no
quibbling.

If the style never changes then cvs diffs stop catching changes that
are not really there.

Readability might even improve.

=head1 HINTS

If you want to change the default style then muck around with
'.perltidyrc';

To quickly make a file work then try 'perltidy -b the_messy_file.pl'.

=head1 HOW IT WORKS

Runs B<perltidy> on files and reports errors if any of the files
differ after having been tidied.  Does not permanently modify the
files being tested.

By default, B<perltidy> will be run on files under the current
directory and its subdirectories with extensions matching:
C<.pm .pl .PL .t>

=head1 METHODS

=head2 run_tests ( [ I<%args> ] )

This is the main entry point for running tests.

A number of options can be specified when running the tests, e.g.:

    run_tests(
              path       => $start_dir,
              perltidyrc => $path_to_config_file,
              exclude    => [ qr{\.t$}, 'inc/'],
    );

=over 4

=item debug

Set C<debug> to a true value to enable additional diagnostic
output, in particular info about any processing done as a result of
specifying the C<exclude> option.  Default is false.

=item exclude

C<run_tests()> will look for files to test under the current
directory and its subdirectories.  By default, it will exclude files
in the "C<./blib/>" directory.  Set C<exclude> to a listref of
exclusion criteria if you need to specify additional rules by which
files will be excluded.

If an item in the C<exclude> list is a string, e.g. "C<./blib/>",
it will be assumed to be a path prefix.  Files will be excluded if
that string matches their path at the beginning.

If an item in the C<exclude> list is a regex object, e.g.
"C<qr{\.t$}>", files will be excluded if that regex matches their
path.

Note that the paths of files to be tested are canonified using
L<File::Spec|File::Spec>C<< ->canonpath >> before any matching is
attempted, which can impact how the exclusion rules apply.  If your
exclusion rules do not seem to be working, turn on the C<debug>
option to see the paths of the files that are being kept/excluded.

=item path

Set C<path> to the path to the top-level directory which contains
the files to be tested.  Defaults to the current directory (i.e.
"C<.>").

=item perltidyrc

By default, B<perltidy> will attempt to read its options from the
F<.perltidyrc> file on your system.  Set C<perltidyrc> to the path
to a custom file if you would like to control the B<perltidy>
options used during testing.

=item mute

By default, C<run_tests()> will output diagnostics about any errors
reported by B<perltidy>, as well as any actual differences found
between the pre-tidied and post-tidied files.  Set C<mute> to a
true value to turn off that diagnostic output.

=item skip_all

Set C<skip_all> to a true value to skip all tests.  Default is false.

=back

=head2 list_files ( [ I<start_path> | I<%args> ] )

Generate the list of files to be tested.  Generally not called directly.

=head2 load_file ( I<path_to_file> )

Load the file to be tested from disk and return the contents.
Generally not called directly.

=head2 is_file_tidy ( I<path_to_file> [ , I<path_to_perltidyrc> ] )

Test if a file is tidy or not.  Generally not called directly.

=head1 SEE ALSO

L<Perl::Tidy>

=head1 AUTHOR

Edmund von der Burg, C<< <evdb at ecclestoad.co.uk> >>

=head1 CONTRIBUTORS

Duncan J. Ferguson, C<< <duncan_j_ferguson at yahoo.co.uk> >>

Stephen, C<< <stephen at enterity.com> >>

Larry Leszczynski, C<< <larryl at cpan.org> >>

=head1 SUGGESTIONS

Please let me know if you have any comments or suggestions.

L<http://ecclestoad.co.uk/>

=head1 COPYRIGHT

Copyright 2007 Edmund von der Burg, all rights reserved.

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

