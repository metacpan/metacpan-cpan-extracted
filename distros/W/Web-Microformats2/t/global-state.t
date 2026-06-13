use strict;
use warnings;
use Test::More;

use HTML::TreeBuilder;
use Web::Microformats2::Parser;

# The parser teaches HTML::TreeBuilder about HTML5 elements so it can find
# microformats nested inside them. That teaching must be scoped to the parse
# call: it must not permanently mutate the %HTML::TreeBuilder::isBodyElement
# package global and leak into everyone else using HTML::TreeBuilder in the
# same process. (See issue #11.)

my @html5_elements = qw(
    article aside details figcaption figure footer header main
    mark nav section summary time
);

# Snapshot which of these the global already treats as body elements, before
# we run any parse, so the assertion is robust to HTML::TreeBuilder versions
# that already know some HTML5 tags.
my %known_before =
    map  { $_ => 1 }
    grep { $HTML::TreeBuilder::isBodyElement{ $_ } }
    @html5_elements;

my $parser = Web::Microformats2::Parser->new;
$parser->parse(
    '<article><div class="h-card"><span class="p-name">Alice</span></div></article>'
);

my @leaked =
    grep { $HTML::TreeBuilder::isBodyElement{ $_ } && !$known_before{ $_ } }
    @html5_elements;

is_deeply( \@leaked, [],
    'parse() does not permanently pollute %HTML::TreeBuilder::isBodyElement' )
    or diag( "Leaked global isBodyElement keys: @leaked" );

done_testing;
