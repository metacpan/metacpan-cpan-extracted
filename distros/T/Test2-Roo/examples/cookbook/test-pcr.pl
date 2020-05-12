use Test2::Roo;

use lib 'lib';

with 'IteratorTest';

run_me(
    {
        iterator_class => 'Path::Class::Rule',
        result_type    => 'Path::Class::Entity',
    },
);

done_testing;
