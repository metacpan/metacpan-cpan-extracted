# vi:filetype=

my $skip;
BEGIN {
    eval "use Class::Accessor";
    if ($@) { $skip = 'Class::Accessor required to run this test' }
}
use Test::More $skip ? (skip_all => $skip) : ();
use UML::Class::Simple;
use Data::Dumper;

$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys=1;

plan tests => 1;

require "t/data/TestClassAccessorPBP.pm";
$painter = UML::Class::Simple->new(['TestClassAccessorPBP']);

my $dom = $painter->as_dom;

is Dumper($dom), <<'_EOC_';
$VAR1 = {
  'classes' => [
    {
      'methods' => [
        'blah'
      ],
      'name' => 'TestClassAccessorPBP',
      'properties' => [
        'name',
        'role',
        'salary'
      ],
      'subclasses' => []
    }
  ]
};
_EOC_

