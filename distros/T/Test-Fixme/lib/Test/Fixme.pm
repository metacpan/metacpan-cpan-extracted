package Test::Fixme;

use 5.006;
use strict;
use warnings;
use Carp;
use File::Find;
use ExtUtils::Manifest qw( maniread );
use Test::Builder;
use base qw( Exporter );

our @EXPORT = qw( run_tests );

# ABSTRACT: Check code for FIXMEs.
our $VERSION = '0.17'; # VERSION

my $Test = Test::Builder->new;

sub run_tests {

    # Get the values and setup defaults if needed.
    my %args = @_;
    $args{match} = 'FIXME' unless defined $args{match} && length $args{match};
    $args{where} = '.'     unless defined $args{where} && length $args{where};
    $args{warn}  = 0       unless defined $args{warn}  && length $args{warn};
    $args{format} = $ENV{TEST_FIXME_FORMAT} if defined $ENV{TEST_FIXME_FORMAT};
    $args{format} = 'original'
      unless defined $args{format} && $args{format} =~ /^(original|perl)$/;
    $args{filename_match} = qr/./
      unless defined $args{filename_match} && length $args{filename_match};
    my $first = 1;

    # Skip all tests if instructed to.
    $Test->skip_all("All tests skipped.") if $args{skip_all};

    # Get files to work with and set the plan.
    my @files;
    if(defined $args{manifest}) {
        @files = keys %{ maniread( $args{manifest} ) };
    } else {
        @files = list_files( $args{where}, $args{filename_match} );
    }
    $Test->plan( tests => scalar @files );

    # Check ech file in turn.
    foreach my $file (@files) {
        my $results = scan_file( file => $file, match => $args{match} );
        my $ok = scalar @$results == 0;
        $Test->ok($ok || $args{warn}, "'$file'");
        next if $ok;
        $Test->diag('') if $first++;
        $Test->diag(do {
          no strict 'refs';
          &{"format_file_results_$args{format}"}($results)
        });
    }
}

sub scan_file {
    my %args = @_;
    return undef unless $args{file} && $args{match};

    # Get the contents of the files and split content into lines.
    my $content     = load_file( $args{file} );
    my @lines       = split $/, $content;
    my $line_number = 0;

    # Set up return array.
    my @results = ();

    foreach my $line (@lines) {
        $line_number++;
        next unless $line =~ m/$args{match}/;

        # We have a match - add it to array.
        push @results,
          {
            file  => $args{file},
            match => $args{match},
            line  => $line_number,
            text  => $line,
          };
    }

    return \@results;
}

sub format_file_results_original {
    my $results = shift;
    return undef unless defined $results;

    my $out = '';

    # format the file name.
    $out .= "File: '" . ${$results}[0]->{file} . "'\n";

    # format the results.
    foreach my $result (@$results) {
        my $line = $$result{line};
        my $txt  = "    $line";
        $txt .= ' ' x ( 8 - length $line );
        $txt .= $$result{text} . "\n";
        $out .= $txt;
    }

    return $out;
}

sub format_file_results_perl {
    my $results = shift;
    return undef unless defined $results;

    my $out = '';

    # format the results.
    foreach my $result (@$results) {
        my $file = ${$results}[0]->{file};
        my $line = $$result{line};
        my $text = $$result{text};

        $out .= "Pattern found at $file line $line:\n $text\n";
    }

    return $out;
}

sub list_files {
    my $path_arg = shift;
    croak
'You must specify a single directory, or reference to a list of directories'
      unless defined $path_arg;

    my $filename_match = shift;
    if ( !defined $filename_match ) {

        # Filename match defaults to matching any single character, for
        # backwards compatibility with one-arg list_files() invocation
        $filename_match = qr/./;
    }

    my @paths;
    if ( ref $path_arg eq 'ARRAY' ) {

        # Ref to array
        @paths = @{$path_arg};
    }
    elsif ( ref $path_arg eq '' ) {

        # one path
        @paths = ($path_arg);
    }
    else {

        # something else
        croak
'Argument to list_files must be a single path, or a reference to an array of paths';
    }

    foreach my $path (@paths) {

        # Die if we got a bad dir.
        croak "'$path' does not exist" unless -e $path;
    }

    my @files;
    find(
        {
            preprocess => sub {
                # no GIT, Subversion or CVS directory contents
                grep !/^(.git|.svn|CVS)$/, @_,
            },
            wanted => sub {
                push @files, $File::Find::name
                    if -f $File::Find::name;
            },
            no_chdir => 1,
        },
        @paths
    );

    @files =
      sort    # sort the files
      grep { m/$filename_match/ }
      grep { !-l $_ }               # no symbolic links
      @files;

    return @files;
}

sub load_file {
    my $filename = shift;

    # If the file is not regular then return undef.
    return undef unless -f $filename;

    # Slurp the file.
    open(my $fh, '<', $filename) || croak "error reading $filename $!";
    my $content = do { local $/; <$fh> };
    close $fh;
    return $content;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Test::Fixme - Check code for FIXMEs.

=head1 VERSION

version 0.17

=head1 SYNOPSIS

 # In a test script like 't/test-fixme.t'
 use Test::Fixme;
 run_tests();
 
 # You can also tailor the behaviour.
 use Test::Fixme;
 run_tests( where    => 'lib',      # where to find files to check
            match    => 'TODO',     # what to check for
            skip_all => $ENV{SKIP}  # should all tests be skipped
 );

=head1 DESCRIPTION

When coding it is common to come up against problems that need to be
addressed but that are not a big deal at the moment. What generally
happens is that the coder adds comments like:

 # FIXME - what about windows that are bigger than the screen?
 
 # FIXME - add checking of user privileges here.

L<Test::Fixme> allows you to add a test file that ensures that none of
these get forgotten in the module.

=head1 METHODS

=head2 run_tests

By default run_tests will search for 'FIXME' in all the files it can
find in the project. You can change these defaults by using 'where' or
'match' as follows:

 run_tests( where => 'lib', # just check the modules.
            match => 'TODO' # look for things that are not done yet.
 );

=over 4

=item where

Specifies where to search for files.  This can be a scalar containing a
single directory name, or it can be a list reference containing multiple
directory names.

=item match

Expression to search for within the files.  This may be a simple
string, or a qr//-quoted regular expression.  For example:

 match => qr/[T]ODO|[F]IXME|[B]UG/,

=item filename_match

Expression to filter file names.  This should be a qr//-quoted regular
expression.  For example:

 match => qr/\.(:pm|pl)$/,

would only match .pm and .pl files under your specified directory.

=item manifest

Specifies the name of your MANIFEST file which will be used as the list
of files to test instead of I<where> or I<filename_match>.

 manifest => 'MANIFEST',

=item warn

Do not fail when a FIXME or other pattern is matched.  Tests that would
have been failures will still issue a diagnostic that will be viewed
when you run C<prove> without C<-v>, C<make test> or C<./Build test>.

=item format

Specifies format to be used for display of pattern matches.

=over 4

=item original

The original and currently default format looks something like this:

 # File: './lib/Test/Fixme.pm'
 #     16      # ABSTRACT: Check code for FIXMEs.
 #     25          $args{match} = 'FIXME' unless defined $args{match} && length $args{match};
 #     28          $args{format} ||= $ENV{TEST_FIXME_FORMAT};
 #     228      # FIXME - what about windows that are bigger than the screen?
 #     230      # FIXME - add checking of user privileges here.
 #     239     By default run_tests will search for 'FIXME' in all the files it can
 #     280     Do not fail when a FIXME or other pattern is matched.  Tests that would
 #     288     If you want to match something other than 'FIXME' then you may find
 #     296      run_tests( skip_all => $ENV{SKIP_TEST_FIXME} );
 #     303     L<Devel::FIXME>

With the line numbers on the left and the offending text on the right.

=item perl

The "perl" format is that used by Perl itself to report warnings and errors.

 # Pattern found at ./lib/Test/Fixme.pm line 16:
 #  # ABSTRACT: Check code for FIXMEs.
 # Pattern found at ./lib/Test/Fixme.pm line 25:
 #      $args{match} = 'FIXME' unless defined $args{match} && length $args{match};
 # Pattern found at ./lib/Test/Fixme.pm line 28:
 #      $args{format} ||= $ENV{TEST_FIXME_FORMAT};
 # Pattern found at ./lib/Test/Fixme.pm line 228:
 #   # FIXME - what about windows that are bigger than the screen?
 # Pattern found at ./lib/Test/Fixme.pm line 230:
 #   # FIXME - add checking of user privileges here.
 # Pattern found at ./lib/Test/Fixme.pm line 239:
 #  By default run_tests will search for 'FIXME' in all the files it can
 # Pattern found at ./lib/Test/Fixme.pm line 280:
 #  Do not fail when a FIXME or other pattern is matched.  Tests that would
 # Pattern found at ./lib/Test/Fixme.pm line 288:
 #  If you want to match something other than 'FIXME' then you may find
 # Pattern found at ./lib/Test/Fixme.pm line 296:
 #   run_tests( skip_all => $ENV{SKIP_TEST_FIXME} );
 # Pattern found at ./lib/Test/Fixme.pm line 303:
 #  L<Devel::FIXME>

For files that contain many offending patterns it may be a bit harder to read for
humans, but easier to parse for IDEs.

=back

You may also use the C<TEST_FIXME_FORMAT> environment variable to override either
the default or the value specified in the test file.

=back

=head1 HINTS

If you want to match something other than 'FIXME' then you may find
that the test file itself is being caught. Try doing this:

 run_tests( match => 'TO'.'DO' );

You may also wish to suppress the tests - try this:

 use Test::Fixme;
 run_tests( skip_all => $ENV{SKIP_TEST_FIXME} );

You can only run run_tests once per file. Please use several test
files if you want to run several different tests.

=head1 CAVEATS

This module is fully supported back to Perl 5.8.1.  It may work on 5.8.0.
It should work on Perl 5.6.x and I may even test on 5.6.2.  I will accept
patches to maintain compatibility for such older Perls, but you may
need to fix it on 5.6.x / 5.8.0 and send me a patch.

=head1 SEE ALSO

L<Devel::FIXME>

=head1 ACKNOWLEDGMENTS

Dave O'Neill added support for 'filename_match' and also being able to pass a
list of several directories in the 'where' argument. Many thanks.

=head1 AUTHOR

Original author: Edmund von der Burg

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Dave O'Neill

gregor herrmann E<lt>gregoa@debian.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005-2024 by Edmund von der Burg <evdb@ecclestoad.co.uk>, Graham Ollis <plicease@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


1;
