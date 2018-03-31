#!perl

use strict;
use warnings;
use Test::More tests => 28;

use lib "t/lib";
use TestTester;

BEGIN { use_ok('Test::DocClaims'); }

=head1 FUNCTIONS

=head2 doc_claims I<DOC_SPEC> I<TEST_SPEC> [ I<TEST_NAME>  ]

=cut

# The third arg is optional.
findings_match( sub {
    doc_claims( "lib/Foo.pm", "t/doc-Foo.t", "Foo.pm" );
}, [
    [ "ok", "Foo.pm" ],
]);
findings_match( sub {
    doc_claims( "lib/Foo.pm", "t/doc-Foo.t" );
}, [
    [ "ok", "documentation claims are tested" ],
]);

=pod

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

=cut

# Test each variation of the DOC_SPEC arg.
# String/wildcard
findings_match( sub {
    doc_claims( "lib/Car.pm", "t/doc-Car.t", "Car.pm" );
}, [
    [ "ok", "Car.pm" ],
]);
findings_match( sub {
    doc_claims( "lib/Car-*.pm", "t/doc-Car.t", "Car-*.pm" );
}, [
    [ "ok", "Car-*.pm" ],
]);

# Hash
findings_match( sub {
    doc_claims( { path => "lib/Car.pm" }, "t/doc-Car.t", "Car.pm" );
}, [
    [ "ok", "Car.pm" ],
]);
findings_match( sub {
    doc_claims( { path => "lib/Car-*.pm" }, "t/doc-Car.t", "Car-*.pm" );
}, [
    [ "ok", "Car-*.pm" ],
]);

# Array with one element
findings_match( sub {
    doc_claims( [ "lib/Car.pm" ], "t/doc-Car.t", "Car.pm" );
}, [
    [ "ok", "Car.pm" ],
]);
findings_match( sub {
    doc_claims( [ "lib/Car-*.pm" ], "t/doc-Car.t", "Car-*.pm" );
}, [
    [ "ok", "Car-*.pm" ],
]);
findings_match( sub {
    doc_claims( [ { path => "lib/Car.pm" } ], "t/doc-Car.t", "Car.pm" );
}, [
    [ "ok", "Car.pm" ],
]);
findings_match( sub {
    doc_claims( [ { path => "lib/Car-*.pm" } ], "t/doc-Car.t", "Car-*.pm" );
}, [
    [ "ok", "Car-*.pm" ],
]);

# Array with two elements
findings_match( sub {
    doc_claims( [
	"lib/Car-1.pm",
	"lib/Car-2.pm",
    ], "t/doc-Car.t", "Car.pm" );
}, [
    [ "ok", "Car.pm" ],
]);
findings_match( sub {
    doc_claims( [
	"lib/Ca*-1.pm",
	"lib/Ca*-2.pm",
    ], "t/doc-Car.t", "Car-*.pm" );
}, [
    [ "ok", "Car-*.pm" ],
]);
findings_match( sub {
    doc_claims( [
	{ path => "lib/Car-1.pm" },
	{ path => "lib/Car-2.pm" },
    ], "t/doc-Car.t", "Car.pm" );
}, [
    [ "ok", "Car.pm" ],
]);
findings_match( sub {
    doc_claims( [
	{ path => "lib/Ca*-1.pm" },
	{ path => "lib/Ca*-2.pm" },
    ], "t/doc-Car.t", "Car-*.pm" );
}, [
    [ "ok", "Car-*.pm" ],
]);

# Test each variation of the TEST_SPEC arg.
# String/wildcard
findings_match( sub {
    doc_claims( "lib/Bar.pm", "t/doc-Bar.t", "Bar.t" );
}, [
    [ "ok", "Bar.t" ],
]);
findings_match( sub {
    doc_claims( "lib/Bar.pm", "t/doc-Bar-*.t", "Bar-*.t" );
}, [
    [ "ok", "Bar-*.t" ],
]);

# Hash
findings_match( sub {
    doc_claims( "lib/Bar.pm", { path => "t/doc-Bar.t" }, "Bar.t" );
}, [
    [ "ok", "Bar.t" ],
]);
findings_match( sub {
    doc_claims( "lib/Bar.pm", { path => "t/doc-Bar-*.t" }, "Bar-*.t" );
}, [
    [ "ok", "Bar-*.t" ],
]);

# Array with one element
findings_match( sub {
    doc_claims( "lib/Bar.pm", [ "t/doc-Bar.t" ], "Bar.t" );
}, [
    [ "ok", "Bar.t" ],
]);
findings_match( sub {
    doc_claims( "lib/Bar.pm", [ "t/doc-Bar-*.t" ], "Bar-*.t" );
}, [
    [ "ok", "Bar-*.t" ],
]);
findings_match( sub {
    doc_claims( "lib/Bar.pm", [ { path => "t/doc-Bar.t" } ], "Bar.t" );
}, [
    [ "ok", "Bar.t" ],
]);
findings_match( sub {
    doc_claims( "lib/Bar.pm", [ { path => "t/doc-Bar-*.t" } ], "Bar-*.t" );
}, [
    [ "ok", "Bar-*.t" ],
]);

# Array with two elements
findings_match( sub {
    doc_claims( "lib/Bar.pm", [
	"t/doc-Bar-1.t",
	"t/doc-Bar-2.t",
    ], "Bar.t" );
}, [
    [ "ok", "Bar.t" ],
]);
findings_match( sub {
    doc_claims( "lib/Bar.pm", [
	"t/doc-Ba*-1.t",
	"t/doc-Ba*-2.t",
    ], "Bar-*.t" );
}, [
    [ "ok", "Bar-*.t" ],
]);
findings_match( sub {
    doc_claims( "lib/Bar.pm", [
	{ path => "t/doc-Bar-1.t" },
	{ path => "t/doc-Bar-2.t" },
    ], "Bar.t" );
}, [
    [ "ok", "Bar.t" ],
]);
findings_match( sub {
    doc_claims( "lib/Bar.pm", [
	{ path => "t/doc-Ba*-1.t" },
	{ path => "t/doc-Ba*-2.t" },
    ], "Bar-*.t" );
}, [
    [ "ok", "Bar-*.t" ],
]);

=pod

If a list of files is given, those files are read in order and the
documentation in each is concatenated.
This is useful when a module file requires many tests that are best split
into multiple files in the test suite.
For example:

=cut

findings_match( sub {

=begin DC_CODE

=cut

  doc_claims( "lib/Foo/Bar.pm", "t/Bar-*.t", "doc claims" );

=end DC_CODE

=cut

}, [
    ["ok", "doc claims"],
]);

=pod

If a wildcard is used, be sure that the generated list of files is in the
correct order. It may be useful to number them (such as Foo-01-SYNOPSIS.t,
Foo-02-DESCRIPTION.t, etc).

=cut

__DATA__

FILE:<lib/Foo.pm>-------------------------------------
=head2 Foo
FILE:<t/doc-Foo.t>-------------------------------------
=head2 Foo
FILE:<lib/Bar.pm>-------------------------------------
=head2 Bar 1
=head2 Bar 2
FILE:<t/doc-Bar.t>-------------------------------------
=head2 Bar 1
=head2 Bar 2
FILE:<t/doc-Bar-1.t>-------------------------------------
=head2 Bar 1
FILE:<t/doc-Bar-2.t>-------------------------------------
=head2 Bar 2
FILE:<lib/Car.pm>-------------------------------------
=head2 Car 1
=head2 Car 2
FILE:<lib/Car-1.pm>-------------------------------------
=head2 Car 1
FILE:<lib/Car-2.pm>-------------------------------------
=head2 Car 2
FILE:<t/doc-Car.t>-------------------------------------
=head2 Car 1
=head2 Car 2

FILE:<lib/Foo/Bar.pm>--------------------------------
=head2 Foo::Bar 1
=head2 Foo::Bar 2
FILE:<t/Bar-1.t>-------------------------------
=head2 Foo::Bar 1
FILE:<t/Bar-2.t>-------------------------------
=head2 Foo::Bar 2
