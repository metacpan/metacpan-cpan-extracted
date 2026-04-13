#!perl

use v5.16;
use strict;
use warnings;
use Test::More;
use Test::QuickGen qw();

my %tags = %Test::QuickGen::EXPORT_TAGS;

is_deeply(
  [ sort @Test::QuickGen::EXPORT_OK ],
  [ sort @{$tags{all} }],
  ':all tag matches EXPORT_OK'
);

for my $tag (keys %tags) {
  subtest "import tag $tag" => sub {
    my @expected = @{$tags{$tag}};

    {
      package TestTag;
      Test::QuickGen->import(":$tag");

      for my $fn (@expected) {
        ::ok(defined &{$fn}, "$fn imported");
      }
    }
  };
}

done_testing;
