#!/usr/bin/env perl

use strict;
use warnings;

use English qw( -no_match_vars );
use Text::Aspell;

use Test::HTML::Spelling;

use Test::Builder::Tester tests => 1;
use Test::More;

SKIP: {

    # We want to see what dictionaries are available, and skip the tests
    # if none of them are available.

    my $speller = Text::Aspell->new;

    my @dicts = $speller->dictionary_info;

    foreach my $lang (qw( en es )) {

        skip "Need dictionary for '${lang}'", 1
          unless ( grep { $ARG->{code} eq $lang } @dicts );

    }

    my $content = join( "", <DATA> );

    note($content);

    my $sc = Test::HTML::Spelling->new();

    test_out("ok 1 - spelling_ok");

    $sc->spelling_ok( $content, "spelling_ok" );

    test_test;

}

done_testing;

__DATA__
<html lang="en">
 <head>
    <title>This is a sample document to test spelling</title>
 </head>
 <body>
  <h1>Sample Document</h1>
  <p>The spelling of this paragraph will be checked.</p>
  <div class="foo no-spellcheck bar">
    <p>Garblesnootch biblefrutz fingfanghulmaloo</p>
    <span class="no-spellcheck">Wyzziwoo</span>
  </div>
  <p>But this is alright.</p>
  <p lang="es">y esta, amigo?
    <span class="no-spellcheck">snibblesnootch</span>
    porque...</p>
 </body>
</html>
