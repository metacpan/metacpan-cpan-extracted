use t::TestLess tests => 1;

run_is command => 'output';

__DATA__
=== Test Usage message
--- command backticks
perl -Ilib -MTest::Less -e "run"
--- output -trim
Usage: test-less [options] command [arguments] [-]

Options:
  -file path_to_index_file
  -quiet
  -verbose

Commands:
  -help
  -tag tags test-files
  -untag tags test-files
  -show test-files
  -list tag-specification
  -prove [prove-flags] tag-specification

Options and commands may be abbreviated to their first letter.

An argument of '-' is replaced by the contents of STDIN split on whitespace.

