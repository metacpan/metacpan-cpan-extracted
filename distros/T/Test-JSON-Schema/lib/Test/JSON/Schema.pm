use strict;
use warnings;
package Test::JSON::Schema; # git description: db019d2
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: Test your data against a JSON Schema
# KEYWORDS: JSON Schema test structured data

our $VERSION = '0.001';

use 5.020;
use strictures 2;
use stable 0.031 'postderef';
use experimental 'signatures';
no autovivification warn => qw(fetch store exists delete);
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';

sub json_schema ($schema) {
  die 'not yet implemented';
}

sub load_json_schema ($schema_or_filename) {
  die 'not yet implemented';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::JSON::Schema - Test your data against a JSON Schema

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Test2::V0l
  use Test::JSON::Schema;

  # something in your application that generates a data structure
  # { foo => 1, bar => 2 }
  my $data = MyApp->execute(...);

  is(
    $data,
    json_schema({
      properties => {
        foo => { type => 'string' },
        bar => { type => 'number' },
      },
    }),
    'data matches the expected schema',
  );

  # file contains: { "type": "number" }
  load_json_schema('t/data/common-app-data-format.json');

  is(
    $data,
    json_schema({
      properties => {
        foo => { type => 'string' },
        bar => { '$ref' => 'file://t/data/common-app-data-format.json' },
      },
    }),
    'data matches the expected schema, with some of it loaded from an external file',
  );

  is(
    'hello',
    json_schema('t/data/common-app-data-format.json'),
    'data matches the expected schema, with the entirety of it loaded from an external file',

prints:

  not ok 1 data matches the expected schema
    # [
    #   {
    #     "instanceLocation": "/foo",
    #     "keywordLocation": "/properties/foo/type",
    #     "error": "got number, not string",
    #   },
    #   {
    #     "instanceLocation": "",
    #     "keywordLocation": "/properties",
    #     "error": "not all properties are valid",
    #   }
  not ok 2 data matches the expected schema, with some of it loaded from an external file
    #   {
    #     "instanceLocation": "/bar",
    #     "keywordLocation": "/properties/bar/$ref/type",
    #     "absoluteKeywordLocation": "file://t/data/common-app-data-format.json#/type",
    #     "error": "got string, not number",
    #   },
    #   {
    #     "instanceLocation": "",
    #     "keywordLocation": "/properties",
    #     "error": "not all properties are valid",
    #   }
  not ok 3 data matches the expected schema, with the entirety of it loaded from an external file
    #   {
    #     "instanceLocation": "hello",
    #     "keywordLocation": "type",
    #     "absoluteKeywordLocation": "file://t/data/common-app-data-format.json#/type",
    #     "error": "got string, not number",
    #   },

=head1 DESCRIPTION

=for stopwords vapourware

NOTE: this distribution is currently vapourware and is not yet implemented!
If you have some opinions about the interface, please come talk to me!

Use a JSON Schema to describe your expected data structure, and embed that in a Test2 function call.

=head1 FUNCTIONS/METHODS

=head2 json_schema

Expresses expected data in the form of a JSON Schema.

=head2 load_json_schema

Loads a JSON Schema into the evaluator so it can be used in subsequent C<json_schema> calls.

If it is a hashref, it is treated as an inline JSON Schema; you must include an C<$id> keyword so it
can be later used via C<$ref> keywords. If it is a string, it is treated as a filename: the file is
loaded from disk; it must have a C<.json> or C<.yaml> extension so that its format can be
determined.  The filename itself is used as the identifier, if an C<$id> keyword is not used in the schema.

=head1 SEE ALSO

=over 4

=item *

L<JSON::Schema::Modern>

=back

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/karenetheridge/Test-JSON-Schema/issues>.

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/perl-qa.html>.

There is also an irc channel available for users of this distribution, at
L<C<#perl> on C<irc.perl.org>|irc://irc.perl.org/#perl-qa>.

I am also usually active on irc, as 'ether' at C<irc.perl.org> and C<irc.libera.chat>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
