#! perl

use Test2::V0;

use Test::Lib;

use Test::CleanNamespaces;

namespaces_clean('My::Failures');

done_testing;

1;
