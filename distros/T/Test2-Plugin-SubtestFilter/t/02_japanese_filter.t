use Test2::V0;
use Test2::Plugin::UTF8;

use lib 't/lib';
use TestHelper;

my $test_file = 't/examples/japanese.t';

my @tests = (
    {
        name => 'no SUBTEST_FILTER - all tests run',
        filter => undef,
        expect => {
            'ユーザー認証'                               => 'executed',
            'ユーザー認証 > パスワード検証'              => 'executed',
            'ユーザー認証 > トークン管理'                => 'executed',
            'データベース操作'                           => 'executed',
            'データベース操作 > トランザクション処理'    => 'executed',
            '文字列処理'                                 => 'executed',
            '文字列処理 > 正規表現マッチング'            => 'executed',
            '文字列処理 > 正規表現マッチング > 漢字かな' => 'executed',
            'テスト用データ'                             => 'executed',
        },
    },
    {
        name => 'Run with SUBTEST_FILTER=ユーザー認証',
        filter => 'ユーザー認証',
        expect => {
            'ユーザー認証'                               => 'executed',
            'ユーザー認証 > パスワード検証'              => 'executed',
            'ユーザー認証 > トークン管理'                => 'executed',
            'データベース操作'                           => 'skipped',
            '文字列処理'                                 => 'skipped',
            'テスト用データ'                             => 'skipped',
        },
    },
    {
        name => 'Run with SUBTEST_FILTER=データベース操作',
        filter => 'データベース操作',
        expect => {
            'ユーザー認証'                               => 'skipped',
            'データベース操作'                           => 'executed',
            'データベース操作 > トランザクション処理'    => 'executed',
            '文字列処理'                                 => 'skipped',
            'テスト用データ'                             => 'skipped',
        },
    },
    {
        name => 'Run with Japanese substring 処理 - matches multiple',
        filter => '処理',
        expect => {
            'ユーザー認証'                               => 'skipped',
            'データベース操作'                           => 'executed',
            'データベース操作 > トランザクション処理'    => 'executed',
            '文字列処理'                                 => 'executed',
            '文字列処理 > 正規表現マッチング'            => 'executed',
            '文字列処理 > 正規表現マッチング > 漢字かな' => 'executed',
            'テスト用データ'                             => 'skipped',
        },
    },
    {
        name => 'Run with space-separated Japanese path',
        filter => 'データベース操作 トランザクション処理',
        expect => {
            'ユーザー認証'                               => 'skipped',
            'データベース操作'                           => 'executed',
            'データベース操作 > トランザクション処理'    => 'executed',
            '文字列処理'                                 => 'skipped',
            'テスト用データ'                             => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER for deeply nested child 漢字かな',
        filter => '漢字かな',
        expect => {
            'ユーザー認証'                               => 'skipped',
            'データベース操作'                           => 'skipped',
            '文字列処理'                                 => 'executed',
            '文字列処理 > 正規表現マッチング'            => 'executed',
            '文字列処理 > 正規表現マッチング > 漢字かな' => 'executed',
            'テスト用データ'                             => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER="パスワード検証" - explores top level for multi-word',
        filter => 'パスワード検証',
        expect => {
            'ユーザー認証'                               => 'executed',
            'ユーザー認証 > パスワード検証'              => 'executed',
            'ユーザー認証 > トークン管理'                => 'skipped',
            'データベース操作'                           => 'skipped',
            '文字列処理'                                 => 'skipped',
            'テスト用データ'                             => 'skipped',
        },
    },
    {
        name => 'No match with Japanese filter 存在しないテスト - skips all',
        filter => '存在しないテスト',
        expect => {
            'ユーザー認証'                               => 'skipped',
            'データベース操作'                           => 'skipped',
            '文字列処理'                                 => 'skipped',
            'テスト用データ'                             => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER with partial nested path match - single word',
        filter => 'トラン',
        expect => {
            'ユーザー認証'                               => 'skipped',
            'データベース操作'                           => 'executed',
            'データベース操作 > トランザクション処理'    => 'executed',
            '文字列処理'                                 => 'skipped',
            'テスト用データ'                             => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER with partial nested path match - two words',
        filter => '文字列処理 正規',
        expect => {
            'ユーザー認証'                               => 'skipped',
            'データベース操作'                           => 'skipped',
            '文字列処理'                                 => 'executed',
            '文字列処理 > 正規表現マッチング'            => 'executed',
            '文字列処理 > 正規表現マッチング > 漢字かな' => 'executed',
            'テスト用データ'                             => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER with partial match behavior - short substring',
        filter => 'デ',
        expect => {
            'ユーザー認証'                               => 'skipped',
            'データベース操作'                           => 'executed',
            'データベース操作 > トランザクション処理'    => 'executed',
            '文字列処理'                                 => 'skipped',
            'テスト用データ'                             => 'executed',
        },
    },
);

for my $tc (@tests) {
    subtest $tc->{name} => sub {
        my $stdout = run_test_file($test_file, $tc->{filter});

        for my $name (sort keys %{$tc->{expect}}) {
            my $status = $tc->{expect}{$name};
            if ($status eq 'executed') {
                like($stdout, match_executed($name), "$name is executed");
            } elsif ($status eq 'skipped') {
                like($stdout, match_skipped($name), "$name is skipped");
            }
        }
    };
}

done_testing;
