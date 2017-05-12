use strict;
use warnings;
use Test::More tests => 3;
use Test::Exception;

BEGIN { use_ok('Text::Snippet::TabStop') };

dies_ok { Text::Snippet::TabStop->new } 'missing required parameters';
dies_ok {Text::Snippet::TabStop->parse( '' ) } 'abstract method does';
