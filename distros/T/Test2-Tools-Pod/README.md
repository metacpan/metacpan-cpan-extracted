# Test2::Tools::Pod

POD syntax test for Test2

    use Test2::V0;
    use Test2::Tools::Pod;

    # Check a single file
    pod_ok 'lib/Module.pm';

    # Check all modules in distribution
    all_pod_ok;

    done_testing;

## Installation

Install with [cpanm][cpm]:

    $ cpanm Test2::Tools::Pod

## Documentation

To learn more about Test2::Tools::Pod, check the included documentation
with:

    $ perldoc Test2::Tools::Pod

Or, if you haven't installed it yet:

    $ perldoc lib/Test2/Tools/Pod

 [cpm]: https://github.com/miyagawa/cpanminus
