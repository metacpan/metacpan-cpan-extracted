#!perl

use strict;
use warnings;
use Test::More tests => 7;

use lib "t/lib";
use TestTester;

BEGIN { use_ok('Test::DocClaims'); }

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

=cut

findings_match( sub {
    doc_claims( "lib/Foo.pm", "t/doc-Foo.t", "Foo.pm" );
}, [
    [ "ok", "Foo.pm" ],
]);

# Test blank lines at the end on one, but not the other, document.
findings_match( sub {
    doc_claims( "lib/File1.pm", "t/doc-File1.t", "File1.pm" );
    doc_claims( "lib/File2.pm", "t/doc-File2.t", "File2.pm" );
}, [
    [ "ok", "File1.pm" ],
    [ "ok", "File2.pm" ],
]);

=pod

Additionally, a special marker, of the form "=for DC_TODO", can be placed
in the test suite in lieu of writing a test.
This serves as a reminder to write the test later, but allows the
documentation to be in sync so the Test::DocClaims test will pass with a
todo warning.
Any text on the line after DC_TODO is ignored and can be used as a comment.

=cut

findings_match( sub {
    doc_claims( "lib/File3.pm", "t/doc-File3.t", "File3.pm" );
}, [
    [ "not ok TODO[1 DC_TODO lines]", "File3.pm" ],
]);

=pod

Especially in the SYNOPSIS section, it is common practice to include
example code in the documentation.
In the test suite, if this code is surrounded by "=begin DC_CODE" and "=end
DC_CODE", it will be compared as if it were part of the POD, but can run as
part of the test.
For example, if this is in the documentation

=cut

my $source = <<'END_SOURCE';

=begin DC_CODE

  Here is an example:

    $obj->process("this is some text");

=end DC_CODE

=cut

END_SOURCE

=pod

this could be in the test

=cut

my $test = <<'END_TEST';

=begin DC_CODE

  Here is an example:

  =begin DC_CODE

  =cut

  $obj->process("this is some text");

  =end DC_CODE

=end DC_CODE

=cut

END_TEST

$source =~ s/^=(begin|end).*//mg;
$test   =~ s/^=(begin|end).*//mg;
findings_match( { "lib/Foo/Bar.pm" => $source, "t/doc-Foo-Bar.t" => $test },
    sub {
        doc_claims( "lib/Foo/Bar.pm", "t/doc-Foo-Bar.t", "code example" );
    },
    [
        [ "ok", "code example" ],
    ]);

=pod

Example code that uses print or say and has a comment at the end will also
match a call to is() in the test.
For example, this in the documentation POD

=cut

my $source2 = <<'END_SOURCE';

  =pod

=begin DC_CODE

  The add function will add two numbers:

    say add(1,2);            # 3
    say add(50,100);         # 150

=end DC_CODE

=cut

END_SOURCE

=pod

will match this in the test.

=cut

my $test2 = <<'END_TEST';

  =pod

=begin DC_CODE

  The add function will add two numbers:

  =begin DC_CODE

  =cut

  is(add(1,2), 3);
  is(add(50,100), 150);

  =end DC_CODE

=end DC_CODE

=cut

END_TEST

$source2 =~ s/^=.*//mg;
$test2   =~ s/^=.*//mg;
$source2 =~ s/^  //mg;
$test2   =~ s/^  //mg;
findings_match( { "lib/Foo/Bar.pm" => $source2, "t/doc-Foo-Bar.t" => $test2 },
    sub {
        doc_claims( "lib/Foo/Bar.pm", "t/doc-Foo-Bar.t", "example w/say" );
    },
    [
        [ "ok", "example w/say" ],
    ]);

=pod

When comparing code inside DC_CODE markers, all leading white space is
ignored.

=cut

# TODO bug: white space outside DC_CODE is currently ignored too
findings_match( sub {
    doc_claims( "lib/File4.pm", "t/doc-File4.t", "File4.pm" );
}, [
    [ "ok", "File4.pm" ],
]);

=pod

When the documentation file type does not support POD (such as mark down
files, *.md) then the entire file is assumed to be documentation and must
match the POD in the test file.
For these files, leading white space is ignored.
This allows a leading space to be added in the POD if necessary.

=for DC_TODO *.md support

=cut

__END__

FILE:<lib/Foo.pm>-------------------------------------
=head2 Foo

This is
split               
across multiple
lines and has odd and trailing white                 space.

FILE:<t/doc-Foo.t>-------------------------------------

=head2 Foo

This is     

=cut

ok test_something();

=pod

=cut

=pod

split




across multiple
lines and has       odd and trailing white space.

FILE:<lib/File1.pm>-------------------------------------
=head2 File1

FILE:<t/doc-File1.t>-------------------------------------
=head2 File1
FILE:<lib/File2.pm>-------------------------------------
=head2 File2
FILE:<t/doc-File2.t>-------------------------------------
=head2 File2

FILE:<lib/File3.pm>-------------------------------------
=head2 File3

Some claim.
Another claim.

FILE:<t/doc-File3.t>-------------------------------------
=head2 File3

Some claim.

=for DC_TODO need to add a test for the above claim

Another claim.

FILE:<lib/File4.pm>-------------------------------------
=head2 Example

  $foo = do_something();
  $bar = do_another();

FILE:<t/doc-File4.t>-------------------------------------
=head2 Example

=begin DC_CODE

=cut

$foo = do_something();
       $bar = do_another();

=end DC_CODE

FILE:<lib/README.md>-------------------------------------
This is a test
of     a markdown file.   
FILE:<t/doc-README.t>-------------------------------------
=pod

This    is a test   
 of a markdown file.
