use Test::More qw/no_plan/;
use warnings;
use strict;
use Test::Exception;
use Text::Livedoor::Wiki::Function;

dies_ok { Text::Livedoor::Wiki::Function->new( { plugins => ['ErrorErrrErrrorFunction'] } )->setup } 'error plugin';

