use strict;
use warnings;
use Test::More;

use WebService::DMM;

subtest 'change own UserAgent' => sub {
    my $ua = Furl->new( agent => 'test' );
    $WebService::DMM::UserAgent = $ua;

    is WebService::DMM::__ua()->agent, 'test', 'Setting own UserAgent';
};

done_testing;
