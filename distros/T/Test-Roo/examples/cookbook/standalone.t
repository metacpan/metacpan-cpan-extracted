use strictures;
use Test::More;

use lib 'lib';
use CorpusCheck;

CorpusCheck->run_tests({ corpus => "/usr/share/dict/words" });

done_testing;
