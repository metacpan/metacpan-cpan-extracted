package Mock::StrictModule;

use strict;
use warnings;

use Test::Mock::Simple;

my $mock = Test::Mock::Simple->new(module => 'StrictModule');

$mock->add(add => sub { return "Should have die'd with a error"; });

1;
