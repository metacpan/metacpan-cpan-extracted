package MyTest::TestBuilderIOLayerUTF8;

use strict;
use warnings;

use Test::Kit;
use Test::Builder;

include 'Test::More';

include 'Test::Output';

my $builder = Test::Builder->new;
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';
binmode $builder->output, ':encoding(utf-8)';
binmode $builder->failure_output, ':encoding(utf-8)';
binmode $builder->failure_output, ':encoding(utf-8)';

1;
