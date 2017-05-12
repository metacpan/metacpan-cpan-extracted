use strict;
use warnings;

use Test::More;

use Text::APL::Context;

my $context;

my $context1 = Text::APL::Context->new;
my $context2 = Text::APL::Context->new;
is($context1->id, $context2->id);

$context1 = Text::APL::Context->new;
$context1->add_var(foo => 'bar');
$context2 = Text::APL::Context->new;
$context2->add_helper(foo => sub {});
isnt($context1->id, $context2->id);

done_testing;
