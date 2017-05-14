Test2::Tools::AfterSubtest
==========================

Exports a single function for executing a callback after every subtest completes.

```perl
use Test2::Bundle::More;
use Test2::Tools::AfterSubtest;

after_subtest(sub {
    diag "subtest has finished";
});

subtest test => sub {
    ok('subtest is running');
};

subtest test2 => sub {
    ok('subtest2 is running');
};
```
