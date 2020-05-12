use Test2::Roo;

use lib 'lib';

with 'IteratorTest';

run_me(
    {
        iterator_class => 'Path::Iterator::Rule',
        result_type    => '',
    }
);

done_testing;
