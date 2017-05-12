#!perl
package main;
use Test::Most 'die';
BEGIN {
    eval 'use PPIx::XPath 2.00';
    plan skip_all => 'PPIx::XPath 2.00 needed for this test' if $@;
}

package PPITransform;{
 use Tree::Transform::XSLTish;
 use strict;
 use warnings;

 default_rules;

 tree_rule match => 'Statement-Sub', action => sub {
     return $_[0]->it->name.$_[0]->it->prototype;
 };

}

package main;
use strict;
use warnings;
use PPI;

plan tests=>1;

{
my $doc=PPI::Document->new(\<<'EOP');
sub gino($%) {}
sub pino {}

gino(\&pino,{1=>2});
EOP

my $trans=PPITransform->new();

my @results=$trans->transform($doc);
is_deeply \@results,['gino($%)','pino'],'PPI example';
}
