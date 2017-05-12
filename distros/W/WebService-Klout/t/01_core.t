use strict;
use warnings;
use Test::More;
use WebService::Klout;

my $klout;

subtest 'new' => sub {
    local $ENV{'KLOUT_API_KEY'} = 'KLOUT_API_KEY';
    $klout = new_ok('WebService::Klout');
};

done_testing;
