# vi:filetype=

use strict;
use warnings;

my $skip;
BEGIN {
    eval "use Class::Accessor::Fast";
    if ($@) { $skip = 'Class::Accessor::Fast required to run this test' }
}
use Test::More $skip ? (skip_all => $skip) : ();
use UML::Class::Simple;
use Data::Dumper;

$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys=1;

plan tests => 1;

require "t/data/TestClassAccessorFast.pm";
my $painter = UML::Class::Simple->new(['TestClassAccessorFast']);

my $dom = $painter->as_dom;

is Dumper($dom), <<'_EOC_';
$VAR1 = {
  'classes' => [
    {
      'methods' => [
        'blah'
      ],
      'name' => 'TestClassAccessorFast',
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

