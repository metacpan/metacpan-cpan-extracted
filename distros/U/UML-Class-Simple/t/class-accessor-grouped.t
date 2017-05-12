use strict;
use warnings;

# vi:filetype=
my $skip;
BEGIN {
    eval "use Class::Accessor::Grouped";
    if ($@) { $skip = 'Class::Accessor::Grouped required to run this test' }
}
use Test::More $skip ? (skip_all => $skip) : ();
use UML::Class::Simple;
use Data::Dumper;

$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys=1;

plan tests => 3;

require "t/data/TestClassAccessorGrouped.pm";
my $painter = UML::Class::Simple->new(['TestClassAccessorGrouped']);

my $dom = $painter->as_dom;

is Dumper($dom), <<'_EOC_';
$VAR1 = {
  'classes' => [
    {
      'methods' => [
        'blah',
        'overridden'
      ],
      'name' => 'TestClassAccessorGrouped',
      'properties' => [
        'lr1name',
        'lr2name',
        'multiple1',
        'multiple2',
        'result_class',
        'singlefield'
      ],
      'subclasses' => []
    }
  ]
};
_EOC_

require "t/data/TestClassAccessorGroupedInheritance.pm";
my $painter2 =
UML::Class::Simple->new(['TestClassAccessorGroupedInheritance']);

my $dom2 = $painter2->as_dom;

is Dumper($dom2), <<'_EOC_';
$VAR1 = {
  'classes' => [
    {
      'methods' => [
        'overridden',
        'subclass_only'
      ],
      'name' => 'TestClassAccessorGroupedInheritance',
      'properties' => [
        'lr1name',
        'lr2name',
        'multiple1',
        'multiple2',
        'result_class',
        'singlefield',
        'sub_lr1name',
        'sub_lr2name',
        'sub_multiple1',
        'sub_multiple2',
        'sub_result_class',
        'sub_singlefield'
      ],
      'subclasses' => []
    }
  ]
};
_EOC_

my $painter3 =
UML::Class::Simple->new(['TestClassAccessorGroupedInheritance']);

$painter3->inherited_methods(0);

my $dom3 = $painter3->as_dom;

is Dumper($dom3), <<'_EOC_';
$VAR1 = {
  'classes' => [
    {
      'methods' => [
        'overridden',
        'subclass_only'
      ],
      'name' => 'TestClassAccessorGroupedInheritance',
      'properties' => [
        'sub_lr1name',
        'sub_lr2name',
        'sub_multiple1',
        'sub_multiple2',
        'sub_result_class',
        'sub_singlefield'
      ],
      'subclasses' => []
    }
  ]
};
_EOC_

