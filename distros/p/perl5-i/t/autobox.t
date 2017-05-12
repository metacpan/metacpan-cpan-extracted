use Test::More tests => 3;

use perl5-i;

my $answer = 42;
[42, 43, 44]->foreach(sub {
    is $_[0], $answer++, "Number $_[0] is ok";
});
