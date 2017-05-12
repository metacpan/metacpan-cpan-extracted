use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Mock::Guard;

use Test::Docker::Image::Utility;

subtest "docker" => sub {
    my @input = qw/run -d -t iwata:mysql51-q4m-hs/;

    my $guard = mock_guard('Test::Docker::Image::Utility' => +{
        run => sub {
            my @got_cmd = @_;
            is_deeply \@got_cmd => ['docker', @input], 'append docker to head';
        },
    });

    lives_and {
        docker(@input);
        is $guard->call_count('Test::Docker::Image::Utility' => 'run') => 1, 'call run method';
    } 'execute docker comannd';
};

subtest "_run" => sub {
    local $ENV{DEBUG} = 1;

    lives_ok {
        Test::Docker::Image::Utility::run('pwd');
    } 'available command';

    dies_ok {
        Test::Docker::Image::Utility::run('hoge');
    } 'nonavailable command';
};

done_testing;
