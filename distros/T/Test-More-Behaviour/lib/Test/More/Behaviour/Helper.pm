package Test::More::Behaviour::Helper;

use strict;
use warnings;

use Exporter qw(import);
use Test::More;
use Term::ANSIColor qw(colored);

our @EXPORT = qw(evaluate_and_print_subtest spec_description context_description);

my $spec_description;
my $context_description;
my $passed = 1;

sub evaluate_and_print_subtest {
  my ($description, $block) = @_;

  print _subtest(_construct_description($description) => _subtest_block($block));

  return;
}

sub _subtest {
  my ($description, $block) = @_;

  $block->();
  return $description->(),"\n";
}

sub _subtest_block {
  my $block = shift;

  return sub {
    eval {
      $passed = $block->();
      1;
    } or do {
      $passed = 0;
      fail($@);
    };
  };
}

sub _construct_description {
  my $result = shift;

  $result = "$spec_description\n  $result" if $spec_description and (! $context_description);
  $result = "$spec_description\n  $context_description\n    $result" if $spec_description and $context_description;

  return sub { colored [_color()], $result };
}

sub _color {
  return $passed ? 'green' : 'red';
}

sub spec_description { $spec_description = shift; }
sub context_description { $context_description = shift; }

1;
