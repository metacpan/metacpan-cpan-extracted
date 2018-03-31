#!perl

use strict;
use warnings;
use Test::More tests => 17;

use lib "t/lib";
use TestTester;

BEGIN { use_ok('Test::DocClaims::Lines'); }

=head1 NAME

Test::DocClaims::Lines - Represent lines form one of more files

=head1 SYNOPSIS

=cut

fake_files( sub {

=begin DC_CODE

=cut

  use Test::DocClaims::Lines;
  my $lines = Test::DocClaims::Lines->new("t/Foo*.t");
  my %files;
  while ( !$lines->is_eof ) {
      my $line = $lines->current_line;
      $files{ $line->path }[ $line->lnum - 1 ] = $line->text;
      $lines->advance_line;
  }

=end DC_CODE

=cut

    is_deeply( \%files,
        {
            "t/Foo-1.t" => [
                "x",
            ],
            "t/Foo-2.t" => [
                "y",
            ],
        },
    ) or diag explain \%files;

} ); # end of fake_files()

=head1 DESCRIPTION

This holds a collection of lines from one or more files.
The file path and line number of each line is recorded as well as
other attributes of both the file and the individual lines.
For example, it records whether a file supports POD documentation
and whether each line is POD documentation or not.
Each line in the list is represented as a Test::DocClaims::Line object.

There is a concept of current line.
This can be used to step through the lines sequentially.

=head1 CONSTRUCTOR

=head2 new I<FILE_SPEC>

The I<FILE_SPEC> argument specifies a list of one or more files.
It can be one of:

  - a string which is the path to a file or a wildcard which is
    expanded by the glob built-in function.
  - a ref to a hash with these keys:
    - path:    path or wildcard (required)
    - has_pod: true if the file can have POD (optional)
  - a ref to an array, where each element is a path, wildcard or hash
    as above

=cut

fake_files( sub {

    my $lines;

    # string
    $lines = Test::DocClaims::Lines->new("t/Foo-1.t");
    is_deeply( list_files($lines), [qw< t/Foo-1.t >] );
    $lines = Test::DocClaims::Lines->new("t/Foo*.t");
    is_deeply( list_files($lines), [qw< t/Foo-1.t t/Foo-2.t >] );

    # hash
    $lines = Test::DocClaims::Lines->new( { path => "t/Foo-1.t" } );
    is_deeply( list_files($lines), [qw< t/Foo-1.t >] );
    $lines = Test::DocClaims::Lines->new( { path => "t/Foo*.t" } );
    is_deeply( list_files($lines), [qw< t/Foo-1.t t/Foo-2.t >] );

    # hash with has_pod
    $lines = Test::DocClaims::Lines->new(
        { path => "t/Foo-1.t", has_pod => 1 } );
    is_deeply( list_files($lines), [qw< t/Foo-1.t >] );
    $lines =
        Test::DocClaims::Lines->new( { path => "t/Foo*.t", has_pod => 1 } );
    is_deeply( list_files($lines), [qw< t/Foo-1.t t/Foo-2.t >] );

    # array with string
    $lines = Test::DocClaims::Lines->new( [ "t/Foo-1.t" ] );
    is_deeply( list_files($lines), [qw< t/Foo-1.t >] );
    $lines = Test::DocClaims::Lines->new( [ "t/Foo*.t" ] );
    is_deeply( list_files($lines), [qw< t/Foo-1.t t/Foo-2.t >] );

    # array with hash
    $lines = Test::DocClaims::Lines->new( [ { path => "t/Foo-1.t" } ] );
    is_deeply( list_files($lines), [qw< t/Foo-1.t >] );
    $lines = Test::DocClaims::Lines->new( [ { path => "t/Foo*.t" } ] );
    is_deeply( list_files($lines), [qw< t/Foo-1.t t/Foo-2.t >] );

    # array with hash with has_pod
    $lines = Test::DocClaims::Lines->new(
        [ { path => "t/Foo-1.t", has_pod => 1 } ] );
    is_deeply( list_files($lines), [qw< t/Foo-1.t >] );
    $lines = Test::DocClaims::Lines->new(
        [ { path => "t/Foo*.t", has_pod => 1 } ] );
    is_deeply( list_files($lines), [qw< t/Foo-1.t t/Foo-2.t >] );

    # array with multiple members
    $lines = Test::DocClaims::Lines->new( [
        "t/Foo-1.t",
        "t/Foo-2*.t",
        { path => "t/Bar-1.t" },
        { path => "t/Bar-2.t", has_pod => 1 },
    ] );
    is_deeply( list_files($lines), [qw<
        t/Foo-1.t
        t/Foo-2.t
        t/Bar-1.t
        t/Bar-2.t
    >] );

} );

=pod

If a list of files is given, those files are read in order and the
lines in each are concatenated.
If a wildcard expands to more than one file they are read in the order
returned by the glob built-in.

=cut

fake_files( sub {

    # array with multiple members
    my $lines = Test::DocClaims::Lines->new( [
        "t/Foo-2*.t",
        "t/Other-*.t",
        "t/Foo-1.t",
    ] );
    is_deeply( list_files($lines), [qw<
        t/Foo-2.t
        t/Other-1.t
        t/Other-2.t
        t/Other-3.t
        t/Other-4.t
        t/Other-5.t
        t/Foo-1.t
    >] ) or diag explain $lines;

});

=head1 ACCESSORS

=head2 is_eof

This returns true if the end of the lines has been reached.

=head2 advance_line

This advances to the next line and returns the Test::DocClaims::Line
object for that line.
If there is no next line, undef is returned.

=head2 current_line

Return the current line, a Test::DocClaims::Line object.
If there is no current line because the end has been reached, undef is
returned.

=head2 paths

Return a list of strings for the paths and/or globs used to read the file
or files.

=cut

fake_files( sub {

    # array with multiple members
    my $lines = Test::DocClaims::Lines->new( [
        "t/Foo-2*.t",
        "t/Other-*.t",
        "t/Foo-1.t",
    ] );
    is_deeply( [ $lines->paths ], [qw<
        t/Foo-2*.t
        t/Other-*.t
        t/Foo-1.t
    >] ) or diag explain $lines;

});

=head1 COPYRIGHT

Copyright (c) Scott E. Lee

=cut

sub list_files {
    my $lines = shift;
    my @files;
    while ( !$lines->is_eof ) {
        my $line  = $lines->current_line;
        push @files, $line->path if !@files || $files[-1] ne $line->path;
        $lines->advance_line;
    }
    return \@files;
}

__DATA__

FILE:<t/Foo-1.t>-------------------------
x
FILE:<t/Foo-2.t>-------------------------
y
FILE:<t/Bar-1.t>-------------------------
a
FILE:<t/Bar-2.t>-------------------------
b
FILE:<t/Other-1.t>-------------------------
xx
FILE:<t/Other-2.t>-------------------------
xx
FILE:<t/Other-3.t>-------------------------
xx
FILE:<t/Other-4.t>-------------------------
xx
FILE:<t/Other-5.t>-------------------------
xx
