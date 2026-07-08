#!perl

use 5.016;
use strict;
use warnings;

use Test::More tests => 6;

#===========================================================================
# Smoke Tests — module loads, basic API
#===========================================================================

Main:
{
    use_ok('Text::MarkdownAdoc');
    use_ok('Text::MarkdownAdoc::Parser');
    use_ok('Text::MarkdownAdoc::Inline');
    use_ok('Text::MarkdownAdoc::Refs');

    # Verify ->new returns an object
    my $converter = Text::MarkdownAdoc->new();
    isa_ok($converter, 'Text::MarkdownAdoc', 'new() returns a Text::MarkdownAdoc object');

    # Verify ->convert('') returns a string
    my $result = $converter->convert('');
    ok(!ref($result) && defined($result), 'convert("") returns a defined string');
}

done_testing();