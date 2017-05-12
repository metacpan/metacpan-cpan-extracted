use lib lib => 't/lib' => glob 'modules/*/lib';
use WebService::Qiita::Test;
use WebService::Qiita;

use Test::More;
use Test::Fatal;
use Test::Mock::Guard qw(mock_guard);

use Carp qw(croak);
use JSON qw(encode_json);

subtest delegade => sub {
    my $stub_ref = sub { croak q(exists delegaded method) };

    subtest client => sub {
        my $client_mock_funcs = +{
            rate_limit => $stub_ref,
        };
        my $mock = mock_guard 'WebService::Qiita::Client', $client_mock_funcs;
        for (keys %$client_mock_funcs) {
            like exception {WebService::Qiita->$_; }, qr(exists delegaded method);
        }

        subtest undefined_method => sub {
            like exception {WebService::Qiita->nainai; }, qr(no such func);
        }
    };

    subtest users => sub {
        my $user_mock_funcs = +{
            user_items           => $stub_ref,
            user_following_tags  => $stub_ref,
            user_following_users => $stub_ref,
            user_stocks          => $stub_ref,
            user                 => $stub_ref,
        };
        my $mock = mock_guard 'WebService::Qiita::Client::Users', $user_mock_funcs;

        for (keys %$user_mock_funcs) {
            like exception {WebService::Qiita->$_; }, qr(exists delegaded method);
        }

        subtest undefined_method => sub {
            like exception {WebService::Qiita->nainai; }, qr(no such func);
        }
    };

    subtest tags => sub {
        my $tag_mock_funcs = +{
            tag_items  => $stub_ref,
            tags       => $stub_ref,
        };
        my $mock = mock_guard 'WebService::Qiita::Client::Tags', $tag_mock_funcs;

        for (keys %$tag_mock_funcs) {
            like exception {WebService::Qiita->$_; }, qr(exists delegaded method);
        }

        subtest undefined_method => sub {
            like exception {WebService::Qiita->nainai; }, qr(no such func);
        }
    };
};


done_testing;
