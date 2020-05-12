use strictures;
use Test2::V0;

use lib 'lib';
use CorpusCheck;

CorpusCheck->run_tests({ corpus => "/usr/share/dict/words" });

done_testing;
