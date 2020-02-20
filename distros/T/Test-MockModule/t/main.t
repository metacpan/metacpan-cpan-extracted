use warnings;
use strict;

use Test::More;
use Test::Warnings;

use Test::MockModule;

sub fourofour { 404 }

my $mocker = Test::MockModule->new('main')->redefine( fourofour => 200 );

is fourofour(), 200, "can mock a function in main # need SUPER > 1.17";

done_testing();
