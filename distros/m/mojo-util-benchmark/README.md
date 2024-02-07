# Mojo::Util::Benchmark

This package is going to provide a set of utilities for measuring the performance of Perl code.

# Usage

```perl
use Mojo::Util::Benchmark qw(benchmark);

my $benchmark = benchmark()->start('query');

# ... query the database here ...

$benchmark->stop('query');
```
