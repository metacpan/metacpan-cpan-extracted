#!perl

use strict;
use warnings;
use Test::More tests => 22;

BEGIN { use_ok('Test::DocClaims::Line'); }

=head1 NAME

Test::DocClaims::Line - Represent one line from a text file

=head1 SYNOPSIS

=cut

my $line;

=begin DC_CODE

=cut

  use Test::DocClaims::Line;
  my %hash = ( text => 'package Foo;', lnum => 1 );
  $hash{file} = { path => 'foo/bar.pm', has_pod => 1 };
  $line = Test::DocClaims::Line->new(%hash);
  is( $line->lnum(), 1 );
  is( $line->path(), "foo/bar.pm" );
  is( $line->text(), "package Foo;" );

=end DC_CODE

=head1 DESCRIPTION

This object represents a single line from a source file, documentation file
or test suite file.
It knows what file it came from and the line number in that file.
It also records other attributes.

=head1 CONSTRUCTOR

=head2 new I<HASH>

This method creates a new object from the I<HASH>.
The I<HASH> must have as a minimum the following keys:

  file    hash of information about the file containing this line
  text    the text of the line
  lnum    the line number in the file

The hash in the "file" key must have as a minimum the following keys:

  path     path of the file
  has_pod  true if this file supports POD (*.pm vs. *.md)

If the above minimum keys are not present the method will die.
Additional keys may be present in either hash.

=cut

my $obj;
$obj = eval { Test::DocClaims::Line->new(
    file => { path => "foo.pm", has_pod => 1 },
    text => "package Foo;",
    lnum => 1,
) };
is( $@, "" );

$obj = eval { Test::DocClaims::Line->new(
    text => "package Foo;",
    lnum => 1,
) };
ok( length $@ );

$obj = eval { Test::DocClaims::Line->new(
    file => { path => "foo.pm", has_pod => 1 },
    lnum => 1,
) };
ok( length $@ );

$obj = eval { Test::DocClaims::Line->new(
    file => { path => "foo.pm", has_pod => 1 },
    text => "package Foo;",
) };
ok( length $@ );

$obj = eval { Test::DocClaims::Line->new(
    file => { has_pod => 1 },
    text => "package Foo;",
    lnum => 1,
) };
ok( length $@ );

$obj = eval { Test::DocClaims::Line->new(
    file => { path => "foo.pm" },
    text => "package Foo;",
    lnum => 1,
) };
ok( length $@ );

=head1 ACCESSORS

The following accessors simply return a value from the constructor.
The meaning of all such values is determined by the caller of the
constructor.
No logic is present to calculate or validate these values.
If the requested value was not passed to the constructor then the returned
value will be undef.

=head2 path

Return the path of the file.

=head2 has_pod

Return true if the file supports POD, false otherwise.

=head2 lnum

Return the line number in the file that this line came from.

=head2 text

Return the text of the line.

=head2 is_doc

Return true if this line is a line of documentation (e.g., a POD line) or
false if not (e.g., code).

=head2 code

Return true if this line is from a DC_CODE section, false otherwise.

=head2 todo

Return true if this line is a "=for DC_TODO" command paragraph.

=cut

my $line1 = Test::DocClaims::Line->new(
    file => { path => "foo.pm", has_pod => 1 },
    text => "package Foo;",
    is_doc => 0,
    code   => 0,
    todo   => 1,
    lnum => 1,
);
my $line2 = Test::DocClaims::Line->new(
    file   => { path => "README.md", has_pod => 0 },
    text   => "This is a test.",
    is_doc => 1,
    code   => 1,
    todo   => 0,
    lnum   => 3,
);
is( $line1->has_pod, 1 );
is( $line2->has_pod, 0 );
is( $line1->lnum, 1 );
is( $line2->lnum, 3 );
is( $line1->text, "package Foo;" );
is( $line2->text, "This is a test." );
ok( !$line1->is_doc );
ok( $line2->is_doc );
ok( !$line1->code );
ok( $line2->code );
ok( $line1->todo );
ok( !$line2->todo );

=head1 COPYRIGHT

Copyright (c) Scott E. Lee

=cut

