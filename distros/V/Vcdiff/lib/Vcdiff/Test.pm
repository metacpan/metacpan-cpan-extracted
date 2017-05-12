package Vcdiff::Test;

use strict;

use Vcdiff;
use File::Temp qw/ tempfile /;

require Test::More;




our $testcases = [
  ["", "", "both empty"],
  ["", "asdfasdfasdfasdf", "only adds"],
  ["asdfasdfasdfasdf", "", "only dels"],

  ["abcdef", "abcdef", "no change"],
  ["abcdef", "abcDef", "single bit change"],

  ["abcdefghi"x100, "abcdefghi"x51 . "zzzzzzzzzzzzzzzz" . "abcdefghi"x50, "insert small delta"],
  ["abcdefghi"x51 . "zzzzzzzzzzzzzzzz" . "abcdefghi"x50, "abcdefghi"x100 . "abcdefghi"x51 . "zzzzzzzzzzzzzzzz" . "abcdefghi"x50, "maybe big delta"],
  ["\x00"x1000000, "\x01"x1000000, "million 0s to million 1s"],
];





## The first two arguments can be strings or references to a strings
##  * If it's a string, the in-memory API is used
##  * If it's a reference, the streaming API is used
## The third argument is a boolean
##  * true: streaming
##  * false: in-memory
## The fourth is description of test

sub verify {
  my ($source_arg, $target_arg, $streaming_output, $test_name) = @_;

  my $differ_backend_to_use = $ENV{VCDIFF_TEST_DIFFER_BACKEND} || $Vcdiff::backend;
  my $patcher_backend_to_use = $ENV{VCDIFF_TEST_PATCHER_BACKEND} || $Vcdiff::backend;

  my ($source, $target, $delta);

  if (ref $source_arg) {
    $source = tempfile();
    $source->autoflush(1);
    print $source $$source_arg;
  } else {
    $source = $source_arg;
  }

  if (ref $target_arg) {
    $target = tempfile();
    $target->autoflush(1);
    print $target $$target_arg;
    seek $target, 0, 0;
  } else {
    $target = $target_arg;
  }

  my ($target2, $target2_fh);

  if ($streaming_output) {
    $delta = tempfile();
    $delta->autoflush(1);
    $target2_fh = tempfile();
    $target2_fh->autoflush(1);

    {
      local $Vcdiff::backend = $differ_backend_to_use;
      Vcdiff::diff($source, $target, $delta);
    }

    seek $delta, 0, 0;

    {
      local $Vcdiff::backend = $patcher_backend_to_use;
      Vcdiff::patch($source, $delta, $target2_fh);
    }

    seek $target2_fh, 0, 0;

    {
      local $/;
      $target2 = <$target2_fh>;
    }
  } else {
    {
      local $Vcdiff::backend = $differ_backend_to_use;
      $delta = Vcdiff::diff($source, $target);
    }

    {
      local $Vcdiff::backend = $patcher_backend_to_use;
      $target2 = Vcdiff::patch($source, $delta);
    }
  }

  if (ref $target_arg) {
    Test::More::is($target2, $$target_arg, $test_name);
  } else {
    Test::More::is($target2, $target, $test_name);
  }
}






## Some backends might only support an in memory API so this is split out into its own test routine

sub in_mem {
  foreach my $testcase (@$testcases) {
    die "incorrect number of elements in testcase spec" if @$testcase != 3;

    verify($testcase->[0], $testcase->[1], undef, $testcase->[2]);
  }
}


## Try every combination of streaming/in-memory

sub streaming {
  my $opt = shift;

  foreach my $testcase (@$testcases) {
    die "incorrect number of elements in testcase spec" if @$testcase != 3;

    Test::More::diag($testcase->[2]);

    for my $i (0..7) {
      my $src = $testcase->[0];
      my $trg = $testcase->[1];
      my $streaming_output;

      $src = \$src if $i & 1;
      $trg = \$trg if $i & 2;
      $streaming_output = 1 if $i & 4;

      next if $opt->{skip_streaming_source_tests} && ($i & 1);

      my $combination = (($i & 1) ? 'M' : 'S') .
                        (($i & 2) ? 'M' : 'S') .
                        (($i & 4) ? 'S' : 'M');

      verify($src, $trg, $streaming_output, "[$combination]");
    }
  }
}


1;
