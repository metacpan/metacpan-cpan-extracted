
use strict;
use Test::More;
use Test::Pod::Spelling (
    spelling => { allow_words => ['Schwern'] }	
);

all_pod_files_spelling_ok();

done_testing();


