package Test::DocClaims;

# Copyright (C) Scott E. Lee

use 5.008009;
use strict;
use warnings;
use Carp;
use File::Find;

use Test::DocClaims::Lines;
our $VERSION = '0.001';

use Test::Builder::Module;
our @ISA    = qw< Test::Builder::Module >;
our @EXPORT = qw<
    doc_claims
    all_doc_claims
>;

our $doc_file_re = qr/\.(pl|pm|pod|md)$/i;
our @doc_ignore_list;

our $TODO;

=head1 NAME

Test::DocClaims - Help assure documentation claims are tested

=head1 SYNOPSIS

To automatically scan for source files containing POD, find the
corresponding tests and verify that those tests match the POD, create the
file t/doc_claims.t with the following lines:

  use Test::More;
  eval "use Test::DocClaims";
  plan skip_all => "Test::DocClaims not found" if $@;
  all_doc_claims();

Or, for more control over the POD files and which tests correspond to them:

  use Test::More;
  eval "use Test::DocClaims";
  plan skip_all => "Test::DocClaims not found" if $@;
  plan tests => 2;
  doc_claims( "lib/Foo/Bar.pm", "t/doc-Foo-Bar.t",
    "doc claims in Foo/Bar.pm" );
  doc_claims( "lib/Foo/Bar/Baz.pm", "t/doc-Foo-Bar-Baz.t",
    "doc claims in Foo/Bar/Baz.pm" );

If a source file (lib/Foo/Bar.pm) contains:

  =head2 add I<arg1> I<arg2>

  This adds two numbers.

  =cut

  sub add {
      return $_[0] + $_[1];
  }

then the corresponding test (t/doc-Foo-Bar.t) might have:

  =head2 add I<arg1> I<arg2>

  This adds two numbers.

  =cut

  is( add(1,2), 3, "can add one and two" );
  is( add(2,3), 5, "can add two and three" );

=head1 DESCRIPTION

A module should have documentation that defines its interface. All claims in
that documentation should have corresponding tests to verify that they are
true. Test::DocClaims is designed to help assure that those tests are written
and maintained.

It would be great if software could read the documentation, enumerate all
of the claims made and then generate the tests to assure
that those claims are properly tested.
However, that level of artificial intelligence does not yet exist.
So, humans must be trusted to enumerate the claims and write the tests.

How can Test::DocClaims help?
As the code and its documentation evolve, the test suite can fall out of
sync, no longer testing the new or modified claims.
This is where Test::DocClaims can assist.
First, a copy of the POD documentation must be placed in the test suite.
Then, after each claim, a test of that claim should be inserted.
Test::DocClaims compares the documentation in the code with the documentation
in the test suite and reports discrepancies.
This will act as a trigger to remind the human to update the test suite.
It is up to the human to actually edit the tests, not just sync up the
documentation.

The comparison is done line by line.
Trailing white space is ignored.
Any white space sequence matches any other white space sequence.
Blank lines as well as "=cut" and "=pod" lines are ignored.
This allows tests to be inserted even in the middle of a paragraph by
placing a "=cut" line before and a "=pod" line after the test.

Additionally, a special marker, of the form "=for DC_TODO", can be placed
in the test suite in lieu of writing a test.
This serves as a reminder to write the test later, but allows the
documentation to be in sync so the Test::DocClaims test will pass with a
todo warning.
Any text on the line after DC_TODO is ignored and can be used as a comment.

Especially in the SYNOPSIS section, it is common practice to include
example code in the documentation.
In the test suite, if this code is surrounded by "=begin DC_CODE" and "=end
DC_CODE", it will be compared as if it were part of the POD, but can run as
part of the test.
For example, if this is in the documentation

  Here is an example:

    $obj->process("this is some text");

this could be in the test

  Here is an example:

  =begin DC_CODE

  =cut

  $obj->process("this is some text");

  =end DC_CODE

Example code that uses print or say and has a comment at the end will also
match a call to is() in the test.
For example, this in the documentation POD

  The add function will add two numbers:

    say add(1,2);            # 3
    say add(50,100);         # 150

will match this in the test.

  The add function will add two numbers:

  =begin DC_CODE

  =cut

  is(add(1,2), 3);
  is(add(50,100), 150);

  =end DC_CODE

When comparing code inside DC_CODE markers, all leading white space is
ignored.

When the documentation file type does not support POD (such as mark down
files, *.md) then the entire file is assumed to be documentation and must
match the POD in the test file.
For these files, leading white space is ignored.
This allows a leading space to be added in the POD if necessary.

=head1 FUNCTIONS

=head2 doc_claims I<DOC_SPEC> I<TEST_SPEC> [ I<TEST_NAME>  ]

Verify that the lines of documentation in I<TEST_SPEC> match the ones in
I<DOC_SPEC>.
The I<TEST_SPEC> and I<DOC_SPEC> arguments specify a list of one or more
files.
Each of the arguments can be one of:

  - a string which is the path to a file or a wildcard which is
    expanded by the glob built-in function.
  - a ref to a hash with these keys:
    - path:    path or wildcard (required)
    - has_pod: true if the file can have POD (optional)
  - a ref to an array, where each element is a path, wildcard or hash
    as above

If a list of files is given, those files are read in order and the
documentation in each is concatenated.
This is useful when a module file requires many tests that are best split
into multiple files in the test suite.
For example:

  doc_claims( "lib/Foo/Bar.pm", "t/Bar-*.t", "doc claims" );

If a wildcard is used, be sure that the generated list of files is in the
correct order. It may be useful to number them (such as Foo-01-SYNOPSIS.t,
Foo-02-DESCRIPTION.t, etc).

=cut

sub doc_claims {
    my ( $doc_spec, $test_spec, $name ) = @_;
    $name = "documentation claims are tested" unless defined $name;
    my $doc  = Test::DocClaims::Lines->new($doc_spec);
    my $test = Test::DocClaims::Lines->new($test_spec);
    _dbg_file( "D", $doc );
    _dbg_file( "T", $test );
    my @error;
    my ( $test_line, $doc_line );
    my $todo = 0;

    while ( !$doc->is_eof && !$test->is_eof ) {
        $doc_line  = $doc->current_line;
        $test_line = $test->current_line;

        # Skip over the line if it is blank or is a non-POD line in a file
        # that supports POD.
        my $last = 0;
        while ( !$doc_line->is_doc || $doc_line->text =~ /^\s*$/ ) {
            _dbg_line( "D", "s", $doc_line );
            if ( $doc->advance_line ) {
                $doc_line = $doc->current_line;
            } else {
                $last = 1;
                last;
            }
        }
        while ( !$test_line->is_doc || $test_line->text =~ /^\s*$/ ) {
            if ( $test_line->todo ) {
                $todo++;
            }
            _dbg_line( "T", "s", $test_line );
            if ( $test->advance_line ) {
                $test_line = $test->current_line;
            } else {
                $last = 1;
                last;
            }
        }
        last if $last;

        if ( _diff( $doc_line, $test_line ) ) {
            _dbg_line( "D", "M", $doc_line );
            _dbg_line( "T", "M", $test_line );
            $test->advance_line;
            $doc->advance_line;
        } else {
            _dbg_line( "D", "X", $doc_line );
            _dbg_line( "T", "X", $test_line );
            my $tb = Test::DocClaims->builder;
            my $fail = $tb->ok( 0, $name );
            _diff_error( $test_line, $doc_line, $name );
            return $fail;
        }
    }

    # Ignore blank lines at the end of file.
    while ( !$doc->is_eof && $doc->current_line =~ /^\s*$/ ) {
        _dbg_line( "D", "e", $doc->current_line );
        $doc->advance_line;
    }
    while ( !$test->is_eof && $test->current_line =~ /^\s*$/ ) {
        _dbg_line( "T", "e", $test->current_line );
        $test->advance_line;
    }

    if ( !$test->is_eof || !$doc->is_eof ) {
        my $tb = Test::DocClaims->builder;
        my $fail = $tb->ok( 0, $name );
        _diff_error( $test->current_line, $doc->current_line, $name );
        return $fail;
    } else {
        my $tb = Test::DocClaims->builder;
    TODO: {
            local $TODO = "$todo DC_TODO lines" if $todo;
            return $tb->ok( $todo ? 0 : 1, $name );
        }
    }
}

# For debugging only.
sub _dbg_file {
    if ( $ENV{DOCCLAIMS_TRACE} ) {
        my $letter = shift;
        my $file   = shift;
        my $path   = join " ", $file->paths;
        print STDERR "$letter ----- $path\n";
    }
}

# For debugging only.
sub _dbg_line {
    if ( $ENV{DOCCLAIMS_TRACE} ) {
        my $letter = shift;
        my $action = shift;
        my $line   = shift;
        my $text   = $line->text;
        my $isdoc  = $line->is_doc ? "d" : ".";
        my $iscode = $line->code ? "c" : ".";
        print STDERR "$letter:$isdoc$iscode$action '$text'\n";
    }
}

# A list of diff routines to handle special cases for lines in a DC_CODE
# section. In the future other keys will be added to this hash that match
# words at the end of the DC_CODE directive. The ones under the "" key are
# tried on every line.
our %code_diff = (
    "" => [
        sub {
            my ( $doc, $test ) = @_;
            if (
                $doc =~ /
                ^ \s* (print|say) \s* (.+?) \s* ; \s+ \# \s* (.+?) \s* $
                /x
                )
            {
                my ( $left, $right ) = ( $2, $3 );
                $left  =~ s/ ^ \( \s* (.*?) \s* \) $ /$1/x;    # remove ()
                $right =~ s/^"(.*)"$/$1/;
                $right =~ s/^'(.*)'$/$1/;
                if (
                    $test =~ /^
                    \s* is \s* \(? \s* \Q$left\E \s*
                    , \s* ["']? \Q$right\E \s* ["']? \s*
                    ( , .* )?
                    \s* \)? \s* ;
                    /x
                    )
                {
                    return 1;
                }
            }
            return 0;
        },
    ],
);

# Given doc and test Test::DocClaims::Line objects, return true if they
# match. This takes white space rules, etc. into account.
sub _diff {
    my $doc_line  = shift;
    my $test_line = shift;
    my $doc       = $doc_line->text;
    my $test      = $test_line->text;
    $doc  =~ s/\s+/ /g;
    $test =~ s/\s+/ /g;
    $doc  =~ s/\s+$//;
    $test =~ s/\s+$//;
    if ( $test_line->code ) {
        $doc  =~ s/^\s+//;
        $test =~ s/^\s+//;
    }
    return 1 if $test eq $doc;

    # Try special diff routines for DC_CODE sections.
    foreach my $subr ( @{ $code_diff{""} } ) {
        return 1 if $subr->( $doc, $test );
    }

    return 0;
}

sub _diff_error {
    my ( $test_line, $doc_line, $name ) = @_;
    my @error;
    my $prefix = "     got";
    foreach my $line ( $test_line, $doc_line ) {
        if ( ref $line ) {
            my $text = $line->text;
            push @error, "$prefix: '$text'";
            push @error, "at " . $line->path . " line " . $line->lnum;
            ( $error[-1], $error[-2] ) = ( $error[-2], $error[-1] )
                if $prefix =~ /got/;
        } else {
            push @error, "$prefix: eof";
        }
        $prefix = "expected";
    }
    my $tb = Test::DocClaims->builder;
    $tb->diag( map { "    $_\n" } @error );
}

=head2 all_doc_claims [ I<DOC_DIRS> [ I<TEST_DIRS> ] ]

This is the easiest way to test the documentation claims.
It automatically searches for documentation and then locates the
corresponding test file or files.
By default, it searches the lib, bin and scripts directories and their
subdirectories for documentation.
For each of these files it looks in (by default) the t
directory for one or more matching files.
It does this with the following patterns, where PATH is the path of the
documentation file with the suffix removed (e.g., .pm or .pl) and slashes
(/) converted to dashes (-).
The patterns are tried in this order until one matches.

  doc-PATH-[0-9]*.t
  doc-PATH.t
  PATH-[0-9]*.t
  PATH.t

If none of the patterns match, the left most directory of the PATH is
removed and the patterns are tried again.
This is repeated until a match is found or the PATH is exhausted.
If the pattern patches multiple files, these files are processed in
alphabetical order and their documentation is concatenated to match against
the documentation file.

If I<DOC_DIRS> is missing or undef, its default value of
[qw< lib bin scripts >] is used.
If I<TEST_DIRS> is missing or undef, its default value of
[qw< t >] is used.

When searching for documentation files, any file with one of these suffixes
is used:

   *.pl
   *.pm
   *.pod
   *.md

Also, any file who's first line matches /^#!.*perl/i is used.

The number of tests run is determined by the number of documentation files
found.
Do not set the number of tests before calling all_doc_claims because it
will do that automatically.

=cut

# TODO add option to change suffixes
sub all_doc_claims {
    my $doc_arg  = shift;
    my $test_arg = shift;
    my @docs     = _find_docs($doc_arg);
    my $tb       = Test::DocClaims->builder;
    $tb->plan( tests => scalar @docs );
    foreach my $doc_file (@docs) {
        my $doc_path = ref $doc_file ? $doc_file->{path} : $doc_file;
        my $test_file = _find_tests( $doc_path, $test_arg );
        if ( length $test_file ) {
            doc_claims( $doc_file, $test_file, "doc claims in $doc_path" );
        } else {
            $tb->ok( 0, "doc claims in $doc_path" );
            $tb->diag("    no test file(s) found for $doc_path");
        }
    }
}

sub _find_docs {
    my $dirs = shift;
    $dirs = [qw< lib bin scripts >] unless defined $dirs;
    $dirs = [$dirs] unless ref $dirs;
    my @files;
    foreach my $path ( sort { $a cmp $b } _list_files($dirs) ) {
        if ( $path =~ m/$doc_file_re/ ) {
            push @files, $path;
        } elsif ( _read_first_block($path) =~ /^#!.*perl/i ) {
            push @files, { path => $path, has_pod => 1 };
        }
    }
    return @files;
}

# Given a list of files and/or directories, search them and return a list
# of all existing files.
sub _list_files {
    my $dirs = shift;
    my @files;
    find(
        {
            wanted => sub { push @files, $_ if -f $_; },
            no_chdir => 1,
        },
        grep { -e $_ } @$dirs
    );
    return @files;
}

# Return the first block of data from a file. This is used for checking the
# first line for #!perl. But, because it reads a fixed amount will not
# cause issues if the file is binary.
sub _read_first_block {
    my $path = shift;
    my $data = "";
    if ( open my $fh, "<", $path ) {
        binmode $fh;
        read( $fh, $data, 4096 );
        close $fh;
    }
    return $data;
}

sub _find_tests {
    my $path = shift;
    my $dirs = shift;
    $dirs = [qw< t >] unless defined $dirs;
    $dirs = [$dirs]   unless ref $dirs;

    # Construct a list of file names to look for. If the input path is
    # "lib/Foo/Bar" then @names becomes "lib-Foo-Bar", "Foo-Bar", "Bar".
    # One could argue that "lib-Foo-Bar" shouldn't be in the list, but it
    # shouldn't cause problems and dealing with the general case would
    # require a complex algorithm.
    $path =~ s/\.\w+$//;
    my @names;
    while (1) {
        push @names, map { my $p = $_; $p =~ s{/}{-}g; $p } $path;
        $path =~ s{^[^/]*/}{} or last;
    }

    # Note that the pattern is returned with single quotes ('). This helps
    # with the case where there is a space in the path. Unfortunately, glob
    # interprets a space to mean separation of multiple patterns unless the
    # pattern is quoted.
    foreach my $dir (@$dirs) {
        foreach my $name (@names) {
            foreach my $pat (
                qw< doc-PATH-[0-9]*.t doc-PATH.t PATH-[0-9]*.t PATH.t >)
            {
                ( my $pattern = $pat ) =~ s/PATH/$name/;
                $pattern = "$dir/$pattern";
                my @list = _glob($pattern);
                return "'$pattern'" if @list;
            }
        }
    }
    return "";
}

# This wrapper for the glob function can be overridden at run time (by the
# TestTester module), where the system glob can only be overridden at
# compile time.
sub _glob {
    my $pattern = shift;
    if ( $pattern =~ /[*]/ ) {
        return glob("'$pattern'");
    } else {
        return -f $pattern ? ($pattern) : ();
    }
}

=head1 SEE ALSO

L<Devel::Coverage>,
L<POD::Tested>,
L<Test::Inline>.
L<Test::Pod>,
L<Test::Pod::Coverage>,
L<Test::Pod::Snippets>,
L<Test::Synopsis>,
L<Test::Synopsis::Expectation>.

=head1 AUTHOR

Scott E. Lee, E<lt>ScottLee@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2016 by Scott E. Lee

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

