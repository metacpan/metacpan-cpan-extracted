use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Text/Handlebars.pm',
    'lib/Text/Handlebars/Compiler.pm',
    'lib/Text/Handlebars/Symbol.pm',
    'lib/Text/Xslate/Syntax/Handlebars.pm',
    't/00-compile.t',
    't/basic.t',
    't/block-helper-builtins.t',
    't/block-helpers.t',
    't/blocks.t',
    't/expressions.t',
    't/helpers-examples.t',
    't/helpers.t',
    't/lambdas.t',
    't/lib/Test/Handlebars.pm',
    't/mustache-extra.t',
    't/mustache-spec-syntax-only.t',
    't/mustache-spec.t',
    't/mustache-spec/Changes',
    't/mustache-spec/README.md',
    't/mustache-spec/Rakefile',
    't/mustache-spec/TESTING.md',
    't/mustache-spec/specs/comments.json',
    't/mustache-spec/specs/comments.yml',
    't/mustache-spec/specs/delimiters.json',
    't/mustache-spec/specs/delimiters.yml',
    't/mustache-spec/specs/interpolation.json',
    't/mustache-spec/specs/interpolation.yml',
    't/mustache-spec/specs/inverted.json',
    't/mustache-spec/specs/inverted.yml',
    't/mustache-spec/specs/partials.json',
    't/mustache-spec/specs/partials.yml',
    't/mustache-spec/specs/sections.json',
    't/mustache-spec/specs/sections.yml',
    't/mustache-spec/specs/~lambdas.json',
    't/mustache-spec/specs/~lambdas.yml',
    't/mustache.t',
    't/mustache/partials/base.mustache',
    't/mustache/partials/user.mustache',
    't/partials.t',
    't/safestring.t'
);

notabs_ok($_) foreach @files;
done_testing;
